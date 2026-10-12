import 'package:flutter/material.dart';

abstract final class ComponentValidators {
  static String? requiredText(
    String? value, {
    required String field,
    int? minLength,
    int? maxLength,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter $field.';
    if (minLength != null && text.length < minLength) {
      return '$field must be at least $minLength characters.';
    }
    if (maxLength != null && text.length > maxLength) {
      return '$field must be $maxLength characters or less.';
    }
    return null;
  }

  static String? optionalText(
    String? value, {
    required String field,
    required int maxLength,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length > maxLength) {
      return '$field must be $maxLength characters or less.';
    }
    return null;
  }

  static String? purchaseDate(DateTime? date) {
    if (date == null) return 'Purchase date is required';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);
    if (selected.isAfter(today)) {
      return 'Purchase date cannot be in the future.';
    }
    return null;
  }

  static String? warrantyEndDate(DateTime? start, DateTime? end) {
    if (end == null) return 'Please select a warranty end date.';
    if (start != null && !end.isAfter(start)) {
      return 'Warranty end date must be after the start date.';
    }
    return null;
  }

  static DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static String? futureReminder(
    DateTime date,
    TimeOfDay time, {
    DateTime? now,
  }) {
    final scheduled = combineDateAndTime(date, time);
    if (!scheduled.isAfter(now ?? DateTime.now())) {
      return 'Reminder time must be in the future.';
    }
    return null;
  }

  static String? cost(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final amount = double.tryParse(text);
    if (amount == null || !amount.isFinite) return 'Enter a valid cost.';
    if (amount < 0) return 'Cost cannot be negative.';
    if (amount > 100000000) {
      return 'Cost cannot exceed 100000000.';
    }
    return null;
  }
}
