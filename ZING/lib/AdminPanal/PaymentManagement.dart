import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../Modal/CoustomUser.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  _PaymentManagementScreenState createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  late Future<List<Payment>> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _paymentsFuture = fetchAllPayments();
  }

  // Fetch all payments from Firestore
  Future<List<Payment>> fetchAllPayments() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collectionGroup('payments')
          .get();

      List<Payment> payments = snapshot.docs.map((doc) => Payment.fromMap(doc.data())).toList();
      return payments;
    } catch (e) {
      print('Error fetching payments: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment Management',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.blueGrey.shade900,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Payment>>(
        future: _paymentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: SpinKitFadingCircle(
              color: Colors.blueAccent,
              size: 60.0,
            ),);
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading payments', style: TextStyle(color: Colors.redAccent)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No payments found.'));
          }

          List<Payment> payments = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return _buildPaymentCard(payment);
            },
          );
        },
      ),
    );
  }

  // Build individual payment card with improved UI/UX
  Widget _buildPaymentCard(Payment payment) {
    return Card(
      elevation: 8,
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPaymentDetailRow(Icons.payment, 'Payment ID', payment.paymentId),
            Divider(thickness: 1, color: Colors.grey.shade300),
            _buildPaymentDetailRow(Icons.attach_money, 'Amount', '${payment.currency} ${payment.amount.toStringAsFixed(2)}', true),
            SizedBox(height: 8),
            _buildPaymentDetailRow(Icons.shopping_bag, 'Items', payment.items),
            SizedBox(height: 8),
            _buildPaymentDetailRow(Icons.info_outline, 'Status', payment.paymentStatus),
            SizedBox(height: 8),
            _buildPaymentDetailRow(Icons.calendar_today, 'Payment Date', payment.paymentDate.toDate().toString()),
          ],
        ),
      ),
    );
  }

  // Helper method to build a row for payment details with icons
  Widget _buildPaymentDetailRow(IconData icon, String label, String value, [bool isHighlighted = false]) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueGrey.shade800, size: 24),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blueGrey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isHighlighted ? 18 : 16,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? Colors.green.shade600 : Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
