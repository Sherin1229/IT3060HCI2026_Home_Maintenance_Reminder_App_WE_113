import 'package:flutter/material.dart';

/// HomiQ HCI Color Theme Configuration
/// Centralized palette to ensure consistency across the application.
class AppColors {
  // Prevent instantiation
  AppColors._();

  // Primary Colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color secondaryTeal = Color(0xFF14B8A6);

  // Background and Surface Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  // Border and Divider Colors
  static const Color border = Color(0xFFE2E8F0);

  // Feedback/Status Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
}
