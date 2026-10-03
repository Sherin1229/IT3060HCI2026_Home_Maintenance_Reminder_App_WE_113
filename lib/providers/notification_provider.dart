import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../models/notification_settings_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  bool _isSaving = false;
  String? _errorMessage;

  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _service.getNotifications(userId);
  }

  Stream<NotificationSettingsModel> getSettings(String userId) {
    return _service.getSettings(userId);
  }

  Future<bool> markAsRead(String notificationId, String userId) {
    return _run(
      () => _service.markAsRead(notificationId, userId),
      'Unable to update notification. Please try again.',
    );
  }

  Future<bool> saveSettings(String userId, NotificationSettingsModel settings) {
    return _run(
      () => _service.saveSettings(userId, settings),
      'Unable to save notification settings. Please try again.',
    );
  }

  Future<bool> _run(Future<void> Function() action, String errorMessage) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      debugPrint('Notification operation error: $error');
      _errorMessage = errorMessage;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
