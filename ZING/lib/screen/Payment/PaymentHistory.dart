import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';


import '../../Modal/CoustomUser.dart';
import '../../Service/CoustomUserProvider.dart';

class PaymentHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final customUserProvider = Provider.of<CustomUserProvider>(context);
    final currentUser = customUserProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment History'),
      ),
      body: FutureBuilder<List<Payment>>(
        future: currentUser!.fetchPayments(), // This now returns Future<List<Payment>>
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: SpinKitFadingCircle(
              color: Colors.blueAccent,
              size: 60.0,
            ),);
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No payments found.'));
          }

          final payments = snapshot.data!;

          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return ListTile(
                title: Text('Payment ID: ${payment.paymentId}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount: \$${payment.amount.toStringAsFixed(2)} ${payment.currency}'),
                    Text('Items: ${payment.items}'),
                    Text('Status: ${payment.paymentStatus}'),
                    Text('Date: ${payment.paymentDate.toDate()}'),
                  ],
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
