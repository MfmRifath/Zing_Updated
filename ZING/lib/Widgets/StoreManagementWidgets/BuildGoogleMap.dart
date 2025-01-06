import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../Modal/CoustomUser.dart';

Widget buildGoogleMap(Store userStore) {
  return Container(
    height: 200,
    width: double.infinity,
    child: GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
            userStore.location.latitude, userStore.location.longitude),
        zoom: 14,
      ),
      markers: {
        Marker(
          markerId: MarkerId('store-location'),
          position: LatLng(
              userStore.location.latitude, userStore.location.longitude),
          infoWindow: InfoWindow(
            title: userStore.name,
            snippet: userStore.category,
          ),
        ),
      },
    ),
  );
}