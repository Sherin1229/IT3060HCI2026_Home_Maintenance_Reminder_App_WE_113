import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';
import '../models/notification_settings_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
              .toList();
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        });
  }

  Future<String> createNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
    bool isSystem = false,
    String? referenceId,
  }) async {
    final document = await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title.trim(),
      'message': message.trim(),
      'type': type.trim().isEmpty ? 'general' : type.trim(),
      'isSystem': isSystem,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      if (referenceId != null && referenceId.trim().isNotEmpty)
        'referenceId': referenceId.trim(),
    });
    return document.id;
  }

  Future<void> markAsRead(String notificationId, String userId) async {
    final reference = _firestore
        .collection('notifications')
        .doc(notificationId);
    final snapshot = await reference.get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw StateError('Notification not found.');
    }
    if (data['userId'] != userId) {
      throw StateError('Notification ownership mismatch.');
    }
    if (data['isRead'] == true) return;
    await reference.update({'isRead': true});
  }

  Stream<NotificationSettingsModel> getSettings(String userId) {
    return _firestore
        .collection('notificationSettings')
        .doc(userId)
        .snapshots()
        .map((snapshot) => NotificationSettingsModel.fromMap(snapshot.data()));
  }

  Future<void> saveSettings(
    String userId,
    NotificationSettingsModel settings,
  ) async {
    await _firestore.collection('notificationSettings').doc(userId).set({
      ...settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
