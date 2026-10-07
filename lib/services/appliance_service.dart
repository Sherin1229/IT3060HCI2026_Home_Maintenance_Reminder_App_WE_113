import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../models/appliance_model.dart';

/// Firestore Service for managing Appliances and Cloudinary photo uploads
class ApplianceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _cloudName = 't6gnkeyn';
  static const String _uploadPreset = 'homiq_warranty_documents';

  /// Upload appliance image to Cloudinary and return the resulting secure URL
  Future<String> uploadAppliancePhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final uploadUrl = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/auto/upload',
    );

    final request = http.MultipartRequest('POST', uploadUrl);
    request.fields['upload_preset'] = _uploadPreset;
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Cloudinary upload failed: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = data['secure_url']?.toString();

    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary did not return a valid photo URL.');
    }

    return secureUrl;
  }

  /// Create new appliance in Firestore
  Future<String> createAppliance({
    required String userId,
    required String applianceName,
    required String category,
    required String brand,
    required DateTime purchaseDate,
    required String modelNumber,
    String? serialNumber,
    String? photoUrl,
  }) async {
    final appliance = ApplianceModel(
      id: '',
      userId: userId,
      applianceName: applianceName,
      category: category,
      brand: brand,
      purchaseDate: purchaseDate,
      modelNumber: modelNumber,
      serialNumber: serialNumber,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection('appliances')
        .add(appliance.toCreateMap());

    return docRef.id;
  }

  /// Real-time stream of current user's appliances
  Stream<List<ApplianceModel>> getUserAppliances(String userId) {
    return _firestore
        .collection('appliances')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            return ApplianceModel.fromMap(doc.id, doc.data());
          }).toList();

          // Sort locally by createdAt desc to avoid requiring composite indexes
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Stream single appliance by ID
  Stream<ApplianceModel?> getApplianceById(String applianceId) {
    return _firestore.collection('appliances').doc(applianceId).snapshots().map(
      (snapshot) {
        if (!snapshot.exists || snapshot.data() == null) return null;
        return ApplianceModel.fromMap(snapshot.id, snapshot.data()!);
      },
    );
  }

  /// Single fetch of appliance by ID
  Future<ApplianceModel?> getApplianceOnce(String applianceId) async {
    final snapshot = await _firestore
        .collection('appliances')
        .doc(applianceId)
        .get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return ApplianceModel.fromMap(snapshot.id, snapshot.data()!);
  }

  /// Update an existing appliance
  Future<void> updateAppliance({
    required String applianceId,
    required String userId,
    required String applianceName,
    required String category,
    required String brand,
    required DateTime purchaseDate,
    required String modelNumber,
    String? serialNumber,
    String? photoUrl,
  }) async {
    final doc = await _firestore
        .collection('appliances')
        .doc(applianceId)
        .get();

    if (!doc.exists) {
      throw Exception('Appliance not found.');
    }

    final data = doc.data();
    if (data == null || data['userId'] != userId) {
      throw Exception('You are not authorized to update this appliance.');
    }

    final appliance = ApplianceModel(
      id: applianceId,
      userId: userId,
      applianceName: applianceName,
      category: category,
      brand: brand,
      purchaseDate: purchaseDate,
      modelNumber: modelNumber,
      serialNumber: serialNumber,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('appliances')
        .doc(applianceId)
        .update(appliance.toUpdateMap());
  }

  /// Delete an appliance from Firestore
  Future<void> deleteAppliance({
    required String applianceId,
    required String userId,
  }) async {
    final doc = await _firestore
        .collection('appliances')
        .doc(applianceId)
        .get();

    if (!doc.exists) {
      throw Exception('Appliance not found.');
    }

    final data = doc.data();
    if (data == null || data['userId'] != userId) {
      throw Exception('You are not authorized to delete this appliance.');
    }

    await _firestore.collection('appliances').doc(applianceId).delete();
  }
}
