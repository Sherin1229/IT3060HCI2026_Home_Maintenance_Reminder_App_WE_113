import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class WarrantyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _cloudName = 't6gnkeyn';
  static const String _uploadPreset = 'homiq_warranty_documents';

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

  Future<void> uploadWarrantyDocument({
    required String userId,
    required String warrantyId,
    required Uint8List fileBytes,
    required String fileName,
    required int fileSize,
  }) async {
    final uploadUrl = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/auto/upload',
    );

    final request = http.MultipartRequest('POST', uploadUrl);

    request.fields['upload_preset'] = _uploadPreset;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Cloudinary upload failed: '
        '${response.statusCode} ${response.body}',
      );
    }

    final responseData =
        jsonDecode(response.body) as Map<String, dynamic>;

    final secureUrl = responseData['secure_url'] as String?;
    final publicId = responseData['public_id'] as String?;
    final resourceType = responseData['resource_type'] as String?;

    if (secureUrl == null || publicId == null) {
      throw Exception(
        'Cloudinary did not return the required document information.',
      );
    }

    await _firestore.collection('warranties').doc(warrantyId).update({
      'documentUrl': secureUrl,
      'documentPublicId': publicId,
      'documentResourceType': resourceType,
      'documentSize': fileSize,
      'uploadedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserWarranties(
    String userId,
  ) {
    return _firestore
        .collection('warranties')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getWarrantyById(
    String warrantyId,
  ) {
    return _firestore
        .collection('warranties')
        .doc(warrantyId)
        .snapshots();
  }
}