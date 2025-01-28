import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart'; // For nice fade/slide animations, optional

import '../../Modal/CoustomUser.dart';
import '../../Service/OrderProvider.dart';

class OrderManagementPage extends StatefulWidget {
  final String storeId;

  const OrderManagementPage({Key? key, required this.storeId}) : super(key: key);

  @override
  _OrderManagementPageState createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  bool _isLoading = true;
  List<Orders> _cachedOrders = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    fetchOrdersByStore();
  }

  Future<void> fetchOrdersByStore() async {
    setState(() => _isLoading = true);

    try {
      debugPrint("Fetching orders for store: ${widget.storeId}");

      final querySnapshot = await _firestore
          .collection('stores')
          .doc(widget.storeId)
          .collection('orders')
          .get();

      debugPrint("Fetched querySnapshot: ${querySnapshot.docs.length} orders");

      if (querySnapshot.docs.isEmpty) {
        debugPrint("No orders found for this store.");
      }

      final fetchedOrders = querySnapshot.docs.map((doc) {
        debugPrint("Order data: ${doc.data()}");
        return Orders.fromDocument(doc);
      }).toList();

      setState(() => _cachedOrders = fetchedOrders);
    } catch (e, stackTrace) {
      debugPrint("Error fetching orders: $e\n$stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching orders: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Rendering OrderManagementPage for store: ${widget.storeId}');

    return SafeArea(
      child: Scaffold(
        // Single top-level scaffold
        appBar: AppBar(
          title: const Text('Customer Orders'),
          backgroundColor: Colors.blue.shade900,
        ),
        body: Container(
          // Subtle gradient background
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: _buildBodyContent(),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Main Body Content
  Widget _buildBodyContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          FadeInDown(
            child: Text(
              'Customer Orders',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade900,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Either loading spinner, empty message, or order list
          _buildOrderList(),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Order list states
  Widget _buildOrderList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cachedOrders.isEmpty) {
      return FadeIn(
        child: Center(
          child: Text(
            'No orders available.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      // Because we are inside SingleChildScrollView
      // we set these so the list won't conflict with scrolling
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _cachedOrders.length,
      itemBuilder: (context, index) {
        final order = _cachedOrders[index];
        // We fade each order card for a smoother effect
        return FadeInUp(child: _buildOrderCard(order));
      },
    );
  }

  // --------------------------------------------------------------------------
  // Single order card
  Widget _buildOrderCard(Orders order) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16.0),
          title: Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.blue[600]),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Order ID: ${order.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _buildOrderSubtitle(order),
          ),
          children: [
            // Expanded details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: _buildOrderProductDetails(order),
            ),
            _buildOrderButtonBar(order),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Order subtitle
  Widget _buildOrderSubtitle(Orders order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Price: \$${order.totalPrice.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 14, color: Colors.green[700]),
        ),
        Text(
          'Delivery Method: ${order.deliveryMethod}',
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          'Placed At: ${order.placedAt}',
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          'Customer Name: ${order.userDetails?.name ?? 'Unknown'}',
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          'Customer Phone: ${order.userDetails?.phoneNumber ?? 'Unknown'}',
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          'Status: ${order.status}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _getStatusColor(order.status),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Product details
  Widget _buildOrderProductDetails(Orders order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Products:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey.shade900,
          ),
        ),
        const SizedBox(height: 8),
        // List each product in the order
        ...order.products.map((product) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '- ${product.name} (\$${product.price.toStringAsFixed(2)})',
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Button bar (Update status, Cancel)
  Widget _buildOrderButtonBar(Orders order) {
    return ButtonBar(
      children: [
        TextButton(
          onPressed: () => updateOrderStatus(order, 'Processed'),
          child: const Text('Mark as Processed', style: TextStyle(color: Colors.blue)),
        ),
        TextButton(
          onPressed: () => updateOrderStatus(order, 'Cancelled'),
          child: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Returns color based on the status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Processed':
        return Colors.blue;
      case 'Shipped':
        return Colors.purple;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // --------------------------------------------------------------------------
  // Update order status
  void updateOrderStatus(Orders order, String newStatus) async {
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.updateOrderStatus(order.storeId, order.id, newStatus);
      setState(() {
        order.status = newStatus; // update in the UI
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order status: $e')),
      );
    }
  }
}