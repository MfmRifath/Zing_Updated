import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Modal/CoustomUser.dart';
import '../../screen/StoreManagement/EditProduct.dart';

Widget buildProductGrid(Store userStore, List<Product> products, BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  double screenHeight = MediaQuery.of(context).size.height;

  int crossAxisCount = screenWidth < 600 ? 2 : (screenWidth < 1200 ? 3 : 4);
  double horizontalPadding = screenWidth < 600 ? 8 : 16;
  double verticalPadding = screenWidth < 600 ? 8 : 16;

  // For simpler layout, use a fixed childAspectRatio (like 0.7 or 0.8).
  // Using screenHeight can cause unbounded constraints in some situations.
  const double childAspectRatio = 0.7;

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
    child: GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        final imageUrl = (product.imageUrl != null && product.imageUrl!.isNotEmpty)
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            shadowColor: Colors.grey.withOpacity(0.2),
            child: InkWell(
              splashColor: Colors.blue.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top image area
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: AspectRatio(
                        aspectRatio: 16 / 9, // Or any ratio suitable for your layout
                        child: Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/zing.png',
                              fit: BoxFit.cover,
                            );
                          },
                          // <-- This is where we show shimmer while loading
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              // Image fully loaded
                              return child;
                            }
                            // Show shimmer placeholder
                            return Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                color: Colors.grey[300],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Text and buttons
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                          const SizedBox(height: 4),
                          Text(
                            "\RS ${product.price.toStringAsFixed(2)}",
                            style: GoogleFonts.lato(
                              fontSize: screenWidth < 600 ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[600],
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Tooltip(
                                message: 'Edit Product',
                                child: IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 26),
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
                                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 26),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Product'),
                                        content: const Text(
                                            'Are you sure you want to delete this product?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.pop(context, true);
                                              try {
                                                await FirebaseFirestore.instance
                                                    .collection('products')
                                                    .doc(product.id)
                                                    .delete();

                                                products.removeAt(index);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content:
                                                    Text('Product deleted successfully'),
                                                  ),
                                                );
                                              } catch (error) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error deleting product: $error'),
                                                  ),
                                                );
                                              }
                                            },
                                            child: const Text('Delete',
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
                  )
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}