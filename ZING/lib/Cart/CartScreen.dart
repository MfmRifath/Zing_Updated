import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../Service/CoustomUserProvider.dart';
import '../Service/OrderProvider.dart';
import '../Service/StoreProvider.dart';
import 'CartProvider.dart';
import '../Modal/CoustomUser.dart';

class CartScreen extends StatefulWidget {
  final String userId;

  const CartScreen({required this.userId});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<void> _fetchStoresFuture;

  @override
  void initState() {
    super.initState();
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    _fetchStoresFuture = storeProvider.fetchStores(); // Fetch stores once during initialization
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Load the cart data
    cartProvider.loadCartFromFirestore(context);

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(
          'Your Cart',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade900,
      ),
      body: FutureBuilder<void>(
        future: _fetchStoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading stores: ${snapshot.error}'));
          }

          return Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.items.isEmpty) {
                return Center(
                  child: FadeIn(
                    child: Text(
                      'Your cart is empty.',
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                    ),
                  ),
                );
              }
              return _buildCartList(context, cartProvider);
            },
          );
        },
      ),
      bottomNavigationBar: _buildCheckoutButton(context, cartProvider),
    );
  }

  Widget _buildCartList(BuildContext context, CartProvider cartProvider) {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);

    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: cartProvider.items.length,
      itemBuilder: (context, index) {
        final cartItem = cartProvider.items[index];

        // Find the store matching the cart item
        final Store store = storeProvider.stores.firstWhere(
              (store) => store.products.any((product) => product.id == cartItem.id),
          orElse: () => Store(
            id: 'unknown',
            name: 'Unknown Store',
            description: 'No description',
            products: [],
            category: 'Unknown',
            deliveryOptions: [],
            location: GeoPoint(0, 0),
            imageUrl: '',
            phoneNumber: 'N/A',
            owner: Owner(id: '', name: 'Unknown Owner', email: '', phone: '', profileImageUrl: ''),
          ),
        );

        return SlideInUp(
          duration: Duration(milliseconds: 500 + index * 100),
          child: Card(
            margin: EdgeInsets.symmetric(vertical: 10),
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  if (cartItem.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        cartItem.imageUrl!,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cartItem.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Price: \$${cartItem.price.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                        Text(
                          'Store: ${store.name}',
                          style: TextStyle(
                            color: store.name == 'Unknown Store'
                                ? Colors.red
                                : Colors.blue.shade500,
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () {
                      cartProvider.removeItem(cartItem, context);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckoutButton(BuildContext context, CartProvider cartProvider) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final userProvider = Provider.of<CustomUserProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElasticIn(
        duration: Duration(milliseconds: 800),
        child: ElevatedButton(
          onPressed: () {
            _showDeliveryMethodDialog(context, cartProvider, orderProvider, userProvider);
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue.shade900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            'Checkout (\$${cartProvider.totalPrice.toStringAsFixed(2)})',
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeliveryMethodDialog(BuildContext context, CartProvider cartProvider, OrderProvider orderProvider, CustomUserProvider userProvider) async {
    String? selectedDeliveryMethod = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String? deliveryMethod = 'Pickup';
        return ZoomIn(
          duration: Duration(milliseconds: 500),
          child: AlertDialog(
            title: Text(
              'Select Delivery Method',
              style: TextStyle(color: Colors.blue.shade900),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Pickup'),
                  value: 'Pickup',
                  groupValue: deliveryMethod,
                  onChanged: (String? value) {
                    deliveryMethod = value;
                    Navigator.of(context).pop(deliveryMethod);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Home Delivery'),
                  value: 'Home Delivery',
                  groupValue: deliveryMethod,
                  onChanged: (String? value) {
                    deliveryMethod = value;
                    Navigator.of(context).pop(deliveryMethod);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedDeliveryMethod != null) {
      _checkout(context, cartProvider, orderProvider, userProvider, selectedDeliveryMethod);
    }
  }

  Future<void> _checkout(BuildContext context, CartProvider cartProvider, OrderProvider orderProvider, CustomUserProvider userProvider, String deliveryMethod) async {
    try {
      final CustomUser? currentUser = userProvider.currentUser;

      if (currentUser == null || cartProvider.items.isEmpty) {
        return;
      }

      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final store = storeProvider.stores.firstWhere(
            (store) => store.products.any((product) => product.id == cartProvider.items.first.id),
      );

      await orderProvider.placeOrder(
        currentUser.id,
        store,
        cartProvider.items,
        cartProvider.totalPrice,
        deliveryMethod,
        currentUser
      );

      cartProvider.clearCart(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order placed successfully!')),
      );
    } catch (e) {
      print("Error placing order: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order.')),
      );
    }
  }
}