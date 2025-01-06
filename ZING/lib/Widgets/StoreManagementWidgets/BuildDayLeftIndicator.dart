import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../screen/StoreManagement/CircleProgressPainter.dart';

Widget buildDaysLeftIndicator(int daysLeft) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'Days Left to Renew: $daysLeft',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey.shade900,
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: 120,
        height: 120,
        child: CustomPaint(
          foregroundPainter: CircleProgressPainter(
            percentage: daysLeft / 30,
            strokeWidth: 10,
            color: daysLeft > 10 ? Colors.blueAccent : Colors.redAccent,
          ),
          child: Center(
            child: Text(
              "$daysLeft",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: daysLeft > 10 ? Colors.blueAccent : Colors.redAccent,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
