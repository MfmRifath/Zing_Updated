import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:zing/Modal/CoustomUser.dart';
import 'package:zing/Service/CoustomUserProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<CustomUserProvider>(context, listen: false);
    final user = userProvider.user;

    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    final userProvider = Provider.of<CustomUserProvider>(context, listen: false);
    final userId = userProvider.user!.id;

    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child("user_images/$userId/profile.jpg");
    UploadTask uploadTask = ref.putFile(image);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _saveProfileChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String? imageUrl;

      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
      }

      final userProvider = Provider.of<CustomUserProvider>(context, listen: false);
      CustomUser updatedUser = CustomUser(
        id: userProvider.user!.id,
        name: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        address: userProvider.user!.address,
        profileImageUrl: imageUrl ?? userProvider.user!.profileImageUrl,
        role: userProvider.user!.role,
        store: userProvider.user!.store,
        favorites: userProvider.user!.favorites,
      );

      print('Updated user: ${updatedUser.name}, Store ID: ${updatedUser.store?.id}');

      await userProvider.saveUserDetails(updatedUser);

      if (updatedUser.role == 'Owner') {
        await _updateStoreOwnerDetails(updatedUser);
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Profile updated successfully!')));
      Navigator.pop(context);
    }
  }

  Future<void> _updateStoreOwnerDetails(CustomUser updatedUser) async {
    try {
      if (updatedUser.store != null && updatedUser.store!.id == null) {
        DocumentReference storeDocRef = FirebaseFirestore.instance
            .collection('stores')
            .doc(updatedUser.store!.id);

        print('Updating store owner details for store ID: ${updatedUser.store!.id}');

        DocumentSnapshot storeSnapshot = await storeDocRef.get();

        if (storeSnapshot.exists) {
          await storeDocRef.update({
            'owner.name': updatedUser.name,
            'owner.email': updatedUser.email,
            'owner.phone': updatedUser.phoneNumber,
            'owner.profileImageUrl': updatedUser.profileImageUrl,
          });

          print('Store owner details updated successfully.');
        } else {
          print('No store found with the given ID.');
        }
      } else {
        print('No store associated with this user.');
      }
    } catch (e) {
      print('Error updating store owner details: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating store owner details.')));
    }
  }

  String? _validateEmail(String? value) {
    final RegExp emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (value == null || value.isEmpty) {
      return 'Email cannot be empty';
    } else if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number cannot be empty';
    } else if (value.length < 10) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<CustomUserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? Center(
        child: SpinKitFadingCircle(
          color: Colors.blueAccent,
          size: 60.0,
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                _buildProfileImage(user),
                SizedBox(height: 20),
                _buildFormFields(),
                SizedBox(height: 30),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(CustomUser? user) {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[300],
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : (user?.profileImageUrl.isNotEmpty ?? false)
                ? NetworkImage(user!.profileImageUrl)
                : null,
            child: _selectedImage == null &&
                (user?.profileImageUrl == null || user!.profileImageUrl.isEmpty)
                ? Icon(Icons.camera_alt, size: 40, color: Colors.white)
                : null,
          ),
          if (_selectedImage != null || user!.profileImageUrl.isNotEmpty)
            Positioned(
              bottom: 0,
              right: 0,
              child: Icon(
                Icons.edit,
                color: Colors.blueAccent,
                size: 28,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                errorStyle: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
              value == null || value.isEmpty ? 'Name cannot be empty' : null,
            ),
            SizedBox(height: 15),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                errorStyle: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                border: OutlineInputBorder(),
              ),
              validator: _validateEmail,
            ),
            SizedBox(height: 15),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                errorStyle: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                border: OutlineInputBorder(),
              ),
              validator: _validatePhone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveProfileChanges,
      child: _isLoading
          ? CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      )
          : Text('Save Changes'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
