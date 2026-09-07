import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
}