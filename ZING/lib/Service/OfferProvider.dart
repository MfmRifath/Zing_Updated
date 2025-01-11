import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class Offer {
  final String id;
  late final String text;
  final String imageUrl;

  Offer({
    required this.id,
    required this.text,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'imageUrl': imageUrl, 'text': text};
  }
  // From Firestore document data
  factory Offer.fromDocument(Map<String, dynamic> docData) {
    return Offer(
      id: docData['id'] ?? '', // Provide a default empty string if 'id' is null
      text: docData['text'] ?? '', // Provide a default empty string if 'text' is null
      imageUrl: docData['imageUrl'] ?? '', // Provide a default empty string if 'imageUrl' is null
    );
  }
}

class OfferProvider with ChangeNotifier {
  List<Offer> _offers = [];
  bool isLoading = false;

  List<Offer> get offers => _offers;

  Future<void> fetchOffers() async {
    try {
      isLoading = true;
      notifyListeners(); // Notify listeners about loading state

      // Fetch offers from Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('offers').get();

      if (snapshot.docs.isNotEmpty) {
        print('Fetched offers: ${snapshot.docs.length}');
        _offers = snapshot.docs
            .map((doc) => Offer.fromDocument(doc.data() as Map<String, dynamic>))
            .toList();
      } else {
        print("No offers found");
        _offers = [];  // Ensure an empty list if no offers are found
      }
    } catch (e, stackTrace) {
      print("Error fetching offers: $e");
      print("StackTrace: $stackTrace");
      _offers = []; // Optional: Set empty list in case of error
    } finally {
      isLoading = false;
      notifyListeners(); // Notify listeners about loading completion
    }
  }





  Future<void> addOffer(String text, File? imageFile) async {
    try {
      String id = FirebaseFirestore.instance.collection('offers').doc().id;
      String imageUrl = '';

      // Upload image to Firebase Storage if an image file is provided
      if (imageFile != null) {
        String fileName = 'offers/$id.jpg';
        TaskSnapshot snapshot = await FirebaseStorage.instance.ref(fileName).putFile(imageFile);
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      // Create a new Offer object
      Offer newOffer = Offer(id: id, imageUrl: imageUrl, text: text);

      // Save to Firestore
      await FirebaseFirestore.instance.collection('offers').doc(id).set(newOffer.toMap());

      // Add to local list
      _offers.add(newOffer);
      notifyListeners();
    } catch (e) {
      print("Error adding offer: $e");
    }
  }

  Future<void> updateOffer(Offer offer) async {
    try {
      await FirebaseFirestore.instance.collection('offers').doc(offer.id).update(offer.toMap());
      int index = _offers.indexWhere((o) => o.id == offer.id);
      if (index != -1) {
        _offers[index] = offer;
        notifyListeners();
      }
    } catch (e) {
      print("Error updating offer: $e");
    }
  }


  Future<void> deleteOffer(String id) async {
    try {
      await FirebaseFirestore.instance.collection('offers').doc(id).delete();
      _offers.removeWhere((offer) => offer.id == id);
      notifyListeners();
    } catch (e) {
      print("Error deleting offer: $e");
    }
  }

}
