import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Service/CoustomUserProvider.dart';


class FilterOrdersScreen extends StatefulWidget {
  final String storeId;
  final String selectedFilter;
  final String? selectedUser;

  FilterOrdersScreen({
    required this.storeId,
    required this.selectedFilter,
    this.selectedUser,
  });

  @override
  _FilterOrdersScreenState createState() => _FilterOrdersScreenState();
}

class _FilterOrdersScreenState extends State<FilterOrdersScreen> {
  String _status = 'All';
  String? _selectedUser;

  @override
  void initState() {
    super.initState();
    _status = widget.selectedFilter;
    _selectedUser = widget.selectedUser;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<CustomUserProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Filter Orders'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter by Status:'),
            DropdownButton<String>(
              value: _status,
              items: <String>['All', 'Pending', 'Shipped', 'Delivered']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _status = newValue!;
                });
              },
            ),
            SizedBox(height: 20),
            Text('Filter by User:'),
            DropdownButton<String>(
              value: _selectedUser,
              items: userProvider.users.map((user) {
                return DropdownMenuItem<String>(
                  value: user.id,
                  child: Text(user.name),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedUser = newValue;
                });
              },
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'status': _status,
                  'user': _selectedUser,
                });
              },
              child: Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
