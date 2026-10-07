import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  final String id;
  final String userId;
  final String? applianceId;
  final String title;
  final String category;
  final String location;
  final DateTime date;
  final String? time;
  final String frequency;
  final String? notes;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ReminderModel({
    required this.id,
    required this.userId,
    this.applianceId,
    required this.title,
    required this.category,
    required this.location,
    required this.date,
    this.time,
    this.frequency = 'Does not repeat',
    this.notes,
    this.isCompleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      if (applianceId != null && applianceId!.trim().isNotEmpty)
        'applianceId': applianceId!.trim(),
      'title': title,
      'category': category,
      'location': location,
      'date': Timestamp.fromDate(date),
      'time': time,
      'frequency': frequency,
      'notes': notes,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  factory ReminderModel.fromMap(String id, Map<String, dynamic> map) {
    return ReminderModel(
      id: id,
      userId: map['userId'] ?? '',
      applianceId: _stringOrNull(map['applianceId']),
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      date: _dateFrom(map['date']) ?? DateTime.now(),
      time: map['time'] as String?,
      frequency: (map['frequency'] as String?)?.trim().isNotEmpty == true
          ? map['frequency'] as String
          : 'Does not repeat',
      notes: map['notes'] as String?,
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt: _dateFrom(map['createdAt']) ?? DateTime.now(),
      updatedAt: _dateFrom(map['updatedAt']),
    );
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static String? _stringOrNull(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
