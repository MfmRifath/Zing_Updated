import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zing/Modal/CoustomUser.dart';
import 'package:zing/Service/StoreProvider.dart';
import 'package:zing/Service/OrderProvider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class AdminStoreDetailScreen extends StatefulWidget {
  final Store store;

  const AdminStoreDetailScreen({Key? key, required this.store}) : super(key: key);

  @override
  State<AdminStoreDetailScreen> createState() => _AdminStoreDetailScreenState();
}

class _AdminStoreDetailScreenState extends State<AdminStoreDetailScreen> {
  late List<YoutubePlayerController> _youtubeControllers;
  Store? _store;
  bool _isLoadingVideos = true;

  @override
  void initState() {
    super.initState();
    _fetchStoreData();
    Provider.of<OrderProvider>(context, listen: false)
        .fetchOrdersByStore(context,widget.store.id!);
  }

  Future<void> _fetchStoreData() async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    Store? fetchedStore = await storeProvider.fetchStore(widget.store.id!);

    if (fetchedStore != null && fetchedStore.videos != null) {
      setState(() {
        _store = fetchedStore;
        _youtubeControllers = _store!.videos!.map((video) {
          final videoId = YoutubePlayer.convertUrlToId(video.url);
          return YoutubePlayerController(
            initialVideoId: videoId ?? '',
            flags: const YoutubePlayerFlags(autoPlay: false),
          );
        }).toList();
        _isLoadingVideos = false;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _youtubeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBackgroundGradient(), // Gradient background
          _store != null ? _buildStoreDetails() : _buildLoading(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      // Bottom nav bar
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        '${_store?.name ?? ''} Details',
        style: const TextStyle(
          fontFamily: 'Georgia',
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      centerTitle: true,
      flexibleSpace: ClipPath(
        clipper: CustomAppBarClipper(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.purple.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade300, Colors.purple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildStoreDetails() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedStoreInfoCard(),
            const SizedBox(height: 20),
            _buildStoreImageCard(),
            const SizedBox(height: 20),
            _buildOrdersCard(),
            const SizedBox(height: 20),
            _buildPaymentsCard(),
            const SizedBox(height: 20),
            _buildStoreLocationCard(),
            const SizedBox(height: 20),
            _buildDeliveryMethodsCard(),
            const SizedBox(height: 20),
            _buildYouTubePlayers(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedStoreInfoCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Store Information'),
              const SizedBox(height: 10),
              _buildInfoRow('Name', _store?.name ?? ''),
              _buildInfoRow('Category', _store?.category ?? ''),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildStoreImageCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.2), // Adding shadow effect for depth
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Store Image'),

          // Image with subtle animation effect on tap
          GestureDetector(
            onTap: () {
              // Implement light effect or any other interaction on tap
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
                top: Radius.circular(20),
              ),
              child: _buildImageWithEffects(), // Improved image display
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildImageWithEffects() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Colors.transparent,
            Colors.black26, // Adding a subtle gradient for contrast
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: _store?.imageUrl != null && _store!.imageUrl.isNotEmpty
          ? Image.network(
        _store!.imageUrl,
        height: 220,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.broken_image,
              size: 50,
              color: Colors.redAccent,
            ),
          );
        },
      )
          : const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 50,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildOrdersCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Orders'),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildOrdersSection(),
          ),
        ],
      ),
    );
  }


  Widget _buildOrdersSection() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.isLoading) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (orderProvider.orders.isEmpty) {
          return Center(
            child: Text(
              'No orders available.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
          );
        } else {
          return ListView.builder(
            itemCount: orderProvider.orders.length,
            shrinkWrap: true,
            physics: BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final order = orderProvider.orders[index];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_cart, color: Colors.blue, size: 24),
                  ),
                  title: Text(
                    'Order #${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Price: \$${order.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14, color: Colors.green),
                      ),
                      Text(
                        'Status: ${order.status}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[600]),
                  onTap: () {
                    // Navigate to order details or add functionality
                  },
                ),
              );
            },
          );
        }
      },
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
      default:
        return Colors.grey;
    }
  }

  Widget _buildPaymentsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Payments to Zing'),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildPaymentsSection(widget.store.owner.id, widget.store.id!),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection(String userId, String storeId) {
    return FutureBuilder<List<Payment>>(
      future: Provider.of<StoreProvider>(context, listen: false)
          .fetchPaymentsForStoreByOwner(userId, storeId), // Fetch payments for the owner by store ID
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final payment = snapshot.data![index]; // Payment object
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                elevation: 8,
                child: ListTile(
                  leading: const Icon(Icons.payment, color: Colors.green),
                  title: Text('Payment ID: ${payment.paymentId}', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amount: ${payment.amount} ${payment.currency}', style: TextStyle(fontSize: 16)),
                      Text('Date: ${payment.paymentDate.toDate()}', style: TextStyle(fontSize: 14)),
                      Text('Status: ${payment.paymentStatus}', style: TextStyle(fontSize: 14, color: payment.paymentStatus == 'Paid' ? Colors.green : Colors.red)),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return const Text('No payments available.');
        }
      },
    );
  }

  Widget _buildStoreLocationCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Store Location'),
          SizedBox(
            height: 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(_store?.location.latitude ?? 0, _store?.location.longitude ?? 0),
                zoom: 14.0,
              ),
              markers: {
                Marker(
                  markerId: MarkerId(_store?.id ?? ''),
                  position: LatLng(_store?.location.latitude ?? 0, _store?.location.longitude ?? 0),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryMethodsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Available Delivery Methods'),
            const SizedBox(height: 10),
            if (_store?.deliveryOptions != null && _store!.deliveryOptions!.isNotEmpty)
              Column(
                children: _store!.deliveryOptions!.map((method) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping, color: Colors.blueGrey),
                        const SizedBox(width: 10),
                        Text(method, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  );
                }).toList(),
              )
            else
              const Text('No delivery methods available.'),
          ],
        ),
      ),
    );
  }

  Widget _buildYouTubePlayers() {
    if (_isLoadingVideos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_youtubeControllers.isEmpty) {
      return const Center(child: Text('No YouTube videos available', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)));
    }

    return Column(
      children: List.generate(_youtubeControllers.length, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              // When the thumbnail is tapped, the video loads
            });
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
            elevation: 8,
            child: Column(
              children: [
                _buildYouTubeThumbnail(index),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      label: const Text('Edit', style: TextStyle(color: Colors.blue)),
                      onPressed: () => _showEditVideoDialog(index),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                      onPressed: () => _deleteVideo(index),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildYouTubeThumbnail(int index) {
    final videoId = YoutubePlayer.convertUrlToId(_store?.videos?[index].url ?? '');
    final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Image.network(thumbnailUrl, fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Center(
            child: Icon(Icons.play_circle_filled, color: Colors.white.withOpacity(0.8), size: 50),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Georgia'),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        _showAddVideoDialog();
      },
      child: const Icon(Icons.add, size: 30),
      backgroundColor: Colors.purple.shade800,
      splashColor: Colors.white,
      elevation: 10,
      hoverElevation: 12,
    );
  }


  void _showAddVideoDialog() {
    final videoUrlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add YouTube Video'),
          content: TextField(
            controller: videoUrlController,
            decoration: const InputDecoration(hintText: 'Enter YouTube Video URL'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Provider.of<StoreProvider>(context, listen: false)
                    .addVideo(widget.store.id ?? '', videoUrlController.text);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditVideoDialog(int index) {
    final videoUrlController = TextEditingController(text: _store?.videos?[index].url);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit YouTube Video'),
          content: TextField(
            controller: videoUrlController,
            decoration: const InputDecoration(hintText: 'Edit YouTube Video URL'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Provider.of<StoreProvider>(context, listen: false)
                    .editVideo(widget.store.id ?? '', _store!.videos![index].id, videoUrlController.text);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteVideo(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Video'),
          content: const Text('Are you sure you want to delete this video?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Provider.of<StoreProvider>(context, listen: false)
                    .deleteVideo(widget.store.id ?? '', _store!.videos![index]);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

// Custom Clipper to add a curved AppBar
class CustomAppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
