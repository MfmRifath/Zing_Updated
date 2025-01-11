import 'package:flutter/material.dart';
import '../../Modal/CoustomUser.dart';


Widget buildRenewScreen(BuildContext context, CustomUser currentUser) {

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
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Renew Access - Payment Details'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Please make a payment to the following bank account:',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Bank Name:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Text('BOC BANK'),
                      ],
                    ),
                    Row(
                      children: [
                        Text('Account Name:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Text('M.Z.M SHAHIL'),
                      ],
                    ),
                    Row(
                      children: [
                        Text('Account Number:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Text('93597815'),
                      ],
                    ),
                    Row(
                      children: [
                        Text('Branch:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Text('Kolonnawa branch'),
                      ],
                    ),
                    SizedBox(height: 15),
                    Text(
                      'After payment, please contact us with the payment receipt to renew your access.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Close'),
                  ),
                ],
              );
            },
          );
        },
    )
      ],
    ),
  );
}