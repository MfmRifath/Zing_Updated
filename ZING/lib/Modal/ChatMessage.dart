import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  String id;
  String message;
  String senderId;
  String receiverId;
  String senderName;
  String senderProfileImageUrl;
  String? replyToMessageId; // Add this field for message reply
  String? replyToMessageContent; // Add this field for message reply content
  Timestamp timestamp;
  String? imageUrl;

  ChatMessage({
    required this.id,
    required this.message,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.senderProfileImageUrl,
    this.replyToMessageId, // Optional field
    this.replyToMessageContent, // Optional field
    required this.timestamp,
    this.imageUrl,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      message: data['message'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderProfileImageUrl: data['senderProfileImageUrl'] ?? '',
      replyToMessageId: data['replyToMessageId'], // Fetch replyToMessageId
      replyToMessageContent: data['replyToMessageContent'], // Fetch replyToMessageContent
      timestamp: data['timestamp'] ?? Timestamp.now(),
      imageUrl: data['imageUrl'] ,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'senderProfileImageUrl': senderProfileImageUrl,
      'replyToMessageId': replyToMessageId, // Include replyToMessageId
      'replyToMessageContent': replyToMessageContent, // Include replyToMessageContent
      'timestamp': timestamp,
      'imageUrl':imageUrl
    };
  }
}
