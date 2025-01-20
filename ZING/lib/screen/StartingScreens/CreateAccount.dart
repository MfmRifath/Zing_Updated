import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../Service/ThameProvider.dart';

class CreateAccountScreen extends StatefulWidget {
  @override
  _CreateAccountScreenState createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool isSendingCode = false;
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
        final enteredNumber = phoneController.text.trim();

        // Validate and prepend the +94 prefix
        if (enteredNumber.isEmpty || !RegExp(r'^[1-9][0-9]{8}$').hasMatch(enteredNumber)) {
          _showSnackbar('Invalid phone number. Enter 9 digits after +94.');
          setState(() => isLoading = false);
          return;
        }

        final formattedNumber = '+94$enteredNumber';
        print('Formatted Phone Number: $formattedNumber');

        setState(() => isSendingCode = true); // Show loader while sending the code

        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: formattedNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
            await _saveUserToFirestore(userCredential.user!);
            _showSnackbar("Phone verification successful!");
          },
          verificationFailed: (FirebaseAuthException e) {
            _showSnackbar("Phone verification failed: ${e.message}");
          },
          codeSent: (String verificationId, int? resendToken) {
            setState(() {
              this.verificationId = verificationId;
              isSendingCode = false; // Hide loader after the code is sent
            });
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
      setState(() {
        isLoading = false;
        isSendingCode = false; // Ensure loader is hidden on error
      });
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

  Widget buildEmailFields() {
    final theme = Theme.of(context);
    return Column(
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
  }

  Widget buildPhoneField() {
    final theme = Theme.of(context);
    return TextFormField(
      controller: phoneController,
      decoration: InputDecoration(
        labelText: "Phone Number",
        prefixText: '+94 ',
        prefixStyle: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Enter a valid phone number';
        }
        if (!RegExp(r'^[1-9][0-9]{8}$').hasMatch(value)) {
          return 'Invalid format. Enter 9 digits after +94.';
        }
        return null;
      },
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              color: theme.scaffoldBackgroundColor,
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
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Create your account to explore amazing features.",
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        boxShadow: theme.cardTheme.shadowColor != null
                            ? [
                          BoxShadow(
                            color: theme.cardTheme.shadowColor!,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ]
                            : null,
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
                                      color: !isPhoneSelected ? theme.primaryColor : theme.disabledColor,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => setState(() => isPhoneSelected = true),
                                  child: Text(
                                    "Use Phone",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isPhoneSelected ? theme.primaryColor : theme.disabledColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            isPhoneSelected ? buildPhoneField() : buildEmailFields(),
                            SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: isLoading || isSendingCode ? null : _createAccount,
                              child: isLoading || isSendingCode
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
                        style: theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isSendingCode)
              Positioned.fill(
                child: Container(
                  color: theme.scaffoldBackgroundColor.withOpacity(0.6),
                  child: Center(
                    child: SpinKitFadingCircle(
                      color: theme.primaryColor,
                      size: 50.0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}