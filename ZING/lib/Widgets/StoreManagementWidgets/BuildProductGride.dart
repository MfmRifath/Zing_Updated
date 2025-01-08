import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Modal/CoustomUser.dart';
import '../../screen/StoreManagement/EditProduct.dart';
Widget buildProductGrid(Store userStore, List<Product> products, BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  double screenHeight = MediaQuery.of(context).size.height;

  // Adjust the number of columns based on the screen width
  int crossAxisCount = screenWidth < 600 ? 2 : (screenWidth < 1200 ? 3 : 4);

  // Adjust padding based on screen width
  double horizontalPadding = screenWidth < 600 ? 8 : 16;
  double verticalPadding = screenWidth < 600 ? 8 : 16;

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
    child: GridView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 50,
        crossAxisSpacing: 50,
        childAspectRatio: (screenWidth / crossAxisCount) / (screenHeight / 2),
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        final imageUrl = product.imageUrl!.isNotEmpty
            ? product.imageUrl
            : 'https://via.placeholder.com/150';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    EditProductScreen(product: product, storeId: userStore.id!),
              ),
            );
          },
          child: Card(
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: BoxConstraints(maxWidth: screenWidth < 600 ? screenWidth : (screenWidth < 1200 ? 600 : 800)), // Limit the width at the bottom
              height: screenWidth < 600 ? 280 : (screenWidth < 1200 ? 300 : 320), // Limiting height
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Responsive Image
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/images/zing.png',
                      image: imageUrl!,
                      height: screenWidth < 600 ? 140 : (screenWidth < 1200 ? 160 : 180),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      fadeInDuration: Duration(milliseconds: 300),
                      fadeOutDuration: Duration(milliseconds: 300),
                      imageErrorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/error_image.png',
                          height: screenWidth < 600 ? 120 : (screenWidth < 1200 ? 140 : 160),
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Responsive Product Name
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: screenWidth < 600 ? 16 : (screenWidth < 1200 ? 18 : 20),
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Responsive Price
                          Text(
                            "\$${product.price.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: screenWidth < 600 ? 14 : (screenWidth < 1200 ? 16 : 18),
                              fontWeight: FontWeight.w600,
                              color: Colors.green[600],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Edit Button
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blueAccent, size: 28),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditProductScreen(product: product, storeId: userStore.id!),
                                    ),
                                  );
                                },
                              ),
                              // Delete Button
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.redAccent, size: 28),
                                onPressed: () async {
                                  final confirm = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Delete Product'),
                                      content: Text('Are you sure you want to delete this product?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(true);

                                            // Delete from Firebase Firestore
                                            FirebaseFirestore.instance
                                                .collection('products')
                                                .doc(product.id) // Use the unique product ID
                                                .delete()
                                                .then((_) {
                                              // After successful deletion, remove the product from the local list
                                              products.removeAt(index);

                                              // Show confirmation message
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Product deleted successfully')),
                                              );
                                            }).catchError((error) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error deleting product: $error')),
                                              );
                                            });
                                          },
                                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}