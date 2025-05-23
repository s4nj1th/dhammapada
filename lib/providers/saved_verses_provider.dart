import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/verses.dart';

class SavedVersesProvider extends ChangeNotifier {
  final List<Verse> _savedVerses = [];

  SavedVersesProvider() {
    _loadSavedVerses();
  }

  List<Verse> get savedVerses => List.unmodifiable(_savedVerses);

  bool isSaved(Verse verse) => _savedVerses.any((v) => v.id == verse.id);

  void toggleSave(Verse verse) {
    if (isSaved(verse)) {
      _savedVerses.removeWhere((v) => v.id == verse.id);
    } else {
      _savedVerses.add(verse);
    }
    _saveToStorage();
    notifyListeners();
  }

  void _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = jsonEncode(_savedVerses.map((v) => v.toJson()).toList());
    await prefs.setString('savedVerses', savedJson);
  }

  void _loadSavedVerses() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString('savedVerses');
    if (savedJson != null) {
      final List decoded = jsonDecode(savedJson);
      _savedVerses.clear();
      _savedVerses.addAll(decoded.map((v) => Verse.fromJsonMap(v)));
      notifyListeners();
    }
  }
}
