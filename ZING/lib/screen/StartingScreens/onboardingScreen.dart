import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; // Import the animations_do package

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // List of widgets for each onboarding page
  List<Widget> _buildPages() {
    return [
      buildOnboardingPage(
        imagePath: 'assets/images/illustration1.png',
        title: 'Best Prices & Deals',
        subtitle: 'Find your favorite meals at the best prices with exclusive deals on our app.',
      ),
      buildOnboardingPage(
        imagePath: 'assets/images/illustration2.png',
        title: 'Track your Orders',
        subtitle: 'Track your orders in real-time from the app.',
      ),
      buildOnboardingPage(
        imagePath: 'assets/images/illustration3.png',
        title: 'Free & Fast Delivery',
        subtitle: 'Get free and fast delivery for all meals above ₹100.',
      ),
    ];
  }

  Widget buildOnboardingPage({required String imagePath, required String title, required String subtitle}) {
    return FadeIn(
      duration: Duration(milliseconds: 800),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          SlideInDown(
            duration: Duration(milliseconds: 1000),
            child: Image.asset(imagePath, height: 250),
          ),
          SizedBox(height: 30),
          ZoomIn(
            duration: Duration(milliseconds: 800),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          SizedBox(height: 16),
          SlideInUp(
            duration: Duration(milliseconds: 800),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          SizedBox(height: 40),
          // Pagination dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 6.0),
                width: _currentPage == index ? 16 : 12,
                height: _currentPage == index ? 16 : 12,
                decoration: BoxDecoration(
                  color: _currentPage == index ? Colors.blue : Colors.grey.shade400,
                  shape: BoxShape.circle,
                  boxShadow: _currentPage == index
                      ? [BoxShadow(color: Colors.blue.shade200, blurRadius: 8, spreadRadius: 1)]
                      : [],
                ),
              );
            }),
          ),
          Spacer(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.blue.shade600],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return SlideInRight(
                      duration: Duration(milliseconds: 500),
                      child: _buildPages()[index],
                    );
                  },
                ),
              ),
              // Login and Create Account Buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    FadeInUp(
                      duration: Duration(milliseconds: 800),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          shadowColor: Colors.black54,
                          elevation: 6,
                        ),
                        child: Text(
                          'Login',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    FadeInUp(
                      duration: Duration(milliseconds: 900),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/createAccount');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          minimumSize: Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          shadowColor: Colors.blueAccent,
                          elevation: 6,
                        ),
                        child: Text(
                          'Create an Account',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}