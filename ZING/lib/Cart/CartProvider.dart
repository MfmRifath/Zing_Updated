import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:zing/Modal/CoustomUser.dart'; // Assuming you have a Product model
import '../Service/CoustomUserProvider.dart';

class CartProvider extends ChangeNotifier {
  List<Product> _items = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Product> get items => _items;

  // Add product to cart and save to Firestore
  void addItem(Product product, BuildContext context) {
    _items.add(product);
    notifyListeners();
    _saveCartToFirestore(context); // Save the cart to Firestore
  }

  // Remove product from cart and save the changes to Firestore
  void removeItem(Product product, BuildContext context) {
    _items.remove(product);
    notifyListeners();
    _saveCartToFirestore(context); // Save updated cart to Firestore
  }

  int get totalItems => _items.length;

  double get totalPrice {
    return _items.fold(0, (total, current) => total + current.price);
  }

  // Save the cart data to Firestore
  Future<void> _saveCartToFirestore(BuildContext context) async {
    try {
      final userProvider = Provider.of<CustomUserProvider>(context, listen: false);
      final CustomUser? currentUser = userProvider.currentUser; // Get current user directly

      if (currentUser == null) {
        print("No user found in the provider.");
        return;
      }

      List<Map<String, dynamic>> cartData = _items.map((product) {
        return {
          'productId': product.id,
          'name': product.name,
          'price': product.price,
          'imageUrl': product.imageUrl,
        };
      }).toList();

      await _firestore.collection('carts').doc(currentUser.id).set({
        'items': cartData,
        'totalPrice': totalPrice,
        'totalItems': totalItems,
      });
    } catch (e) {
      print("Error saving cart to Firestore: $e");
    }
  }

  // Load the cart from Firestore
  Future<void> loadCartFromFirestore(BuildContext context) async {
    try {
      final userProvider = Provider.of<CustomUserProvider>(context, listen: false);
      final CustomUser? currentUser = userProvider.currentUser; // Get current user directly

      if (currentUser == null) {
        print("No user found in the provider.");
        return;
      }

      DocumentSnapshot doc = await _firestore.collection('carts').doc(currentUser.id).get();
      if (doc.exists) {
        List<dynamic> items = (doc.data() as Map<String, dynamic>)['items'] ?? [];
        _items = items.map((item) {
          return Product(
            id: item['productId'],
            name: item['name'],
            price: item['price'],
            imageUrl: item['imageUrl'],
          );
        }).toList();
        notifyListeners(); // Notify listeners to update the UI
      }
    } catch (e) {
      print("Error loading cart from Firestore: $e");
    }
  }

  // Clear the cart after checkout or manual reset
  Future<void> clearCart(BuildContext context) async {
    try {
      final userProvider = Provider.of<CustomUserProvider>(context, listen: false);
      final CustomUser? currentUser = userProvider.currentUser; // Get current user directly

      if (currentUser == null) {
        print("No user found in the provider.");
        return;
      }

      _items.clear();
      notifyListeners();
      await _firestore.collection('carts').doc(currentUser.id).delete(); // Clear cart in Firestore
    } catch (e) {
      print("Error clearing cart in Firestore: $e");
    }
  }
}
