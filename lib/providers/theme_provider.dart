import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app-wide appearance preference and persists it on this device.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider._(this._themeMode);

  static const String preferenceKey = 'theme_mode';

  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  static Future<ThemeProvider> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedValue = preferences.getString(preferenceKey);
    return ThemeProvider._(_modeFromValue(savedValue));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(preferenceKey, _valueFromMode(mode));
  }

  static ThemeMode _modeFromValue(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' || _ => ThemeMode.system,
    };
  }

  static String _valueFromMode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }
}
