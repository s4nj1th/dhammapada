import 'package:flutter/foundation.dart';

class VerseTrackerProvider with ChangeNotifier {
  List<HistoryEntry> _viewHistory = [];

  List<HistoryEntry> get viewHistory => List.unmodifiable(_viewHistory);

  int getLastViewed(int chapterId) {
    for (var i = _viewHistory.length - 1; i >= 0; i--) {
      final entry = _viewHistory[i];
      if (entry.chapterId == chapterId && entry.verseIds.isNotEmpty) {
        return int.tryParse(entry.verseIds.last) ?? 1;
      }
    }
    return 1;
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
