import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../Service/SettingProvider.dart';

class AdminUpdateRegistrationAmountScreen extends StatefulWidget {
  @override
  _AdminUpdateRegistrationAmountScreenState createState() =>
      _AdminUpdateRegistrationAmountScreenState();
}

class _AdminUpdateRegistrationAmountScreenState
    extends State<AdminUpdateRegistrationAmountScreen> {
  final _amountController = TextEditingController();
  final _currencyController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final settingsProvider =
    Provider.of<SettingsProvider>(context, listen: false);
    setState(() {
      isLoading = true;
    });

    try {
      final currentAmount = await settingsProvider.getRegistrationAmount();
      final currentCurrency = await settingsProvider.getCurrency();

      setState(() {
        _amountController.text = currentAmount.toString();
        _currencyController.text = currentCurrency;
      });
    } catch (e) {
      _showSnackBar(context, 'Error loading current settings');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Update Registration Amount',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  label: 'Registration Amount',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  hintText: 'Enter amount (e.g., 50.00)',
                ),
                SizedBox(height: 16),
                _buildTextField(
                  label: 'Currency',
                  controller: _currencyController,
                  hintText: 'Enter currency (e.g., USD)',
                ),
                SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_amountController.text.isEmpty ||
                          _currencyController.text.isEmpty) {
                        _showSnackBar(context, 'Please fill out all fields.');
                        return;
                      }
                      final newAmount = double.parse(_amountController.text);
                      final newCurrency = _currencyController.text;
                      _updateRegistrationAmount(
                          settingsProvider, newAmount, newCurrency);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 12),
                      child: Text(
                        'Update Amount',
                        style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.blueAccent,
                      elevation: 6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Center(
              child: SpinKitFadingCircle(
                color: Colors.blueAccent,
                size: 60.0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _updateRegistrationAmount(
      SettingsProvider settingsProvider, double newAmount, String newCurrency) async {
    setState(() {
      isLoading = true;
    });

    await settingsProvider.updateRegistrationAmount(newAmount, newCurrency);

    setState(() {
      isLoading = false;
    });

    _showSnackBar(context, 'Registration amount updated successfully!');
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
