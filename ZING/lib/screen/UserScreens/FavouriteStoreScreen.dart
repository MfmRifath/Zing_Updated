import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '../../Modal/CoustomUser.dart';
import '../../Service/CoustomUserProvider.dart';
import '../StoreScreen/StoreScreen.dart';

class FavouriteStoreScreen extends StatefulWidget {
  @override
  _FavouriteStoreScreenState createState() => _FavouriteStoreScreenState();
}

class _FavouriteStoreScreenState extends State<FavouriteStoreScreen> {
  Future<List<Store>>? _favoriteStoresFuture;
late CustomUser currentUser;
  @override
  void initState() {
    super.initState();
    _loadFavoriteStores();
  }

  void _loadFavoriteStores() {
    final customUserProvider = Provider.of<CustomUserProvider>(context, listen: false);
    currentUser = customUserProvider.user!;

    setState(() {
      _favoriteStoresFuture = _fetchFavoriteStores(currentUser.favorites!);
    });
    }

  Future<List<Store>> _fetchFavoriteStores(List<String> favoriteStoreIds) async {
    if (favoriteStoreIds.isEmpty) {
      return [];
    }

    List<Store> favoriteStores = [];

    for (String storeId in favoriteStoreIds) {
      DocumentSnapshot storeSnapshot = await FirebaseFirestore.instance.collection('stores').doc(storeId).get();
      if (storeSnapshot.exists) {
        Map<String, dynamic>? storeData = storeSnapshot.data() as Map<String, dynamic>?;
        if (storeData != null) {
          Store store = Store.fromMap(storeData);
          favoriteStores.add(store);
        }
      }
    }

    return favoriteStores;
  }

  void _navigateToStoreScreen(Store store, CustomUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreDetailScreen(store: store, user:user ,),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       // Light grey background color for a clean look
      body: FutureBuilder<List<Store>>(
        future: _favoriteStoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: SpinKitFadingCircle(
                      color: Colors.blue,
              size: 60.0,
            ),);
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading favorite stores', style: TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No favorite stores found.', style: TextStyle(fontSize: 18, color: Colors.grey)));
          } else {
            List<Store> favoriteStores = snapshot.data!;

            return ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              itemCount: favoriteStores.length,
              itemBuilder: (context, index) {
                Store store = favoriteStores[index];

                return GestureDetector(
                  onTap: () => _navigateToStoreScreen(store, currentUser),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: Offset(0, 6), // Soft shadow for elevation effect
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: [
                          // Store Image with rounded and elevated styling
                          Container(
                            margin: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                store.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.store, size: 80, color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          // Store Details
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    store.name,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    store.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
