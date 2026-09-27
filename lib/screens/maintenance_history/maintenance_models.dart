import 'package:flutter/material.dart';

enum MaintenanceStatus { completed, upcoming, overdue }

class MaintenanceRecord {
  final String id;
  final String title;
  final String appliance;
  final String location;
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final MaintenanceStatus status;
  final String? cost;
  final String? serviceProvider;
  final String? notes;
  final IconData icon;

  const MaintenanceRecord({
    required this.id,
    required this.title,
    required this.appliance,
    required this.location,
    required this.scheduledDate,
    this.completedDate,
    required this.status,
    this.cost,
    this.serviceProvider,
    this.notes,
    required this.icon,
  });
}

final List<MaintenanceRecord> maintenanceRecords = [
  MaintenanceRecord(
    id: 'ac-cleaning',
    title: 'AC Cleaning',
    appliance: 'Living Room AC',
    location: 'Living Room',
    scheduledDate: DateTime(2025, 9, 10),
    completedDate: DateTime(2025, 9, 10),
    status: MaintenanceStatus.completed,
    cost: 'LKR 5,000',
    serviceProvider: 'CoolAir Service',
    notes: 'Cleaned indoor and outdoor unit. Replaced air filter.',
    icon: Icons.air,
  ),
  MaintenanceRecord(
    id: 'water-filter',
    title: 'Water Filter Replacement',
    appliance: 'Kitchen',
    location: 'Kitchen',
    scheduledDate: DateTime(2025, 9, 20),
    status: MaintenanceStatus.upcoming,
    icon: Icons.water_drop_outlined,
  ),
  MaintenanceRecord(
    id: 'refrigerator-cleaning',
    title: 'Refrigerator Cleaning',
    appliance: 'Kitchen',
    location: 'Kitchen',
    scheduledDate: DateTime(2025, 8, 1),
    status: MaintenanceStatus.overdue,
    icon: Icons.kitchen_outlined,
  ),
  MaintenanceRecord(
    id: 'washing-machine',
    title: 'Washing Machine Service',
    appliance: 'Laundry',
    location: 'Laundry',
    scheduledDate: DateTime(2025, 6, 15),
    completedDate: DateTime(2025, 6, 15),
    status: MaintenanceStatus.completed,
    icon: Icons.local_laundry_service_outlined,
  ),
  MaintenanceRecord(
    id: 'gas-stove',
    title: 'Gas Stove Service',
    appliance: 'Kitchen',
    location: 'Kitchen',
    scheduledDate: DateTime(2025, 4, 12),
    completedDate: DateTime(2025, 4, 12),
    status: MaintenanceStatus.completed,
    icon: Icons.local_fire_department_outlined,
  ),
];

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
