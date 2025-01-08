import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:zing/Service/StoreProvider.dart';
import 'package:zing/AdminPanal/AdminStoreDetails.dart';
import 'package:zing/AdminPanal/ManageUser.dart';

import 'package:zing/Modal/CoustomUser.dart';
import 'package:zing/AdminPanal/AddAdminScreen.dart';
import '../Service/CoustomUserProvider.dart';
import 'AdminUpdateRegitrationAmount.dart';

class AdminPanelDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);
    final customUserProvider = Provider.of<CustomUserProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BounceInDown(
                child: _buildHeader(context, 'Admin Dashboard'),
              ),
              SizedBox(height: 20),

              // Manage Stores Section
              SlideInLeft(
                child: _buildSectionTitle(context, 'Manage Stores'),
              ),
              SizedBox(height: 12),
              SlideInLeft(
                delay: Duration(milliseconds: 300),
                child: _buildStoreList(storeProvider, context),
              ),
              _buildDivider(),



              // Manage Registration Amount Section
              FadeIn(
                child: _buildSectionTitle(context, 'Manage Registration Amount'),
              ),
              FadeIn(
                delay: Duration(milliseconds: 300),
                child: _buildElevatedButton(
                  context,
                  icon: Icons.attach_money,
                  label: 'Set Registration Amount',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminUpdateRegistrationAmountScreen()),
                    );
                  },
                ),
              ),
              _buildDivider(),

              // Manage Users Section
              ZoomIn(
                child: _buildSectionTitle(context, 'Manage Users'),
              ),
              ZoomIn(
                delay: Duration(milliseconds: 300),
                child: _buildElevatedButton(
                  context,
                  icon: Icons.people,
                  label: 'Manage Users',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ManageUsersPage()),
                    );
                  },
                ),
              ),
              _buildDivider(),

              // Manage Admins Section
              BounceInUp(
                child: _buildSectionTitle(context, 'Manage Admins'),
              ),
              BounceInUp(
                delay: Duration(milliseconds: 300),
                child: _buildElevatedButton(
                  context,
                  icon: Icons.admin_panel_settings,
                  label: 'Add Admin',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddAdminScreen()),
                    );
                  },
                ),
              ),
              BounceInUp(
                delay: Duration(milliseconds: 500),
                child: _buildAdminList(customUserProvider, context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.tealAccent,
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Icon(Icons.dashboard, color: Colors.tealAccent, size: 24),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildElevatedButton(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28, color: Colors.white),
      label: Text(
        label,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: Colors.black38,
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Divider(
        thickness: 1.5,
        color: Colors.tealAccent.withOpacity(0.3),
      ),
    );
  }

  Widget _buildStoreList(StoreProvider storeProvider, BuildContext context) {
    if (storeProvider.isLoading) {
      return Center(
        child: SpinKitFadingCircle(
          color: Colors.tealAccent,
          size: 50.0,
        ),
      );
    }

    if (storeProvider.stores.isEmpty) {
      return Center(
        child: Text(
          'No stores found.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: storeProvider.stores.length,
      itemBuilder: (context, index) {
        final store = storeProvider.stores[index];
        return SlideInLeft(
          delay: Duration(milliseconds: 300 * index),
          child: _buildStoreCard(store, context),
        );
      },
    );
  }

  Widget _buildStoreCard(Store store, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminStoreDetailScreen(store: store),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 6,
        margin: EdgeInsets.symmetric(vertical: 10),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.tealAccent,
            child: Icon(Icons.store, size: 28, color: Colors.white),
          ),
          title: Text(
            store.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            'Category: ${store.category}',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 20, color: Colors.teal),
        ),
      ),
    );
  }

  Widget _buildAdminList(CustomUserProvider customUserProvider, BuildContext context) {
    if (customUserProvider.isLoading) {
      return Center(
        child: SpinKitFadingCircle(
          color: Colors.tealAccent,
          size: 60.0,
        ),
      );
    }

    final adminUsers = customUserProvider.users.where((user) => user.role == 'Admin').toList();

    if (adminUsers.isEmpty) {
      return Center(
        child: Text(
          'No admins found.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: adminUsers.length,
      itemBuilder: (context, index) {
        final admin = adminUsers[index];
        return BounceInUp(
          delay: Duration(milliseconds: 300 * index),
          child: _buildAdminCard(admin, context),
        );
      },
    );
  }

  Widget _buildAdminCard(CustomUser admin, BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 6,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.tealAccent,
          child: Icon(Icons.admin_panel_settings, size: 28, color: Colors.white),
        ),
        title: Text(
          admin.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          'Email: ${admin.email}',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 20, color: Colors.teal),
      ),
    );
  }
}