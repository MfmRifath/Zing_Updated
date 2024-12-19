import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:zing/AdminPanal/USerDetails.dart';
import 'package:zing/Service/CoustomUserProvider.dart';
import '../Modal/CoustomUser.dart';

class ManageUsersPage extends StatefulWidget {
  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  String searchQuery = '';
  Timer? _debounce;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<CustomUserProvider>(context);
    final users = userProvider.users;

    // Filter users by search query
    final filteredUsers = users.where((user) {
      return user.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    // Separate users by role
    final admins = filteredUsers.where((user) => user.role == 'Admin').toList();
    final owners = filteredUsers.where((user) => user.role == 'Owner').toList();
    final regularUsers = filteredUsers.where((user) => user.role == 'User').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Users', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade900,
      ),
      body: userProvider.isLoading
          ? Center(child: SpinKitFadingCircle(
        color: Colors.blueAccent,
        size: 60.0,
      ),)
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(), // Enhanced search bar
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  if (admins.isNotEmpty) _buildUserSection('Admins', admins, userProvider),
                  if (owners.isNotEmpty) _buildUserSection('Owners', owners, userProvider),
                  if (regularUsers.isNotEmpty) _buildUserSection('Users', regularUsers, userProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build a debounced search bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          labelText: 'Search by name',
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: Colors.blueGrey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        onChanged: (value) {
          _onSearchChanged(value);
        },
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 300), () {
      setState(() {
        searchQuery = query;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // Build a user section with enhanced UI
  Widget _buildUserSection(String title, List<CustomUser> users, CustomUserProvider userProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade700,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 6,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  radius: 24,
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  user.name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Text(
                  '${user.email}\nRole: ${user.role}',
                  style: TextStyle(height: 1.5, color: Colors.grey[600]),
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _deleteUser(user, userProvider, context),
                ),
                onTap: () => _viewUserDetails(user, context),
              ),
            );
          },
        ),
      ],
    );
  }

  // Function to view user details
  void _viewUserDetails(CustomUser user, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailsPage(user: user),
      ),
    );
  }

  // Function to delete a user with a confirmation dialog and error handling
  void _deleteUser(CustomUser user, CustomUserProvider userProvider, BuildContext context) async {
    final confirm = await _showDeleteConfirmation(context);
    if (confirm) {
      bool isOwner = user.role == 'Owner';
      String? storeId = isOwner ? user.store?.id : null;

      try {
        await userProvider.deleteUser(user.id, isOwner: isOwner, storeId: storeId);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User deleted successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete user: $e')));
      }
    }
  }

  // Delete confirmation dialog
  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text('Delete User'),
          ],
        ),
        content: Text('Are you sure you want to delete this user? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.blueGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }
}
