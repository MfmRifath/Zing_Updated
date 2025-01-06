import 'package:cloud_firestore/cloud_firestore.dart';

class CustomUser {
  String id; // Firebase Authentication UID
  String name;
  String email;
  String phoneNumber;
  String address;
  String profileImageUrl;
  String role;
  bool? hasPaid; // Add this field to track payment status
  Store? store; // Optional Store property for users with the role 'Owner'
  List<String>? favorites;
  List<Payment>? payments; // Add payments field

  CustomUser({
    this.hasPaid,
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.address = '',
    this.profileImageUrl = '',
    this.role ='User',
    this.store,
    this.favorites = const [],
    this.payments = const [], // Initialize an empty list of payments
  });
// Add a favorite store
  void addFavorite(String storeId) {
    if (!favorites!.contains(storeId)) {
      favorites!.add(storeId);
    }
  }

  // Remove a favorite store
  void removeFavorite(String storeId) {
    favorites!.remove(storeId);
  }
  Future<List<Payment>> fetchPayments() async {
    try {
      // Query the 'payments' subcollection for this user
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .collection('payments')
          .get();

      // Parse the payments using fromMap
      payments = snapshot.docs.map((doc) => Payment.fromMap(doc.data())).toList();

      return payments!;
    } catch (e) {
      print('Error fetching payments: $e');
      return [];
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'hasPaid': hasPaid ?? false,
      'phoneNumber': phoneNumber,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'role': role,
      'store': store?.toMap(),
      'favorites': favorites ?? [],
      'payments': payments?.map((payment) => payment.toMap()).toList() ?? [],
    };
  }

  factory CustomUser.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CustomUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      role: data['role'] ?? 'User',
      hasPaid: data['hasPaid'] ?? false,
      store: data['store'] != null ? Store.fromMap(data['store']) : null,
      favorites: List<String>.from(data['favorites'] ?? []),
      payments: (data['payments'] as List<dynamic>?)
          ?.map((payment) => Payment.fromMap(payment))
          .toList() ??
          [],
    );
  }
  factory CustomUser.fromMap(Map<String, dynamic> data) {
    return CustomUser(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      role: data['role'] ?? 'User',
      hasPaid: data['hasPaid'] ?? false,
      store: data['store'] != null ? Store.fromMap(data['store']) : null,
      favorites: List<String>.from(data['favorites'] ?? []),
      payments: (data['payments'] as List<dynamic>?)
          ?.map((payment) => Payment.fromMap(payment))
          .toList() ??
          [],
    );
  }
}

class Store {
  String? id; // Store unique ID
  double? registrationsAmount;
  final String name; // Store name
  final String description; // Store description
  List<Rating> ratings; // Store rating (now it's a list of `Rating` objects)
  final String category; // Store category (e.g., Asian, Burgers)
  final String imageUrl; // Store image URL
  final List<Product> products;
  final List<Order>? orders; // List of store orders
  final Owner owner; // Store owner's details
  final GeoPoint location; // GeoPoint to store latitude and longitude
  final bool isFavourite;
  final String phoneNumber;
  List<YouTubeVideo>? videos; // Favourite status
  List<String>? deliveryOptions; // New field for delivery options
  double? deliveryCost; // New field for delivery cost (for Store Delivery)


  Store({
    required this.phoneNumber,
    this.id,
    this.registrationsAmount,
    required this.name,
    required this.description,
    this.ratings = const [],
    required this.category,
    required this.imageUrl,
    required this.products,
    required this.owner,
    required this.location,
    this.isFavourite = false,
    this.orders,
    this.videos = const [],
    this.deliveryOptions = const [], // Default to 'Store Pickup'
    this.deliveryCost, // Optional delivery cost
  });
// Add this function in your Store model
  Future<double> getAverageRating() async {
    try {
      QuerySnapshot ratingsSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(this.id)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isNotEmpty) {
        double total = 0;
        int count = ratingsSnapshot.docs.length;

        for (var doc in ratingsSnapshot.docs) {
          total += (doc['rating'] ?? 0.0) as double;
        }

        return total / count;
      } else {
        return 0.0; // No ratings yet
      }
    } catch (e) {
      print('Error fetching ratings: $e');
      return 0.0;
    }
  }


  // Submit rating method
  // Add this function in your Store model
  Future<void> submitRating(String userId, double rating) async {
    try {
      // Assuming you have a 'ratings' subcollection in your store's document
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(this.id)
          .collection('ratings')
          .doc(userId) // Each user can only rate once
          .set({
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Rating submitted successfully');
    } catch (e) {
      print('Error submitting rating: $e');
    }
  }


  // Check if the user has already rated
  bool userHasRated(String userId) {
    return ratings.any((rating) => rating.userId == userId);
  }
  // Convert Store object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'registrationAmount': registrationsAmount,
      'phoneNumber': phoneNumber,
      'name': name,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'products': products.map((product) => product.toMap()).toList(),
      'owner': owner.toMap(),
      'location': location,
      'isFavourite': isFavourite,
      'videos': videos?.map((video) => video.toMap()).toList(),
      'deliveryOptions': deliveryOptions,
      'deliveryCost': deliveryCost,
    };
  }


  // Create a Store object from a DocumentSnapshot
  static Store fromMap(Map<String, dynamic> data) {
    return Store(
      id: data['id'],
      phoneNumber: data['phoneNumber'] ?? '',
      name: data['name'] ?? '',
      registrationsAmount: data['registrationAmount'],
      description: data['description'] ?? '',
      ratings: (data['ratings'] as List<dynamic>?)
          ?.map((ratingMap) => Rating.fromMap(ratingMap))
          .toList() ??
          [],
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      products: (data['products'] as List<dynamic>?)
          ?.map((productMap) => Product.fromMap(productMap))
          .toList() ??
          [],
      owner: Owner.fromMap(data['owner']),
      location: data['location'],
      isFavourite: data['isFavourite'] ?? false,
      videos: (data['videos'] as List<dynamic>?)
          ?.map((videoMap) => YouTubeVideo.fromMap(videoMap))
          .toList() ??
          [],
      deliveryOptions:(data['deliveryOptions'] as List<dynamic>).map((item) => item as String).toList(),
      deliveryCost: data['deliveryCost']?.toDouble(),
    );
  }
}

class Payment {
  late final String paymentId;
  final String storeId;
  final double amount;
  final String currency;
  final String items;
  late final String paymentStatus;
  final Timestamp paymentDate;

  Payment({
    required this.storeId,
    required this.paymentId,
    required this.amount,
    required this.currency,
    required this.items,
    required this.paymentStatus,
    required this.paymentDate,
  });

  // Create Payment from DocumentSnapshot
  static Payment fromMap(Map<String, dynamic> data)  {
    return Payment(
      paymentId: data['paymentId'],
      amount: data['amount'].toDouble(),
      currency: data['currency'],
      items: data['items'],
      paymentStatus: data['paymentStatus'],
      paymentDate: data['paymentDate'],
      storeId: data['storeId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'amount': amount,
      'currency': currency,
      'items': items,
      'paymentStatus': paymentStatus,
      'paymentDate': paymentDate,
      'storeId':storeId,
    };
  }
}

class Product {
  String id = ''; // Product ID
  final String name; // Product name
  final String? description; // Product description
  final double price; // Product price
  final double? rating; // Product rating
  final String? imageUrl; // Product image URL
  final bool isAvailable; // Availability status
  final double? discount; // Discount percentage (nullable)

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.rating,
    this.imageUrl,
    this.isAvailable = true, // Default availability
    this.discount, // Optional field, default is null
  });

  // Convert Product object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'rating': rating,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'discount': discount,
    };
  }

  // Create a Product object from a map
  static Product fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      rating: map['rating']?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      discount: map['discount']?.toDouble(),
    );
  }

}

class Owner {
  final String id; // Owner ID
  final String name; // Owner name
  final String email; // Owner email
  final String phone; // Owner phone
  final String profileImageUrl; // Owner profile picture

  Owner({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImageUrl,
  });

  // Convert Owner object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
    };
  }

  // Create an Owner object from a map
  static Owner fromMap(Map<String, dynamic> map) {
    return Owner(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
    );
  }
}

class Rating {
  final String userId;
  final double score;

  Rating({required this.userId, required this.score});

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'score': score,
    };
  }

  static Rating fromMap(Map<String, dynamic> map) {
    return Rating(
      userId: map['userId'] ?? '',
      score: map['score']?.toDouble() ?? 0.0,
    );
  }
}

class Orders {
  String id; // Order ID
  String userId;
  String storeId; // The user who placed the order
  List<Product> products; // List of products in the order
  double totalPrice; // Total price of the order
  String status; // Order status (e.g., Pending, Processed, Shipped, Delivered)
  Timestamp placedAt;
  String deliveryMethod;
  CustomUser? userDetails;
  Store? storeDetails;// The timestamp when the order was placed

  Orders({
    this.id = '', // Empty ID initially, Firestore will generate this
    required this.userId,
    required this.storeId,
    required this.products,
    required this.totalPrice,
    this.status = 'Pending', // Default status
    required this.placedAt,
    required this.deliveryMethod,
    this.userDetails,
    this.storeDetails
  });

  // Convert Order object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'storeId': storeId,
      'products': products.map((product) => product.toMap()).toList(),
      'totalPrice': totalPrice,
      'status': status,
      'placedAt': placedAt,
      'deliveryMethod':deliveryMethod,
      'userDetails':userDetails,

    };
  }

  // Create an Order object from a DocumentSnapshot
  // Create an Order object from a DocumentSnapshot
  factory Orders.fromDocument(DocumentSnapshot<Object?> doc) {
    if (doc.data() == null) {
      throw Exception("Document data is null for doc ID: ${doc.id}");
    }

    final data = doc.data() as Map<String, dynamic>;

    return Orders(
      id: doc.id,
      userId: data['userId'] ?? '',
      storeId: data['storeId'] ?? '',
      products: (data['products'] as List<dynamic>? ?? [])
          .map((productMap) => Product.fromMap(productMap))
          .toList(),
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'Pending',
      placedAt: data['placedAt'] is Timestamp
          ? data['placedAt'] as Timestamp
          : Timestamp.now(), // Default to current timestamp if missing
      deliveryMethod: data['deliveryMethod'] ?? 'Unknown',
      userDetails: data['userDetails'] != null
          ? CustomUser.fromMap(data['userDetails'] as Map<String, dynamic>)
          : null,
      storeDetails: data['storeDetails'] != null
          ? Store.fromMap(data['storeDetails'] as Map<String, dynamic>)
          : null,
    );
  }

  // Update order status
  Future<void> updateStatus(String storeId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('orders')
          .doc(id)
          .update({'status': newStatus});
    } catch (e) {
      print("Error updating order status: $e");
    }
  }
}
class YouTubeVideo {
  String id;
  String url; // The YouTube URL

  YouTubeVideo({required this.id, required this.url});

  // Convert the YouTubeVideo object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
    };
  }

  // Create a YouTubeVideo object from a map
  static YouTubeVideo fromMap(Map<String, dynamic> map) {
    return YouTubeVideo(
      id: map['id'] ?? '',
      url: map['url'] ?? '',
    );
  }
}
