import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// 1) Import translator
import 'package:translator/translator.dart';

import '../Modal/ChatMessage.dart';
import '../Service/ChatProvider.dart';

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  const FullScreenImageView({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Hero(
            tag: imageUrl,
            child: InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String userId;
  final String storeId;
  final String storeName;
  final String storeImageUrl;

  const ChatScreen({
    Key? key,
    this.chatId,
    required this.userId,
    required this.storeId,
    required this.storeName,
    required this.storeImageUrl,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ----------------------------------------------------------------
  // Controllers & State
  final TextEditingController messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  String? _chatId;
  String? get _effectiveChatId => _chatId ?? widget.chatId;

  String _cachedPresenceStatus = "Checking...";
  Message? _replyToMessage;
  late Future<void> _fetchMessagesFuture;

  // 2) Translator instance (unofficial GoogleTranslator)
  final GoogleTranslator _translator = GoogleTranslator();

  // 3) Cache of translations: key = "${messageId}_${langCode}", value = "translated text"
  final Map<String, String> _translationCache = {};

  // 4) Let the user pick one of English/Tamil/Sinhala
  final Map<String, String> _languageMap = {
    'English': 'en',
    'Tamil': 'ta',
    'Sinhala': 'si',
  };
  String _selectedLanguage = 'en'; // default is English

  @override
  void initState() {
    super.initState();

    // If a chat ID was provided, fetch its messages
    _fetchMessagesFuture = (widget.chatId != null)
        ? Provider.of<ChatProvider>(context, listen: false)
        .fetchMessages(widget.chatId!)
        : Future.value();

    _chatId = widget.chatId;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll the list to the bottom (newest message) when we want
  Future<void> _scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);

      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (_effectiveChatId == null) {
        final newChatId = await chatProvider.createChat(
          userId: widget.userId,
          storeId: widget.storeId,
        );
        setState(() => _chatId = newChatId);
      }

      try {
        await chatProvider.sendImage(_effectiveChatId!, widget.userId, file);
        _scrollToBottom();
      } catch (e) {
        debugPrint("Error uploading image: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to upload image. Please try again.")),
        );
      }
    }
  }

  // ----------------------------------------------------------------
  // Build
  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Chat area
            Expanded(
              child: _effectiveChatId == null
                  ? _buildEmptyConversation()
                  : FutureBuilder(
                future: _fetchMessagesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Error loading messages.'));
                  } else {
                    if (chatProvider.messages.isEmpty) {
                      return _buildEmptyConversation();
                    } else {
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: chatProvider.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatProvider.messages[index];
                          final isMe = (message.senderId == widget.userId);

                          // Show date header if needed
                          bool showDateHeader = false;
                          if (index == chatProvider.messages.length - 1) {
                            // Oldest => always show date
                            showDateHeader = true;
                          } else {
                            final nextMsg = chatProvider.messages[index + 1];
                            final currDate = _dayString(message.timestamp);
                            final nextDate = _dayString(nextMsg.timestamp);
                            showDateHeader = (currDate != nextDate);
                          }

                          return Column(
                            children: [
                              if (showDateHeader) _buildDateHeader(message.timestamp),
                              _buildMessageRow(message, isMe),
                            ],
                          );
                        },
                      );
                    }
                  }
                },
              ),
            ),

            // Bottom input
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leadingWidth: 50,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(widget.storeImageUrl),
        ),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store name
          Text(
            widget.storeName,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),

          // Presence stream
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('stores')
                .doc(widget.storeId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData &&
                  snapshot.connectionState == ConnectionState.waiting) {
                if (_cachedPresenceStatus == "Checking...") {
                  return Text(_cachedPresenceStatus,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12));
                } else {
                  return Text(_cachedPresenceStatus,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12));
                }
              }

              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null ||
                  !snapshot.data!.exists) {
                _cachedPresenceStatus = "Offline";
                return Text(_cachedPresenceStatus,
                    style: TextStyle(color: Colors.redAccent, fontSize: 12));
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final isOnline = data['isOnline'] ?? false;
              final lastActive = data['lastActiveAt'] as Timestamp?;

              if (isOnline) {
                _cachedPresenceStatus = "Online";
              } else {
                final lastSeenText = _formatLastSeen(lastActive?.toDate());
                _cachedPresenceStatus = lastSeenText;
              }

              return Text(
                _cachedPresenceStatus,
                style: TextStyle(
                  color: isOnline ? Colors.green.shade400 : Colors.grey[600],
                  fontSize: 12,
                ),
              );
            },
          ),
        ],
      ),
      centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.black),
      // Language dropdown for dynamic translations
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              items: _languageMap.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.value,
                  child: Text(entry.key, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (newLang) {
                if (newLang != null) {
                  setState(() {
                    // Clear the cache if changing language so we re-translate
                    _translationCache.clear();
                    _selectedLanguage = newLang;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------
  // Date header
  Widget _buildDateHeader(DateTime dateTime) {
    final dateLabel = _dayString(dateTime);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              dateLabel,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  // Single message row
  Widget _buildMessageRow(Message message, bool isMe) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 60 : 8,
        right: isMe ? 8 : 60,
        top: 4,
        bottom: 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(widget.storeImageUrl),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: _buildMessageBubble(message, isMe)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  // Chat bubble with dynamic translation
  Widget _buildMessageBubble(Message message, bool isMe) {
    final bubbleColor = isMe ? Colors.blue[600] : Colors.grey[50];
    final textColor = isMe ? Colors.white : Colors.black87;
    final borderRadius = BorderRadius.only(
      topLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
      topRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
      bottomLeft: const Radius.circular(12),
      bottomRight: const Radius.circular(12),
    );

    return GestureDetector(
      onLongPress: () => _onMessageLongPress(message, isMe),
      child: Container(
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: message.isImage
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Column(
            crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // If replying
              if (message.replyToText != null && message.replyToText!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue[400] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    message.replyToSenderName != null
                        ? "${message.replyToSenderName!}: ${message.replyToText!}"
                        : message.replyToText!,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isMe ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),

              if (message.isImage)
                _buildImageContent(message, isMe)
              else
              // 5) Dynamically translate text messages
                _buildTranslatedText(message.messageId, message.message),

              const SizedBox(height: 4),
              Text(
                _formatTimestamp(message.timestamp),
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // This widget translates the original text on-the-fly
  Widget _buildTranslatedText(String messageId, String originalText) {
    final cacheKey = "${messageId}_$_selectedLanguage";

    // 1) If we have a cached translation, use it
    if (_translationCache.containsKey(cacheKey)) {
      final translated = _translationCache[cacheKey]!;
      return Text(translated, style: const TextStyle(fontSize: 15, height: 1.2));
    }

    // 2) Not in cache => show "Translating..." placeholder
    //    while we do an async call
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fire off the translation if we haven't yet
      _translator
          .translate(
        originalText,
        from: 'auto',        // detect source
        to: _selectedLanguage,
      )
          .then((translation) {
        _translationCache[cacheKey] = translation.text;
        setState(() {}); // Rebuild to show translated text
      })
          .catchError((e) {
        debugPrint("Translation failed for message $messageId: $e");
      });
    });

    return const Text(
      "Translating...",
      style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
    );
  }

  // ----------------------------------------------------------------
  // Long press
  void _onMessageLongPress(Message message, bool isMe) async {
    final List<PopupMenuEntry<String>> menuItems = [
      const PopupMenuItem<String>(
        value: 'reply',
        child: Text("Reply"),
      ),
    ];
    if (isMe) {
      menuItems.add(
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text("Delete"),
        ),
      );
    }

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(100, 100, 100, 100),
      items: menuItems,
    );

    if (selected == 'reply') {
      setState(() {
        _replyToMessage = message;
      });
    } else if (selected == 'delete' && isMe) {
      _showDeleteDialog(message);
    }
  }

  // ----------------------------------------------------------------
  // Image bubble
  Widget _buildImageContent(Message message, bool isMe) {
    if (message.isUploading) {
      return SizedBox(
        height: 150,
        width: 150,
        child: Stack(
          children: [
            Container(color: Colors.black12),
            Center(
              child: CircularProgressIndicator(
                color: isMe ? Colors.white : Colors.blue,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.2),
                alignment: Alignment.center,
                child: const Text(
                  "Uploading...",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return GestureDetector(
        onTap: () {
          // Full screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenImageView(imageUrl: message.message),
            ),
          );
        },
        child: Hero(
          tag: message.message,
          child: Image.network(
            message.message,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              final value = progress.cumulativeBytesLoaded /
                  (progress.expectedTotalBytes ?? 1);
              return SizedBox(
                width: 150,
                height: 150,
                child: Center(child: CircularProgressIndicator(value: value)),
              );
            },
          ),
        ),
      );
    }
  }

  // ----------------------------------------------------------------
  // Delete message
  Future<void> _showDeleteDialog(Message message) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message?'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.deleteMessage(_effectiveChatId!, message);
    }
  }

  // ----------------------------------------------------------------
  // Bottom input
  Widget _buildMessageInput() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // If replying
          if (_replyToMessage != null)
            Container(
              color: Colors.grey[300],
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to: ${_replyToMessage!.message.length > 30
                          ? _replyToMessage!.message.substring(0, 30) + '...'
                          : _replyToMessage!.message}',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _replyToMessage = null);
                    },
                    child: const Icon(Icons.close, size: 18),
                  )
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image, color: Colors.grey[700]),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: "Type your message...",
                        border: InputBorder.none,
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () async {
                      final text = messageController.text.trim();
                      if (text.isNotEmpty) {
                        final chatProvider =
                        Provider.of<ChatProvider>(context, listen: false);

                        // We do NOT translate here. We store the original text in Firestore
                        // The bubble will translate it dynamically.

                        if (_effectiveChatId == null) {
                          final newChatId = await chatProvider.createChat(
                            userId: widget.userId,
                            storeId: widget.storeId,
                          );
                          setState(() => _chatId = newChatId);
                        }

                        try {
                          await chatProvider.sendMessage(
                            _effectiveChatId!,
                            widget.userId,
                            text, // store original
                            replyToText: _replyToMessage?.message,
                            replyToSenderName: _replyToMessage != null
                                ? (_replyToMessage!.senderId == widget.userId
                                ? "You"
                                : widget.storeName)
                                : null,
                          );
                          messageController.clear();
                          setState(() => _replyToMessage = null);
                          _scrollToBottom();
                        } catch (e) {
                          debugPrint("Error sending message: $e");
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  // Empty conversation
  Widget _buildEmptyConversation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.message_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No messages yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start the conversation by sending a message.",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  // Helper to format timestamp as HH:mm
  String _formatTimestamp(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  // ----------------------------------------------------------------
  // Convert "lastActiveAt" to "Last seen..."
  String _formatLastSeen(DateTime? lastActive) {
    if (lastActive == null) return "Offline";
    final now = DateTime.now();
    final diff = now.difference(lastActive);

    if (diff.inMinutes < 1) {
      return "Last seen just now";
    } else if (diff.inMinutes < 60) {
      return "Last seen ${diff.inMinutes} min ago";
    } else if (diff.inHours < 24) {
      return "Last seen ${diff.inHours} hour(s) ago";
    } else {
      final days = diff.inDays;
      return "Last seen $days day${days > 1 ? 's' : ''} ago";
    }
  }

  // ----------------------------------------------------------------
  // Convert date => "Today", "Yesterday", or "Mar 5, 2025"
  String _dayString(DateTime dateTime) {
    final now = DateTime.now();
    final justDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (justDate == today) {
      return "Today";
    } else if (justDate == yesterday) {
      return "Yesterday";
    } else {
      return "${_monthName(dateTime.month)} ${dateTime.day}, ${dateTime.year}";
    }
  }

  String _monthName(int month) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return months[month - 1];
  }
}