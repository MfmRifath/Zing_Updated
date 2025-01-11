import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Service/StoreProvider.dart';
import '../../screen/StoreManagement/EditStoreScreen.dart';

Widget buildAddStoreButton(BuildContext context) {
  final storeProvider = Provider.of<StoreProvider>(context, listen: false);

  return Center(
    child: Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 250, // Reduced width for a smaller size
        padding: EdgeInsets.all(16), // Reduced padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12), // Reduced padding for the icon
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.store_rounded,
                size: 40, // Smaller icon
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(height: 16), // Reduced spacing
            Text(
              'Start Your Business',
              style: TextStyle(
                fontSize: 20, // Smaller font size
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            SizedBox(height: 8), // Reduced spacing
            Text(
              'Create your store and start selling today',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14, // Smaller font size
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 20), // Reduced spacing
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton.icon(
                icon: Icon(
                  Icons.add_business_rounded,
                  color: Colors.white,
                  size: 20, // Smaller icon
                ),
                label: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Add Store',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16, // Smaller font size
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Smaller padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Smaller radius
                  ),
                  elevation: 4.0,
                  shadowColor: Colors.blue.withOpacity(0.3),
                ).copyWith(
                  overlayColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.hovered))
                        return Colors.blue.shade800;
                      return null;
                    },
                  ),
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditStoreDialog(
                        refreshStoreData: () {
                          storeProvider.fetchStores();
                        },
                      ),
                    ),
                  );
                  if (result == true) {
                    storeProvider.fetchStores();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}