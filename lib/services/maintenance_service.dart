import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/maintenance_model.dart';

class MaintenanceService {
  MaintenanceService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String collectionName = 'maintenanceRecords';
  static const String _cloudName = 't6gnkeyn';
  static const String _uploadPreset = 'homiq_warranty_documents';

  CollectionReference<Map<String, dynamic>> get _records =>
      _firestore.collection(collectionName);

  Future<String> createRecord(MaintenanceRecord record) async {
    _verifyAuthenticatedUser(record.userId);
    final document = await _records.add(record.toCreateMap());
    return document.id;
  }

  Stream<List<MaintenanceRecord>> getRecords(String userId) {
    if (FirebaseAuth.instance.currentUser?.uid != userId) {
      return Stream.error(
        StateError('You must be signed in to view these records.'),
      );
    }
    return _records.where('userId', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      final records = snapshot.docs
          .map((doc) => MaintenanceRecord.fromMap(doc.id, doc.data()))
          .toList();
      records.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
      return records;
    });
  }

  Stream<MaintenanceRecord?> getRecordById(String recordId, String userId) {
    if (FirebaseAuth.instance.currentUser?.uid != userId) {
      return Stream.error(
        StateError('You must be signed in to view this record.'),
      );
    }
    return _records.doc(recordId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null || data['userId'] != userId) {
        return null;
      }
      return MaintenanceRecord.fromMap(snapshot.id, data);
    });
  }

  Future<MaintenanceRecord?> getRecordOnce(
    String recordId,
    String userId,
  ) async {
    _verifyAuthenticatedUser(userId);
    final snapshot = await _records.doc(recordId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null || data['userId'] != userId) {
      return null;
    }
    return MaintenanceRecord.fromMap(snapshot.id, data);
  }

  Future<void> updateRecord(MaintenanceRecord record) async {
    _verifyAuthenticatedUser(record.userId);
    final reference = _records.doc(record.id);
    await _verifyOwnership(reference, record.userId);
    await reference.update(record.toUpdateMap());
  }

  Future<void> markCompleted({
    required String recordId,
    required String userId,
    required DateTime completedDate,
    required String? notes,
    required String? cost,
    required String? serviceProvider,
    required List<String> photoUrls,
  }) async {
    _verifyAuthenticatedUser(userId);
    final reference = _records.doc(recordId);
    await _verifyOwnership(reference, userId);
    await reference.update({
      'completedDate': Timestamp.fromDate(completedDate),
      'notes': notes?.trim(),
      'cost': cost?.trim(),
      'serviceProvider': serviceProvider?.trim(),
      'photoUrls': photoUrls,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteRecord(String recordId, String userId) async {
    _verifyAuthenticatedUser(userId);
    final reference = _records.doc(recordId);
    await _verifyOwnership(reference, userId);
    await reference.delete();
  }

  Future<List<String>> uploadPhotos({
    required List<Uint8List> fileBytes,
    required List<String> fileNames,
  }) async {
    if (fileBytes.length != fileNames.length) {
      throw ArgumentError('Photo bytes and names must have the same length.');
    }

    final urls = <String>[];
    for (var index = 0; index < fileBytes.length; index++) {
      urls.add(await _uploadPhoto(fileBytes[index], fileNames[index]));
    }
    return urls;
  }

  Future<String> _uploadPhoto(Uint8List bytes, String fileName) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/auto/upload'),
    )..fields['upload_preset'] = _uploadPreset;
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw StateError('Cloudinary photo upload failed.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = data['secure_url']?.toString();
    if (secureUrl == null || secureUrl.isEmpty) {
      throw StateError('Cloudinary did not return a photo URL.');
    }
    return secureUrl;
  }

  Future<void> _verifyOwnership(
    DocumentReference<Map<String, dynamic>> reference,
    String userId,
  ) async {
    final snapshot = await reference.get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw StateError('Maintenance record not found.');
    }
    if (data['userId'] != userId) {
      throw StateError('You do not have permission to modify this record.');
    }
  }

  void _verifyAuthenticatedUser(String userId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != userId) {
      throw StateError('You must be signed in to manage these records.');
    }
  }
}
