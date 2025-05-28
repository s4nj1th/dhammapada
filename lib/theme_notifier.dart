import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isAmoled = false;
  bool _useSystemFont = false;
  bool _sepiaMode = false;

  ThemeMode get themeMode => _themeMode;
  bool get isAmoled => _isAmoled;
  bool get useSystemFont => _useSystemFont;
  bool get sepiaMode => _sepiaMode;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('themeMode') ?? 'system';
    _themeMode = ThemeMode.values.firstWhere((e) => e.name == theme);
    _isAmoled = prefs.getBool('isAmoled') ?? false;
    _useSystemFont = prefs.getBool('useSystemFont') ?? true;
    _sepiaMode = prefs.getBool('sepiaMode') ?? false;
    notifyListeners();
  }

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _themeMode.name);
    notifyListeners();
  }

  void toggleAmoled(bool val) async {
    _isAmoled = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAmoled', _isAmoled);
    notifyListeners();
  }

  void toggleFont(bool useSystem) async {
    _useSystemFont = useSystem;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useSystemFont', _useSystemFont);
    notifyListeners();
  }

  void toggleSepia(bool mode) async {
    _sepiaMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sepiaMode', mode);
    notifyListeners();
  }
}
