import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:zing/Modal/CoustomUser.dart';
import 'package:zing/Service/CoustomUserProvider.dart';
// Import Store and Owner model

class StoreProvider with ChangeNotifier {
  List<Store> _stores = [];
  bool isLoading = true;

  List<Store> get stores => _stores;

  StoreProvider() {
    fetchStores();
  }

  Store? _selectedStore;

  Store? get selectedStore => _selectedStore;

  // Method to set the selected store
  void selectStore(Store store) {
  _selectedStore = store;
  notifyListeners();
  }


  /// Fetch stores from Firestore
  Future<void> fetchStores() async {
    isLoading = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners(); // Notify after the current frame
    });

    try {
      QuerySnapshot storeSnapshot = await FirebaseFirestore.instance.collection('stores').get();

      _stores = await Future.wait(storeSnapshot.docs.map((doc) async {
        return await _storeFromFirestore(doc);
      }).toList());

      isLoading = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners(); // Notify after fetching completes
      });
    } catch (e) {
      print('Error fetching stores: $e');
      isLoading = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners(); // Notify even if an error occurs
      });
    }
  }

  Future<List<Product>> fetchProductsForStore(String storeId) async {
    // Fetch products from the "products" sub-collection under the store
    QuerySnapshot productSnapshot = await FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .collection('products')
        .get();

    // Map product documents to a list of Product objects
    return productSnapshot.docs.map((productDoc) {
      Map<String, dynamic> productData = productDoc.data() as Map<String, dynamic>;
      return Product(
        id: productDoc.id,
        name: productData['name'],
        description: productData['description'],
        price: productData['price'].toDouble(),
        rating: productData['rating'].toDouble(),
        imageUrl: productData['imageUrl'] ?? 'https://via.placeholder.com/150',
      );
    }).toList();
  }
  Future<Store?> getStoreById(String storeId) async {
    if (storeId.isEmpty) {
      print('Error: storeId is empty');
      return null; // Return early if storeId is empty
    }

    try {
      // Fetch the store document from Firestore
      final storeDoc = await FirebaseFirestore.instance.collection('stores').doc(storeId).get();

      if (storeDoc.exists) {
        // Extract the data map and pass it to fromMap
        Map<String, dynamic> storeData = storeDoc.data() as Map<String, dynamic>;
        return Store.fromMap(storeData); // Correctly map the store data
      } else {
        print('Error: Store not found for storeId: $storeId');
        return null; // Return null if the store document does not exist
      }
    } catch (e) {
      print("Error fetching store for storeId $storeId: $e");
      throw Exception("Failed to fetch store data."); // Throw a more specific error
    }
  }


  Future<void> addStore(Store newStore, CustomUserProvider userProvider) async {
    try {
      // Step 1: Add the new store to Firestore
      DocumentReference storeRef = await FirebaseFirestore.instance.collection('stores').add(newStore.toMap());
      newStore.id = storeRef.id; // Assign generated document ID to store

      // Step 2: Update the current user's store property
      if (userProvider.user != null) {
        userProvider.user!.store = newStore;

        // Step 3: Save the updated user details in Firestore
        await userProvider.saveUserDetails(userProvider.user!);
      }

      // Step 4: Refresh the stores list to reflect the changes
      await fetchStores();
    } catch (e) {
      print('Error adding store: $e');
    }
  }



  // Edit an existing store and update the user's store details
  Future<void> editStore(String storeId, Store updatedStore, CustomUserProvider userProvider) async {
    try {
      // Update the store document in Firestore
      await FirebaseFirestore.instance.collection('stores').doc(storeId).update(updatedStore.toMap());

      // If the user's store is being updated, reflect the changes
      if (userProvider.user?.store != null && userProvider.user!.store!.id == storeId) {
        userProvider.user!.store = updatedStore;

        // Save the updated user store in Firestore
        await userProvider.saveUserDetails(userProvider.user!);
      }

      // Refresh the stores list after editing
      await fetchStores();
    } catch (e) {
      print('Error editing store: $e');
    }
  }

  // Delete a store and update the user's store information
  Future<void> deleteStore(String storeId, CustomUserProvider userProvider) async {
    try {
      // Ensure storeId is not empty or null
      if (storeId.isEmpty) {
        throw Exception("Store ID cannot be empty or null.");
      }

      // Debug print to check the storeId
      print("Deleting store with ID: $storeId");

      // Delete all the products under the store first
      QuerySnapshot productSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .get();

      for (var productDoc in productSnapshot.docs) {
        await productDoc.reference.delete();
      }

      // Delete the store document from Firestore
      await FirebaseFirestore.instance.collection('stores').doc(storeId).delete();

      // If the user's store is being deleted, remove the store from the user
      if (userProvider.user?.store != null && userProvider.user!.store!.id == storeId) {
        userProvider.user!.store = null;

        // Save the updated user details in Firestore
        await userProvider.saveUserDetails(userProvider.user!);
      }

      // Refresh the stores list after deleting
      await fetchStores();
    } catch (e) {
      print('Error deleting store: $e');
    }
  }


  /// Add a new product to the store
  /// Add a new product to the store and update the user's store
  Future<void> addProduct(String storeId, Product newProduct, CustomUserProvider userProvider, BuildContext context) async {
    try {
      if (storeId.isEmpty) {
        throw Exception('Store ID cannot be empty.');
      }
      // Step 1: Add product to Firestore and get the document reference
      DocumentReference productRef = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .add(newProduct.toMap());

      // Step 2: Assign Firestore-generated ID to the product
      newProduct.id = productRef.id;

      // Step 3: Update the CustomUser's store with the new product
      if (userProvider.user?.store != null && userProvider.user!.store!.id == storeId) {
        // Add the new product to the user's store products list
        userProvider.user!.store!.products.add(newProduct);

        // Step 4: Save the updated user details in Firestore
        await userProvider.saveUserDetails(userProvider.user!);

        // Optionally, update the user's store in Firestore with the new product list (this is done automatically by saveUserDetails)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userProvider.user!.id) // Assuming user's ID is available in userProvider
            .update({
          'store.products': userProvider.user!.store!.products.map((product) => product.toMap()).toList(),
        });
      }

      // Step 5: Optionally refresh the stores list after adding the product
      await fetchStores();

    } catch (e) {
      print('Error adding product: $e');
      // Optionally display the error on the UI with a SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: $e')),
      );
    }
  }



// Edit an existing product
  Future<void> editProduct(String storeId, Product updatedProduct, CustomUserProvider userProvider) async {
    try {
      // Update the product in Firestore
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .doc(updatedProduct.id)
          .update(updatedProduct.toMap());

      // If the user's store is being updated, reflect the changes in the user's store
      if (userProvider.user?.store != null && userProvider.user!.store!.id == storeId) {
        int productIndex = userProvider.user!.store!.products.indexWhere((prod) => prod.id == updatedProduct.id);
        if (productIndex != -1) {
          userProvider.user!.store!.products[productIndex] = updatedProduct;

          // Save the updated user store in Firestore
          await userProvider.saveUserDetails(userProvider.user!);
        }
      }

      // Optionally refresh the stores list after editing
      fetchStores();
    } catch (e) {
      print('Error editing product: $e');
    }
  }

// Delete an existing product from a store and update the user's store
  Future<void> deleteProduct(String storeId, String productId, CustomUserProvider userProvider) async {
    try {
      // Delete the product from Firestore
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .doc(productId)
          .delete();

      // If the user's store is being updated, reflect the deletion in the user's store
      if (userProvider.user?.store != null && userProvider.user!.store!.id == storeId) {
        // Remove the product from the user's store
        userProvider.user!.store!.products.removeWhere((prod) => prod.id == productId);

        // Save the updated user store in Firestore
        await userProvider.saveUserDetails(userProvider.user!);
      }

      // Optionally refresh the stores list after deleting
      fetchStores();
    } catch (e) {
      print('Error deleting product: $e');
    }
  }
  Future<List<Payment>> fetchPaymentsForStoreByOwner(String userId, String storeId) async {
    try {
      // Fetch payments from the 'payments' subcollection under the specific user
      QuerySnapshot<Map<String, dynamic>> paymentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('payments')
          .where('storeId', isEqualTo: storeId) // Filter by storeId
          .get();

      // Map the documents to Payment objects
      List<Payment> payments = paymentSnapshot.docs.map((doc) {
        return Payment.fromMap(doc.data());
      }).toList();

      return payments;
    } catch (e) {
      print('Error fetching payments for user $userId: $e');
      return [];
    }
  }

  Future<Store?> fetchStore(String storeId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .get();

      if (snapshot.exists) {
        final storeData = snapshot.data();
        return Store.fromMap(storeData!); // Parse the store data
      }
    } catch (e) {
      print('Error fetching store data: $e');
    }
    return null;
  }


  /// Helper method to map Firestore document to a Store object
  Future<Store> _storeFromFirestore(DocumentSnapshot doc) async {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Owner data
    Owner owner = Owner(
      id: data['owner']['id'] ?? '', // Add fallback for missing data
      name: data['owner']['name'] ?? '',
      email: data['owner']['email'] ?? '',
      phone: data['owner']['phone'] ?? '',
      profileImageUrl: data['owner']['profileImageUrl'] ?? '',
    );

    // Step 1: Fetch products for this store from the "products" sub-collection
    List<Product> products = [];
    QuerySnapshot productSnapshot = await FirebaseFirestore.instance
        .collection('stores')
        .doc(doc.id)
        .collection('products') // Access the "products" sub-collection
        .get();

    // Step 2: Map the fetched documents to a list of Product objects
    products = productSnapshot.docs.map((productDoc) {
      Map<String, dynamic> productData = productDoc.data() as Map<String, dynamic>;
      return Product(
        id: productDoc.id,
        name: productData['name'] ?? '',
        description: productData['description'] ?? '',
        price: (productData['price'] ?? 0).toDouble(), // Handle missing or incorrect data
        rating: (productData['rating'] ?? 0).toDouble(),
        imageUrl: productData['imageUrl'] ?? '',
      );
    }).toList();

    // Step 3: Return the fully populated store, adding default values if fields are missing
    return Store(
      id: doc.id,
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      owner: owner,
      products: products, // Attach fetched products to the store
      location: data['location'] ?? GeoPoint(0, 0), // Default location if missing
      deliveryOptions: data['deliveryOptions'] != null
          ? List<String>.from(data['deliveryOptions'])
          : [], // Default empty list if missing
      deliveryCost: (data['deliveryCost'] ?? 0).toDouble(), // Default cost if missing
    );
  }


// Add a new YouTube video to a store
  Future<void> addVideo(String storeId, String videoUrl) async {
    try {
      final videoId = YoutubePlayer.convertUrlToId(videoUrl);
      if (videoId != null) {
        YouTubeVideo newVideo = YouTubeVideo(id: videoId, url: videoUrl);
        await FirebaseFirestore.instance.collection('stores').doc(storeId).update({
          'videos': FieldValue.arrayUnion([newVideo.toMap()])
        });
        notifyListeners();
      } else {
        print('Invalid YouTube URL');
      }
    } catch (e) {
      print('Error adding video: $e');
    }
  }

  // Edit an existing YouTube video
  Future<void> editVideo(String storeId, String videoId, String newUrl) async {
    try {
      YouTubeVideo updatedVideo = YouTubeVideo(id: videoId, url: newUrl);
      await FirebaseFirestore.instance.collection('stores').doc(storeId).update({
        'videos': FieldValue.arrayRemove([{'id': videoId}]), // Remove old video
      });
      await FirebaseFirestore.instance.collection('stores').doc(storeId).update({
        'videos': FieldValue.arrayUnion([updatedVideo.toMap()]), // Add updated video
      });
      notifyListeners();
    } catch (e) {
      print('Error editing video: $e');
    }
  }

  // Delete a YouTube video
  Future<void> deleteVideo(String storeId, YouTubeVideo video) async {
    try {
      await FirebaseFirestore.instance.collection('stores').doc(storeId).update({
        'videos': FieldValue.arrayRemove([video.toMap()])
      });
      notifyListeners();
    } catch (e) {
      print('Error deleting video: $e');
    }
  }
// Fetch owner details by storeId
  Future<CustomUser?> fetchOwnerByStoreId(String storeId) async {
    try {
      // Query the users collection for an owner whose storeId matches
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Owner')
          .where('store.id', isEqualTo: storeId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Fetch the first matched owner (assuming one owner per store)
        final ownerDoc = snapshot.docs.first;
        return CustomUser.fromDocument(ownerDoc);
      } else {
        print('No owner found for storeId: $storeId');
        return null;
      }
    } catch (e) {
      print('Error fetching owner by storeId: $e');
      return null;
    }
  }

  Future<String?> findChatId(String customerId, String storeId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: customerId)
        .get();

    for (var doc in snapshot.docs) {
      List participants = doc['participants'];
      if (participants.contains(storeId)) {
        return doc.id;
      }
    }
    return null; // No chat found
  }
  Future<List<Map<String, dynamic>>> fetchUserChatsForOwner(String storeId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: storeId)
          .orderBy('lastUpdated', descending: true)
          .get();

      // Parse chat metadata and return user details
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final participants = data['participants'] as List<dynamic>;
        final customerId = participants.firstWhere((id) => id != storeId);
        return {
          'chatId': doc.id,
          'customerId': customerId,
          'lastMessage': data['lastMessage'] ?? '',
          'lastUpdated': data['lastUpdated'] ?? Timestamp.now(),
        };
      }).toList();
    } catch (e) {
      print("Error fetching chats for owner: $e");
      return [];
    }
  }

}