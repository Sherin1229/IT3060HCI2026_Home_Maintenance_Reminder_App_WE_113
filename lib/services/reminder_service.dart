import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reminder_model.dart';

class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createReminder(ReminderModel reminder) async {
    await _firestore.collection('reminders').add(reminder.toMap());
  }

  Stream<List<ReminderModel>> getReminders(String userId) {
    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final reminders = snapshot.docs
              .map((doc) => ReminderModel.fromMap(doc.id, doc.data()))
              .toList();

          reminders.sort((a, b) => a.date.compareTo(b.date));

          return reminders;
        });
  }

  Stream<ReminderModel?> getReminderById(String reminderId, String userId) {
    return _firestore.collection('reminders').doc(reminderId).snapshots().map((
      doc,
    ) {
      final data = doc.data();
      if (!doc.exists || data == null || data['userId'] != userId) return null;
      return ReminderModel.fromMap(doc.id, data);
    });
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    final reference = _firestore.collection('reminders').doc(reminder.id);
    await _verifyOwnership(reference, reminder.userId);
    await reference.update({
      'title': reminder.title,
      'category': reminder.category,
      'location': reminder.location,
      'date': Timestamp.fromDate(reminder.date),
      'time': reminder.time,
      'frequency': reminder.frequency,
      'notes': reminder.notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markReminderCompleted(String reminderId, String userId) async {
    final reference = _firestore.collection('reminders').doc(reminderId);
    await _verifyOwnership(reference, userId);
    await reference.update({
      'isCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteReminder(String reminderId, String userId) async {
    final reference = _firestore.collection('reminders').doc(reminderId);
    await _verifyOwnership(reference, userId);
    await reference.delete();
  }

  Future<void> _verifyOwnership(
    DocumentReference<Map<String, dynamic>> reference,
    String userId,
  ) async {
    final snapshot = await reference.get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw StateError('Reminder not found.');
    }
    if (data['userId'] != userId) {
      throw StateError('You do not have permission to modify this reminder.');
    }
  }
}
