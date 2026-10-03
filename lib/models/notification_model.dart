import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isSystem;
  final bool isRead;
  final DateTime createdAt;
  final String? referenceId;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.type = 'general',
    this.isSystem = false,
    this.isRead = false,
    required this.createdAt,
    this.referenceId,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isSystem': isSystem,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      if (referenceId != null) 'referenceId': referenceId,
    };
  }

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    final type = map['type']?.toString().trim();
    final referenceId = map['referenceId']?.toString().trim();
    return NotificationModel(
      id: id,
      userId: map['userId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      type: type == null || type.isEmpty ? 'general' : type,
      isSystem: map['isSystem'] as bool? ?? false,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: _dateFrom(map['createdAt']) ?? DateTime.now(),
      referenceId: referenceId == null || referenceId.isEmpty
          ? null
          : referenceId,
    );
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
