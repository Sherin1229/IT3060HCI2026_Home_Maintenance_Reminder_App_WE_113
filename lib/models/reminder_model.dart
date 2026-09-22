import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  final String id;
  final String userId;
  final String title;
  final String category;
  final String location;
  final DateTime date;
  final String? time;
  final String? notes;
  final DateTime createdAt;

  const ReminderModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.location,
    required this.date,
    this.time,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'category': category,
      'location': location,
      'date': Timestamp.fromDate(date),
      'time': time,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReminderModel.fromMap(String id, Map<String, dynamic> map) {
    return ReminderModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      time: map['time'],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
