import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../Modal/ChatMessage.dart';
import '../Modal/CoustomUser.dart';
import '../Service/ChatProvider.dart';
import '../Service/TrasnlationService.dart';
import '../Service/CoustomUserProvider.dart';

class ChatScreen extends StatefulWidget {
  final CustomUser currentUser;
  final String storeId;
  final String storeImageUrl;
  final String userImageUrl;

  ChatScreen({
    required this.currentUser,
    required this.storeId,
    required this.storeImageUrl,
    required this.userImageUrl,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isInitialized = false;
  final ScrollController _scrollController = ScrollController();
  ChatMessage? _selectedMessage;
  String _selectedLanguage = 'en'; // Default language: English
  final TranslationService _translationService = TranslationService(); // Translation service instance

  // Store translated messages in a map
  Map<String, String> _translatedMessages = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        chatProvider.updateUserId(widget.currentUser.id);
        chatProvider.updateStoreId(widget.storeId);
        chatProvider.updateSenderRole(chatProvider.senderRole);
      });
      _isInitialized = true;
    }
  }

  Future<void> _pickAndSendImage(ChatProvider chatProvider, CustomUser currentUser, CustomUserProvider customUserProvider) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery); // You can also use ImageSource.camera for camera

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      // Upload the image to Firebase Storage
      String? imageUrl = await chatProvider.uploadImage(imageFile);

      if (imageUrl != null) {
        // Send the image URL as a message
        chatProvider.sendMessage(
          '',
          currentUser,
          currentUser,  // Receiver is either store or user
          null,  // No reply
          imageUrl,  // Image URL
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _selectMessageForReply(ChatMessage message) {
    setState(() {
      _selectedMessage = message;
    });
  }

  void _cancelReply() {
    setState(() {
      _selectedMessage = null;
    });
  }

  void _confirmDeleteMessage(BuildContext context, ChatProvider chatProvider, String messageId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Message'),
          content: Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                chatProvider.deleteMessage(messageId);
                Navigator.of(context).pop();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _translateMessage(String message, String targetLang) async {
    return await _translationService.translateText(message, targetLang);
  }

  BoxDecoration _messageDecoration(bool isSentByUser) {
    return BoxDecoration(
      gradient: isSentByUser
          ? LinearGradient(colors: [Colors.deepPurpleAccent, Colors.purpleAccent])
          : LinearGradient(colors: [Colors.greenAccent, Colors.lightGreen]),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: isSentByUser ? Radius.circular(16) : Radius.zero,
        bottomRight: isSentByUser ? Radius.zero : Radius.circular(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final customUserProvider = Provider.of<CustomUserProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.currentUser.role == 'Owner' && widget.currentUser.store!.id == widget.storeId
              ? 'Chat with Customer'
              : 'Chat with Store',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 2,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              icon: Icon(Icons.language, color: Colors.white),
              underline: Container(),
              dropdownColor: Colors.deepPurpleAccent,
              items: [
                DropdownMenuItem(
                  child: Text('English', style: TextStyle(color: Colors.white)),
                  value: 'en',
                ),
                DropdownMenuItem(
                  child: Text('Tamil', style: TextStyle(color: Colors.white)),
                  value: 'ta',
                ),
                DropdownMenuItem(
                  child: Text('Sinhala', style: TextStyle(color: Colors.white)),
                  value: 'si',
                ),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<CustomUser?>(
        future: customUserProvider.getUserById(chatProvider.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SpinKitFadingCircle(
                color: Colors.blueAccent,
                size: 60.0,
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error loading user data'));
          }

          return Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.2,
                  child: Image.asset(
                    'assets/images/zing.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: StreamBuilder<List<ChatMessage>>(
                      stream: widget.currentUser.role == "Owner" && widget.currentUser.store!.id == widget.storeId
                          ? chatProvider.fetchMessagesForStoreOwner(widget.storeId)
                          : chatProvider.fetchMessages(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Text('No messages yet.'));
                        }

                        final messages = snapshot.data!;

                        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                        return ListView.builder(
                          controller: _scrollController,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            bool isSentByUser = message.senderId == widget.currentUser.id || (widget.currentUser.store != null ? message.senderId == widget.currentUser.store!.id : false);

                            final currentUserProfileImageUrl = (widget.currentUser.role == 'Owner' && widget.currentUser.store!.id == widget.storeId)
                                ? widget.currentUser.store!.imageUrl
                                : widget.userImageUrl;

                            return Dismissible(
                              key: Key(message.id),
                              direction: DismissDirection.startToEnd,
                              onDismissed: (direction) {
                                _selectMessageForReply(message);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Message selected for reply')),
                                );
                              },
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                color: Colors.blueAccent.withOpacity(0.5),
                                child: Icon(Icons.reply, color: Colors.white),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: isSentByUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  children: [
                                    if (!isSentByUser)
                                      CircleAvatar(
                                        backgroundImage: message.senderProfileImageUrl.isNotEmpty
                                            ? NetworkImage(message.senderProfileImageUrl)
                                            : AssetImage('assets/images/zing.png') as ImageProvider,
                                        radius: 24,
                                        backgroundColor: Colors.white,
                                      ),
                                    if (!isSentByUser) SizedBox(width: 10),
                                    Flexible(
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        padding: const EdgeInsets.all(14.0),
                                        decoration: _messageDecoration(isSentByUser),
                                        child: Column(
                                          crossAxisAlignment: isSentByUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                          children: [
                                            if (message.replyToMessageContent != null)
                                              Text(
                                                'Replying to: ${message.replyToMessageContent}',
                                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                              ),
                                            SizedBox(height: 4),
                                            if (message.imageUrl != null) Image.network(message.imageUrl!), // Show image if available
                                            SizedBox(height: 4),
                                            Text(
                                              _translatedMessages[message.id] ?? message.message,
                                              style: TextStyle(color: Colors.white, fontSize: 16),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              _formatTimestamp(message.timestamp),
                                              style: TextStyle(fontSize: 10, color: Colors.grey[300]),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                final translation = await _translateMessage(message.message, _selectedLanguage);
                                                if (translation != null) {
                                                  setState(() {
                                                    _translatedMessages[message.id] = translation;
                                                  });
                                                }
                                              },
                                              child: Text('Translate', style: TextStyle(color: Colors.yellowAccent)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isSentByUser)
                                      CircleAvatar(
                                        backgroundImage: currentUserProfileImageUrl.isNotEmpty
                                            ? NetworkImage(currentUserProfileImageUrl)
                                            : AssetImage('assets/images/zing.png') as ImageProvider,
                                        radius: 24,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (_selectedMessage != null)
                    Container(
                      color: Colors.grey[200],
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.reply, color: Colors.grey),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Replying to: ${_selectedMessage!.message}",
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.cancel, color: Colors.redAccent),
                            onPressed: _cancelReply,
                          ),
                        ],
                      ),
                    ),
                  _buildMessageInput(chatProvider, widget.currentUser, customUserProvider),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildMessageInput(ChatProvider chatProvider, CustomUser currentUser, CustomUserProvider customUserProvider) {
    bool canSendMessage = currentUser.role == 'User' || (_selectedMessage != null && currentUser.role == 'Owner');

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.photo, color: Colors.deepPurpleAccent),
            onPressed: () => _pickAndSendImage(chatProvider, currentUser, customUserProvider),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: chatProvider.messageController,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(fontFamily: 'Montserrat'),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                maxLines: null,
                enabled: canSendMessage,
              ),
            ),
          ),
          SizedBox(width: 8),
          FloatingActionButton(
            onPressed: canSendMessage
                ? () async {
              final message = chatProvider.messageController.text;
              if (_selectedMessage != null) {
                chatProvider.sendMessage(
                    message,
                    currentUser,
                    _selectedMessage!.senderId == widget.storeId
                        ? currentUser
                        : await customUserProvider.getUserById(_selectedMessage!.senderId),
              _selectedMessage,
              );
              _cancelReply();
              } else {
              chatProvider.sendMessage(
              message,
              currentUser,
              currentUser,
              null,
              );
              }
              chatProvider.messageController.clear();
            }
                : null,
            child: Icon(Icons.send, color: Colors.white),
            backgroundColor: canSendMessage ? Colors.deepPurpleAccent : Colors.grey,
          ),
        ],
      ),
    );
  }
}
