import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'waste_classifier.dart';

class ScanHistoryService {
  static Future<void> saveScan(
    WasteClassification classification,
  ) async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to save a scan.',
      );
    }

    int ecoPoints = 5;

    if (classification.recyclable) {
      ecoPoints = 10;
    }

    await FirebaseFirestore.instance
        .collection('waste_scans')
        .add({
      'userId': user.uid,
      'wasteType': classification.wasteType,
      'material': classification.material,
      'recyclable': classification.recyclable,
      'hazardLevel': classification.hazardLevel,
      'disposalAdvice':
          classification.disposalAdvice,
      'confidence':
          classification.confidence,
      'ecoPoints': ecoPoints,
      'timestamp':
          FieldValue.serverTimestamp(),
    });

    // Update user's statistics.
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'totalScans': FieldValue.increment(1),
      'ecoPoints':
          FieldValue.increment(ecoPoints),
      'totalRecycled':
          classification.recyclable
              ? FieldValue.increment(1)
              : FieldValue.increment(0),
    }, SetOptions(merge: true));
  }
}