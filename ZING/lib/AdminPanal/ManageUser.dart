import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:zing/AdminPanal/UserDetails.dart';
import '../Modal/CoustomUser.dart';

import '../Service/CoustomUserProvider.dart';

class ManageUsersPage extends StatefulWidget {
  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageConstants {
  static const double borderRadius = 12.0;
  static const Duration searchDebounceTime = Duration(milliseconds: 300);
  static const String title = 'Manage Users';
  static const double elevation = 8.0;
  static const double spacing = 16.0;
}

class _ManageUsersPageState extends State<ManageUsersPage> with SingleTickerProviderStateMixin {
  String searchQuery = '';
  Timer? _debounce;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _showBackToTopButton = _scrollController.offset >= 200;
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<CustomUserProvider>(context);
    final users = userProvider.users ?? [];

    final filteredUsers = users.where((user) {
      return user.name != null &&
          user.name.isNotEmpty &&
          user.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    final admins = filteredUsers.where((user) => user.role == 'Admin').toList();
    final owners = filteredUsers.where((user) => user.role == 'Owner').toList();
    final regularUsers = filteredUsers.where((user) => user.role == 'User').toList();

    return Scaffold(
      appBar: _buildAppBar(),
      body: userProvider.isLoading
          ? _buildLoadingIndicator()
          : _buildMainContent(admins, owners, regularUsers, userProvider),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      title: Text(
        _ManageUsersPageConstants.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.blueGrey.shade900,
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        tabs: [
          Tab(text: 'Admins'),
          Tab(text: 'Owners'),
          Tab(text: 'Users'),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitFadingCircle(
            color: Colors.blueAccent,
            size: 60.0,
          ),
          SizedBox(height: 16),
          Text(
            'Loading Users...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
      List<CustomUser> admins,
      List<CustomUser> owners,
      List<CustomUser> regularUsers,
      CustomUserProvider userProvider,
      ) {
    return Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(admins, userProvider, 'Admins'),
                _buildUserList(owners, userProvider, 'Owners'),
                _buildUserList(regularUsers, userProvider, 'Users'),
              ],
            ),
          ),
        ],
      );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ManageUsersPageConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search users...',
          prefixIcon: Icon(Icons.search, color: Colors.blueGrey),
          suffixIcon: Icon(Icons.filter_list, color: Colors.blueGrey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_ManageUsersPageConstants.borderRadius),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildUserList(List<CustomUser> users, CustomUserProvider userProvider, String title) {
    if (users.isEmpty) {
      return _buildEmptyState(title);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) => _buildUserCard(users[index], userProvider),
    );
  }

  Widget _buildEmptyState(String userType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 64,
            color: Colors.blueGrey.shade300,
          ),
          SizedBox(height: 16),
          Text(
            'No $userType Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: TextStyle(
              color: Colors.blueGrey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(CustomUser user, CustomUserProvider userProvider) {
    final userName = user.name ?? 'Unknown User';
    final userEmail = user.email ?? 'No email provided';
    final userRole = user.role ?? 'No role assigned';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_ManageUsersPageConstants.borderRadius),
      ),
      elevation: _ManageUsersPageConstants.elevation,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => _viewUserDetails(user, context),
        borderRadius: BorderRadius.circular(_ManageUsersPageConstants.borderRadius),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildUserAvatar(userName),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildUserActions(user, userProvider),
                ],
              ),
              SizedBox(height: 12),
              _buildRoleChip(userRole),
              if (user.role == 'Owner' || user.role == 'Admin')
                _buildStoreAccessSwitch(user, userProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String userName) {
    return Hero(
      tag: 'avatar_${userName}',
      child: CircleAvatar(
        backgroundColor: Colors.blueGrey.shade800,
        radius: 30,
        child: Text(
          userName[0].toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    Color chipColor;
    switch (role.toLowerCase()) {
      case 'admin':
        chipColor = Colors.blue;
        break;
      case 'owner':
        chipColor = Colors.purple;
        break;
      default:
        chipColor = Colors.green;
    }

    return Chip(
      label: Text(
        role,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: chipColor,
    );
  }

  Widget _buildStoreAccessSwitch(CustomUser user, CustomUserProvider userProvider) {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text(
            'Store Access',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          Switch.adaptive(
            value: user.storeAccess,
            onChanged: (value) => _toggleStoreAccess(user, value, userProvider, context),
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildUserActions(CustomUser user, CustomUserProvider userProvider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit, color: Colors.blue),
          onPressed: () => _viewUserDetails(user, context),
          tooltip: 'Edit User',
        ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteUser(user, userProvider, context),
          tooltip: 'Delete User',
        ),
      ],
    );
  }

  Widget? _buildFloatingActionButton() {
    return _showBackToTopButton
        ? FloatingActionButton(
      onPressed: _scrollToTop,
      child: Icon(Icons.arrow_upward),
      tooltip: 'Back to Top',
    )
        : null;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(_ManageUsersPageConstants.searchDebounceTime, () {
      setState(() {
        searchQuery = query;
      });
    });
  }

  Future<void> _toggleStoreAccess(
      CustomUser user,
      bool value,
      CustomUserProvider userProvider,
      BuildContext context,
      ) async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      scaffold.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Updating store access...'),
            ],
          ),
        ),
      );

      await userProvider.updatePaymentStatusAndStoreAccess(user, value);
      setState(() {
        user.storeAccess = value;
      });

      scaffold.clearSnackBars();
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Store access updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      scaffold.clearSnackBars();
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Failed to update store access: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewUserDetails(CustomUser user, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailsPage(user: user),
      ),
    );
  }

  Future<void> _deleteUser(
      CustomUser user,
      CustomUserProvider userProvider,
      BuildContext context,
      ) async {
    final confirm = await _showDeleteConfirmation(context);
    if (confirm) {
      final scaffold = ScaffoldMessenger.of(context);
      bool isOwner = user.role == 'Owner';
      String? storeId = isOwner ? user.store?.id : null;

      try {
        scaffold.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Deleting user...'),
              ],
            ),
          ),
        );

        await userProvider.deleteUser(user.id, isOwner: isOwner, storeId: storeId);

        scaffold.clearSnackBars();
        scaffold.showSnackBar(
          SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        scaffold.clearSnackBars();
        scaffold.showSnackBar(
          SnackBar(
            content: Text('Failed to delete user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_ManageUsersPageConstants.borderRadius),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text('Delete User'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this user? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.blueGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ?? false;
  }
}