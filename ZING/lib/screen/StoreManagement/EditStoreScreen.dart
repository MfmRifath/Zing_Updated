import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zing/Service/CoustomUserProvider.dart';
import 'package:zing/Service/StoreProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:zing/Modal/CoustomUser.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../Service/SettingProvider.dart';

class AddEditStoreDialog extends StatefulWidget {
  final Store? store;
  Function refreshStoreData;
  AddEditStoreDialog({this.store, required this.refreshStoreData});

  @override
  _AddEditStoreDialogState createState() => _AddEditStoreDialogState();
}

class _AddEditStoreDialogState extends State<AddEditStoreDialog> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController phoneNumberController;
  late TextEditingController deliveryCostController;
  LatLng? storeLocation;
  bool isEditMode = false;
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  String? selectedCategory;
  bool isLoading = false;
  final List<String> categories = [
    'Electronics', 'Clothing', 'Food', 'Sports', 'Beauty', 'Education', 'Electrical', 'Kids', 'Mens', 'Womens', 'Phone'
  ];

  // Track selected delivery methods
  bool isStorePickupSelected = false;
  bool isHomeDeliverySelected = false;

  @override
  void initState() {
    super.initState();
    isEditMode = widget.store != null;

    nameController = TextEditingController(text: isEditMode ? widget.store!.name : '');
    descriptionController = TextEditingController(text: isEditMode ? widget.store!.description : '');
    phoneNumberController = TextEditingController(text: isEditMode ? widget.store!.phoneNumber : '');
    deliveryCostController = TextEditingController();

    if (isEditMode) {
      storeLocation = LatLng(widget.store!.location.latitude, widget.store!.location.longitude);
      selectedCategory = widget.store!.category;

      // Initialize delivery methods based on existing store
      isStorePickupSelected = widget.store!.deliveryOptions!.contains('Store Pickup');
      isHomeDeliverySelected = widget.store!.deliveryOptions!.contains('Home Delivery');
      if (widget.store!.deliveryCost != null) {
        deliveryCostController.text = widget.store!.deliveryCost!.toString();
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    phoneNumberController.dispose();
    deliveryCostController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImageToFirebase(File imageFile) async {
    try {
      String fileName = 'store_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final userProvider = Provider.of<CustomUserProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.0),
            ),
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEditMode ? 'Edit Store' : 'Add Store',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickImageFromGallery,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Circular frame for the image
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey.shade300, // Background color for a subtle border effect
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: _pickedImage != null
                                ? FileImage(_pickedImage!)
                                : isEditMode
                                ? NetworkImage(widget.store!.imageUrl)
                                : AssetImage('assets/images/profile.jpg') as ImageProvider,
                            child: _pickedImage == null && !isEditMode // Placeholder icon when no image is selected
                                ? Icon(Icons.store, size: 40, color: Colors.grey.shade700)
                                : null,
                          ),
                        ),
                        // Add an overlay icon for better user feedback
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Store Name',
                      hintText: 'Enter the store name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.store),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: phoneNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Store Phone Number',
                      hintText: 'Enter the phone number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.category),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter a brief description of the store',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Methods',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      SizedBox(height: 10),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: isStorePickupSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        isStorePickupSelected = value!;
                                      });
                                    },
                                  ),
                                  Text(
                                    'Store Pickup',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              Divider(color: Colors.grey.shade300),
                              Row(
                                children: [
                                  Checkbox(
                                    value: isHomeDeliverySelected,
                                    onChanged: (value) {
                                      setState(() {
                                        isHomeDeliverySelected = value!;
                                      });
                                    },
                                  ),
                                  Text(
                                    'Home Delivery',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isHomeDeliverySelected) ...[
                        SizedBox(height: 10),
                        TextField(
                          controller: deliveryCostController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Delivery Cost',
                            hintText: 'Enter delivery cost',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Icon(Icons.monetization_on),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      LatLng? selectedLocation = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectLocationScreen(
                            initialLocation: storeLocation,
                          ),
                        ),
                      );

                      if (selectedLocation != null) {
                        setState(() {
                          storeLocation = selectedLocation;
                        });
                      }
                    },
                    icon: Icon(
                      Icons.location_pin,
                      color: Colors.white,
                      size: 24,
                    ),
                    label: Text(
                      storeLocation == null ? 'Pick Store Location' : 'Location Selected',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: storeLocation == null ? Colors.redAccent : Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                  SizedBox(height: 20),
                  if (!isEditMode) ...[
                    Text(
                      'Registration Amount: \$${settingsProvider.registrationAmount?.toStringAsFixed(2)} ${settingsProvider.currency}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                  ],
                  ElevatedButton(
                    onPressed: () async {
                      if (storeLocation == null || selectedCategory == null || (!isStorePickupSelected && !isHomeDeliverySelected)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please select a location, category, and delivery method'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.redAccent,
                            duration: Duration(seconds: 3),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        isLoading = true;
                      });

                      try {
                        String imageUrl = 'https://via.placeholder.com/150';
                        if (_pickedImage != null) {
                          imageUrl = await _uploadImageToFirebase(_pickedImage!);
                        }

                        List<String> deliveryOptions = [];
                        if (isStorePickupSelected) deliveryOptions.add('Store Pickup');
                        if (isHomeDeliverySelected) deliveryOptions.add('Home Delivery');

                        double? deliveryCost;
                        if (isHomeDeliverySelected) {
                          deliveryCost = double.tryParse(deliveryCostController.text);
                        }

                        if (isEditMode) {
                          Store updatedStore = Store(
                            id: widget.store!.id,
                            phoneNumber: phoneNumberController.text,
                            name: nameController.text,
                            description: descriptionController.text,
                            category: selectedCategory!,
                            imageUrl: imageUrl,
                            location: GeoPoint(storeLocation!.latitude, storeLocation!.longitude),
                            deliveryOptions: deliveryOptions,
                            deliveryCost: deliveryCost,
                            owner: widget.store!.owner,
                            products: widget.store!.products,
                          );

                          await storeProvider.editStore(widget.store!.id!, updatedStore, userProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Store updated successfully!'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        } else {
                          CustomUser? currentUser = userProvider.user;

                          if (currentUser != null) {
                            Store newStore = Store(
                              id: '',
                              phoneNumber: phoneNumberController.text,
                              name: nameController.text,
                              description: descriptionController.text,
                              category: selectedCategory!,
                              imageUrl: imageUrl,
                              deliveryOptions: deliveryOptions,
                              deliveryCost: deliveryCost,
                              owner: Owner(
                                id: currentUser.id,
                                name: currentUser.name,
                                email: currentUser.email,
                                phone: currentUser.phoneNumber,
                                profileImageUrl: currentUser.profileImageUrl,
                              ),
                              products: [],
                              location: GeoPoint(storeLocation!.latitude, storeLocation!.longitude),
                            );
                            await storeProvider.addStore(newStore,userProvider);
                            // Show bank details after store registration
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Admin Bank Details'),
                                  content: Text(
                                      'To complete get your store, please pay the registration fee to the following bank account:'
                                          '\nBank: XYZ Bank'
                                          '\nAccount Number: 123456789'
                                          '\nAccount Name: Admin Name'
                                          '\nBranch: XYZ Branch'
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );


                            widget.refreshStoreData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Store added successfully!'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        setState(() {
                          isLoading = false;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.redAccent,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(isEditMode ? 'Save Changes' : 'Add Store'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}class SelectLocationScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const SelectLocationScreen({this.initialLocation});

  @override
  _SelectLocationScreenState createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  LatLng? pickedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: pickedLocation ?? LatLng(6.9271, 79.8612), // Default to San Francisco
          zoom: 10,
        ),
        onTap: (LatLng latLng) {
          setState(() {
            pickedLocation = latLng;
          });
        },
        markers: pickedLocation != null
            ? {
          Marker(
            markerId: MarkerId('picked-location'),
            position: pickedLocation!,
          ),
        }
            : {},
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        onPressed: () {
          if (pickedLocation == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please select a location')),
            );
          } else {
            Navigator.of(context).pop(pickedLocation);
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Move FAB to center bottom
    );
  }
}
