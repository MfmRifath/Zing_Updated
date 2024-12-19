import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class SettingsProvider with ChangeNotifier {
  double? registrationAmount;
  String? currency;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fetchGlobalRegistrationAmount() async {
    try {
      DocumentSnapshot settingsDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('globalSettings')
          .get();

      if (settingsDoc.exists) {
        final data = settingsDoc.data() as Map<String, dynamic>?;
        registrationAmount = data?['registrationAmount']?.toDouble() ?? 0.0;
        currency = data?['currency'] ?? 'USD'; // Default to 'USD' if not set
        notifyListeners();
      } else {
        print("Global settings document does not exist.");
      }
    } catch (e) {
      print('Error fetching global registration amount: $e');
    }
  }

  // Allow admin to update the registration amount and currency
  Future<void> updateRegistrationAmount(double newAmount, String newCurrency) async {
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('globalSettings')
          .set({
        'registrationAmount': newAmount,
        'currency': newCurrency,
      }, SetOptions(merge: true)); // Merge to update only these fields

      registrationAmount = newAmount;
      currency = newCurrency;
      notifyListeners();
    } catch (e) {
      print('Error updating registration amount: $e');
    }
  }
  Future<double> getRegistrationAmount() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection('settings')
          .doc('registration')
          .get();

      if (doc.exists) {
        return doc.data()?['amount'] ?? 0.0;
      } else {
        throw Exception('Registration settings not found.');
      }
    } catch (e) {
      print('Error fetching registration amount: $e');
      throw e;
    }
  }

  // Method to get the current currency from Firestore
  Future<String> getCurrency() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection('settings')
          .doc('registration')
          .get();

      if (doc.exists) {
        return doc.data()?['currency'] ?? 'USD';
      } else {
        throw Exception('Currency settings not found.');
      }
    } catch (e) {
      print('Error fetching currency: $e');
      throw e;
    }
  }

  // Method to update the registration amount and currency in Firestore

}
