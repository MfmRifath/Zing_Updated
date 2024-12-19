import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import '../Modal/ChatMessage.dart';
import '../Modal/CoustomUser.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // Add FirebaseStorage instance

  String userId;
  String storeId;
  String senderRole; // 'Owner' or 'User'
  final TextEditingController messageController = TextEditingController();

  ChatProvider({
    required this.userId,
    required this.storeId,
    required this.senderRole,
  });

  // Fetch messages between current user and store
  Stream<List<ChatMessage>> fetchMessages() {
    // Query 1: Messages where the user is the sender
    final sentMessages = _firestore
        .collection('chats')
        .doc(storeId)
        .collection('messages')
        .where('senderId', isEqualTo: userId)
        .snapshots();

    // Query 2: Messages where the user is the receiver
    final receivedMessages = _firestore
        .collection('chats')
        .doc(storeId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .snapshots();

    // Combine both streams
    return Rx.combineLatest2(
      sentMessages,
      receivedMessages,
          (QuerySnapshot<Map<String, dynamic>> sentSnapshot, QuerySnapshot<Map<String, dynamic>> receivedSnapshot) {
        // Map both sent and received messages
        final sentList = sentSnapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
        final receivedList = receivedSnapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();

        // Combine both lists
        return [...sentList, ...receivedList];
      },
    ).map((messages) {
      // Optionally, you can sort the combined messages by timestamp
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }



  // Fetch messages only for the store owner
  Stream<List<ChatMessage>> fetchMessagesForStoreOwner(String storeId) {
    return _firestore
        .collection('chats')
        .doc(storeId)
    // Ensure we're only fetching messages for this specific store
        .collection('messages') // Store is the receiver
        .snapshots()
        .map((snapshot) {
      List<ChatMessage> messages = snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();

      // Sort messages by timestamp manually
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return messages;
    });
  }

  // Send message
  Future<String?> uploadImage(File image) async {
    try {
      // Create a unique file name
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload image to Firebase Storage
      final task = await _storage.ref('chat_images/$storeId/$fileName').putFile(image);

      // Get download URL of uploaded image
      final downloadUrl = await task.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Updated sendMessage method to handle text and image
  Future<void> sendMessage(
      String message,
      CustomUser? sender,
      CustomUser? userReceiver,
      [ChatMessage? replyToMessage, String? imageUrl]
      ) async {
    if (message.isEmpty && imageUrl == null || sender == null) return;

    final receiverId = sender.role == "User" ? storeId : userReceiver?.id;
    if (receiverId == null) return;

    final chatMessage = ChatMessage(
      id: '',
      message: message,
      senderId: sender.role == "User" ? sender.id : storeId,
      receiverId: receiverId,
      senderName: sender.role == "User" ? sender.name : sender.store!.name,
      senderProfileImageUrl: sender.role == "User" ? sender.profileImageUrl : sender.store!.imageUrl,
      timestamp: Timestamp.now(),
      replyToMessageId: replyToMessage?.id,
      replyToMessageContent: replyToMessage?.message,
      imageUrl: imageUrl,  // Pass the image URL if any
    );

    await _firestore
        .collection('chats')
        .doc(storeId)
        .collection('messages')
        .add(chatMessage.toMap());

    messageController.clear();  // Clear input after sending
  }
  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    await _firestore
        .collection('chats')
        .doc(storeId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  // Update user ID
  void updateUserId(String newUserId) {
    userId = newUserId;
    notifyListeners();
  }

  // Update store ID
  void updateStoreId(String newStoreId) {
    storeId = newStoreId;
    notifyListeners();
  }

  // Update sender role
  void updateSenderRole(String newRole) {
    senderRole = newRole;
    notifyListeners();
  }
}
