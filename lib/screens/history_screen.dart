import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/verses.dart';
import '../models/chapters.dart';
import '../providers/verse_tracker_provider.dart';
import 'verse_screen.dart';

class HistoryScreen extends StatefulWidget {
  final Map<int, Chapter> chapterMap;

  const HistoryScreen({super.key, required this.chapterMap});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Verse> _allVerses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVerses();
  }

  Future<void> _loadVerses() async {
    final jsonString = await rootBundle.loadString('assets/verses.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final allVerses = jsonData.entries
        .map((e) => Verse.fromJson(e.key, e.value))
        .toList();

    setState(() {
      _allVerses = allVerses;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = Provider.of<VerseTrackerProvider>(
      context,
    ).viewHistory.reversed.toList();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (history.isEmpty) {
      return const Center(child: Text("No history yet."));
    }

    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];

        String subtitleText;
        final verseCount = entry.verseIds.length;

        if (verseCount == 1) {
          subtitleText = 'Verse: ${entry.verseIds[0]}';
        } else if (verseCount == 2) {
          subtitleText = 'Verses: ${entry.verseIds[0]}, ${entry.verseIds[1]}';
        } else if (verseCount > 2) {
          subtitleText =
              'Verses: ${entry.verseIds[0]} to ${entry.verseIds.last}';
        } else {
          subtitleText = 'No verses';
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text('Chapter ${entry.chapterId}'),
            subtitle: Text(subtitleText),
            onTap: () {
              final chapterVerses = _allVerses
                  .where((v) => v.chapter == entry.chapterId)
                  .toList();

              final lastVerseId = entry.verseIds.isNotEmpty
                  ? entry.verseIds.last
                  : null;

              final initialIndex = lastVerseId != null
                  ? chapterVerses.indexWhere(
                      (v) => v.id == lastVerseId.toString(),
                    )
                  : 0;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VerseScreen(
                    chapterMap: widget.chapterMap,
                    initialVerseId: initialIndex + 1,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
