import 'package:flutter/material.dart';
import 'app_colors.dart';

/// HomiQ Theme Configuration
/// Enforces premium UI aesthetics, readability, and accessibility (HCI best practices).
class AppTheme {
  // Prevent instantiation
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.secondaryTeal,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.surface,
        onSecondary: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onError: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // Typography / Text Styling for Hierarchy & Readability
      textTheme: const TextTheme(
        // Screen Titles
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        // Section Titles
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        // Body Text
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
          height: 1.5, // Enhances line readability
        ),
        // Supporting / Captions / Small Text
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        // Button text
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      // Elevated Button Theme (Large Touch Targets & Clear States)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 50), // At least 48dp high target
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          disabledForegroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          minimumSize: const Size(double.infinity, 50), // At least 48dp high target
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text Fields (Clear Focus, Error, and Normal States with Large Padding)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2.0),
        ),
        labelStyle: const TextStyle(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
        hintStyle: const TextStyle(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
        errorStyle: const TextStyle(
          fontSize: 13,
          color: AppColors.error,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Card Theme (Soft visual separation and elevation)
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0, // Material 3 uses color/outline by default, but we enforce clear borders
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 6,
        shadowColor: const Color(0x1A0F172A), // 10% opacity of textPrimary
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
      ),

      // Bottom Navigation Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
