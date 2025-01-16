import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zing/Modal/CoustomUser.dart';
import 'package:zing/Service/CoustomUserProvider.dart';

class FirebaseLoginScreen extends StatefulWidget {
  @override
  _FirebaseLoginScreenState createState() => _FirebaseLoginScreenState();
}

class _FirebaseLoginScreenState extends State<FirebaseLoginScreen> {
  bool isPhoneSelected = false;
  bool isTermsAccepted = false; // To track if terms are accepted
  final TextEditingController phoneController = TextEditingController(text: '+94 ');
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  String? _verificationId;

  // URL of Terms and Conditions
  final String termsUrl = "https://zingmarketingmastery.com/"; // Replace with your actual Terms URL

  // Open Terms and Conditions in Browser
  Future<void> _launchTermsUrl() async {
    if (await canLaunch(termsUrl)) {
      await launch(termsUrl);
    } else {
      _showSnackBar("Unable to open Terms and Conditions URL.", isError: true);
    }
  }

  // Show Terms and Conditions Dialog
  void _showTermsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Terms and Conditions"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Please read and accept our Terms and Conditions before proceeding.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: _launchTermsUrl,
              child: Text(
                "View Terms and Conditions",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isTermsAccepted = true;
              });
              Navigator.pop(context); // Close dialog
            },
            child: Text("Accept"),
          ),
        ],
      ),
    );
  }

  // Check Terms and Conditions Before Login
  void _checkTermsAndLogin() {
    if (!isTermsAccepted) {
      _showTermsDialog();
      return;
    }

    if (isPhoneSelected) {
      _loginWithPhoneNumber();
    } else {
      _loginWithEmail();
    }
  }

  // Google Sign-In
  Future<void> _googleSignIn() async {
    final userProvider = Provider.of<CustomUserProvider>(context, listen: false);

    try {
      GoogleSignIn googleSignIn = GoogleSignIn();
      GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account != null) {
        GoogleSignInAuthentication googleAuth = await account.authentication;
        AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(credential);

        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          CustomUser newUser = CustomUser(
            id: userCredential.user!.uid,
            name: userCredential.user!.displayName ?? 'Google User',
            email: userCredential.user!.email ?? '',
            phoneNumber: userCredential.user!.phoneNumber ?? '',
            profileImageUrl: userCredential.user!.photoURL ?? '',
          );
          await userProvider.saveUserDetails(newUser);
        }

        _showSnackBar("Google Sign-In Successful!");

        // Navigate to the /home route
        Navigator.pushNamed(context, '/home');
      }
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    }
  }

  // Email/Password Login
  Future<void> _loginWithEmail() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => isLoading = true);
      try {
        await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        _showSnackBar("Login Successful!");
        Navigator.pushNamed(context, '/home'); // Replace '/home' with your home route
      } on FirebaseAuthException catch (e) {
        _showSnackBar(e.message ?? "Login failed.", isError: true);
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  // Phone Number Login
  Future<void> _loginWithPhoneNumber() async {
    if (phoneController.text.isEmpty || !phoneController.text.startsWith('+94')) {
      _showSnackBar("Enter a valid phone number starting with +94", isError: true);
      return;
    }

    setState(() => isLoading = true);
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneController.text.trim(),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          _showSnackBar("Phone Login Successful!");
          Navigator.pushNamed(context, '/home'); // Replace '/home' with your home route
        },
        verificationFailed: (FirebaseAuthException e) {
          _showSnackBar(e.message ?? "Phone login failed.", isError: true);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
          });
          _showOTPDialog();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  // OTP Dialog for Phone Number Login
  void _showOTPDialog() {
    String otpCode = "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Enter OTP"),
        content: TextField(
          onChanged: (value) {
            otpCode = value;
          },
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter OTP',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                if (_verificationId != null) {
                  PhoneAuthCredential credential = PhoneAuthProvider.credential(
                    verificationId: _verificationId!,
                    smsCode: otpCode,
                  );
                  await _auth.signInWithCredential(credential);
                  _showSnackBar("Phone Login Successful!");
                  Navigator.pushNamed(context, '/home'); // Replace '/home' with your home route
                }
              } catch (e) {
                _showSnackBar("Invalid OTP", isError: true);
              }
            },
            child: Text("Submit"),
          ),
        ],
      ),
    );
  }

  // Snackbar for Feedback
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100, Colors.blue.shade300],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Spacer(flex: 2),
                  FadeInDown(
                    child: Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 10),
                  FadeInDown(
                    delay: Duration(milliseconds: 300),
                    child: Text(
                      "Login to your account",
                      style: TextStyle(fontSize: 18, color: Colors.blue.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Spacer(flex: 1),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isPhoneSelected = true),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: isPhoneSelected ? Colors.blue.shade300 : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                "Phone Number",
                                style: TextStyle(
                                  color: isPhoneSelected ? Colors.black : Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isPhoneSelected = false),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: !isPhoneSelected ? Colors.blue.shade300 : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                "Email",
                                style: TextStyle(
                                  color: !isPhoneSelected ? Colors.black : Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: isPhoneSelected
                        ? TextFormField(
                      key: ValueKey("phone"),
                      controller: phoneController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.phone, color: Colors.blue),
                        labelText: "Phone Number",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || !value.startsWith('+94')) {
                          return 'Phone number must start with +94';
                        }
                        return null;
                      },
                    )
                        : Column(
                      key: ValueKey("email"),
                      children: [
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email, color: Colors.blue),
                            labelText: "Email",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || !value.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock, color: Colors.blue),
                            labelText: "Password",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Enter a valid password';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _checkTermsAndLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(isPhoneSelected ? "Request OTP" : "Login"),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _googleSignIn,
                    icon: FaIcon(FontAwesomeIcons.google, color: Colors.red),
                    label: Text("Login with Google"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}