import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Firestore Appliance Model for HomiQ
class ApplianceModel {
  final String id;
  final String userId;
  final String applianceName;
  final String category;
  final String brand;
  final DateTime purchaseDate;
  final String modelNumber;
  final String? serialNumber;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ApplianceModel({
    required this.id,
    required this.userId,
    required this.applianceName,
    required this.category,
    required this.brand,
    required this.purchaseDate,
    required this.modelNumber,
    this.serialNumber,
    this.photoUrl,
    required this.createdAt,
    this.updatedAt,
  });

  /// Map for creating a new document in Firestore
  Map<String, dynamic> toCreateMap() {
    return {
      'userId': userId,
      'applianceName': applianceName.trim(),
      'category': category.trim(),
      'brand': brand.trim(),
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'modelNumber': modelNumber.trim(),
      'serialNumber': serialNumber?.trim(),
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Map for updating an existing document in Firestore
  Map<String, dynamic> toUpdateMap() {
    return {
      'applianceName': applianceName.trim(),
      'category': category.trim(),
      'brand': brand.trim(),
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'modelNumber': modelNumber.trim(),
      'serialNumber': serialNumber?.trim(),
      if (photoUrl != null) 'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Construct model from Firestore document map
  factory ApplianceModel.fromMap(String id, Map<String, dynamic> map) {
    return ApplianceModel(
      id: id,
      userId: map['userId']?.toString() ?? '',
      applianceName: map['applianceName']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Other',
      brand: map['brand']?.toString() ?? '',
      purchaseDate: _dateFrom(map['purchaseDate']) ?? DateTime.now(),
      modelNumber: map['modelNumber']?.toString() ?? '',
      serialNumber: _stringOrNull(map['serialNumber']),
      photoUrl: _stringOrNull(map['photoUrl']),
      createdAt: _dateFrom(map['createdAt']) ?? DateTime.now(),
      updatedAt: _dateFrom(map['updatedAt']),
    );
  }

  static String? _stringOrNull(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  /// Category Icon helper matching project visual guidelines
  IconData get categoryIcon {
    final cat = category.toLowerCase();
    if (cat.contains('refrigerator') || cat.contains('fridge')) {
      return Icons.kitchen_rounded;
    }
    if (cat.contains('ac') || cat.contains('air')) {
      return Icons.ac_unit_rounded;
    }
    if (cat.contains('washing') || cat.contains('laundry')) {
      return Icons.local_laundry_service_rounded;
    }
    if (cat.contains('tv') || cat.contains('television')) {
      return Icons.tv_rounded;
    }
    if (cat.contains('microwave') || cat.contains('oven')) {
      return Icons.microwave_rounded;
    }
    if (cat.contains('water') || cat.contains('heater')) {
      return Icons.water_drop_rounded;
    }
    if (cat.contains('dishwasher')) {
      return Icons.countertops_rounded;
    }
    return Icons.devices_other_rounded;
  }
}
