import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:zing/Modal/CoustomUser.dart';
import 'package:zing/screen/StoreScreen/ProductDetailsScreen.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import '../../Chat/ChatScreen.dart';
import 'customCarousel.dart';

class StoreDetailScreen extends StatefulWidget {
  final Store store;
  final CustomUser user;

  StoreDetailScreen({required this.store, required this.user});

  @override
  _StoreDetailScreenState createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  GoogleMapController? _mapController;
  Position? _userPosition;
  List<LatLng> polylineCoordinates = [];
  Set<Polyline> polylines = {};
  double _currentRating = 0;
  bool _hasRated = false;
  double _averageRating = 0;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _checkIfUserHasRated();
    _loadAverageRating();
  }

  Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userPosition = position;
        _getDirections();
      });
    } catch (e) {
      print("Error getting user location: $e");
    }
  }

  Future<void> _getDirections() async {
    if (_userPosition == null) return;

    String baseUrl = 'https://maps.googleapis.com/maps/api/directions/json?';
    String origin = '${_userPosition!.latitude},${_userPosition!.longitude}';
    String destination =
        '${widget.store.location.latitude},${widget.store.location.longitude}';
    String apiKey = 'AIzaSyD-Y7nIBM2QYYBVa7pTvT7GPCvFqEWtfN4';

    final url = '$baseUrl'
        'origin=$origin&destination=$destination&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      if ((data['routes'] as List).isNotEmpty) {
        var points = data['routes'][0]['overview_polyline']['points'];
        _decodePolyline(points);
        _updateCameraPosition();
      }
    } else {
      print('Error fetching directions');
    }
  }

  void _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }

    setState(() {
      polylineCoordinates = points;
      polylines.add(Polyline(
        polylineId: PolylineId('route'),
        points: polylineCoordinates,
        color: Colors.blue,
        width: 6,
      ));
    });
  }

  void _updateCameraPosition() {
    if (_userPosition != null) {
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          _userPosition!.latitude < widget.store.location.latitude
              ? _userPosition!.latitude
              : widget.store.location.latitude,
          _userPosition!.longitude < widget.store.location.longitude
              ? _userPosition!.longitude
              : widget.store.location.longitude,
        ),
        northeast: LatLng(
          _userPosition!.latitude > widget.store.location.latitude
              ? _userPosition!.latitude
              : widget.store.location.latitude,
          _userPosition!.longitude > widget.store.location.longitude
              ? _userPosition!.longitude
              : widget.store.location.longitude,
        ),
      );

      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  Future<void> _checkIfUserHasRated() async {
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      bool hasRated = await widget.store.userHasRated(firebaseUser.uid);

      setState(() {
        _hasRated = hasRated;
      });
    }
  }

  Future<void> _loadAverageRating() async {
    double averageRating = await widget.store.getAverageRating();

    setState(() {
      _averageRating = averageRating;
    });
  }

  void _submitRating() async {
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      await widget.store.submitRating(firebaseUser.uid, _currentRating);
      setState(() {
        _hasRated = true;
      });
      _loadAverageRating();
    }
  }

  Future<void> _showRatingDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return FadeIn(
          child: AlertDialog(
            title: Text(
              'Rate this store',
              style: TextStyle(fontFamily: 'Georgia'),
            ),
            content: RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _currentRating = rating;
                });
              },
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  _submitRating();
                  Navigator.pop(context); // Close the dialog
                },
                child: Text('Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F0E4),
      appBar: AppBar(
        title: BounceInDown(
          child: Text(
            widget.store.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              fontFamily: 'Georgia',
              color: Colors.white,
            ),
          ),
        ),
        elevation: 2,
        centerTitle: true,
        backgroundColor: Colors.blue.shade900,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInDown(child: _buildStoreDetailsWithLogo()),
                SizedBox(height: 20),
                FadeInLeft(child: _buildStoreInformation()),
                SizedBox(height: 20),
                ZoomIn(child: buildDeliveryOptions(widget.store)),
                SizedBox(height: 20),
                FadeInRight(child: _buildRatingSection()),
                SizedBox(height: 20),
                SlideInUp(child: _buildMapWithPolyline()),
                SizedBox(height: 20),
                FadeIn(child: _buildProductSection()),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: BounceInUp(
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  storeId: widget.store.id!,
                  currentUser: widget.user,
                  storeImageUrl: widget.store.imageUrl,
                  userImageUrl: widget.user.profileImageUrl,
                ),
              ),
            );
          },
          label: Text(
            'Chat with Store',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          icon: Icon(Icons.chat),
          backgroundColor: Colors.blue.shade900,
        ),
      ),
    );
  }

// Inside your StoreDetailScreen widget
  Widget _buildStoreDetailsWithLogo() {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    // Extract media URLs (both image and video URLs)
    List<String> mediaUrls = [
      widget.store.imageUrl, // The main image URL
      ...widget.store.videos!.map((video) => video.url), // Extract video URLs (can be YouTube links)
    ];

    return Stack(
      children: [
        Container(
          height: screenHeight * 0.65,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade200, Colors.blue.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            height: screenHeight * 0.3,
            color: Colors.blue.withOpacity(0.2),
          ),
        ),
        Positioned(
          left: screenWidth * 0.05,
          right: screenWidth * 0.05,
          bottom: screenHeight * 0.05,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: screenHeight * 0.08,
                width: screenHeight * 0.08,
                child: Image.asset('assets/images/zing.png'),
              ),
              SizedBox(height: screenHeight * 0.02),

              CustomCarousel(
                store: widget.store, // Pass the combined list of image and video URLs
                onPageChanged: (index) {
                  debugPrint('Page Changed: $index');
                }
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                widget.store.name,
                style: TextStyle(
                  fontSize: screenHeight * 0.035,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                widget.store.description,
                style: TextStyle(
                  fontSize: screenHeight * 0.02,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.01),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone,
                      color: Colors.white, size: screenHeight * 0.03),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    widget.store.phoneNumber,
                    style: TextStyle(
                      fontSize: screenHeight * 0.02,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoreInformation() {
    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.category,
          label: "Category",
          value: widget.store.category,
        ),
      ],
    );
  }
  Widget buildDeliveryOptions(Store store) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Options',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
              fontFamily: 'Georgia',
            ),
          ),
          SizedBox(height: 10),
          // Display each delivery option
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: store.deliveryOptions!.map((option) {
              if (option == 'Home Delivery' && store.deliveryCost != null) {
                // If it's 'Home Delivery' and the store has a delivery cost, show the cost
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Home Delivery (Cost: \$${store.deliveryCost!.toStringAsFixed(2)})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                      fontFamily: 'Georgia',
                    ),
                  ),
                );
              } else {
                // For other delivery options, display them without a cost
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade700,
                      fontFamily: 'Georgia',
                    ),
                  ),
                );
              }
            }).toList(),
          ),
        ],
      ),
    );
  }


  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(20), // Increased padding for more space
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Softer border radius for modern look
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Average Rating: $_averageRating',
                style: TextStyle(
                  fontSize: 20, // Increased font size for better readability
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Georgia',
                  color: Colors.black87, // Slightly darker color for text
                ),
              ),
              Icon(
                Icons.star_border_outlined,
                color: Colors.amber.shade600,
                size: 28,
              ),
            ],
          ),
          SizedBox(height: 10), // Added spacing between elements
          RatingBarIndicator(
            rating: _averageRating,
            itemBuilder: (context, index) => Icon(
              Icons.star_rounded,
              color: Colors.amber.shade700,
            ),
            itemCount: 5,
            itemSize: 35.0, // Increased star size
            direction: Axis.horizontal,
          ),
          SizedBox(height: 20),
          if (!_hasRated)
            Center(
              child: ElevatedButton.icon(
                onPressed: _showRatingDialog,
                icon: Icon(Icons.rate_review, color: Colors.white),
                label: Text(
                  'Rate this store',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue.shade900, // A deeper blue color
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // More rounded button
                  ),
                  elevation: 8, // Slight elevation for better interaction
                  shadowColor: Colors.blue.shade200, // Shadow to enhance button
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildMapWithPolyline() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenMap(
              polylines: polylines,
              storeLocation: LatLng(
                widget.store.location.latitude,
                widget.store.location.longitude,
              ),
              userPosition: _userPosition,
            ),
          ),
        );
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.store.location.latitude,
                widget.store.location.longitude,
              ),
              zoom: 14,
            ),
            polylines: polylines,
            markers: {
              Marker(
                markerId: MarkerId(widget.store.id!),
                position: LatLng(
                  widget.store.location.latitude,
                  widget.store.location.longitude,
                ),
                infoWindow: InfoWindow(title: widget.store.name),
              ),
              if (_userPosition != null)
                Marker(
                  markerId: MarkerId("user"),
                  position: LatLng(
                    _userPosition!.latitude,
                    _userPosition!.longitude,
                  ),
                  infoWindow: InfoWindow(title: 'Your Location'),
                ),
            },
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProductSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Products"),
        SizedBox(height: 10),
        _buildProductGrid(widget.store.products),
      ],
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    if (products.isEmpty) {
      return Center(child: Text('No products available.'));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16), // Added padding around the grid
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.68, // Adjust aspect ratio for better layout
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(
                  product: product,
                  store: widget.store,
                ),
              ),
            );
          },
          child: Hero(
            tag: product.imageUrl ?? '',
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              shadowColor: Colors.black.withOpacity(0.3), // Subtle shadow
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product.imageUrl ?? '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                        fontFamily: 'Georgia',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "\RS ${product.price.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                            fontFamily: 'Georgia',
                          ),
                        ),
                        Icon(
                          Icons.add_shopping_cart,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[700]),
        SizedBox(width: 10),
        Text(
          "$label: ",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Georgia'),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 16, color: Colors.black54, fontFamily: 'Georgia'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        fontFamily: 'Georgia',
      ),
    );
  }
}

class FullScreenMap extends StatelessWidget {
  final Set<Polyline> polylines;
  final LatLng storeLocation;
  final Position? userPosition;

  const FullScreenMap({
    Key? key,
    required this.polylines,
    required this.storeLocation,
    this.userPosition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Full Screen Map"),
          backgroundColor: Colors.blue.shade900,
        ),
        body: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: storeLocation,
            zoom: 14,
          ),
          polylines: polylines,
          markers: {
            Marker(
              markerId: MarkerId("store"),
              position: storeLocation,
              infoWindow: InfoWindow(title: "Store Location"),
            ),
            if (userPosition != null)
              Marker(
                markerId: MarkerId("user"),
                position: LatLng(userPosition!.latitude, userPosition!.longitude),
                infoWindow: InfoWindow(title: "Your Location"),
              ),
          },
        ),
      ),
    );
  }
}
