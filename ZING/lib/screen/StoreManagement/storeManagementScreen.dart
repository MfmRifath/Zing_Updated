import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zing/Widgets/StoreManagementWidgets/BuildProductGride.dart';
import 'package:zing/Widgets/StoreManagementWidgets/OrederWidets.dart';

import '../../Modal/CoustomUser.dart';
import '../../Service/CoustomUserProvider.dart';
import '../../Widgets/StoreManagementWidgets/BuildRenewScreen.dart';
import '../../Widgets/StoreManagementWidgets/BuildStoreHeader.dart';
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
  bool _showOrderManagement = false;
  late FirebaseFirestore _firestore;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    fetchUserData();
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
      final paymentSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('payments')
          .orderBy('paymentDate', descending: true)
          .limit(1)
          .get();

      if (paymentSnapshot.docs.isNotEmpty) {
        final paymentData = paymentSnapshot.docs.first.data();
        final paymentDate = (paymentData['paymentDate'] as Timestamp).toDate();
        final currentDate = DateTime.now();
        _daysLeft = 30 - currentDate.difference(paymentDate).inDays;

        if (_daysLeft <= 0) {
          _hasAccess = false;
          _currentUser?.storeAccess = false;
        }
      } else {
        _hasAccess = false;
        _currentUser?.storeAccess = false;
      }
    } catch (e) {
      print("Error fetching payment data: $e");
      _hasAccess = false;
      _currentUser?.storeAccess = false;
    }
  }

  Future<void> fetchProductsForStore(String storeId) async {
    try {
      final productSnapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .get();

      setState(() {
        _products = productSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Product(
            id: doc.id,
            name: data['name'],
            description: data['description'],
            price: data['price'].toDouble(),
            rating: data['rating'].toDouble(),
            imageUrl: data['imageUrl'] ?? '',
          );
        }).toList();
      });
    } catch (e) {
      print("Error fetching products: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 100, height: 100, color: Colors.grey[300]),
              SizedBox(height: 16),
              Container(width: 200, height: 20, color: Colors.grey[300]),
            ],
          ),
        ),
      );
    }

    if (_currentUser == null || !_currentUser!.storeAccess!) {
      return _buildAccessDeniedScreen();
    }

    return _buildStoreManagementContent();
  }

  Widget _buildAccessDeniedScreen() {
    return Center(
      child: Card(
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                "Access Denied",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "You don't have access to this section.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              if (_currentUser?.store == null) buildAddStoreButton(context),
              if (!_hasAccess) buildRenewScreen(context, _currentUser!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreManagementContent() {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Store Header
              buildStoreHeader(_currentUser!.store!, _currentUser!, context),

              // Warning Banner if necessary
              if (_daysLeft <= 7 && _daysLeft > 0) _buildWarningBanner(),

              // Action Buttons for toggling views
              _buildActionButtons(),

              // Conditional rendering of either Order Management or Store Page
              _showOrderManagement
                  ? OrderManagementPage(storeId: _currentUser!.store!.id!)
                  : buildProductGrid(
                _currentUser!.store!,
                _products,
                context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Your store access expires in $_daysLeft days. Renew now!",
              style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => setState(() => _showOrderManagement = !_showOrderManagement),
              child: Text(_showOrderManagement ? "Back to Store" : "Manage Orders"),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: buildAddProductButton(_currentUser!.store!, context),
          ),
        ],
      ),
    );
  }
}
