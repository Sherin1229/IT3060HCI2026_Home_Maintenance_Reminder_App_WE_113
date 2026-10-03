import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../config/app_colors.dart';

enum MaintenanceStatus { completed, upcoming, overdue }

class MaintenanceRecord {
  final String id;
  final String userId;
  final String title;
  final String appliance;
  final String location;
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final String? cost;
  final String? serviceProvider;
  final String? notes;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MaintenanceRecord({
    required this.id,
    required this.userId,
    required this.title,
    required this.appliance,
    required this.location,
    required this.scheduledDate,
    this.completedDate,
    this.cost,
    this.serviceProvider,
    this.notes,
    this.photoUrls = const [],
    required this.createdAt,
    this.updatedAt,
  });

  MaintenanceStatus get status {
    if (completedDate != null) return MaintenanceStatus.completed;
    final today = DateUtils.dateOnly(DateTime.now());
    return DateUtils.dateOnly(scheduledDate).isBefore(today)
        ? MaintenanceStatus.overdue
        : MaintenanceStatus.upcoming;
  }

  IconData get icon {
    final value = '$title $appliance'.toLowerCase();
    if (value.contains('ac') || value.contains('air')) return Icons.air;
    if (value.contains('water') || value.contains('filter')) {
      return Icons.water_drop_outlined;
    }
    if (value.contains('refrigerator') || value.contains('fridge')) {
      return Icons.kitchen_outlined;
    }
    if (value.contains('washing')) return Icons.local_laundry_service_outlined;
    if (value.contains('gas') || value.contains('stove')) {
      return Icons.local_fire_department_outlined;
    }
    return Icons.build_outlined;
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'userId': userId,
      'title': title.trim(),
      'appliance': appliance.trim(),
      'location': location.trim(),
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'completedDate': completedDate == null
          ? null
          : Timestamp.fromDate(completedDate!),
      'cost': cost?.trim(),
      'serviceProvider': serviceProvider?.trim(),
      'notes': notes?.trim(),
      'photoUrls': photoUrls,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title.trim(),
      'appliance': appliance.trim(),
      'location': location.trim(),
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'completedDate': completedDate == null
          ? null
          : Timestamp.fromDate(completedDate!),
      'cost': cost?.trim(),
      'serviceProvider': serviceProvider?.trim(),
      'notes': notes?.trim(),
      'photoUrls': photoUrls,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory MaintenanceRecord.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return MaintenanceRecord(
      id: id,
      userId: map['userId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      appliance: map['appliance']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      scheduledDate: _dateFrom(map['scheduledDate']) ?? DateTime.now(),
      completedDate: _dateFrom(map['completedDate']),
      cost: _stringOrNull(map['cost']),
      serviceProvider: _stringOrNull(map['serviceProvider']),
      notes: _stringOrNull(map['notes']),
      photoUrls: _stringList(map['photoUrls']),
      createdAt: _dateFrom(map['createdAt']) ?? DateTime.now(),
      updatedAt: _dateFrom(map['updatedAt']),
    );
  }

  static String? _stringOrNull(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

String formatMaintenanceDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

String formatMonth(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String maintenanceStatusLabel(MaintenanceStatus status) {
  switch (status) {
    case MaintenanceStatus.completed:
      return 'Completed';
    case MaintenanceStatus.upcoming:
      return 'Upcoming';
    case MaintenanceStatus.overdue:
      return 'Overdue';
  }
}

Color maintenanceStatusColor(MaintenanceStatus status) {
  switch (status) {
    case MaintenanceStatus.completed:
      return AppColors.success;
    case MaintenanceStatus.upcoming:
      return AppColors.primaryBlue;
    case MaintenanceStatus.overdue:
      return AppColors.error;
  }
}
