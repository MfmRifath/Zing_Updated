import 'dart:io'; // Import to handle file operations
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'package:path/path.dart'; // Import for filename utilities
import 'package:zing/Modal/CoustomUser.dart';
import 'package:zing/Service/StoreProvider.dart';
import 'package:zing/Service/CoustomUserProvider.dart';
import 'package:image_picker/image_picker.dart'; // Import the image_picker package

class EditProductScreen extends StatefulWidget {
  final Product? product;
  final String storeId;

  EditProductScreen({this.product, required this.storeId}); // product is null when adding a new product

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descriptionController;
  late TextEditingController ratingController;

  File? _selectedImage; // To store the image selected from the gallery
  final ImagePicker _picker = ImagePicker(); // Image picker instance
  bool _isUploading = false;
  String? _uploadedImageUrl; // Stores the URL of the uploaded image

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product?.name ?? '');
    priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _uploadedImageUrl = widget.product?.imageUrl; // Set initial image URL if editing
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    ratingController.dispose();
    super.dispose();
  }

  // Method to pick an image from the gallery
  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path); // Store the selected image
      });
    }
  }

  // Method to upload image to Firebase Storage and get the download URL
  Future<String> _uploadImage(File image) async {
    setState(() {
      _isUploading = true;
    });

    try {
      String fileName = basename(image.path); // Get the file name
      final storageRef = FirebaseStorage.instance.ref().child('products/$fileName');
      UploadTask uploadTask = storageRef.putFile(image);

      // Wait for the upload to complete and get the URL
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      setState(() {
        _isUploading = false;
      });

      return downloadUrl; // Return the download URL
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final userProvider = Provider.of<CustomUserProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Edit Product' : 'Add Product'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 4.0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(nameController, 'Product Name', TextInputType.text),
              SizedBox(height: 16),
              _buildTextField(priceController, 'Price', TextInputType.numberWithOptions(decimal: true)),
              SizedBox(height: 16),
              _buildTextField(descriptionController, 'Description', TextInputType.text),
              SizedBox(height: 16),

              // Image picker and preview section
              Text(
                'Product Image',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImageFromGallery,
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                      : (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _uploadedImageUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 40, color: Colors.grey[500]),
                      Text(
                        'Tap to Add Image',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30),

              // Upload button or progress indicator
              _isUploading
                  ? Center(child: SpinKitFadingCircle(
                color: Colors.blueAccent,
                size: 60.0,
              ),)
                  : ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text(widget.product != null ? 'Save Changes' : 'Add Product'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  textStyle: TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.blueAccent,
                ),
                onPressed: () async {
                  try {
                    if (_selectedImage != null) {
                      // Upload the selected image and get the download URL
                      _uploadedImageUrl = await _uploadImage(_selectedImage!);
                    }

                    final productName = nameController.text.trim();
                    final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                    final description = descriptionController.text.trim();
                    final rating = double.tryParse(ratingController.text.trim()) ?? 0.0;

                    if (productName.isEmpty || price <= 0 || rating < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please fill all fields with valid values')),
                      );
                      return;
                    }

                    // Set default placeholder URL if no image is uploaded
                    String imageUrlToUse = _uploadedImageUrl?.isNotEmpty == true
                        ? _uploadedImageUrl!
                        : 'https://via.placeholder.com/150';  // Placeholder image URL

                    if (widget.product != null) {
                      // Edit existing product
                      storeProvider.editProduct(
                        widget.storeId,
                        Product(
                          id: widget.product!.id,
                          name: productName,
                          price: price,
                          description: description,
                          rating: rating,
                          imageUrl: imageUrlToUse,
                          isAvailable: widget.product!.isAvailable,
                        ),
                        userProvider,
                      );
                    } else {
                      // Add new product
                      storeProvider.addProduct(
                        widget.storeId,
                        Product(
                          id: '',
                          name: productName,
                          price: price,
                          description: description,
                          rating: rating,
                          imageUrl: imageUrlToUse,  // Use the placeholder image URL if necessary
                        ),
                        userProvider,
                        context,
                      );
                    }

                    Navigator.of(context).pop(); // Return to the previous screen
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('An error occurred: ${e.toString()}')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // A method to build a styled text field
  Widget _buildTextField(TextEditingController controller, String label, TextInputType inputType) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 16, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }
}
