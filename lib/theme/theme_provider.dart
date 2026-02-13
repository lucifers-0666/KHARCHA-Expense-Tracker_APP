import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemePreference { light, dark, system }

class ThemeProvider with ChangeNotifier {
  ThemePreference _themePreference = ThemePreference.system;
  static const String _themeKey = 'theme_preference';

  ThemePreference get themePreference => _themePreference;

  ThemeProvider() {
    _loadThemePreference();
  }

  ThemeMode get themeMode {
    switch (_themePreference) {
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
      case ThemePreference.system:
        return ThemeMode.system;
    }
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);

    if (savedTheme != null) {
      _themePreference = ThemePreference.values.firstWhere(
        (e) => e.toString() == savedTheme,
        orElse: () => ThemePreference.system,
      );
      notifyListeners();
    }
  }

  Future<void> setThemePreference(ThemePreference preference) async {
    _themePreference = preference;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, preference.toString());
  }

  bool isDarkMode(BuildContext context) {
    if (_themePreference == ThemePreference.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themePreference == ThemePreference.dark;
  }
}
