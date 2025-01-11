import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../Service/AdvertisementProvider.dart';

class ManageAdvertisementsPage extends StatefulWidget {
  @override
  _ManageAdvertisementsPageState createState() => _ManageAdvertisementsPageState();
}

class _ManageAdvertisementsPageState extends State<ManageAdvertisementsPage> {
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final advertisementProvider = Provider.of<AdvertisementProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Advertisements'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Advertisement',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity)
                    : Center(child: Icon(Icons.add_a_photo, size: 50, color: Colors.blue)),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_selectedImage != null && _descriptionController.text.isNotEmpty) {
                  advertisementProvider.addAdvertisement(_descriptionController.text, _selectedImage!);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Advertisement Added!')));
                  _descriptionController.clear();
                  setState(() {
                    _selectedImage = null;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select an image and add a description.')));
                }
              },
              child: Text('Add Advertisement'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: advertisementProvider.advertisements.isEmpty
                  ? Center(child: Text('No advertisements available.'))
                  : ListView.builder(
                itemCount: advertisementProvider.advertisements.length,
                itemBuilder: (context, index) {
                  final ad = advertisementProvider.advertisements[index];
                  return ListTile(
                    leading: Image.network(ad.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                    title: Text(ad.description),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        advertisementProvider.deleteAdvertisement(ad.imageUrl);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Advertisement Deleted!')));
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
