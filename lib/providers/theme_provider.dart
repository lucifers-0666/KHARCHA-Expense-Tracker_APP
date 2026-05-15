import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ThemeProvider — persists dark mode preference via SharedPreferences.
/// Consumed via Provider.of<ThemeProvider>(context) everywhere.
class ThemeProvider extends ChangeNotifier {
  bool _isDark;

  ThemeProvider({bool initialDark = false}) : _isDark = initialDark;

  bool get isDark => _isDark;

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  Future<void> toggle() => setDark(!_isDark);
}
