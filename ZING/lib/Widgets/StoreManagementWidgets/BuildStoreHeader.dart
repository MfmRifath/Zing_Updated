import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Modal/CoustomUser.dart';
import 'BuildGoogleMap.dart';
import 'buildDeleivaryOption.dart';
import 'buildStoreActionButton.dart';

Widget buildStoreHeader(Store userStore, CustomUser currentUser, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
    child: Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      shadowColor: Colors.black.withOpacity(0.1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Image Section with Overlay
            Stack(
              children: [
                FadeInImage.assetNetwork(
                  placeholder: 'assets/images/zing.png',
                  image: userStore.imageUrl.isNotEmpty
                      ? userStore.imageUrl
                      : 'https://via.placeholder.com/400x200.png?text=No+Image',
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  fadeInDuration: Duration(milliseconds: 500),
                  fadeOutDuration: Duration(milliseconds: 500),
                ),
                // Overlay with dark background
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                    ),
                  ),
                ),
              ],
            ),
            // Store Details Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store Name with larger font and more prominent style
                  Text(
                    userStore.name,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Category in subtle style
                  Text(
                    "Category: ${userStore.category}",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Delivery Options
                  buildDeliveryOptions(userStore),
                  SizedBox(height: 24),
                  // Contact Information with improved styling
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.blue, size: 26),
                      SizedBox(width: 12),
                      Text(
                        userStore.phoneNumber,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  // Google Map Section
                  buildGoogleMap(userStore),
                  SizedBox(height: 24),
                  // Action Buttons (Floating button style)
                  Align(
                    alignment: Alignment.center,
                    child: buildStoreActions(userStore, currentUser, context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}