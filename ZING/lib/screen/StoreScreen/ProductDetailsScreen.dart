import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:zing/Cart/CartProvider.dart';
import 'package:zing/Modal/CoustomUser.dart';
import 'package:zing/Service/OrderProvider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:zing/screen/UserScreens/EditeUser.dart';
import '../../Service/CoustomUserProvider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final Store store;

  ProductDetailScreen({required this.product, required this.store});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  CustomUser? currentUser;
  bool isLoading = true;
  String? errorMessage;
  String? selectedDeliveryMethod;

  @override
  void initState() {
    super.initState();
    fetchCurrentUser();
  }

  Future<void> fetchCurrentUser() async {
    final userProvider = Provider.of<CustomUserProvider>(context, listen: false);
    try {
      await userProvider.fetchUserDetails();
      setState(() {
        currentUser = userProvider.user;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching user data: $e";
        isLoading = false;
      });
    }
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(), // Replace with your Edit Profile Screen
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(
          widget.product.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.blue.shade900,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white),
      ),
      body: isLoading
          ? Center(
        child: SpinKitFadingCircle(
          color: Colors.blueAccent,
          size: 60.0,
        ),
      )
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : currentUser == null
          ? Center(child: Text('No user found'))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Animated Product Image
              FadeIn(
                duration: Duration(milliseconds: 800),
                child: _buildProductImage(),
              ),
              SizedBox(height: 20),

              // Product Name and Price
              FadeInLeft(
                duration: Duration(milliseconds: 800),
                child: _buildProductDetails(),
              ),
              SizedBox(height: 20),

              // Product Description
              FadeInRight(
                duration: Duration(milliseconds: 800),
                child: _buildSection("Description", widget.product.description ?? "No description available."),
              ),
              SizedBox(height: 30),

              // Action Buttons with Animation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Bounce(
                    duration: Duration(milliseconds: 800),
                    child: _buildActionButton(
                      label: "Add to Cart",
                      icon: Icons.add_shopping_cart,
                      color: Colors.blue.shade700,
                      onPressed: () {
                        cart.addItem(widget.product, context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("${widget.product.name} added to cart!"),
                          duration: Duration(seconds: 2),
                        ));
                      },
                    ),
                  ),
                  Bounce(
                    duration: Duration(milliseconds: 800),
                    child: _buildActionButton(
                      label: "Order Now",
                      icon: Icons.shopping_bag,
                      color: Colors.blue.shade900,
                      onPressed: () async {
                        await _showDeliveryMethodDialog(context, currentUser!, orderProvider);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Hero(
      tag: widget.product.imageUrl ?? '',
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade200,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
          image: DecorationImage(
            image: NetworkImage(widget.product.imageUrl ?? ''),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildProductDetails() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "\$${widget.product.price.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "In Stock",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(fontSize: 16, color: Colors.blue.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      onPressed: onPressed,
    );
  }

  Future<void> _showDeliveryMethodDialog(
      BuildContext context,
      CustomUser currentUser,
      OrderProvider orderProvider,
      ) async {
    // Check if user details are complete
    if (currentUser.name.isEmpty ||
        currentUser.phoneNumber.isEmpty ||
        currentUser.profileImageUrl.isEmpty) {
      // Show an alert dialog to notify the user to update their profile
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Incomplete Profile Details',
              style: TextStyle(color: Colors.red.shade900),
            ),
            content: Text(
              'Please update your profile to include your name, phone number, and profile picture before placing an order.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900),
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  _navigateToEditProfile(context); // Navigate to profile edit screen
                },
                child: Text('Update Profile'),
              ),
            ],
          );
        },
      );
      return; // Exit the function to prevent order placement
    }

    // If user details are complete, proceed to show delivery method dialog
    String? selectedMethod = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return ZoomIn(
          duration: Duration(milliseconds: 800),
          child: AlertDialog(
            title: Text('Select Delivery Method', style: TextStyle(color: Colors.blue.shade900)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.store.deliveryOptions!.map((method) {
                return RadioListTile<String>(
                  activeColor: Colors.blue.shade900,
                  title: Text(method, style: TextStyle(color: Colors.blue.shade700)),
                  value: method,
                  groupValue: selectedDeliveryMethod,
                  onChanged: (String? value) {
                    setState(() {
                      selectedDeliveryMethod = value!;
                    });
                    Navigator.pop(context, value);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (selectedMethod != null) {
      setState(() {
        selectedDeliveryMethod = selectedMethod;
      });

      try {
        // Call the updated placeOrder function
        await orderProvider.placeOrder(
          currentUser.id,
          widget.store,
          [widget.product],
          widget.product.price,
          selectedMethod,
          currentUser,
        );

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Order placed for ${widget.product.name} with $selectedMethod!"),
          duration: Duration(seconds: 2),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error placing order: $e"),
          duration: Duration(seconds: 2),
        ));
      }
    }
  }
}