import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/appliance_model.dart';
import '../services/appliance_service.dart';

class ApplianceProvider extends ChangeNotifier {
  final ApplianceService _applianceService = ApplianceService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Stream<List<ApplianceModel>> getUserAppliances(String userId) {
    return _applianceService.getUserAppliances(userId);
  }

  Stream<ApplianceModel?> getApplianceById(String applianceId) {
    return _applianceService.getApplianceById(applianceId);
  }

  Future<String?> uploadPhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      return await _applianceService.uploadAppliancePhoto(
        bytes: bytes,
        fileName: fileName,
      );
    } catch (e) {
      debugPrint('Upload appliance photo error: $e');
      _errorMessage = 'Failed to upload appliance photo.';
      return null;
    }
  }

  Future<bool> createAppliance({
    required String userId,
    required String applianceName,
    required String category,
    required String brand,
    required DateTime purchaseDate,
    required String modelNumber,
    String? serialNumber,
    String? photoUrl,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _applianceService.createAppliance(
        userId: userId,
        applianceName: applianceName,
        category: category,
        brand: brand,
        purchaseDate: purchaseDate,
        modelNumber: modelNumber,
        serialNumber: serialNumber,
        photoUrl: photoUrl,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Create appliance error: $e');
      _errorMessage = 'Unable to save appliance. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateAppliance({
    required String applianceId,
    required String userId,
    required String applianceName,
    required String category,
    required String brand,
    required DateTime purchaseDate,
    required String modelNumber,
    String? serialNumber,
    String? photoUrl,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _applianceService.updateAppliance(
        applianceId: applianceId,
        userId: userId,
        applianceName: applianceName,
        category: category,
        brand: brand,
        purchaseDate: purchaseDate,
        modelNumber: modelNumber,
        serialNumber: serialNumber,
        photoUrl: photoUrl,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Update appliance error: $e');
      _errorMessage = 'Unable to update appliance. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteAppliance({
    required String applianceId,
    required String userId,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _applianceService.deleteAppliance(
        applianceId: applianceId,
        userId: userId,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Delete appliance error: $e');
      _errorMessage = 'Unable to delete appliance. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
