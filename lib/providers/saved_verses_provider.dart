import 'package:flutter/material.dart';
import '../../models/verses.dart';

class SavedVersesProvider extends ChangeNotifier {
  final List<Verse> _savedVerses = [];

  List<Verse> get savedVerses => _savedVerses;

  bool isSaved(Verse verse) => _savedVerses.any((v) => v.id == verse.id);

  void toggleSave(Verse verse) {
    if (isSaved(verse)) {
      _savedVerses.removeWhere((v) => v.id == verse.id);
    } else {
      _savedVerses.add(verse);
    }
    notifyListeners();
  }
}
