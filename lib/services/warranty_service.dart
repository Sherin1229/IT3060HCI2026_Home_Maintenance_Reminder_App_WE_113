import 'package:cloud_firestore/cloud_firestore.dart';

class WarrantyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createWarranty({
    required String userId,
    required String applianceType,
    required String brand,
    required String model,
    required DateTime warrantyStartDate,
    required DateTime warrantyEndDate,
    required String provider,
    required String notes,
    required String documentType,
    required String documentName,
  }) async {
    final document = await _firestore.collection('warranties').add({
      'userId': userId,
      'applianceType': applianceType.trim(),
      'brand': brand.trim(),
      'model': model.trim(),
      'warrantyStartDate': Timestamp.fromDate(warrantyStartDate),
      'warrantyEndDate': Timestamp.fromDate(warrantyEndDate),
      'provider': provider.trim(),
      'notes': notes.trim(),
      'documentType': documentType,
      'documentName': documentName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserWarranties(String userId) {
    return _firestore
        .collection('warranties')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }
}