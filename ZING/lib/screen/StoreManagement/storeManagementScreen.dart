import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zing/Modal/CoustomUser.dart';
import 'package:zing/Service/CoustomUserProvider.dart';
import '../../Widgets/StoreManagementWidgets/BuildDayLeftIndicator.dart';
import '../../Widgets/StoreManagementWidgets/BuildProductGride.dart';
import '../../Widgets/StoreManagementWidgets/BuildRenewScreen.dart';
import '../../Widgets/StoreManagementWidgets/BuildStoreHeader.dart';
import '../../Widgets/StoreManagementWidgets/OrederWidets.dart';
import '../../Widgets/StoreManagementWidgets/buildAddProductButton.dart';
import '../../Widgets/StoreManagementWidgets/buildAddStoreButton.dart';

class StoreManagementWidget extends StatefulWidget {
  @override
  _StoreManagementWidgetState createState() => _StoreManagementWidgetState();
}

class _StoreManagementWidgetState extends State<StoreManagementWidget> {
  CustomUser? _currentUser;
  List<Product> _products = [];
  bool _isLoading = true;
  int _daysLeft = 0;
  bool _hasAccess = true;
  bool _showOrderManagement = false; // Controls the display of order management

  late FirebaseFirestore _firestore;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    _firestore = FirebaseFirestore.instance;
  }

  Future<void> fetchUserData() async {
    final userProvider = Provider.of<CustomUserProvider>(context, listen: false);
    final currentUser = userProvider.user;

    if (currentUser != null && currentUser.store != null) {
      final storeId = currentUser.store!.id!;
      await fetchProductsForStore(storeId);
      await fetchLatestPaymentAndCalculateDaysLeft(currentUser.id);
    }

    setState(() {
      _currentUser = currentUser;
      _isLoading = false;
    });
  }

  Future<void> fetchLatestPaymentAndCalculateDaysLeft(String userId) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> paymentSnapshot =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('payments')
          .orderBy('paymentDate', descending: true)
          .limit(1)
          .get();

      if (paymentSnapshot.docs.isNotEmpty) {
        final paymentData = paymentSnapshot.docs.first.data();
        final Timestamp paymentDate = paymentData['paymentDate'];
        DateTime currentDate = DateTime.now();
        Duration difference = currentDate.difference(paymentDate.toDate());
        _daysLeft = 30 - difference.inDays;

        if (_daysLeft <= 0) {
          _hasAccess = false;
        }
      } else {
        _hasAccess = false;
      }
    } catch (e) {
      print("Error fetching latest payment: $e");
      _hasAccess = false;
    }
  }

  Future<void> fetchProductsForStore(String storeId) async {
    try {
      QuerySnapshot productSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .get();

      List<Product> products = productSnapshot.docs.map((productDoc) {
        Map<String, dynamic> productData = productDoc.data() as Map<String, dynamic>;
        return Product(
          id: productDoc.id,
          name: productData['name'],
          description: productData['description'],
          price: productData['price'].toDouble(),
          rating: productData['rating'].toDouble(),
          imageUrl: productData['imageUrl'] ?? '',
        );
      }).toList();

      setState(() {
        _products = products;
      });
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (_currentUser!.role == 'User') {
      return Center(child: Text('You are not authorized to access this section.'));
    }

    if (_currentUser!.store == null) {
      return buildAddStoreButton(context);
    }

    return _hasAccess ? _buildStoreManagementContent() : buildRenewScreen(context, _currentUser!);
  }

  Widget _buildStoreManagementContent() {
    return SingleChildScrollView(
      child: ConstrainedBox( // Adding ConstrainedBox to prevent unbounded height
        constraints: BoxConstraints(minHeight: 0.0), // Ensure the height is constrained
        child: Column(
          children: [
            // Days Left Indicator
            buildDaysLeftIndicator(_daysLeft),

            // Store Header Section
            buildStoreHeader(_currentUser!.store!, _currentUser!, context),

            // Product Grid Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: buildProductGrid(_currentUser!.store!, _products, context),
                ),
              ),
            ),

            // Add Product Button Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: buildAddProductButton(_currentUser!.store!, context),
            ),

            // Navigate to Order Management Button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    // Toggle the visibility of order management
                    _showOrderManagement = !_showOrderManagement; // Set this first to handle UI change immediately
                  });

                  // Push the OrderManagementPage when toggling to order management
                  if (_showOrderManagement) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderManagementPage(storeId: _currentUser!.store!.id!),
                      ),
                    );
                  }
                },
                child: Text(_showOrderManagement ? 'Back to Store Management' : 'Manage Orders'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}