import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';

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
                colors: [Colors.black, Colors.grey],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Company Logo with subtle shadow
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage('assets/images/zing.png'), // Your company logo path
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
                  'ZING',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Animated ListTiles for company details with improved UI
          _buildAnimatedListTile(
            delay: 300,
            icon: Icons.phone,
            title: 'Phone: +94 76 673 789',
          ),
          _buildAnimatedListTile(
            delay: 400,
            icon: Icons.email,
            title: 'Email: shahil@zingmarketingmastery.com',
          ),

          // Website link
          _buildAnimatedListTile(
            delay: 500,
            icon: Icons.language,
            title: 'Website',
            onTap: () => _launchURL('https://zingmarketingmastery.com/'),
          ),

          // TikTok link
          _buildAnimatedListTile(
            delay: 600,
            icon: Icons.video_library,
            title: 'TikTok: @company',
            onTap: () => _launchURL('https://www.tiktok.com/@zing.official_?_t=8qi5IDOzsPg&_r=1'),
          ),

          // Instagram link
          _buildAnimatedListTile(
            delay: 700,
            icon: Icons.camera_alt,
            title: 'Instagram: @company',
            onTap: () => _launchURL('https://www.instagram.com/zing_official.lk?igsh=ZnVxMXBnYnp1d2dy&utm_source=qr'),
          ),

          Divider(),

          // About Us with a clear CTA
          _buildAnimatedListTile(
            delay: 800,
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
          backgroundColor: Colors.black,
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

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
