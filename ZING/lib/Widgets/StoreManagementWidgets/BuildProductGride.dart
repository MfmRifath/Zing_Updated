import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../Modal/CoustomUser.dart';
import '../../screen/StoreManagement/EditProduct.dart';

Widget buildProductGrid(Store userStore, List<Product> products, BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  double screenHeight = MediaQuery.of(context).size.height;

  int crossAxisCount = screenWidth < 600 ? 2 : (screenWidth < 1200 ? 3 : 4);
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
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: (screenWidth / crossAxisCount) / (screenHeight / 2.5),
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
            elevation: 5.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadowColor: Colors.grey.withOpacity(0.2),
            child: InkWell(
              splashColor: Colors.blue.withAlpha(30),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey[50]!],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                constraints: BoxConstraints(maxWidth: screenWidth < 600 ? screenWidth : 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Image.network(
                          imageUrl!,
                          height: screenWidth < 600 ? 140 : (screenWidth < 1200 ? 160 : 180),
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/error_image.png',
                              height: screenWidth < 600 ? 140 : 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: GoogleFonts.lato(
                                fontSize: screenWidth < 600 ? 16 : (screenWidth < 1200 ? 18 : 20),
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              "\RS ${product.price.toStringAsFixed(2)}",
                              style: GoogleFonts.lato(
                                fontSize: screenWidth < 600 ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[600],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Tooltip(
                                  message: 'Edit Product',
                                  child: IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blueAccent, size: 26),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditProductScreen(
                                              product: product, storeId: userStore.id!),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Tooltip(
                                  message: 'Delete Product',
                                  child: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.redAccent, size: 26),
                                    onPressed: () async {
                                      bool? confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('Delete Product'),
                                          content: Text(
                                              'Are you sure you want to delete this product?'),
                                          actions: [
                                            TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: Text('Cancel')),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context, true);
                                                FirebaseFirestore.instance
                                                    .collection('products')
                                                    .doc(product.id)
                                                    .delete()
                                                    .then((_) {
                                                  products.removeAt(index);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'Product deleted successfully')));
                                                }).catchError((error) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'Error deleting product: $error')));
                                                });
                                              },
                                              child: Text('Delete',
                                                  style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
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
          ),
        );
      },
    ),
  );
}