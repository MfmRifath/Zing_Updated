import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String messageId;
  final String senderId;
  final String message;
  final DateTime timestamp;
  final bool isImage;
  final bool isUploading;
  final bool isSending;

  /// New fields for replying/quoting:
  final String? replyToText;
  final String? replyToSenderName;

  Message({
    required this.messageId,
    required this.senderId,
    required this.message,
    required this.timestamp,
    this.isImage = false,
    this.isUploading = false,
    this.isSending = false,
    this.replyToText,
    this.replyToSenderName,
  });

  // --------------------------------------------------------------------------
  // Factory to create a message from Firestore
  factory Message.fromMap(Map<String, dynamic> map, String docId) {
    return Message(
      messageId: docId,
      senderId: map['senderId'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isImage: map['isImage'] ?? false,
      isUploading: false,         // Firestore won't store 'isUploading'
      isSending: map['isSending'] ?? false,
      replyToText: map['replyToText'] as String?,           // could be null
      replyToSenderName: map['replyToSenderName'] as String?, // could be null
    );
  }

  // --------------------------------------------------------------------------
  // Convert to map for Firestore or temporary message handling
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isImage': isImage,
      'isUploading': isUploading,  // Typically not stored in Firestore
      'isSending': isSending,      // Typically not stored in Firestore
      // Add the reply fields if they exist
      if (replyToText != null) 'replyToText': replyToText,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
    };
  }

  // --------------------------------------------------------------------------
  // Create a modified copy of this Message (e.g., to update flags)
  Message copyWith({
    String? messageId,
    String? senderId,
    String? message,
    DateTime? timestamp,
    bool? isImage,
    bool? isUploading,
    bool? isSending,
    String? replyToText,
    String? replyToSenderName,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isImage: isImage ?? this.isImage,
      isUploading: isUploading ?? this.isUploading,
      isSending: isSending ?? this.isSending,
      replyToText: replyToText ?? this.replyToText,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
    );
  }
}