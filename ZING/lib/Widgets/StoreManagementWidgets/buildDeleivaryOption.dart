import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Modal/CoustomUser.dart';

Widget buildDeliveryOptions(Store store) {
  List<Widget> deliveryOptionsWidgets = [];

  for (var option in store.deliveryOptions!) {
    if (option == 'Home Delivery' && store.deliveryCost != null) {
      deliveryOptionsWidgets.add(Text(
          'Delivery Option: Home Delivery (Cost: \$${store.deliveryCost!
              .toStringAsFixed(2)})',
          style: TextStyle(fontSize: 16, color: Colors.green.shade700)));
    } else {
      deliveryOptionsWidgets.add(Text('Delivery Option: $option',
          style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade700)));
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: deliveryOptionsWidgets,
  );
}