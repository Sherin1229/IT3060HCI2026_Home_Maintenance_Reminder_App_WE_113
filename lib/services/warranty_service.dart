import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'device_notification_service.dart';

class WarrantyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _cloudName = 't6gnkeyn';
  static const String _uploadPreset = 'homiq_warranty_documents';

  Future<String> createWarranty({
    required String userId,
    required String applianceId,
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
    final normalizedApplianceId = applianceId.trim();
    if (normalizedApplianceId.isEmpty) {
      throw ArgumentError.value(
        applianceId,
        'applianceId',
        'A warranty must be linked to an appliance.',
      );
    }

    final document = await _firestore.collection('warranties').add({
      'userId': userId,
      'applianceId': normalizedApplianceId,
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

    await _runNotificationAction(
      () => DeviceNotificationService.instance.scheduleWarranty(
        warrantyId: document.id,
        userId: userId,
        expiryDate: warrantyEndDate,
        applianceName: '${brand.trim()} ${applianceType.trim()}'.trim(),
      ),
    );

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
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Cloudinary upload failed: '
        '${response.statusCode} ${response.body}',
      );
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    final secureUrl = responseData['secure_url'] as String?;
    final publicId = responseData['public_id'] as String?;
    final resourceType = responseData['resource_type'] as String?;

    if (secureUrl == null || publicId == null) {
      throw Exception(
        'Cloudinary did not return the required document information.',
      );
    }

    await _firestore.collection('warranties').doc(warrantyId).update({
      'documentName': fileName,
      'documentUrl': secureUrl,
      'documentPublicId': publicId,
      'documentResourceType': resourceType,
      'documentSize': fileSize,
      'uploadedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserWarranties(String userId) {
    return _firestore
        .collection('warranties')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getWarrantyById(
    String warrantyId,
  ) {
    return _firestore.collection('warranties').doc(warrantyId).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getWarrantyOnce(
    String warrantyId,
  ) {
    return _firestore.collection('warranties').doc(warrantyId).get();
  }

  Future<void> updateWarranty({
    required String warrantyId,
    required String applianceId,
    required String applianceType,
    required String brand,
    required String model,
    required DateTime warrantyStartDate,
    required DateTime warrantyEndDate,
    required String provider,
    required String notes,
  }) async {
    final normalizedApplianceId = applianceId.trim();
    if (normalizedApplianceId.isEmpty) {
      throw ArgumentError.value(
        applianceId,
        'applianceId',
        'A warranty must be linked to an appliance.',
      );
    }

    final existing = await _firestore
        .collection('warranties')
        .doc(warrantyId)
        .get();
    final userId = existing.data()?['userId']?.toString();
    await _firestore.collection('warranties').doc(warrantyId).update({
      'applianceType': applianceType.trim(),
      'applianceId': normalizedApplianceId,
      'brand': brand.trim(),
      'model': model.trim(),
      'warrantyStartDate': Timestamp.fromDate(warrantyStartDate),
      'warrantyEndDate': Timestamp.fromDate(warrantyEndDate),
      'provider': provider.trim(),
      'notes': notes.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _runNotificationAction(
      () => DeviceNotificationService.instance.cancelWarranty(warrantyId),
    );
    if (userId != null && userId.isNotEmpty) {
      await _runNotificationAction(
        () => DeviceNotificationService.instance.scheduleWarranty(
          warrantyId: warrantyId,
          userId: userId,
          expiryDate: warrantyEndDate,
          applianceName: '${brand.trim()} ${applianceType.trim()}'.trim(),
        ),
      );
    }
  }

  Future<void> deleteWarranty({
    required String warrantyId,
    required String userId,
  }) async {
    final document = await _firestore
        .collection('warranties')
        .doc(warrantyId)
        .get();

    if (!document.exists) {
      throw Exception('Warranty not found.');
    }

    final data = document.data();

    if (data == null || data['userId'] != userId) {
      throw Exception('You are not allowed to delete this warranty.');
    }

    await _firestore.collection('warranties').doc(warrantyId).delete();
    await _runNotificationAction(
      () => DeviceNotificationService.instance.cancelWarranty(warrantyId),
    );
  }

  Future<void> _runNotificationAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('Warranty notification update failed: $error');
    }
  }
}
