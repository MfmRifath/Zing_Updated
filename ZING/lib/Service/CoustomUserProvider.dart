import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zing/Modal/CoustomUser.dart';
import 'package:cloud_functions/cloud_functions.dart';

class CustomUserProvider with ChangeNotifier {
  CustomUser? currentUser;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Payment> _payments = [];
  List<Payment> get payments => _payments;
  CustomUser? get user => currentUser;
  bool get isLoading => _isLoading;
  List<CustomUser> _users = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<CustomUser> get users => _users;
  CustomUserProvider() {
    _initializeUser();
  }

  Future<void> updatePaymentStatusAndStoreAccess(CustomUser user, bool accessStatus) async {
    try {
      // Update `storeAccess` field
      user.storeAccess = accessStatus;

      // Fetch the latest payment record and update it
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('payments')
          .orderBy('paymentDate', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var paymentDoc = snapshot.docs.first;
        // Update the payment document with current payment status and the current date
        await paymentDoc.reference.update({
          'paymentStatus': 'Completed',
          'paymentDate': FieldValue.serverTimestamp(), // Sets the current timestamp in Firestore
        });
      }

      // Update Firestore to reflect the changes
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({'storeAccess': accessStatus, 'hasPaid': true});

      notifyListeners();
    } catch (e) {
      print('Error updating payment status or store access: $e');
      rethrow;
    }
  }

  // Initialize the user data and payments concurrently
  Future<void> _initializeUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        fetchUsers(),
        fetchPaymentsForCurrentUser(),
      ]);
    } catch (e) {
      print("Error during initialization: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

    void refreshUserData() {
      fetchUserDataFromFirestore();  // Call to re-fetch data from Firestore
    }

    // Fetch the current logged-in user's details from Firestore
    Future<void> fetchUserDataFromFirestore() async {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        print("No user is logged in.");
        return;
      }

      try {
        final userRef = FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid);
        final DocumentSnapshot<Map<String, dynamic>> userDoc = await userRef.get();

        if (userDoc.exists && userDoc.data() != null) {
          currentUser = CustomUser.fromDocument(userDoc);  // Update the current user
          notifyListeners();  // Notify listeners about the data change
        } else {
          print("User data not found.");
        }
      } catch (e) {
        print("Error fetching user details: $e");
      }
    }
  // Fetch all users from Firestore
  // Fetch all users from Firestore with real-time updates
  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Use snapshots() to listen for real-time updates
      FirebaseFirestore.instance.collection('users').snapshots().listen((snapshot) {
        _users = snapshot.docs.map((doc) {
          return CustomUser.fromDocument(doc);
        }).toList();
        notifyListeners(); // Notify listeners when data changes
      });
    } catch (e) {
      print("Error fetching users: $e");
    } finally {
      _isLoading = false;
    }
  }


  // Fetch payments for the current user
  Future<void> fetchPaymentsForCurrentUser() async {
    if (currentUser == null) {
      print('No current user set.');
      return;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> paymentsSnapshot =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.id)
          .collection('payments')
          .get();

      _payments = paymentsSnapshot.docs.map((doc) {
        return Payment.fromMap(doc.data());
      }).toList();

      notifyListeners();
    } catch (e) {
      print('Error fetching payments: $e');
    }
  }

  // Add payment to the current user's subcollection
  Future<void> addPaymentToCurrentUser(Payment payment) async {
    if (currentUser == null) {
      print('No current user set.');
      return;
    }

    try {
      DocumentReference paymentRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.id)
          .collection('payments')
          .add(payment.toMap());

      payment.paymentId = paymentRef.id;

      // Re-fetch the updated user data
      await fetchUserDetails();

      print("Payment added successfully and user details updated.");
    } catch (e) {
      print('Error adding payment: $e');
    }
  }

  // Fetch the current logged-in user's details
  Future<CustomUser?> fetchUserDetails() async {
    User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      print("No user is logged in.");
      return null;
    }

    try {
      final userRef =
      FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid);
      final DocumentSnapshot<Map<String, dynamic>> userDoc = await userRef.get();

      if (userDoc.exists && userDoc.data() != null) {
        currentUser = CustomUser.fromDocument(userDoc);
        notifyListeners();
        return currentUser;
      } else {
        print("User data not found.");
        return null;
      }
    } catch (e) {
      print("Error fetching user details: $e");
      return null;
    }
  }

  // Add a store to the current user
  Future<void> addStoreToUser(Store newStore) async {
    if (currentUser == null) {
      print("No current user set.");
      return;
    }

    try {
      DocumentReference storeRef =
      await FirebaseFirestore.instance.collection('stores').add(newStore.toMap());
      newStore.id = storeRef.id;

      currentUser!.store = newStore;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.id)
          .update({'store': newStore.toMap()});

      notifyListeners();
    } catch (e) {
      print("Error adding store to user: $e");
    }
  }

  // Handle favorite stores
  void addFavoriteStore(String storeId) {
    if (currentUser != null && !currentUser!.favorites!.contains(storeId)) {
      currentUser!.addFavorite(storeId);
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.id)
          .update({'favorites': currentUser!.favorites});
      notifyListeners();
    }
  }

  void removeFavoriteStore(String storeId) {
    if (currentUser != null && currentUser!.favorites!.contains(storeId)) {
      currentUser!.removeFavorite(storeId);
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.id)
          .update({'favorites': currentUser!.favorites});
      notifyListeners();
    }
  }
// Fetch a user by their user ID
  Future<CustomUser?> fetchUserById(String userId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        return CustomUser.fromDocument(userDoc);
      } else {
        print("User not found for ID: $userId");
        return null;
      }
    } catch (e) {
      print("Error fetching user by ID: $e");
      return null;
    }
  }
  bool isFavoriteStore(String storeId) {
    return currentUser?.favorites!.contains(storeId) ?? false;
  }

  // Monitor authentication state changes
  void monitorAuthState() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        print("User is currently signed out.");
        currentUser = null;
        notifyListeners();
      } else {
        print("User is signed in.");
        fetchUserDetails();
      }
    });
  }

  // Sign out the user
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      currentUser = null;
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Save user details in Firestore
  Future<void> saveUserDetails(CustomUser user) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .set(user.toMap(), SetOptions(merge: true));
      currentUser = user;
      notifyListeners();
    } catch (e) {
      print("Error saving user details: $e");
    }
  }
  Future<void> deleteUser(String userId, {bool isOwner = false, String? storeId}) async {
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      print("User found: ${firebaseUser.uid}");
      try {

        // Step 1: Delete the user's store if the user is an owner
        if (isOwner && storeId != null) {
          await _deleteStore(storeId);
        }

        // Step 2: Delete user from Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).delete();

        // Step 3: Delete user from Firebase Authentication
        final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('deleteUser');
        await callable.call({
          "uid": userId,
        });


        _users.removeWhere((user) => user.id == userId);
        notifyListeners();
      } catch (e) {
        print('Error deleting user: $e');
      }
    } else {
      print("User not found in Firebase Authentication.");
    }


  }

  Future<void> _deleteStore(String storeId) async {
    try {
      // Step 1: Delete all the products associated with the store
      QuerySnapshot productsSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .get();

      for (var productDoc in productsSnapshot.docs) {
        await productDoc.reference.delete();
      }

      // Step 2: Delete the store document from Firestore
      await FirebaseFirestore.instance.collection('stores').doc(storeId).delete();

      print('Store deleted successfully');
    } catch (e) {
      print('Error deleting store: $e');
    }
  }
  // Add user to Firebase Authentication and Firestore
  Future<void> addUser({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String role, // Adding role as a required parameter
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Create user in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Construct a new CustomUser object
      CustomUser newUser = CustomUser(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        address: '', // Default values can be changed as needed
        profileImageUrl: '', // Default profile image (or set your own)
        role: role, // Role set from input
      );

      // Add user details to Firestore
      await FirebaseFirestore.instance.collection('users').doc(newUser.id).set(newUser.toMap());

      // Set the new user to the provider's state
      currentUser = newUser;
    } catch (e) {
      print("Error adding new user: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
// Fetch a user by their user ID
  Future<CustomUser?> getUserById(String userId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        return CustomUser.fromDocument(userDoc);
      } else {
        print("User not found for ID: $userId");
        return null;
      }
    } catch (e) {
      print("Error fetching user by ID: $e");
      return null;
    }
  }
// Add user to Firebase Authentication and Firestore
  Future<void> addAdmin({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Create user in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Construct a new CustomUser object for Admin
      CustomUser newUser = CustomUser(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        address: '', // Default values can be changed as needed
        profileImageUrl: '', // Default profile image (or set your own)
        role: 'Admin', // Role is set to 'Admin'
      );

      // Add admin user details to Firestore
      await FirebaseFirestore.instance.collection('users').doc(newUser.id).set(newUser.toMap());

      // Set the new user to the provider's state
      currentUser = newUser;
    } catch (e) {
      print("Error adding new admin: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
// Change password for the current user
  Future<void> changePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        await user.reload(); // Reload user to apply changes
        print("Password updated successfully.");
      } else {
        print("No user is logged in to change the password.");
      }
    } catch (e) {
      if (e.toString().contains('requires-recent-login')) {
        print("Error: The user needs to reauthenticate before changing the password.");
      } else {
        print("Error changing password: $e");
      }
      rethrow;
    }
  }


}
