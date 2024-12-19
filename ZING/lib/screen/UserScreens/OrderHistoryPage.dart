import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:zing/Service/OrderProvider.dart'; // Replace with your actual import
import 'package:zing/Service/StoreProvider.dart'; // Replace with your actual import
import 'package:zing/Modal/CoustomUser.dart'; // Replace with your actual import
import '../../Service/CoustomUserProvider.dart'; // Replace with your actual import

class OrderHistoryPage extends StatefulWidget {
  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  Future<List<Orders>>? _orderFuture; // Cache the future

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<CustomUserProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      final CustomUser? user = userProvider.currentUser;
      if (user != null) {
        _orderFuture = orderProvider.fetchUserOrdersAcrossStores(user.id); // Cache the future
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<CustomUserProvider>(context);
    final storeProvider = Provider.of<StoreProvider>(context);

    final CustomUser? user = userProvider.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Order History', style: TextStyle(fontSize: 24)),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
          elevation: 2,
        ),
        body: Center(
          child: Text(
            'User not found.',
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Order History', style: TextStyle(fontSize: 24)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 2,
      ),
      body: FutureBuilder<List<Orders>>(
        future: _orderFuture, // Use the cached future
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (orderSnapshot.hasError) {
            return Center(
              child: Text(
                'Error fetching orders: ${orderSnapshot.error}',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          } else if (!orderSnapshot.hasData || orderSnapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No orders found.',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            );
          } else {
            return _buildOrderList(context, orderSnapshot.data!, storeProvider);
          }
        },
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<Orders> orders, StoreProvider storeProvider) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];

        // Check if storeId is valid before fetching the store
        if (order.storeId == null || order.storeId.isEmpty) {
          print('Invalid storeId for order: ${order.id}');
          return _buildErrorCard(order.id);
        }

        return FutureBuilder<Store?>(
          future: storeProvider.getStoreById(order.storeId),
          builder: (context, storeSnapshot) {
            String storeName = 'Unknown Store';
             if (storeSnapshot.hasError) {
              storeName = 'Error fetching store';
              print('Error fetching store: ${storeSnapshot.error}');
            } else if (storeSnapshot.hasData && storeSnapshot.data != null) {
              storeName = storeSnapshot.data!.name;
            }

            return _buildOrderCard(context, order, storeName);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, Orders order, String storeName) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(order, storeName),
            SizedBox(height: 12),
            _buildProductList(order.products),
            Divider(),
            _buildOrderFooter(order),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String orderId) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        color: Colors.redAccent.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: Invalid store ID for order $orderId',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader(Orders order, String storeName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order ID: ${order.id}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
        ),
        SizedBox(height: 8),
        Text(
          'Store: $storeName',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildProductList(List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: products.map((product) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '- ${product.name}',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrderFooter(Orders order) {
    final DateFormat formatter = DateFormat.yMMMd().add_jm();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Total: ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '\$${order.totalPrice.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[600]),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Status: ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              order.status,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: order.status == 'Delivered' ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Placed on: ${formatter.format(order.placedAt.toDate())}',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }
}
