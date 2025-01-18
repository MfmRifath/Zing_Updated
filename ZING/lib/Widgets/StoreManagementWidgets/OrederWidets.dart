import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Modal/CoustomUser.dart';
import '../../Service/OrderProvider.dart';

class OrderManagementPage extends StatefulWidget {
  final String storeId;

  OrderManagementPage({required this.storeId});

  @override
  _OrderManagementPageState createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  bool _isLoading = true;
  List<Orders> _cachedOrders = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fetchOrdersByStore() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("Fetching orders for store: ${widget.storeId}");

      final querySnapshot = await _firestore
          .collection('stores')
          .doc(widget.storeId)
          .collection('orders')
          .get();

      print("Fetched querySnapshot: ${querySnapshot.docs.length} orders");

      if (querySnapshot.docs.isEmpty) {
        print("No orders found for the store.");
      }

      final fetchedOrders = querySnapshot.docs.map((doc) {
        print("Order data: ${doc.data()}");
        return Orders.fromDocument(doc); // Assuming Orders.fromDocument is defined
      }).toList();

      setState(() {
        _cachedOrders = fetchedOrders;
      });
    } catch (e, stackTrace) {
      print("Error fetching orders: $e\n$stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching orders: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchOrdersByStore();
  }

  @override
  Widget build(BuildContext context) {
    print('Rendering OrderManagementPage for store: ${widget.storeId}');
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(  // Wrap the Column in SingleChildScrollView to handle overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Orders',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade900,
                ),
              ),
              SizedBox(height: 20),
              _buildOrderList(),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildOrderList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_cachedOrders.isEmpty) {
      return Center(
        child: Text(
          'No orders available.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: BouncingScrollPhysics(),
      itemCount: _cachedOrders.length,
      itemBuilder: (context, index) {
        final order = _cachedOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Orders order) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          tilePadding: EdgeInsets.all(16.0),
          title: Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.blue[600]),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Order ID: ${order.id}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Price: \$${order.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14, color: Colors.green[700]),
                ),
                Text(
                  'Delivery Method: ${order.deliveryMethod}',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  'Placed At: ${order.placedAt}',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  'Customer Name: ${order.userDetails?.name ?? 'Unknown'}',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  'Customer Phone Number: ${order.userDetails?.phoneNumber ?? 'Unknown'}',
                  style: TextStyle(fontSize: 14),
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
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
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
                  SizedBox(height: 10),
                  ...order.products.map((product) {
                    return Text(
                      '- ${product.name} (\$${product.price.toStringAsFixed(2)})',
                      style: TextStyle(fontSize: 14),
                    );
                  }).toList(),
                ],
              ),
            ),
            ButtonBar(
              children: [
                TextButton(
                  onPressed: () => updateOrderStatus(order, 'Processed'),
                  child: Text(
                    'Mark as Processed',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                TextButton(
                  onPressed: () => updateOrderStatus(order, 'Cancelled'),
                  child: Text(
                    'Cancel Order',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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

  void updateOrderStatus(Orders order, String newStatus) async {
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.updateOrderStatus(order.storeId, order.id, newStatus);
      setState(() {
        order.status = newStatus; // Update the status in the UI
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $newStatus.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order status: $e')));
    }
  }
}