import 'package:flutter/material.dart';
import 'package:zing/Modal/CoustomUser.dart';

class OrderDetailsPage extends StatelessWidget {
  final Orders order;

  OrderDetailsPage({required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary section
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            SizedBox(height: 12),
            Card(
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.receipt, color: Colors.blueGrey),
                title: Text('Order ID: ${order.id}'),
                subtitle: Text(
                  'Status: ${order.status}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            // Total price section
            Row(
              children: [
                Icon(Icons.attach_money, color: Colors.blueGrey),
                SizedBox(width: 8),
                Text(
                  'Total Price: \$${order.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(thickness: 1),
            SizedBox(height: 16),
            // Product list section
            Text(
              'Products Ordered',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            SizedBox(height: 12),
            _buildProductList(order.products),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: products.map((product) {
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: Icon(Icons.shopping_bag, color: Colors.blueGrey),
            title: Text(
              product.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      }).toList(),
    );
  }
}
