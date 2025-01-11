import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Service/OfferProvider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ManageOfferPage extends StatefulWidget {
  @override
  _ManageOfferPageState createState() => _ManageOfferPageState();
}

class _ManageOfferPageState extends State<ManageOfferPage> {
  final TextEditingController _textController = TextEditingController();
  File? _pickedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  void _clearFields() {
    _textController.clear();
    _pickedImage = null;
  }

  @override
  Widget build(BuildContext context) {
    final offerProvider = Provider.of<OfferProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Offers'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: offerProvider.offers.isEmpty
                  ? Center(
                child: Text(
                  'No offers available',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: offerProvider.offers.length,
                itemBuilder: (context, index) {
                  Offer offer = offerProvider.offers[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(10),
                      leading: offer.imageUrl.isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          offer.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      )
                          : Icon(Icons.image, size: 50, color: Colors.blue),
                      title: Text(
                        offer.text,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              _textController.text = offer.text;
                              showModalBottomSheet(
                                context: context,
                                builder: (ctx) {
                                  return _buildBottomSheet(
                                    context,
                                    offerProvider,
                                    isEditing: true,
                                    offer: offer,
                                  );
                                },
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              offerProvider.deleteOffer(offer.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _clearFields();
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) {
                    return _buildBottomSheet(context, offerProvider, isEditing: false);
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: Text(
                'Add Offer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, OfferProvider offerProvider,
      {bool isEditing = false, Offer? offer}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _pickedImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_pickedImage!, fit: BoxFit.cover),
              )
                  : offer != null && offer.imageUrl.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(offer.imageUrl, fit: BoxFit.cover),
              )
                  : Center(
                child: Icon(Icons.add_a_photo, size: 50, color: Colors.blue),
              ),
            ),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: 'Offer Text',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (isEditing && offer != null) {
                offer.text = _textController.text;
                offerProvider.updateOffer(offer);
              } else {
                offerProvider.addOffer(_textController.text, _pickedImage);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            ),
            child: Text(isEditing ? 'Update Offer' : 'Add Offer'),
          ),
        ],
      ),
    );
  }
}
