import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import 'package:provider/provider.dart';

import '../../Modal/CoustomUser.dart';
import '../../Service/CoustomUserProvider.dart';
import '../../Service/SettingProvider.dart';
import '../../Service/StoreProvider.dart';


void makePayment(
    BuildContext context,
    Store store,
    CustomUser user,
    StoreProvider storeProvider,
    CustomUserProvider userProvider, {
      required VoidCallback onPaymentSuccess,
    }) async {
  final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

  // Ensure the registration amount is fetched
  await settingsProvider.fetchGlobalRegistrationAmount();

  if (settingsProvider.registrationAmount == null || settingsProvider.currency == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: Registration amount or currency is not set.')),
    );
    return;
  }

  var paymentObject = {
    "sandbox": true,
    "merchant_id": "1228930",
    "merchant_secret": "Mjk3Njc0NDcwNTI1NDY1MDE4ODkxMTQ0NjI4NTMzMzE5Nzg0MzU1MQ==",
    "notify_url": "http://sample.com/notify",
    "order_id": "ItemNo12345",
    "items": "Store Management Access",
    "amount": settingsProvider.registrationAmount!.toString(),
    "currency": settingsProvider.currency,
    "first_name": user.name,
    "last_name": "",
    "email": user.email,
    "phone": user.phoneNumber,
    "address": "No.1, Galle Road",
    "city": "Colombo",
    "country": "Sri Lanka"
  };

  PayHere.startPayment(paymentObject, (paymentId) async {
    print("Payment Success. Payment Id: $paymentId");

    final paymentData = {
      "paymentId": paymentId,
      "amount": settingsProvider.registrationAmount!,
      "currency": settingsProvider.currency!,
      "items": 'Store Management Access',
      "paymentStatus": 'Completed',
      "paymentDate": Timestamp.now(),
      "storeId": store.id
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .collection('payments')
        .add(paymentData);

    // Invoke success callback to refresh UI
    onPaymentSuccess();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment successful. Store access renewed!')),
    );
  }, (error) {
    print("Payment Failed. Error: $error");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed, store not added')),
    );
  }, () {
    print("Payment Dismissed");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment dismissed')),
    );
  });
}

Widget buildRenewScreen(BuildContext context, CustomUser currentUser) {
  final storeProvider = Provider.of<StoreProvider>(context, listen: false);
  final customUserProvider = Provider.of<CustomUserProvider>(context, listen: false);

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Your access has expired.',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
    ElevatedButton.icon(
      icon: Icon(Icons.refresh),
      label: Text('Renew Access'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4.0,
      ),
      onPressed: () {
        makePayment(
          context,
          currentUser.store!,
          currentUser,
          storeProvider,
          customUserProvider,
          onPaymentSuccess: () {
            storeProvider.fetchStores();
            customUserProvider.refreshUserData();
          },
        );
      },
    )
      ],
    ),
  );
}