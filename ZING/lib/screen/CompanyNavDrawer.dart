import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class CompanyNavDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue, // You can change to any color or gradient
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Logo
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage('assets/company_logo.png'), // Your company logo path
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // Company Name
                Text(
                  'Company Name',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                // Company Address
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
          // Animated ListTiles for company details
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
          _buildAnimatedListTile(
            delay: 600,
            icon: Icons.info_outline,
            title: 'About Us',
            onTap: () {
              // Add action to navigate to an "About Us" page or show more details
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
        leading: Icon(icon),
        title: Text(title),
        onTap: onTap,
      ),
    );
  }
}