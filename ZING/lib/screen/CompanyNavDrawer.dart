import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class CompanyNavDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Drawer Header with gradient and logo
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Logo with subtle shadow
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage('assets/company_logo.png'), // Your company logo path
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),
                // Company Name with increased font size
                Text(
                  'Company Name',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 5),
                // Company Address with lighter text
                Text(
                  'Company Address',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Animated ListTiles for company details with improved UI
          _buildAnimatedListTile(
            delay: 100,
            icon: Icons.business,
            title: 'Founder: John Doe',
          ),
          _buildAnimatedListTile(
            delay: 200,
            icon: Icons.location_on,
            title: 'Address: 123 Main St, City, Country',
          ),
          _buildAnimatedListTile(
            delay: 300,
            icon: Icons.phone,
            title: 'Phone: +123 456 789',
          ),
          _buildAnimatedListTile(
            delay: 400,
            icon: Icons.email,
            title: 'Email: info@company.com',
          ),
          _buildAnimatedListTile(
            delay: 500,
            icon: Icons.language,
            title: 'Website: www.company.com',
          ),
          Divider(),

          // About Us with a clear CTA
          _buildAnimatedListTile(
            delay: 600,
            icon: Icons.info_outline,
            title: 'About Us',
            onTap: () {
              // Navigate to About Us page
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedListTile({
    required int delay,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return FadeInLeft(
      delay: Duration(milliseconds: delay),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        onTap: onTap,
        tileColor: Colors.transparent, // Make the background transparent for a cleaner look
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }
}