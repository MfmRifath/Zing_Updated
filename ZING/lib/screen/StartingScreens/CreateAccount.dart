import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateAccountScreen extends StatefulWidget {
  @override
  _CreateAccountScreenState createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isPhoneSelected = false;
  String _selectedRole = 'User';
  bool isLoading = false;
  String verificationId = "";

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      if (isPhoneSelected) {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneController.text.trim(),
          verificationCompleted: (PhoneAuthCredential credential) async {
            final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
            await _saveUserToFirestore(userCredential.user!);
            _showSnackbar("Phone verification successful!");
          },
          verificationFailed: (FirebaseAuthException e) {
            _showSnackbar("Phone verification failed: ${e.message}");
          },
          codeSent: (String verificationId, int? resendToken) {
            this.verificationId = verificationId;
            _showOTPDialog();
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            this.verificationId = verificationId;
          },
        );
      } else {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        await _saveUserToFirestore(userCredential.user!);
        _showSnackbar("Account created successfully!");
      }
    } on FirebaseAuthException catch (e) {
      _showSnackbar("Error: ${e.message}");
    } catch (e) {
      _showSnackbar("Unexpected error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'phone': phoneController.text.trim(),
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _showSnackbar("User details saved to Firestore!");
    } catch (e) {
      _showSnackbar("Failed to save user details: $e");
    }
  }

  void _showOTPDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Enter OTP"),
        content: TextFormField(
          controller: otpController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "OTP",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final credential = PhoneAuthProvider.credential(
                  verificationId: verificationId,
                  smsCode: otpController.text.trim(),
                );
                final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
                await _saveUserToFirestore(userCredential.user!);
                _showSnackbar("Phone verification successful!");
                Navigator.of(context).pop();
              } catch (e) {
                _showSnackbar("Failed to verify OTP: $e");
              }
            },
            child: Text("Verify"),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget buildEmailFields() => Column(
    children: [
      TextFormField(
        controller: emailController,
        decoration: InputDecoration(
          labelText: "Email Address",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || !value.contains('@')) {
            return 'Enter a valid email';
          }
          return null;
        },
      ),
      SizedBox(height: 20),
      TextFormField(
        controller: passwordController,
        decoration: InputDecoration(
          labelText: "Password",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        obscureText: true,
        validator: (value) {
          if (value == null || value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
    ],
  );

  Widget buildPhoneField() => TextFormField(
    controller: phoneController,
    decoration: InputDecoration(
      labelText: "Phone Number",
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    keyboardType: TextInputType.phone,
    validator: (value) {
      if (value == null || value.isEmpty || value.length < 10) {
        return 'Enter a valid phone number';
      }
      return null;
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade300, Colors.blue.shade600],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 60),
                  Text(
                    "Welcome to Zing!",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Create your account to explore amazing features.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            onChanged: (String? newValue) {
                              setState(() => _selectedRole = newValue!);
                            },
                            items: [
                              DropdownMenuItem(value: 'User', child: Text("User")),
                              DropdownMenuItem(value: 'Owner', child: Text("Owner")),
                            ],
                            decoration: InputDecoration(
                              labelText: "Select Role",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                onPressed: () => setState(() => isPhoneSelected = false),
                                child: Text(
                                  "Use Email",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: !isPhoneSelected ? Colors.blue : Colors.grey,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(() => isPhoneSelected = true),
                                child: Text(
                                  "Use Phone",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isPhoneSelected ? Colors.blue : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          isPhoneSelected ? buildPhoneField() : buildEmailFields(),
                          SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: isLoading ? null : _createAccount,
                            child: isLoading
                                ? SpinKitFadingCircle(color: Colors.white, size: 20.0)
                                : Text("Create Account"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      "Already have an account? Log in",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: SpinKitFadingCircle(
                    color: Colors.white,
                    size: 50.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}