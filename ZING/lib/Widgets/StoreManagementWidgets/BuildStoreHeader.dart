import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Modal/CoustomUser.dart';
import 'BuildGoogleMap.dart';
import 'buildDeleivaryOption.dart';
import 'buildStoreActionButton.dart';

Widget buildStoreHeader(Store userStore, CustomUser currentUser, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Card(
      elevation: 10.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            child: FadeInImage.assetNetwork(
              placeholder: 'assets/images/zing.png',
              image: userStore.imageUrl.isNotEmpty
                  ? userStore.imageUrl
                  : 'https://via.placeholder.com/400x200.png?text=No+Image',
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              fadeInDuration: Duration(milliseconds: 300),
              fadeOutDuration: Duration(milliseconds: 300),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userStore.name,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade900,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Category: ${userStore.category}",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 10),
                buildDeliveryOptions(userStore),
                // Display the delivery options
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.phone, color: Colors.blueGrey, size: 22),
                    SizedBox(width: 8),
                    Text(
                      userStore.phoneNumber,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                buildGoogleMap(userStore),
                SizedBox(height: 16),
                buildStoreActions(userStore, currentUser, context),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}