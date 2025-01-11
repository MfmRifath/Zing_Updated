import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class Advertisement {
  final String imageUrl;
  final String description;

  Advertisement({required this.imageUrl, required this.description});

  factory Advertisement.fromFDocument(DocumentSnapshot doc) {
    return Advertisement(
      imageUrl: doc['imageUrl'] ?? '',
      description: doc['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'description': description,
    };
  }
}

class AdvertisementProvider with ChangeNotifier {
  List<Advertisement> _advertisements = [];

  List<Advertisement> get advertisements => _advertisements;

  bool isLoading = false;
  String errorMessage = '';

  Future<void> fetchAdvertisements() async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('advertisements').get();
      _advertisements = snapshot.docs.map((doc) => Advertisement.fromFDocument(doc)).toList();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print("Error fetching advertisements: $e");
      isLoading = false;
      errorMessage = "Failed to load advertisements";
      notifyListeners();
    }
  }




  Future<void> addAdvertisement(String description, File imageFile) async {
    try {
      String fileName = 'advertisements/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload image to Firebase Storage
      TaskSnapshot snapshot = await FirebaseStorage.instance.ref(fileName).putFile(imageFile);
      String imageUrl = await snapshot.ref.getDownloadURL();

      // Save to Firestore
      Advertisement advertisement = Advertisement(imageUrl: imageUrl, description: description);
      await FirebaseFirestore.instance.collection('advertisements').add(advertisement.toMap());

      // Update local list
      _advertisements.add(advertisement);
      notifyListeners();
    } catch (e) {
      print("Error adding advertisement: $e");
    }
  }


  Future<void> deleteAdvertisement(String id) async {
    try {
      await FirebaseFirestore.instance.collection('advertisements').doc(id).delete();
      _advertisements.removeWhere((ad) => ad.imageUrl == id);
      notifyListeners();
    } catch (e) {
      print("Error deleting advertisement: $e");
    }
  }

}
