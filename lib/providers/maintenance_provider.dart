import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/maintenance_model.dart';
import '../services/maintenance_service.dart';

class MaintenanceProvider extends ChangeNotifier {
  MaintenanceProvider({MaintenanceService? service})
      : _service = service ?? MaintenanceService();

  final MaintenanceService _service;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Stream<List<MaintenanceRecord>> getRecords(String userId) {
    return _service.getRecords(userId);
  }

  /// Alias used by DashboardScreen.
  Stream<List<MaintenanceRecord>> getUserMaintenanceRecords(String userId) {
    return _service.getRecords(userId);
  }

  Stream<MaintenanceRecord?> getRecordById(String recordId, String userId) {
    return _service.getRecordById(recordId, userId);
  }

  Future<MaintenanceRecord?> getRecordOnce(String recordId, String userId) {
    return _service.getRecordOnce(recordId, userId);
  }

  Future<List<String>?> uploadPhotos(
    List<Uint8List> bytes,
    List<String> names,
  ) async {
    try {
      return await _service.uploadPhotos(fileBytes: bytes, fileNames: names);
    } catch (error) {
      debugPrint('Maintenance photo upload error: $error');
      _errorMessage = 'Unable to upload photos. Please try again.';
      notifyListeners();
      return null;
    }
  }

  Future<bool> createRecord(MaintenanceRecord record) {
    return _run(() => _service.createRecord(record), 'Unable to save maintenance record. Please try again.');
  }

  Future<bool> updateRecord(MaintenanceRecord record) {
    return _run(() => _service.updateRecord(record), 'Unable to update maintenance record. Please try again.');
  }

  Future<bool> markCompleted({
    required String recordId,
    required DateTime completedDate,
    required String? notes,
    required String? cost,
    required String? serviceProvider,
    required List<String> photoUrls,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Future.value(false);
    return _run(
      () => _service.markCompleted(
        recordId: recordId,
        userId: user.uid,
        completedDate: completedDate,
        notes: notes,
        cost: cost,
        serviceProvider: serviceProvider,
        photoUrls: photoUrls,
      ),
      'Unable to mark maintenance as completed. Please try again.',
    );
  }

  Future<bool> deleteRecord(String recordId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Future.value(false);
    return _run(
      () => _service.deleteRecord(recordId, user.uid),
      'Unable to delete maintenance record. Please try again.',
    );
  }

  Future<bool> _run(Future<Object?> Function() action, String errorMessage) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await action();
      return true;
    } catch (error) {
      debugPrint('Maintenance operation error: $error');
      _errorMessage = errorMessage;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
