import 'package:flutter/foundation.dart';

class VerseTrackerProvider with ChangeNotifier {
  List<HistoryEntry> _viewHistory = [];

  List<HistoryEntry> get viewHistory => List.unmodifiable(_viewHistory);

  int getLastViewed() {
    if (_viewHistory.isEmpty) return 1;
    return int.tryParse(_viewHistory.last.verseIds.last) ?? 1;
  }

  void recordVerseView(int chapterId, String verseId) {
    if (_viewHistory.isEmpty ||
        _viewHistory.last.chapterId != chapterId ||
        _viewHistory.last.verseIds.contains(verseId)) {
      _viewHistory.add(HistoryEntry(chapterId, [verseId]));
    } else {
      _viewHistory.last.verseIds.add(verseId);
    }
    notifyListeners();
  }

  void resetSessionHistory() {
    _viewHistory.clear();
    notifyListeners();
  }
}

class HistoryEntry {
  final int chapterId;
  final List<String> verseIds;

  HistoryEntry(this.chapterId, this.verseIds);
}
