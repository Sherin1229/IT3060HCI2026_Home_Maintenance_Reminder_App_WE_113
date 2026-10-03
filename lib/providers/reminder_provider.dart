import 'package:flutter/material.dart';

import '../models/reminder_model.dart';
import '../services/reminder_service.dart';

class ReminderProvider extends ChangeNotifier {
  final ReminderService _reminderService = ReminderService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> createReminder(ReminderModel reminder) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _reminderService.createReminder(reminder);

      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Create reminder error: $e');
      _errorMessage = 'Unable to save reminder. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Stream<List<ReminderModel>> getReminders(String userId) {
    return _reminderService.getReminders(userId);
  }

  Stream<ReminderModel?> getReminderById(String reminderId, String userId) {
    return _reminderService.getReminderById(reminderId, userId);
  }

  Future<bool> updateReminder(ReminderModel reminder) async {
    return _runMutation(
      () => _reminderService.updateReminder(reminder),
      'Unable to update reminder. Please try again.',
    );
  }

  Future<bool> markReminderCompleted(String reminderId, String userId) async {
    return _runMutation(
      () => _reminderService.markReminderCompleted(reminderId, userId),
      'Unable to mark reminder as completed. Please try again.',
    );
  }

  Future<bool> deleteReminder(String reminderId, String userId) async {
    return _runMutation(
      () => _reminderService.deleteReminder(reminderId, userId),
      'Unable to delete reminder. Please try again.',
    );
  }

  Future<bool> _runMutation(
    Future<void> Function() action,
    String errorMessage,
  ) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await action();
      return true;
    } catch (error) {
      debugPrint('Reminder operation error: $error');
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
