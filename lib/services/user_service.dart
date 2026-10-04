import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _cloudName = 't6gnkeyn';
  static const String _uploadPreset = 'homiq_warranty_documents';

  Future<void> createUserProfile({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'fullName': fullName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final document = await _firestore.collection('users').doc(uid).get();

    if (!document.exists) {
      return null;
    }

    return document.data();
  }

  Stream<Map<String, dynamic>?> watchUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return snapshot.data();
    });
  }

  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
    required String phone,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> uploadProfileImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
    )..fields['upload_preset'] = _uploadPreset;
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw StateError('Profile image upload failed.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = data['secure_url']?.toString();
    if (secureUrl == null || secureUrl.isEmpty) {
      throw StateError('Cloudinary did not return an image URL.');
    }
    return secureUrl;
  }

  Future<void> updateProfilePhoto({
    required String uid,
    required String photoUrl,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
