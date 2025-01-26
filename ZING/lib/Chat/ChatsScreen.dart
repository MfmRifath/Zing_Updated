import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zing/Modal/CoustomUser.dart';
import 'package:zing/Service/CoustomUserProvider.dart';
import '../Service/ChatProvider.dart';
import 'ChatScreen.dart';

class OwnerChatListScreen extends StatefulWidget {
  final String storeId;

  OwnerChatListScreen({required this.storeId});

  @override
  _OwnerChatListScreenState createState() => _OwnerChatListScreenState();
}

class _OwnerChatListScreenState extends State<OwnerChatListScreen> {
  Map<String, CustomUser> usersCache = {};

  Future<void> _fetchUsers(List<Map<String, dynamic>> chats) async {
    final userProvider = Provider.of<CustomUserProvider>(context, listen: false);

    for (var chat in chats) {
      final customerId = chat['customerId'];
      if (!usersCache.containsKey(customerId)) {
        CustomUser? user = await userProvider.fetchUserById(customerId);
        if (user != null) {
          usersCache[customerId] = user;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
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
      ),
      body: FutureBuilder(
        future: chatProvider.fetchAllUserChats(widget.storeId),
        builder: (context, snapshot) {
          final chats = chatProvider.allChats;
          if (chats.isEmpty) {
            return _buildEmptyState();
          }

          return FutureBuilder(
            future: _fetchUsers(chats),
            builder: (context, userSnapshot) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF5F7FA), Color(0xFFEFF3F8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  itemCount: chats.length,
                  separatorBuilder: (context, index) => SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final customerId = chat['customerId'];
                    final lastMessage = chat['lastMessage'];
                    final lastUpdated = chat['lastUpdated'] as Timestamp;
                    final user = usersCache[customerId];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatId: chat['chatId'],
                              userId: widget.storeId,
                              storeId: widget.storeId,
                              storeName: user != null ? user.name : "User: $customerId",
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.15),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: user?.profileImageUrl != null && user!.profileImageUrl.isNotEmpty
                                      ? NetworkImage(user.profileImageUrl)
                                      : AssetImage('assets/default_user.png') as ImageProvider,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    height: 12,
                                    width: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user != null ? user.name : "User: $customerId",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    lastMessage,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${DateTime.fromMillisecondsSinceEpoch(lastUpdated.seconds * 1000).toLocal()}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[500]),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/empty_state.png',
            height: 150,
          ),
          SizedBox(height: 16),
          Text(
            "No messages yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Users who message your store will appear here.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}