import 'package:flutter/material.dart';

/// Local Appliance model for UI presentation.
/// (No Firebase/backend integration as per task requirements).
class ApplianceItem {
  final String id;
  final String name;
  final String category;
  final String brand;
  final String modelNumber;
  final String? serialNumber;
  final String? purchaseDate;
  final String
  maintenanceType; // e.g. "Next Service", "Next Filter Clean", "Next Tub Clean"
  final String nextMaintenanceDate;
  final String status; // "Active", "Expiring"
  final IconData icon;
  final Color iconBackgroundColor;
  final String? description;
  final String? warrantyProvider;
  final String? warrantyExpiry;
  final int? filterLifePercentage;

  const ApplianceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.brand,
    required this.modelNumber,
    this.serialNumber,
    this.purchaseDate,
    required this.maintenanceType,
    required this.nextMaintenanceDate,
    required this.status,
    required this.icon,
    required this.iconBackgroundColor,
    this.description,
    this.warrantyProvider,
    this.warrantyExpiry,
    this.filterLifePercentage,
  });

  /// Sample mock appliances matching the project requirements & reference screenshots
  static List<ApplianceItem> get sampleAppliances => [
    const ApplianceItem(
      id: 'app_1',
      name: 'Samsung Refrigerator',
      category: 'KITCHEN',
      brand: 'Samsung',
      modelNumber: 'RF28R7351SG',
      purchaseDate: 'Oct 12, 2022',
      maintenanceType: 'Next Service',
      nextMaintenanceDate: 'Oct 15, 2024',
      status: 'Active',
      icon: Icons.kitchen_rounded,
      iconBackgroundColor: Color(0xFFEEF2FF),
      description: 'Samsung Family Hub 4-Door French Door',
      warrantyProvider: 'Samsung Extended Care',
      warrantyExpiry: 'Oct 12, 2025 (1y 6m left)',
      filterLifePercentage: 24,
    ),
    const ApplianceItem(
      id: 'app_2',
      name: 'Bedroom AC',
      category: 'COOLING',
      brand: 'Daikin',
      modelNumber: 'Daikin FTKA35',
      purchaseDate: 'May 10, 2023',
      maintenanceType: 'Next Filter Clean',
      nextMaintenanceDate: 'Nov 01, 2024',
      status: 'Active',
      icon: Icons.ac_unit_rounded,
      iconBackgroundColor: Color(0xFFE0F2FE),
      description: 'Daikin Inverter Split Air Conditioner 1.5 Ton',
      warrantyProvider: 'Daikin Protect',
      warrantyExpiry: 'May 10, 2025',
      filterLifePercentage: 75,
    ),
    const ApplianceItem(
      id: 'app_3',
      name: 'Washing Machine',
      category: 'LAUNDRY',
      brand: 'LG',
      modelNumber: 'LG WM4000HWA',
      purchaseDate: 'Jan 20, 2022',
      maintenanceType: 'Next Tub Clean',
      nextMaintenanceDate: 'Dec 10, 2024',
      status: 'Expiring',
      icon: Icons.local_laundry_service_rounded,
      iconBackgroundColor: Color(0xFFEFF6FF),
      description: 'LG Front Load Washer with TurboWash',
      warrantyProvider: 'LG Care Shield',
      warrantyExpiry: 'Dec 20, 2024 (Expiring soon)',
      filterLifePercentage: 40,
    ),
  ];
}

/// Maintenance task item for Appliance Details
class MaintenanceTask {
  final String id;
  final String title;
  final String description;
  final String timeBadge; // e.g. "In 2 weeks", "Oct 2024"
  final IconData icon;
  final bool isWaterFilter;
  final bool isCompleted;

  const MaintenanceTask({
    required this.id,
    required this.title,
    required this.description,
    required this.timeBadge,
    required this.icon,
    this.isWaterFilter = false,
    this.isCompleted = false,
  });
}
