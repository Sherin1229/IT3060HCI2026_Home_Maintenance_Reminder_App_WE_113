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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
