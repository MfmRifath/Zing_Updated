import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:zing/Service/StoreProvider.dart';


import '../Modal/CoustomUser.dart'; // Assuming your Store model exists

class ManageStoresPage extends StatelessWidget {
  const ManageStoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Stores'),
        centerTitle: true,
      ),
      body: storeProvider.isLoading
          ? Center(child: SpinKitFadingCircle(
        color: Colors.blueAccent,
        size: 60.0,
      ),)
          : ListView.builder(
        itemCount: storeProvider.stores.length,
        itemBuilder: (context, index) {
          final store = storeProvider.stores[index];
          return ListTile(
            title: Text(store.name),
            subtitle: Text(store.category),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteStore(store.id!, storeProvider, context),
            ),
            onTap: () => _editStore(store, context),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addStore(context),
        child: Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  // Function to add a new store
  void _addStore(BuildContext context) {
    Navigator.pushNamed(context, '/add-store');
  }

  // Function to edit a store
  void _editStore(Store store, BuildContext context) {
    Navigator.pushNamed(context, '/edit-store', arguments: store);
  }

  // Function to delete a store
  void _deleteStore(String storeId, StoreProvider storeProvider, BuildContext context) async {
    final confirm = await _showDeleteConfirmation(context);
    if (confirm) {
      await storeProvider.deleteStore(storeId, Provider.of(context, listen: false));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Store deleted successfully')));
    }
  }

  // Function to show delete confirmation dialog
  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Store'),
        content: Text('Are you sure you want to delete this store?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
        ],
      ),
    ) ?? false;
  }
}
