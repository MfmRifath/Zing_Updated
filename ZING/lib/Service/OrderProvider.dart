import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../Modal/CoustomUser.dart';
import 'CoustomUserProvider.dart';

class OrderProvider with ChangeNotifier {
  List<Orders> _orders = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Orders> get orders => _orders;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Fetch orders for a specific store
  Future<void> fetchOrdersByStore(BuildContext context, String storeId) async {
    _isLoading = true;
    notifyListeners();

    try {
      print("Fetching orders for store: $storeId");

      // Fetch orders
      final querySnapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('orders')
          .get();

      final fetchedOrders = querySnapshot.docs.map((doc) {
        print("Order data: ${doc.data()}");
        return Orders.fromDocument(doc);
      }).toList();

      // Fetch user details
      final userIds = fetchedOrders.map((order) => order.userId).toSet().toList();
      print("User IDs: $userIds");

      if (userIds.isNotEmpty) {
        final userChunks = _splitList(userIds, 10); // Firestore 'whereIn' limit
        final userMap = <String, CustomUser>{};

        for (var chunk in userChunks) {
          final userQuerySnapshot = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();

          for (var doc in userQuerySnapshot.docs) {
            userMap[doc.id] = CustomUser.fromMap(doc.data());
          }
        }

        for (var order in fetchedOrders) {
          order.userDetails = userMap[order.userId]!;
        }
      }

      _orders = fetchedOrders;
      notifyListeners();
    } catch (e, stackTrace) {
      print("Error fetching orders: $e\n$stackTrace");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Place an order for a user in a specific store
  Future<void> placeOrder(
      String userId,
      Store store,
      List<Product> products,
      double totalPrice,
      String deliveryMethod,
      CustomUser userData,
      ) async {
    try {
      final batch = _firestore.batch();

      // Order data
      final orderData = {
        'userId': userId,
        'userDetails': userData.toMap(),
        'storeId': store.id,
        'storeName': store.name,
        'deliveryMethod': deliveryMethod,
        'totalPrice': totalPrice,
        'placedAt': Timestamp.now(),
        'products': products.map((product) => product.toMap()).toList(),
      };

      // Add order to the store
      final storeOrderRef = _firestore
          .collection('stores')
          .doc(store.id)
          .collection('orders')
          .doc();
      batch.set(storeOrderRef, orderData);

      // Add order to the user's document
      final userOrderRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc();
      batch.set(userOrderRef, orderData);

      await batch.commit();
      print("Order placed successfully!");
    } catch (e) {
      print("Error placing order: $e");
      throw e;
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String storeId, String orderId, String newStatus) async {
    try {
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});
      notifyListeners();
    } catch (e) {
      print("Error updating order status: $e");
    }
  }

  // Fetch orders for a user across all stores
  Future<List<Orders>> fetchUserOrdersAcrossStores(String userId) async {
    try {
      final storeSnapshot = await _firestore.collection('stores').get();
      List<Orders> userOrders = [];

      for (var storeDoc in storeSnapshot.docs) {
        final ordersSnapshot = await _firestore
            .collection('stores')
            .doc(storeDoc.id)
            .collection('orders')
            .where('userId', isEqualTo: userId)
            .get();

        userOrders.addAll(ordersSnapshot.docs.map((doc) => Orders.fromDocument(doc)).toList());
      }

      print("User orders fetched: ${userOrders.length}");
      return userOrders;
    } catch (e) {
      print("Error fetching user orders: $e");
      return [];
    }
  }

  // Helper function to split a list into chunks
  List<List<T>> _splitList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }
}