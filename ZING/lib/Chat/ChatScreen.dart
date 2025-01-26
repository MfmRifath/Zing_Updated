import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../Modal/ChatMessage.dart';
import '../Service/ChatProvider.dart';

class ChatScreen extends StatefulWidget {
  String? chatId; // Chat ID can be null initially
  final String userId; // Current user's ID
  final String storeId; // Store's ID (to generate chatId)
  final String storeName; // Store name for the chat title

  ChatScreen({
    this.chatId,
    required this.userId,
    required this.storeId,
    required this.storeName,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      _sendImage(File(pickedFile.path));
    }
  }

  Future<void> _sendImage(File imageFile) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (widget.chatId == null) {
      final newChatId = await chatProvider.createChat(
        userId: widget.userId,
        storeId: widget.storeId,
      );
      setState(() {
        widget.chatId = newChatId;
      });
    }

    await chatProvider.sendImage(widget.chatId!, widget.userId, imageFile);
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF50A5FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          "Chat with ${widget.storeName}",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFEFF3F8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Messages Display Section
            Expanded(
              child: widget.chatId == null
                  ? _buildEmptyConversation()
                  : FutureBuilder(
                future: chatProvider.fetchMessages(widget.chatId!),
                builder: (context, snapshot) {


                  if (chatProvider.messages.isEmpty) {
                    return _buildEmptyConversation();
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: chatProvider.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatProvider.messages[index];
                      final isMe = message.senderId == widget.userId;

                      return _buildMessageBubble(message, isMe);
                    },
                  );
                },
              ),
            ),

            // Message Input Section
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Tooltip(
                    message: "Send an image",
                    child: IconButton(
                      icon: Icon(Icons.image, color: Colors.grey[600]),
                      onPressed: _pickImage,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Color(0xFF4A90E2)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      final messageText = messageController.text.trim();
                      if (messageText.isNotEmpty) {
                        if (widget.chatId == null) {
                          final newChatId = await chatProvider.createChat(
                            userId: widget.userId,
                            storeId: widget.storeId,
                          );
                          setState(() {
                            widget.chatId = newChatId;
                          });
                        }

                        chatProvider.sendMessage(
                          widget.chatId!,
                          widget.userId,
                          messageText,
                        );

                        messageController.clear();
                      }
                    },
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFF4A90E2),
                      child: Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6),
        padding: message.isImage ? EdgeInsets.all(0) : EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: isMe
              ? LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF50A5FF)])
              : LinearGradient(colors: [Color(0xFFF1F0F0), Color(0xFFECECEC)]),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: isMe ? Radius.circular(12) : Radius.circular(0),
            bottomRight: isMe ? Radius.circular(0) : Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: message.isImage
            ? Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: message.isUploading
                  ? Image.file(
                File(message.message),
                fit: BoxFit.cover,
              )
                  : Image.network(
                message.message,
                fit: BoxFit.cover,
              ),
            ),
            if (message.isUploading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')} ${message.timestamp.hour >= 12 ? 'PM' : 'AM'}",
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyConversation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.message_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            "No messages yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            "Start the conversation by sending a message.",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}