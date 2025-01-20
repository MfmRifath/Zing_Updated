import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // List of widgets for each onboarding page
  List<Widget> _buildPages(BuildContext context) {
    double imageHeight = MediaQuery.of(context).size.height * 0.35;
    return [
      buildOnboardingPage(
        context: context,
        imagePath: 'assets/images/illustration1.png',
        title: 'Best Prices & Deals',
        subtitle: 'Find your favorite meals at the best prices with exclusive deals on our app.',
        imageHeight: imageHeight,
      ),
      buildOnboardingPage(
        context: context,
        imagePath: 'assets/images/illustration2.png',
        title: 'Track your Orders',
        subtitle: 'Track your orders in real-time from the app.',
        imageHeight: imageHeight,
      ),
      buildOnboardingPage(
        context: context,
        imagePath: 'assets/images/illustration3.png',
        title: 'Fast Delivery',
        subtitle: 'Get fast delivery for all Items.',
        imageHeight: imageHeight,
      ),
    ];
  }

  Widget buildOnboardingPage({
    required BuildContext context,
    required String imagePath,
    required String title,
    required String subtitle,
    required double imageHeight,
  }) {
    return FadeIn(
      duration: Duration(milliseconds: 800),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          SlideInDown(
            duration: Duration(milliseconds: 1000),
            child: Image.asset(imagePath, height: imageHeight),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          ZoomIn(
            duration: Duration(milliseconds: 800),
            child: Text(
              title,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.07,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          SlideInUp(
            duration: Duration(milliseconds: 800),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.045,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.04),
          // Pagination dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 6.0),
                width: _currentPage == index
                    ? MediaQuery.of(context).size.width * 0.04
                    : MediaQuery.of(context).size.width * 0.03,
                height: _currentPage == index
                    ? MediaQuery.of(context).size.width * 0.04
                    : MediaQuery.of(context).size.width * 0.03,
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
    double buttonHeight = MediaQuery.of(context).size.height * 0.07;

    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade300, Colors.blue.shade600],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.06),
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
                        child: _buildPages(context)[index],
                      );
                    },
                  ),
                ),
                // Login and Create Account Buttons
                Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.02),
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
                            minimumSize: Size(double.infinity, buttonHeight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            shadowColor: Colors.black54,
                            elevation: 6,
                          ),
                          child: Text(
                            'Login',
                            style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.045),
                          ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                      FadeInUp(
                        duration: Duration(milliseconds: 900),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/createAccount');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            minimumSize: Size(double.infinity, buttonHeight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            shadowColor: Colors.blueAccent,
                            elevation: 6,
                          ),
                          child: Text(
                            'Create an Account',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.045,
                              color: Colors.white,
                            ),
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
      ),
    );
  }
}