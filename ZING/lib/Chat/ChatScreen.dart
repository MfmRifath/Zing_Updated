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

  Future<void> _pickAndSendImage(ChatProvider chatProvider,
      CustomUser currentUser, CustomUserProvider customUserProvider) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource
        .gallery); // You can also use ImageSource.camera for camera

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      // Upload the image to Firebase Storage
      String? imageUrl = await chatProvider.uploadImage(imageFile);

      if (imageUrl != null) {
        // Send the image URL as a message
        chatProvider.sendMessage(
          '',
          currentUser,
          currentUser, // Receiver is either store or user
          null, // No reply
          imageUrl, // Image URL
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

  void _confirmDeleteMessage(BuildContext context, ChatProvider chatProvider, ChatMessage message) {
    if (message.senderId == widget.currentUser.id) {
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
                  chatProvider.deleteMessage(message.id);
                  Navigator.of(context).pop();
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can only delete your own messages.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  Future<String?> _translateMessage(String message, String targetLang) async {
    return await _translationService.translateText(message, targetLang);
  }

  BoxDecoration _messageDecoration(bool isSentByUser) {
    return BoxDecoration(
      gradient: isSentByUser
          ? LinearGradient(
          colors: [Colors.deepPurpleAccent, Colors.purpleAccent])
          : LinearGradient(colors: [Colors.black, Colors.white]),
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
    final customUserProvider = Provider.of<CustomUserProvider>(
        context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          (widget.currentUser.role == 'Owner' ||
              widget.currentUser.role == 'Admin') &&
              widget.currentUser.store!.id == widget.storeId
              ? 'Chat with Customer'
              : 'Chat with Store',
          style: TextStyle(
              fontFamily: 'Montserrat', fontWeight: FontWeight.w500),
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
                      stream: (widget.currentUser.role == "Owner" ||
                          widget.currentUser.role == "Admin") &&
                          widget.currentUser.store!.id == widget.storeId
                          ? chatProvider.fetchMessagesForStoreOwner(
                          widget.storeId)
                          : chatProvider.fetchMessages(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Text('No messages yet.'));
                        }

                        final messages = snapshot.data!;

                        WidgetsBinding.instance.addPostFrameCallback((_) =>
                            _scrollToBottom());

                        return ListView.builder(
                          controller: _scrollController,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            bool isSentByUser = message.senderId ==
                                widget.currentUser.id ||
                                (widget.currentUser.store != null
                                    ? message.senderId ==
                                    widget.currentUser.store!.id
                                    : false);

                            final currentUserProfileImageUrl = ((widget
                                .currentUser.role == 'Owner' ||
                                widget.currentUser.role == 'Admin') &&
                                widget.currentUser.store!.id == widget.storeId)
                                ? widget.currentUser.store!.imageUrl
                                : widget.userImageUrl;

                            return Dismissible(
                              key: Key(message.id),
                              direction: DismissDirection.startToEnd,
                              onDismissed: (direction) {
                                // Show a confirmation dialog before deleting the message
                                _confirmDeleteMessage(context, chatProvider, message);
                                _selectMessageForReply(message);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Message selected for reply'),
                                    backgroundColor: Colors.greenAccent, // Changed color for feedback
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blueAccent, Colors.blue.withOpacity(0.6)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.reply, color: Colors.white, size: 28),
                                    SizedBox(width: 10),
                                    Text('Reply', style: TextStyle(color: Colors.white, fontSize: 16)),
                                  ],
                                ),
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
                                        radius: 20,
                                        backgroundColor: Colors.grey.shade100,
                                      ),
                                    if (!isSentByUser) SizedBox(width: 10),
                                    Flexible(
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        padding: const EdgeInsets.all(12.0),
                                        decoration: BoxDecoration(
                                          color: isSentByUser ? Colors.deepPurpleAccent : Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(16.0),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 5,
                                              offset: Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: isSentByUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                          children: [
                                            if (message.replyToMessageContent != null)
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 6.0),
                                                child: Text(
                                                  'Replying to: ${message.replyToMessageContent}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            if (message.imageUrl != null)
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.network(
                                                  message.imageUrl!,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            SizedBox(height: 4),
                                            Text(
                                              _translatedMessages[message.id] ?? message.message,
                                              style: TextStyle(
                                                color: isSentByUser ? Colors.white : Colors.black87,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  _formatTimestamp(message.timestamp),
                                                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                                ),
                                                InkWell(
                                                  onTap: () async {
                                                    final translation = await _translateMessage(
                                                        message.message, _selectedLanguage);
                                                    if (translation != null) {
                                                      setState(() {
                                                        _translatedMessages[message.id] = translation;
                                                      });
                                                    }
                                                  },
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.translate, color: Colors.yellowAccent, size: 16),
                                                      SizedBox(width: 4),
                                                      Text('Translate', style: TextStyle(color: Colors.yellowAccent)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isSentByUser) SizedBox(width: 10),
                                    if (isSentByUser)
                                      CircleAvatar(
                                        backgroundImage: currentUserProfileImageUrl.isNotEmpty
                                            ? NetworkImage(currentUserProfileImageUrl)
                                            : AssetImage('assets/images/zing.png') as ImageProvider,
                                        radius: 20,
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
                  _buildMessageInput(
                      chatProvider, widget.currentUser, customUserProvider),
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

  Widget _buildMessageInput(ChatProvider chatProvider, CustomUser currentUser,
      CustomUserProvider customUserProvider) {
    bool canSendMessage = (currentUser.role == 'User' ||
        currentUser.role == 'Admin') ||
        (_selectedMessage != null &&
            (currentUser.role == 'Owner' || currentUser.role == 'Admin'));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                _pickAndSendImage(
                    chatProvider, currentUser, customUserProvider),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1),
              child: Icon(Icons.photo, color: Colors.deepPurpleAccent),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: chatProvider.messageController,
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  enabled: canSendMessage,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: canSendMessage
                ? () async {
              final message = chatProvider.messageController.text;
              if (_selectedMessage != null) {
                chatProvider.sendMessage(
                  message,
                  currentUser,
                  _selectedMessage!.senderId == widget.storeId
                      ? currentUser
                      : await customUserProvider.getUserById(
                      _selectedMessage!.senderId),
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
            child: CircleAvatar(
              radius: 24,
              backgroundColor: canSendMessage ? Colors.black: Colors
                  .grey.shade300,
              child: Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}