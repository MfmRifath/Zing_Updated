import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../Service/CoustomUserProvider.dart';

class AddAdminScreen extends StatefulWidget {
  @override
  _AddAdminScreenState createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends State<AddAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  String _phoneNumber = '';

  @override
  Widget build(BuildContext context) {
    final customUserProvider = Provider.of<CustomUserProvider>(context);
    bool isLoading = customUserProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Admin', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                children: [
                  _buildTextField(
                    label: 'Name',
                    onChanged: (value) => setState(() => _name = value),
                    validator: (value) => value!.isEmpty ? 'Enter a name' : null,
                    icon: Icons.person,
                  ),
                  _buildTextField(
                    label: 'Email',
                    onChanged: (value) => setState(() => _email = value),
                    validator: (value) => value!.isEmpty ? 'Enter an email' : null,
                    icon: Icons.email,
                  ),
                  _buildTextField(
                    label: 'Password',
                    onChanged: (value) => setState(() => _password = value),
                    validator: (value) => value!.isEmpty ? 'Enter a password' : null,
                    icon: Icons.lock,
                    obscureText: true,
                  ),
                  _buildTextField(
                    label: 'Phone Number',
                    onChanged: (value) => setState(() => _phoneNumber = value),
                    validator: (value) => value!.isEmpty ? 'Enter a phone number' : null,
                    icon: Icons.phone,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        customUserProvider.addAdmin(
                          email: _email,
                          password: _password,
                          name: _name,
                          phoneNumber: _phoneNumber,
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      child: Text(
                        'Add Admin',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6,
                    ),
                  ),
                  SizedBox(height: 20),
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
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required ValueChanged<String> onChanged,
    required String? Function(String?)? validator,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,

          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        ),
        obscureText: obscureText,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}