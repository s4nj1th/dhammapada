import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationsProvider with ChangeNotifier {
  final Map<String, String> _allTranslations = {
    'max_muller': 'Max Müller',
    'woodwards': 'FL Woodwards',
    'thannisaro': 'Ṭhānissaro Bhikkhu',
  };

  static const _prefsSelectedKey = 'selected_translations';
  static const _prefsOrderKey = 'translation_order';

  List<String> _selectedTranslations = [];
  List<String> _translationOrder = [];
  bool _isInitialized = false;

  final Map<String, Map<String, String>> _verseDataByTranslation = {};

  bool get isInitialized => _isInitialized;
  Map<String, String> get allTranslations => _allTranslations;
  List<String> get selectedTranslations => _selectedTranslations;
  List<String> get translationOrder => _translationOrder;
  Map<String, Map<String, String>> get verseDataByTranslation =>
      _verseDataByTranslation;

  TranslationsProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadFromPrefs();
    await loadTranslationFiles();
    _isInitialized = true;
    notifyListeners();
  }

  void toggleTranslation(String code, bool isSelected) {
    if (isSelected) {
      if (!_selectedTranslations.contains(code)) {
        _selectedTranslations.add(code);
      }
    } else {
      _selectedTranslations.remove(code);
    }
    _saveToPrefs();
    notifyListeners();
  }

  void reorderTranslations(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = _translationOrder.removeAt(oldIndex);
    _translationOrder.insert(newIndex, item);
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    _selectedTranslations =
        prefs.getStringList(_prefsSelectedKey) ?? ['max_muller'];

    _translationOrder =
        prefs.getStringList(_prefsOrderKey) ?? _allTranslations.keys.toList();

    _selectedTranslations = _selectedTranslations
        .where(_allTranslations.containsKey)
        .toList();
    _translationOrder = _translationOrder
        .where(_allTranslations.containsKey)
        .toList();

    for (final key in _allTranslations.keys) {
      if (!_translationOrder.contains(key)) {
        _translationOrder.add(key);
      }
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsSelectedKey, _selectedTranslations);
    await prefs.setStringList(_prefsOrderKey, _translationOrder);
  }

  Future<void> loadTranslationFiles() async {
    for (final key in _selectedTranslations) {
      if (_verseDataByTranslation.containsKey(key)) continue;
      try {
        final data = await rootBundle.loadString(
          'assets/translations/$key.json',
        );
        final Map<String, dynamic> json = jsonDecode(data);
        _verseDataByTranslation[key] = json.map(
          (k, v) => MapEntry(k, v.toString()),
        );
      } catch (e) {
        debugPrint('Error loading translation $key: $e');
      }
    }
  }
}
