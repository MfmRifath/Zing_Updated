import 'package:flutter/material.dart';
import 'package:zing/Modal/CoustomUser.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserDetailsPage extends StatelessWidget {
  final CustomUser user;

  const UserDetailsPage({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserHeader(context),
              SizedBox(height: 20),
              _buildUserDetails(context),
              SizedBox(height: 20),
              _buildUserRole(context),
              SizedBox(height: 20),
              if (user.role == 'Owner' && user.store != null) ...[
                _buildStoreLocation(context), // Google Map for store location
                SizedBox(height: 20),
                _buildStoreDetails(context),  // More detailed store information
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Widget to build the user profile header
  Widget _buildUserHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.blueGrey,
          backgroundImage: user.profileImageUrl.isNotEmpty
              ? NetworkImage(user.profileImageUrl)
              : null,
          child: user.profileImageUrl.isEmpty
              ? Text(
            user.name[0].toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          )
              : null,
        ),
        SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              user.email,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  // Widget to build the user details card
  Widget _buildUserDetails(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            _buildDetailRow('Email', user.email),
            SizedBox(height: 10),
            _buildDetailRow('Phone', user.phoneNumber),
            SizedBox(height: 10),
            _buildDetailRow('Address', user.address.isNotEmpty ? user.address : 'No Address Provided'),
          ],
        ),
      ),
    );
  }

  // Widget to build the user role card
  Widget _buildUserRole(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            _buildDetailRow('Role', user.role),
            if (user.role == 'Owner' && user.store != null) ...[
              SizedBox(height: 10),
              _buildDetailRow('Store ID', user.store!.id!),
              SizedBox(height: 10),
              _buildDetailRow('Store Name', user.store!.name),
            ],
          ],
        ),
      ),
    );
  }

  // Widget to show the store location using Google Maps
  Widget _buildStoreLocation(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Store Location',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Container(
          height: 250,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(user.store!.location.latitude, user.store!.location.longitude),  // Store coordinates
              zoom: 14,
            ),
            markers: {
              Marker(
                markerId: MarkerId('storeLocation'),
                position: LatLng(user.store!.location.latitude, user.store!.location.longitude),
                infoWindow: InfoWindow(
                  title: user.store!.name,
                  snippet: 'Store Location',
                ),
              ),
            },
          ),
        ),
      ],
    );
  }

  // Widget to show more details about the store, including delivery methods
  Widget _buildStoreDetails(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Store Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            _buildDetailRow('Store Description', user.store!.description),
            SizedBox(height: 10),
            _buildDetailRow('Category', user.store!.category),
            SizedBox(height: 10),
            _buildDetailRow('Rating', _calculateAverageRating(user.store!.ratings).toStringAsFixed(1)),
            SizedBox(height: 10),
            _buildDeliveryOptions(),  // New delivery options section
            SizedBox(height: 10),
            Text(
              'Products Available:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            _buildProductList(user.store!.products),
          ],
        ),
      ),
    );
  }

  // New widget to display delivery options
  Widget _buildDeliveryOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Options:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        if (user.store!.deliveryOptions!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: user.store!.deliveryOptions!.map((method) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('- $method'),
              );
            }).toList(),
          )
        else
          Text('No delivery options available.'),
      ],
    );
  }

  // Widget to display a list of products offered by the store
  Widget _buildProductList(List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: products.map((product) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text('- ${product.name} (\$${product.price.toStringAsFixed(2)})'),
        );
      }).toList(),
    );
  }

  // Helper function to calculate the average rating
  double _calculateAverageRating(List<Rating> ratings) {
    if (ratings.isEmpty) return 0.0;
    double totalScore = ratings.fold(0.0, (sum, rating) => sum + rating.score);
    return totalScore / ratings.length;
  }

  // Helper widget to build a row of details
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(value),
      ],
    );
  }
}
