import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

import '../Modal/ChatMessage.dart';

class ChatProvider with ChangeNotifier {
  List<Message> messages = [];
  List<Map<String, dynamic>> allChats = [];

  // Fetch active chats for the store

  Future<void> fetchAllUserChats(String storeId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: storeId)
          .orderBy('lastUpdated', descending: true)
          .get();

      print("Fetched ${snapshot.docs.length} chats for storeId: $storeId");

      List<Map<String, dynamic>> chats = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print("Chat data: $data");

        final participants = data['participants'] as List<dynamic>;
        final customerId = participants.firstWhere((id) => id != storeId);

        // Add chat info to the list
        chats.add({
          'chatId': doc.id,
          'customerId': customerId,
          'lastMessage': data['lastMessage'] ?? '',
          'lastUpdated': data['lastUpdated'] as Timestamp,
        });
      }

      allChats = chats;
      print("All chats: $allChats");
      notifyListeners();
    } catch (e) {
      print("Error fetching all user chats: $e");
    }
  }
  // Fetch messages for a specific chat
  Future<void> fetchMessages(String chatId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .get();

    messages = snapshot.docs
        .map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    notifyListeners();
  }

  // Send a message
  Future<void> sendMessage(String chatId, String senderId, String messageText) async {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    await chatRef.collection('messages').add({
      'senderId': senderId,
      'message': messageText,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await chatRef.update({
      'lastMessage': messageText,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    await fetchMessages(chatId);
  }

  // Create a new chat and return its ID
  Future<String> createChat({
    required String userId,
    required String storeId,
  }) async {
    final chatId = '${userId}_$storeId';
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    await chatRef.set({
      'participants': [userId, storeId],
      'lastMessage': '',
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    return chatId;
  }
  // Send image
  // Send image with placeholder
  Future<void> sendImage(String chatId, String senderId, File imageFile) async {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    // Add a placeholder message
    final tempMessage = Message(
      messageId: DateTime.now().toString(),
      senderId: senderId,
      message: imageFile.path,
      timestamp: DateTime.now(),
      isImage: true,
      isUploading: true, // Mark as uploading
    );

    messages.insert(0, tempMessage);
    notifyListeners();

    try {
      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child('$chatId/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await storageRef.putFile(imageFile);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // Save image to Firestore
      await chatRef.collection('messages').add({
        'senderId': senderId,
        'message': imageUrl,
        'isImage': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Remove placeholder and replace with actual message
      messages.remove(tempMessage);
      messages.insert(
        0,
        Message(
          messageId: DateTime.now().toString(),
          senderId: senderId,
          message: imageUrl,
          timestamp: DateTime.now(),
          isImage: true,
          isUploading: false,
        ),
      );
      notifyListeners();

      // Update chat metadata
      await chatRef.update({
        'lastMessage': '📷 Image',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error uploading image: $e');
      messages.remove(tempMessage); // Remove placeholder on failure
      notifyListeners();
    }
  }
}