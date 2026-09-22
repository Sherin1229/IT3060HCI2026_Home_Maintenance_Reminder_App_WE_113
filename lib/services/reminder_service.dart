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
              .map(
                (doc) => ReminderModel.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList();

          reminders.sort(
            (a, b) => a.date.compareTo(b.date),
          );

          return reminders;
        });
  }
}
