import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationsProvider with ChangeNotifier {
  final Map<String, String> _allTranslations = {
    'max_muller': 'Max Müller',
    'woodwards': 'FL Woodwards',
  };

  static const _prefsSelectedKey = 'selected_translations';
  static const _prefsOrderKey = 'translation_order';

  List<String> _selectedTranslations = [];
  List<String> _translationOrder = [];

  TranslationsProvider() {
    _loadFromPrefs();
  }

  Map<String, String> get allTranslations => _allTranslations;

  List<String> get selectedTranslations => _selectedTranslations;

  List<String> get translationOrder => _translationOrder;

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

    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsSelectedKey, _selectedTranslations);
    await prefs.setStringList(_prefsOrderKey, _translationOrder);
  }
}
