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

  // Dark-mode neutrals. Brand and semantic colors remain shared.
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF111C2E);
  static const Color darkSurfaceVariant = Color(0xFF18263A);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkBorder = Color(0xFF334155);

  // Feedback/Status Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color neutralSurface(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;

  static Color blueSurface(BuildContext context) =>
      Theme.of(context).colorScheme.primaryContainer;

  static Color tealSurface(BuildContext context) =>
      Theme.of(context).colorScheme.secondaryContainer;

  static Color successSurface(BuildContext context) =>
      _isDark(context) ? const Color(0xFF123D2A) : const Color(0xFFDCFCE7);

  static Color warningSurface(BuildContext context) =>
      _isDark(context) ? const Color(0xFF4A2B12) : const Color(0xFFFFF7ED);

  static Color warningSurfaceStrong(BuildContext context) =>
      _isDark(context) ? const Color(0xFF5B3412) : const Color(0xFFFFEDD5);

  static Color errorSurface(BuildContext context) =>
      Theme.of(context).colorScheme.errorContainer;

  static Color subtleSurface(BuildContext context) =>
      _isDark(context) ? darkSurfaceVariant : const Color(0xFFF8FBFF);

  static Color primaryOutline(BuildContext context) =>
      _isDark(context) ? const Color(0xFF60A5FA) : const Color(0xFFBFDBFE);

  static Color warningOutline(BuildContext context) =>
      _isDark(context) ? const Color(0xFF9A5B24) : const Color(0xFFFED7AA);

  static Color errorOutline(BuildContext context) =>
      _isDark(context) ? const Color(0xFFB94A55) : const Color(0xFFFCA5A5);

  static Color successText(BuildContext context) =>
      _isDark(context) ? const Color(0xFF4ADE80) : success;

  static Color warningText(BuildContext context) =>
      _isDark(context) ? const Color(0xFFFDBA74) : const Color(0xFFC2410C);

  static Color errorText(BuildContext context) =>
      Theme.of(context).colorScheme.error;
}
