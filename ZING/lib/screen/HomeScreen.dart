import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:zing/AdminPanal/AdminPanalDashBoard.dart';
import 'package:zing/Cart/CartScreen.dart';
import 'package:zing/Modal/CoustomUser.dart';
import 'package:zing/Service/CoustomUserProvider.dart';
import 'package:zing/Service/StoreProvider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zing/screen/StoreManagement/storeManagementScreen.dart';
import 'package:zing/screen/StoreScreen/StoreScreen.dart';
import 'package:zing/screen/UserScreens/FavouriteStoreScreen.dart';
import 'package:zing/screen/UserScreens/UserProfile.dart';
import 'package:shimmer/shimmer.dart';

class HomePageScreen extends StatefulWidget {
  @override
  _HomePageScreenState createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _selectedCategory = null;
    _requestLocationPermission();
  }

  final List<String> categories = [
    'Electronics',
    'Clothing',
    'Food',
    'Sports',
    'Beauty',
    'Education',
    'Electrical',
    'Kids',
    'Mens',
    'Womens',
    'Phone',
  ];

  int _selectedIndex = 0;
  late PageController _pageController;
  String _searchQuery = '';
  Position? _currentPosition;
  String? _selectedCategory;

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      _getCurrentLocation();
    } else if (status.isDenied || status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);
    final userProvider = Provider.of<CustomUserProvider>(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        appBar: _buildAppBar(screenWidth, screenHeight, userProvider),
        drawer: _buildNavDrawer(screenHeight, screenWidth),
        body: OrientationBuilder(
          builder: (context, orientation) {
            return FutureBuilder<CustomUser?>(
              future: userProvider.fetchUserDetails(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error fetching user data: ${snapshot.error}'));
                }

                final user = snapshot.data;

                if (user == null) {
                  return Center(
                    child: Column(
                      children: [
                        Text('User not found'),
                        SpinKitFadingCircle(
                          color: Colors.blueAccent,
                          size: screenWidth * 0.2,
                        ),
                      ],
                    ),
                  );
                }

                return PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  physics: BouncingScrollPhysics(),
                  children: [
                    _wrapWithAnimation(
                      _buildHomePage(storeProvider, user, screenWidth, screenHeight, orientation),
                      animationType: AnimationType.fadeIn,
                    ),
                    _wrapWithAnimation(
                      FavouriteStoreScreen(),
                      animationType: AnimationType.bounceIn,
                    ),
                    _wrapWithAnimation(
                      CartScreen(userId: user.id),
                      animationType: AnimationType.slideInLeft,
                    ),
                    _wrapWithAnimation(
                      UserProfilePage(),
                      animationType: AnimationType.slideInRight,
                    ),
                    if (user.role == 'Owner' || user.role == "Admin")
                      _wrapWithAnimation(
                        StoreManagementWidget(),
                        animationType: AnimationType.zoomIn,
                      ),
                    if (user.role == 'Admin')
                      _wrapWithAnimation(
                        AdminPanelDashboard(),
                        animationType: AnimationType.slideInUp,
                      ),
                  ],
                );
              },
            );
          },
        ),
        bottomNavigationBar: _buildBottomNavigationBar(userProvider.user, screenWidth),
      ),
    );
  }

  Widget _buildHomePage(StoreProvider storeProvider, CustomUser user, double screenWidth, double screenHeight, Orientation orientation) {
    return storeProvider.isLoading
        ? _buildShimmerGrid(screenWidth, screenHeight)
        : _buildContentGrid(storeProvider, user, screenWidth, screenHeight, orientation);
  }

  Widget _buildShimmerGrid(double screenWidth, double screenHeight) {
    return GridView.builder(
      padding: EdgeInsets.all(screenWidth * 0.04),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: screenWidth * 0.04,
        mainAxisSpacing: screenHeight * 0.02,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentGrid(StoreProvider storeProvider, CustomUser user, double screenWidth, double screenHeight, Orientation orientation) {
    List<Store> filteredStores = storeProvider.stores.where((store) {
      return (_selectedCategory == null ||
          store.category == _selectedCategory) &&
          store.products.any((product) =>
              product.name.toLowerCase().contains(_searchQuery));
    }).toList();

    List<Store> nearbyStores = [];
    List<Store> otherStores = [];

    for (Store store in filteredStores) {
      double? distance = _calculateDistance(store.location.latitude, store.location.longitude);
      if (distance != null && distance <= 5) {
        nearbyStores.add(store);
      } else {
        otherStores.add(store);
      }
    }

    otherStores.sort((a, b) {
      double? distanceA = _calculateDistance(a.location.latitude, a.location.longitude);
      double? distanceB = _calculateDistance(b.location.latitude, b.location.longitude);

      if (distanceA == null || distanceB == null) return 0;
      return distanceA.compareTo(distanceB);
    });

    return ListView(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
      children: [
        _buildCategorySelector(screenWidth, screenHeight, orientation),
        if (nearbyStores.isNotEmpty)
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Text(
              'Nearby Stores',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045),
            ),
          ),
        if (nearbyStores.isNotEmpty) _buildStoreGrid(nearbyStores, user, screenWidth, screenHeight, orientation),
        if (otherStores.isNotEmpty)
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Text(
              'Other Stores (sorted by distance)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045),
            ),
          ),
        if (otherStores.isNotEmpty) _buildStoreGrid(otherStores, user, screenWidth, screenHeight, orientation),
      ],
    );
  }
  Widget _buildCategorySelector(double screenWidth, double screenHeight, Orientation orientation) {
    final isPortrait = orientation == Orientation.portrait;

    return SizedBox(
      height: isPortrait ? screenHeight * 0.15 : screenHeight * 0.25,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == categories[index];

          return FadeInLeft(
            delay: Duration(milliseconds: 100 * index),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedCategory = null;
                  } else {
                    _selectedCategory = categories[index];
                  }
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),  // Adjust border radius as needed
                      child: Container(
                        width: screenWidth * 0.16,
                        height: screenWidth * 0.16,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                                'assets/images/${categories[index].toLowerCase()}.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      categories[index],
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: screenWidth * 0.04,
                        color: isSelected ? Colors.blueAccent : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  double? _calculateDistance(double storeLat, double storeLng) {
    if (_currentPosition == null) {
      print('User location is not available');
      return null;
    }
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      storeLat,
      storeLng,
    ) / 1000;
  }

  Widget _buildStoreGrid(
      List<Store> stores,
      CustomUser user,
      double screenWidth,
      double screenHeight,
      Orientation orientation) {
    final customUserProvider = Provider.of<CustomUserProvider>(context, listen: false);
    final isPortrait = orientation == Orientation.portrait;

    return Container(
      height: isPortrait ? screenHeight * 0.35 : screenHeight * 0.6,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stores.length,
        itemBuilder: (context, index) {
          final store = stores[index];
          final distance = _calculateDistance(store.location.latitude, store.location.longitude);
          final isFavorite = customUserProvider.isFavoriteStore(store.id!);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoreDetailScreen(store: store, user: user),
                ),
              );
            },
            child: FadeIn(
              delay: Duration(milliseconds: 100 * index), // Staggered fade-in for grid items
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: screenWidth * 0.45,
                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 3,
                      offset: Offset(0, 5),
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  image: DecorationImage(
                    image: NetworkImage(store.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: screenHeight * 0.02,
                      right: screenWidth * 0.02,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isFavorite) {
                              customUserProvider.removeFavoriteStore(store.id!);
                            } else {
                              customUserProvider.addFavoriteStore(store.id!);
                            }
                          });
                        },
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(child: child, scale: animation);
                          },
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.white,
                            size: screenWidth * 0.07,
                            key: ValueKey(isFavorite),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.name,
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.yellow, size: screenWidth * 0.04),
                                SizedBox(width: screenWidth * 0.01),
                                FutureBuilder<double>(
                                  future: store.getAverageRating(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return Text('Error', style: TextStyle(color: Colors.white));
                                    }
                                    return Text(
                                      snapshot.data?.toStringAsFixed(1) ?? '0.0',
                                      style: TextStyle(color: Colors.white),
                                    );
                                  },
                                ),
                                Spacer(),
                                Text(
                                  distance != null ? '${distance.toStringAsFixed(2)} km' : 'N/A',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              store.category,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: screenWidth * 0.03,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildBottomNavigationBar(CustomUser? user, double screenWidth) {
    List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(
        icon: Icon(
          Icons.home,
          color: _selectedIndex == 0 ? Colors.blueAccent : Colors.grey.shade600,
        ),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          Icons.favorite,
          color: _selectedIndex == 1 ? Colors.blueAccent : Colors.grey.shade600,
        ),
        label: 'Favourites',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          Icons.add_shopping_cart,
          color: _selectedIndex == 2 ? Colors.blueAccent : Colors.grey.shade600,
        ),
        label: 'Cart',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          Icons.person,
          color: _selectedIndex == 3 ? Colors.blueAccent : Colors.grey.shade600,
        ),
        label: 'User',
      ),
    ];

    if (user?.role == 'Owner' || user?.role == "Admin") {
      items.add(BottomNavigationBarItem(
        icon: Icon(
          Icons.store,
          color: _selectedIndex == 4 ? Colors.blueAccent : Colors.grey.shade600,
        ),
        label: 'Owner',
      ));
    }

    if (user?.role == 'Admin') {
      items.add(BottomNavigationBarItem(
        icon: Icon(
          Icons.admin_panel_settings,
          color: _selectedIndex == 5 ? Colors.blueAccent : Colors.grey.shade600,
        ),
        label: 'Admin',
      ));
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            spreadRadius: 3,
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey.shade600,
          selectedIconTheme: IconThemeData(
            size: screenWidth * 0.09,
            color: Colors.blueAccent,
          ),
          unselectedIconTheme: IconThemeData(
            size: screenWidth * 0.08,
            color: Colors.grey.shade600,
          ),
          selectedLabelStyle: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
            fontFamily: 'Georgia',
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: screenWidth * 0.03,
            fontFamily: 'Georgia',
          ),
          items: items,
        ),
      ),
    );
  }
  AppBar _buildAppBar(double screenWidth, double screenHeight, CustomUserProvider userProvider) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.indigoAccent.shade100,
              Colors.indigoAccent.shade700,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu, color: Colors.white, size: screenWidth * 0.07),
          onPressed: () {
            Scaffold.of(context).openDrawer(); // Opens the navigation drawer
          },
          splashRadius: screenWidth * 0.06 > 0 ? screenWidth * 0.06 : null, // Ensure splashRadius is valid
          tooltip: 'Menu',
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: screenHeight * 0.05,
            child: Image.asset('assets/images/zing.png'),
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Z I N G",
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black45,
                      offset: Offset(1, 2),
                    ),
                  ],
                ),
              ),
              Text(
                "MARKETING MASTERY",
                style: TextStyle(
                  fontSize: screenWidth * 0.02,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: GestureDetector(
              onTap: () {
                // Add any action here, such as opening the profile page
              },
              child: IconButton(
                onPressed: ()async {
                  await Provider.of<CustomUserProvider>(context, listen: false).signOut();
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                icon: Row(
                  children: [
                    Icon(Icons.logout), // Wrap the icon in Icon widget
                  ],
                ),
              )
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.08),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.02),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for products...',
                hintStyle: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.grey[600],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.indigoAccent,
                  size: screenWidth * 0.06,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
              ),
              cursorColor: Colors.indigoAccent,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavDrawer(double screenHeight, double screenWidth) {
    return Drawer(
      child: Column(
        children: <Widget>[
          Container(
            height: screenHeight * 0.3,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/zing.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.6), Colors.black.withOpacity(0.3)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 16,
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'ZING',
                            style: TextStyle(
                              fontSize: screenWidth * 0.07,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'Marketing Mastery',
                            style: TextStyle(
                              fontSize: screenWidth * 0.05,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '123 Business St, City',
                            style: TextStyle(
                              fontSize: screenWidth * 0.03,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildListTile(
                  icon: Icons.business,
                  title: 'Founder: John Doe',
                  iconColor: Colors.blueAccent,
                  screenWidth: screenWidth,
                ),
                _buildListTile(
                  icon: Icons.phone,
                  title: 'Phone: +123 456 7890',
                  iconColor: Colors.green,
                  screenWidth: screenWidth,
                ),
                _buildListTile(
                  icon: Icons.email,
                  title: 'Email: info@zingmarketing.com',
                  iconColor: Colors.redAccent,
                  screenWidth: screenWidth,
                ),
                _buildListTile(
                  icon: Icons.language,
                  title: 'Website: www.zingmarketingmastery.com',
                  iconColor: Colors.purpleAccent,
                  screenWidth: screenWidth,
                ),
                Divider(
                  color: Colors.grey.shade400,
                  thickness: 1,
                  indent: screenWidth * 0.05,
                  endIndent: screenWidth * 0.05,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: screenWidth * 0.03,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildListTile({
    required IconData icon,
    required String title,
    required Color iconColor,
    required double screenWidth,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [iconColor.withOpacity(0.8), iconColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: screenWidth * 0.06,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
      onTap: () {
        // Add navigation or actions here
      },
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: screenWidth * 0.04),
      tileColor: Colors.grey.shade100.withOpacity(0.5),
      hoverColor: Colors.grey.shade200.withOpacity(0.7),
      contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenWidth * 0.03),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
  Widget _wrapWithAnimation(Widget child, {required AnimationType animationType}) {
    switch (animationType) {
      case AnimationType.fadeIn:
        return FadeIn(child: child, duration: Duration(milliseconds: 500));
      case AnimationType.bounceIn:
        return Bounce(child: child, duration: Duration(milliseconds: 500));
      case AnimationType.slideInLeft:
        return SlideInLeft(child: child, duration: Duration(milliseconds: 500));
      case AnimationType.slideInRight:
        return SlideInRight(child: child, duration: Duration(milliseconds: 500));
      case AnimationType.slideInUp:
        return SlideInUp(child: child, duration: Duration(milliseconds: 500));
      case AnimationType.zoomIn:
        return ZoomIn(child: child, duration: Duration(milliseconds: 500));
      default:
        return child;
    }
  }
}
enum AnimationType {
  fadeIn,
  bounceIn,
  slideInLeft,
  slideInRight,
  slideInUp,
  zoomIn,
}