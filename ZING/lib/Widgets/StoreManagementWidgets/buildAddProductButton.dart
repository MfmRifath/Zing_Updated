import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Modal/CoustomUser.dart';
import '../../screen/StoreManagement/EditProduct.dart';

Widget buildAddProductButton(Store userStore, BuildContext context ) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: ElevatedButton.icon(
      icon: Icon(Icons.add),
      label: Text('Add Product'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4.0,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditProductScreen(storeId: userStore.id!),
          ),
        );
      },
    ),
  );
}
