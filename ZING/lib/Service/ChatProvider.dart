import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import '../Modal/ChatMessage.dart';

class ChatProvider with ChangeNotifier {
  // Single list of messages for the currently active chat:
  List<Message> _messages = [];
  List<Message> get messages => _messages;

  // A list of all chats for this store (for the store's "inbox" screen):
  List<Map<String, dynamic>> allChats = [];

  // --------------------------------------------------------------------------
  // 1) Fetch the store's chat list (the "inbox"):
  Future<void> fetchAllUserChats(String storeId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: storeId)
          .orderBy('lastUpdated', descending: true)
          .get();

      final chats = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final participants = data['participants'] as List<dynamic>;
        final customerId = participants.firstWhere((id) => id != storeId);

        chats.add({
          'chatId': doc.id,
          'customerId': customerId,
          'lastMessage': data['lastMessage'] ?? '',
          'lastUpdated': data['lastUpdated'] as Timestamp,
        });
      }

      allChats = chats;
      notifyListeners();
    } catch (e) {
      print("Error fetching all user chats: $e");
    }
  }

  // --------------------------------------------------------------------------
  // 2) Fetch all messages for a particular chat:
  Future<void> fetchMessages(String chatId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .get();

      final loaded = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Make sure your Message.fromMap supports replyTo fields
        return Message.fromMap(data, doc.id);
      }).toList();

      _messages = loaded;
      notifyListeners();
    } catch (e) {
      print("Error fetching messages: $e");
      throw e;
    }
  }

  // --------------------------------------------------------------------------
  // 3) Create chat document (if not exist) for user & store:
  Future<String> createChat({
    required String userId,
    required String storeId,
  }) async {
    // Simple approach: chatId is "userId_storeId" for 1-to-1
    final chatId = '${userId}_$storeId';
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    try {
      // Check if chat already exists
      final existingChat = await chatRef.get();
      if (!existingChat.exists) {
        // Create the new chat doc
        await chatRef.set({
          'participants': [userId, storeId],
          'lastMessage': '',
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // If it exists, optionally update 'lastUpdated'
        await chatRef.update({
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      return chatId;
    } catch (e) {
      debugPrint('Error creating chat: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // 4) Send a text message (with optional reply info)
  Future<void> sendMessage(
      String chatId,
      String senderId,
      String messageText, {
        String? replyToText,
        String? replyToSenderName,
      }) async {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    // 1. Create local temp message
    final tempMessage = Message(
      messageId: DateTime.now().toIso8601String(),
      senderId: senderId,
      message: messageText,
      timestamp: DateTime.now(),
      isImage: false,
      isUploading: false,
      // NEW: store reply info if provided
      replyToText: replyToText,
      replyToSenderName: replyToSenderName,
    );

    // 2. Insert the temp message for immediate UI
    _messages.insert(0, tempMessage);
    notifyListeners();

    try {
      // 3. Add the final message to Firestore (including reply fields if present)
      final newMessageDoc = await chatRef.collection('messages').add({
        'senderId': senderId,
        'message': messageText,
        'isImage': false,
        'timestamp': FieldValue.serverTimestamp(),
        if (replyToText != null) 'replyToText': replyToText,
        if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      });

      // 4. Update parent chat doc
      await chatRef.update({
        'lastMessage': messageText,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // 5. Remove the temp message
      _messages.remove(tempMessage);

      // 6. Insert final message with Firestore ID
      final finalMessage = Message(
        messageId: newMessageDoc.id,
        senderId: senderId,
        message: messageText,
        timestamp: DateTime.now(), // or parse from server if needed
        isImage: false,
        isUploading: false,
        // carry over the reply fields
        replyToText: replyToText,
        replyToSenderName: replyToSenderName,
      );
      _messages.insert(0, finalMessage);
      notifyListeners();

    } catch (e) {
      debugPrint('Error sending message: $e');
      // Remove temp from local list so UI is consistent
      _messages.remove(tempMessage);
      notifyListeners();
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // 5) Send an image (with ephemeral "uploading" state).
  //    If you also want to reply to images, add the same optional fields:
  Future<String> sendImage(
      String chatId,
      String senderId,
      File imageFile, {
        String? replyToText,
        String? replyToSenderName,
      }) async {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    // 1. Local temp message
    final tempMessage = Message(
      messageId: DateTime.now().toIso8601String(),
      senderId: senderId,
      message: imageFile.path, // local file path as placeholder
      timestamp: DateTime.now(),
      isImage: true,
      isUploading: true,
      // If replying to an existing message
      replyToText: replyToText,
      replyToSenderName: replyToSenderName,
    );
    _messages.insert(0, tempMessage);
    notifyListeners();

    try {
      // 2. Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref('chat_images/$chatId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = await storageRef.putFile(imageFile);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // 3. Create the final message doc in Firestore
      final newMessageDoc = await chatRef.collection('messages').add({
        'senderId': senderId,
        'message': imageUrl,
        'isImage': true,
        'timestamp': FieldValue.serverTimestamp(),
        if (replyToText != null) 'replyToText': replyToText,
        if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      });

      // 4. Update parent chat doc
      await chatRef.update({
        'lastMessage': '📷 Image',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // 5. Remove the temp message
      _messages.remove(tempMessage);

      // 6. Insert final message with the remote URL
      final finalMessage = Message(
        messageId: newMessageDoc.id,
        senderId: senderId,
        message: imageUrl,
        timestamp: DateTime.now(),
        isImage: true,
        isUploading: false,
        replyToText: replyToText,
        replyToSenderName: replyToSenderName,
      );
      _messages.insert(0, finalMessage);
      notifyListeners();

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      // On failure, remove the temp message
      _messages.remove(tempMessage);
      notifyListeners();
      throw Exception('Failed to upload image');
    }
  }

  // --------------------------------------------------------------------------
  // Delete a message (both locally & in Firestore)
  Future<void> deleteMessage(String chatId, Message message) async {
    try {
      // 1. Delete from Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(message.messageId)
          .delete();

      // 2. Remove from local list
      _messages.removeWhere((m) => m.messageId == message.messageId);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting message: $e");
      rethrow;
    }
  }

  // Add a message to our local list (front).
  void addMessage(String chatId, Message message) {
    _messages.insert(0, message);
    notifyListeners();
  }

  // Update a message in our local list by matching messageId.
  void updateMessage(String chatId, Message updatedMessage) {
    final index = _messages.indexWhere((m) => m.messageId == updatedMessage.messageId);
    if (index != -1) {
      _messages[index] = updatedMessage;
      notifyListeners();
    }
  }

  // Remove a message from local list by ID.
  void removeMessage(String chatId, Message message) {
    _messages.removeWhere((m) => m.messageId == message.messageId);
    notifyListeners();
  }
}