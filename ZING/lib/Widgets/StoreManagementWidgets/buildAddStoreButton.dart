import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Service/StoreProvider.dart';
import '../../screen/StoreManagement/EditStoreScreen.dart';

Widget buildAddStoreButton(BuildContext context) {
  final storeProvider = Provider.of<StoreProvider>(context, listen: false);
  return Center(
    child: ElevatedButton.icon(
      icon: Icon(Icons.add, color: Colors.white),
      label: Text(
        'Add Store',
        style: TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4.0,
      ),
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditStoreDialog(
              refreshStoreData: () {
                storeProvider.fetchStores(); // Fetch store list when returning
              },
            ),
          ),
        );
        if (result == true) {
          storeProvider.fetchStores(); // Optionally refresh after completion
        }
      },
    ),
  );
}