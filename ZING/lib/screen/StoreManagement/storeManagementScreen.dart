import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:zing/Modal/CoustomUser.dart';
import 'package:zing/Service/CoustomUserProvider.dart';
import 'package:zing/Service/StoreProvider.dart';
import 'package:zing/screen/StoreManagement/EditProduct.dart';
import 'package:zing/screen/StoreManagement/EditStoreScreen.dart';
import '../../Chat/ChatScreen.dart';
import '../../Service/OrderProvider.dart';
import '../../Service/SettingProvider.dart';
import 'CircleProgressPainter.dart';

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

  late FirebaseFirestore _firestore;
  List<Orders> _cachedOrders = [];

  @override
  void initState() {
    super.initState();
    fetchUserData();
    _firestore = FirebaseFirestore.instance;
    // Fetch user data on initialization
  }




  Future<void> fetchOrdersByStore(String storeId) async {
    if (_isLoading || _cachedOrders.isNotEmpty) {
      // Skip fetching if already loading or data is cached
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print("Fetching orders for store: $storeId");

      final querySnapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('orders')
          .get();

      final fetchedOrders = querySnapshot.docs.map((doc) {
        print("Order data: ${doc.data()}");
        return Orders.fromDocument(doc);
      }).toList();

      setState(() {
        _cachedOrders = fetchedOrders;
      });
    } catch (e, stackTrace) {
      print("Error fetching orders: $e\n$stackTrace");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  List<List<T>> _splitList<T>(List<T> list, int chunkSize) {
    final List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }
  Future<void> fetchUserData() async {
    final userProvider = Provider.of<CustomUserProvider>(context, listen: false);
    final currentUser = userProvider.user;

    if (currentUser != null && currentUser.store != null) {
      final storeId = currentUser.store!.id!;
      await fetchProductsForStore(storeId);

      // Fetch the latest payment for this user and calculate remaining days
      await fetchLatestPaymentAndCalculateDaysLeft(currentUser.id);
    }

    setState(() {
      _currentUser = currentUser;
      _isLoading = false;
    });
  }
  Future<CustomUser?> fetchUserDetails(String userId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userSnapshot.exists) {
        final data = userSnapshot.data()!;
        return CustomUser(
          id: userSnapshot.id,
          name: data['name'],
          email: data['email'],
          phoneNumber: data['phoneNumber'],
          profileImageUrl: data['profileImageUrl'] ?? '',
        );
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
    return null;
  }

  Future<void> fetchLatestPaymentAndCalculateDaysLeft(String userId) async {
    try {
      // Fetch the most recent payment
      final QuerySnapshot<Map<String, dynamic>> paymentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('payments')
          .orderBy('paymentDate', descending: true)
          .limit(1)
          .get();

      if (paymentSnapshot.docs.isNotEmpty) {
        // Assuming the payment document contains a 'paymentDate' field
        final paymentData = paymentSnapshot.docs.first.data();
        final Timestamp paymentDate = paymentData['paymentDate'];

        // Calculate days left based on the payment date
        DateTime currentDate = DateTime.now();
        Duration difference = currentDate.difference(paymentDate.toDate());
        _daysLeft = 30 - difference.inDays;

        if (_daysLeft <= 0) {
          _hasAccess = false;
        }
      } else {
        // No payments found, revoke access
        _hasAccess = false;
      }
    } catch (e) {
      print("Error fetching latest payment: $e");
      _hasAccess = false;
    }
  }
  
  Future<void> fetchProductsForStore(String storeId) async {
    try {
      QuerySnapshot productSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .get();

      List<Product> products = productSnapshot.docs.map((productDoc) {
        Map<String, dynamic> productData = productDoc.data() as Map<String, dynamic>;
        return Product(
          id: productDoc.id,
          name: productData['name'],
          description: productData['description'],
          price: productData['price'].toDouble(),
          rating: productData['rating'].toDouble(),
          imageUrl: productData['imageUrl'] ?? '',
        );
      }).toList();

      setState(() {
        _products = products;
      });
    } catch (e) {
      print('Error fetching products: $e');
    }
  }
  Future<void> _updateOrderStatus(String orderId, String storeId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Order status updated to $newStatus.'),
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update status: $e'),
        duration: Duration(seconds: 2),
      ));
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: SpinKitFadingCircle(
          color: Colors.blueAccent,
          size: 60.0,
        ),
      );
    }

    if (_currentUser == null) {
      return Center(child: Text('No authenticated user found.'));
    }

    if (_currentUser!.role == 'User') {
      return Center(child: Text('You are not authorized to access this section.'));
    }

    if (_currentUser!.store == null) {
      return _buildAddStoreButton();
    }

    return _hasAccess ? _buildStoreManagementContent() : _buildRenewScreen();
  }
// Payment functionality
  void makePayment(BuildContext context, Store store, CustomUser user, StoreProvider storeProvider, CustomUserProvider userProvider, Function setStateCallback) async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    // Ensure the registration amount has been fetched
    await settingsProvider.fetchGlobalRegistrationAmount();

    if (settingsProvider.registrationAmount == null || settingsProvider.currency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Registration amount or currency is not set.')),
      );
      return;
    }

    var paymentObject = {
      "sandbox": true, // Use true for testing, false for production
      "merchant_id": "1228930",
      "merchant_secret": "Mjk3Njc0NDcwNTI1NDY1MDE4ODkxMTQ0NjI4NTMzMzE5Nzg0MzU1MQ==",
      "notify_url": "http://sample.com/notify",
      "order_id": "ItemNo12345",
      "items": "Store Management Access",
      "amount": settingsProvider.registrationAmount!.toString(),
      "currency": settingsProvider.currency,
      "first_name": user.name,
      "last_name": "", // Provide an empty string if there's no last name
      "email": user.email,
      "phone": user.phoneNumber,
      "address": "No.1, Galle Road",
      "city": "Colombo",
      "country": "Sri Lanka"
    };

    PayHere.startPayment(paymentObject, (paymentId) async {
      print("Payment Success. Payment Id: $paymentId");

      // Create the payment object
      final paymentData = {
        "paymentId": paymentId,
        "amount": settingsProvider.registrationAmount!,
        "currency": settingsProvider.currency!,
        "items": 'Store Management Access',
        "paymentStatus": 'Completed',
        "paymentDate": Timestamp.now(),
        "storeId": store.id
      };

      // Add payment to the sub-collection 'payments' under the user's document in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id) // Assuming 'uid' is the user ID field in the CustomUser object
          .collection('payments')
          .add(paymentData);

      // Update the state locally after payment completion using the passed setState callback
      setStateCallback(() {
        _daysLeft = 30; // Reset days left to 30
        _hasAccess = true; // Grant access
      });

      // Optionally show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment successful. Store access renewed!')),
      );

    }, (error) {
      print("Payment Failed. Error: $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed, store not added')));

    }, () {
      print("Payment Dismissed");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment dismissed')));
    });
  }

  Widget _buildStoreManagementContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDaysLeftIndicator(),
          _buildStoreHeader(_currentUser!.store!),
          _buildOrderManagementSection(_currentUser!.store!.id!), // Display orders from customers
          _buildProductGrid(_currentUser!.store!, _products),
          _buildAddProductButton(_currentUser!.store!),

        ],
      ),
    );
  }
  Widget _buildOrderManagementSection(String storeId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
          _buildOrderList(storeId),
        ],
      ),
    );
  }
  Widget _buildOrderList(String storeId) {
    return FutureBuilder<void>(
      future: fetchOrdersByStore(storeId),
      builder: (context, snapshot) {
        if (_isLoading) {
          return Center(child: CircularProgressIndicator());
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order status updated to $newStatus.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating order status: $e')));
    }
  }
  Widget _buildDaysLeftIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        children: [
          Text(
            'Days Left to Renew: $_daysLeft',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade900,
            ),
          ),
          SizedBox(height: 20),
          CustomPaint(
            foregroundPainter: CircleProgressPainter(
              percentage: _daysLeft / 30,
              strokeWidth: 10,
              color: _daysLeft > 10 ? Colors.blueAccent : Colors.redAccent,
            ),
            child: Container(
              width: 120,
              height: 120,
              child: Center(
                child: Text(
                  "$_daysLeft",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _daysLeft > 10 ? Colors.blueAccent : Colors.redAccent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

  }

  Widget _buildRenewScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Your access has expired.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('Renew Access'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4.0,
            ),
            onPressed: () {
              // Call the makePayment function and pass the setState callback
              makePayment(
                context,
                _currentUser!.store!,
                _currentUser!,
                Provider.of<StoreProvider>(context, listen: false),
                Provider.of<CustomUserProvider>(context, listen: false),
                setState,  // Pass the setState callback to makePayment
              );
            },
          ),

        ],
      ),
    );
  }

  Widget _buildAddStoreButton() {
    final storeProvider = Provider.of<StoreProvider>(context,listen: false);
    return Center(
      child: ElevatedButton.icon(
        icon: Icon(Icons.add),
        label: Text('Add Store'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4.0,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditStoreDialog(refreshStoreData: () {
                setState(() {
                  // Trigger UI refresh here after adding or editing the store
                  storeProvider.fetchStores(); // Re-fetch the store list from Firestore or other data sources
                });
              },),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoreHeader(Store userStore) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 10.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/images/zing.png',
                image: userStore.imageUrl.isNotEmpty
                    ? userStore.imageUrl
                    : 'https://via.placeholder.com/400x200.png?text=No+Image',
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                fadeInDuration: Duration(milliseconds: 300),
                fadeOutDuration: Duration(milliseconds: 300),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userStore.name,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade900,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Category: ${userStore.category}",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildDeliveryOptions(userStore), // Display the delivery options
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.blueGrey, size: 22),
                      SizedBox(width: 8),
                      Text(
                        userStore.phoneNumber,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildGoogleMap(userStore),
                  SizedBox(height: 16),
                  _buildStoreActions(userStore, _currentUser!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDeliveryOptions(Store store) {
    List<Widget> deliveryOptionsWidgets = [];

    for (var option in store.deliveryOptions!) {
      if (option == 'Home Delivery' && store.deliveryCost != null) {
        deliveryOptionsWidgets.add(Text('Delivery Option: Home Delivery (Cost: \$${store.deliveryCost!.toStringAsFixed(2)})',
            style: TextStyle(fontSize: 16, color: Colors.green.shade700)));
      } else {
        deliveryOptionsWidgets.add(Text('Delivery Option: $option',
            style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade700)));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: deliveryOptionsWidgets,
    );
  }


  Widget _buildGoogleMap(Store userStore) {
    return Container(
      height: 200,
      width: double.infinity,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(userStore.location.latitude, userStore.location.longitude),
          zoom: 14,
        ),
        markers: {
          Marker(
            markerId: MarkerId('store-location'),
            position: LatLng(userStore.location.latitude, userStore.location.longitude),
            infoWindow: InfoWindow(
              title: userStore.name,
              snippet: userStore.category,
            ),
          ),
        },
      ),
    );
  }

  Widget _buildStoreActions(Store userStore, CustomUser user) {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditStoreDialog(store: userStore, refreshStoreData: () {
                      setState(() {
                        // Trigger UI refresh here after adding or editing the store
                        storeProvider.fetchStores(); // Re-fetch the store list from Firestore or other data sources
                      });
                    },),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
              ),
              label: Text(
                'Edit Store',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: () async {
                final confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Delete Store'),
                    content: Text('Are you sure you want to delete this store? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  Provider.of<StoreProvider>(context, listen: false)
                      .deleteStore(userStore.id!, Provider.of<CustomUserProvider>(context, listen: false));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
              ),
              label: Text(
                'Delete Store',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          icon: Icon(Icons.chat, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  storeId: userStore.id!,
                  currentUser: user,
                  storeImageUrl: userStore.imageUrl,
                  userImageUrl: user.profileImageUrl,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 6,
          ),
          label: Text(
            'Chat with Customer',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildProductGrid(Store userStore, List<Product> products) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth < 600 ? 2 : 3;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: products.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: screenWidth < 600 ? 0.75 : 0.65,
        ),
        itemBuilder: (context, index) {
          final product = products[index];
          final imageUrl = product.imageUrl!.isNotEmpty
              ? product.imageUrl
              : 'https://via.placeholder.com/150';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProductScreen(product: product, storeId: userStore.id!),
                ),
              );
            },
            child: Card(
              elevation: 6.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/images/zing.png',
                      image: imageUrl!,
                      height: screenWidth < 600 ? 140 : 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      fadeInDuration: Duration(milliseconds: 300),
                      fadeOutDuration: Duration(milliseconds: 300),
                      imageErrorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/error_image.png',
                          height: screenWidth < 600 ? 140 : 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 1.0, right: 1.0, bottom: 0.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: screenWidth < 600 ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "\$${product.price.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[600],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blueAccent),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProductScreen(
                                          product: product, storeId: userStore.id!),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () async {
                                  final confirm = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Delete Product'),
                                      content: Text('Are you sure you want to delete this product?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    // Delete product logic here
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddProductButton(Store userStore) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        icon: Icon(Icons.add),
        label: Text('Add Product'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4.0,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProductScreen(storeId: userStore.id!),
            ),
          );
        },
      ),
    );
  }
}


