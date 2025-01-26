import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String messageId;
  final String senderId;
  final String message;
  final DateTime timestamp;
  final bool isImage;
  final bool isUploading; // For temporary messages

  Message({
    required this.messageId,
    required this.senderId,
    required this.message,
    required this.timestamp,
    this.isImage = false,
    this.isUploading = false,
  });

  // Factory to create a message from Firestore
  factory Message.fromMap(Map<String, dynamic> map, String id) {
    return Message(
      messageId: id,
      senderId: map['senderId'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isImage: map['isImage'] ?? false,
      isUploading: map['isUploading'] ?? false, // Default to false
    );
  }

  // Convert to map for temporary message handling
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'message': message,
      'timestamp': timestamp,
      'isImage': isImage,
      'isUploading': isUploading,
    };
  }
}