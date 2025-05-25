import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isAmoled = false;

  ThemeMode get themeMode => _themeMode;
  bool get isAmoled => _isAmoled;

  ThemeNotifier() {
    _loadTheme();
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _saveTheme();
    notifyListeners();
  }

  void toggleAmoled(bool value) {
    _isAmoled = value;
    _saveTheme();
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('isDarkTheme')) {
      final isDark = prefs.getBool('isDarkTheme') ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    _isAmoled = prefs.getBool('isAmoled') ?? false;

    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', _themeMode == ThemeMode.dark);
    await prefs.setBool('isAmoled', _isAmoled);
  }
}
