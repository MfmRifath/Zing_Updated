import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Chat/ChatScreen.dart';
import '../../Modal/CoustomUser.dart';
import '../../Service/CoustomUserProvider.dart';
import '../../Service/StoreProvider.dart';
import '../../screen/StoreManagement/EditStoreScreen.dart';

Widget buildStoreActions(Store userStore, CustomUser user, BuildContext context) {
  final storeProvider = Provider.of<StoreProvider>(context, listen: false);
  final customUserProvider = Provider.of<CustomUserProvider>(context, listen: false);

  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditStoreDialog(
                    store: userStore,
                    refreshStoreData: () {
                      storeProvider.fetchStores();
                    },
                  ),
                ),
              );
              if (result == true) {
                storeProvider.fetchStores(); // Re-fetch store data after editing
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 6,
            ),
            label: Text(
              'Edit Store',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.delete, color: Colors.white),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete Store'),
                  content: Text('Are you sure you want to delete this store? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await storeProvider.deleteStore(userStore.id!, customUserProvider);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 6,
            ),
            label: Text(
              'Delete Store',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
      SizedBox(height: 16),
      ElevatedButton.icon(
        icon: Icon(Icons.chat, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                storeId: userStore.id!,
                currentUser: user,
                storeImageUrl: userStore.imageUrl,
                userImageUrl: user.profileImageUrl,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
        ),
        label: Text(
          'Chat with Customer',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    ],
  );
}