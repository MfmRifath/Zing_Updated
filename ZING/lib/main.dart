import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import for Firebase Auth
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import this for orientation lock
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:zing/Service/CoustomUserProvider.dart';
import 'package:zing/Service/SettingProvider.dart';
import 'package:zing/Service/StoreProvider.dart';
import 'package:zing/screen/HomeScreen.dart';
import 'package:zing/screen/StartingScreens/CreateAccount.dart';
import 'package:zing/screen/StartingScreens/LoginScreen.dart';
import 'dart:async';
import 'package:zing/screen/StartingScreens/onboardingScreen.dart';

import 'Cart/CartProvider.dart';
import 'Service/ChatProvider.dart';
import 'Service/OrderProvider.dart';

Future<void> requestPermissions() async {
  try {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.notification,
      // Add any other permissions your app needs
    ].request();

    if (statuses[Permission.notification] == PermissionStatus.denied) {
      // Handle denied case
      debugPrint('Notification permission denied');
    } else if (statuses[Permission.notification] == PermissionStatus.permanentlyDenied) {
      // Guide user to app settings
      await openAppSettings();
    }
  } catch (e) {
    debugPrint('Error requesting permissions: $e');
  }
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request permissions before Firebase initialization
  await requestPermissions();

  // Lock the app to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  var logger = Logger();
  try {
    logger.d("Logger is working!");

    // Initialize Firebase first
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCoqKGffVMkwU-QntZpBGGOP1raLV0JnkY',
        appId: '1:685215974205:android:382cf5dcbd774cfa267b54',
        messagingSenderId: '685215974205',
        projectId: 'zing-cb51c',
        storageBucket: 'zing-cb51c.appspot.com',
      ),
    );

    // After Firebase is initialized, activate App Check
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,  // Change to appropriate provider for production
      appleProvider: AppleProvider.debug,     // Change to appropriate provider for production
    );

    print("Firebase initialized successfully.");
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CustomUserProvider()..fetchUserDetails()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..fetchGlobalRegistrationAmount()),
        ChangeNotifierProvider(create: (_) => ChatProvider(
          userId: '',    // Temporary values, will be updated in `update`
          storeId: '',   // Temporary values, will be updated in `update`
          senderRole: '', // Temporary values, will be updated in `update`
        )),
      ],
      child: const Zing(), // Add the const keyword in the correct place
    ),
  );
}
class Zing extends StatelessWidget {
  const Zing({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        color: Colors.white,
        home: AuthWrapper(),
        routes: {
          '/onboarding': (context) => OnboardingScreen(),
          '/login': (context) => FirebaseLoginScreen(),
          '/createAccount': (context) => CreateAccountScreen(), // assuming you have this already
          '/home': (context) => HomePageScreen(),
        },
      ),
    );
  }
}

// AuthWrapper to handle initial navigation based on login state
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If a user is logged in, go directly to HomeScreen
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            // If no user is logged in, show the SplashScreen
            return const SplashScreen();
          } else {
            // If user is logged in, show the HomeScreen
            return HomePageScreen();
          }
        }

        // Show a loading screen while checking authentication state
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}



class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  late Animation<Offset> _textAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller for 3 seconds
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Define the scaling animation for the logo
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    // Define a slide-up animation for the text
    _textAnimation = Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Start the animation
    _controller.forward();

    // After 4 seconds, navigate to the onboarding screen
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose animation controller when done
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black,
              Colors.blue.shade900,
              Colors.blue.shade700,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.2, 0.6, 1.0], // Control color transitions
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Scale transition for the logo
              ScaleTransition(
                scale: _logoAnimation,
                child: Image.asset(
                  'assets/images/zing.png', // Replace with your logo path
                  height: 200,
                  width: 200,
                ),
              ),
              const SizedBox(height: 20),
              // Slide transition for the text
              SlideTransition(
                position: _textAnimation,
                child: const Text(
                  'Z I N G',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'MARKETING MASTERY',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}