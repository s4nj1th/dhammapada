import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LastViewed {
  final int chapterId;
  final String? verseId;

  LastViewed(this.chapterId, this.verseId);
}

class VerseTrackerProvider with ChangeNotifier {
  List<HistoryEntry> _viewHistory = [];

  VerseTrackerProvider() {
    _loadHistory();
  }

  List<HistoryEntry> get viewHistory => List.unmodifiable(_viewHistory);

  LastViewed? getLastViewed() {
    if (_viewHistory.isEmpty) return null;

    final lastEntry = _viewHistory.last;

    if (lastEntry.isDivider) {
      return LastViewed(lastEntry.chapterId, null);
    }

    final lastVerse = lastEntry.verseIds.isNotEmpty
        ? lastEntry.verseIds.last
        : null;
    return LastViewed(lastEntry.chapterId, lastVerse);
  }

  void recordVerseView(int chapterId, String verseId) {
    _viewHistory.add(HistoryEntry(chapterId, [verseId]));
    _saveHistory();
    notifyListeners();
  }

  void resetSessionHistory() {
    _viewHistory.clear();
    _saveHistory();
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(
      _viewHistory.map((entry) => entry.toJson()).toList(),
    );
    await prefs.setString('viewHistory', historyJson);
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('viewHistory');
    if (historyJson != null) {
      final decoded = jsonDecode(historyJson) as List;
      _viewHistory = decoded
          .map((entry) => HistoryEntry.fromJson(entry))
          .toList();
      notifyListeners();
    }
  }
}

class HistoryEntry {
  final int chapterId;
  final List<String> verseIds;
  final bool isDivider;

  HistoryEntry(this.chapterId, this.verseIds, {this.isDivider = false});

  Map<String, dynamic> toJson() => {
    'chapterId': chapterId,
    'verseIds': verseIds,
    'isDivider': isDivider,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      json['chapterId'] as int,
      List<String>.from(json['verseIds']),
      isDivider: json['isDivider'] ?? false,
    );
  }
}
