import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chapters.dart';
import '../providers/verse_tracker_provider.dart';
import 'verse_screen.dart';

class HistoryScreen extends StatelessWidget {
  final Map<int, Chapter> chapterMap;

  const HistoryScreen({super.key, required this.chapterMap});

  @override
  Widget build(BuildContext context) {
    final rawHistory = Provider.of<VerseTrackerProvider>(context).viewHistory
        .expand(
          (entry) => entry.verseIds.map(
            (id) => _VerseView(entry.chapterId, int.tryParse(id)),
          ),
        )
        .where((v) => v.verseId != null)
        .toList();

    if (rawHistory.isEmpty) {
      return const Center(child: Text("No history yet."));
    }

    // Sort and group contiguous verses
    rawHistory.sort((a, b) {
      int cmp = a.chapterId.compareTo(b.chapterId);
      return cmp != 0 ? cmp : a.verseId!.compareTo(b.verseId!);
    });

    final List<_GroupedEntry> grouped = [];
    for (final view in rawHistory) {
      if (grouped.isEmpty ||
          grouped.last.chapterId != view.chapterId ||
          view.verseId! != grouped.last.verseIds.last + 1) {
        grouped.add(_GroupedEntry(view.chapterId, [view.verseId!]));
      } else {
        grouped.last.verseIds.add(view.verseId!);
      }
    }

    final reversedGrouped = grouped.reversed.toList();

    return ListView.builder(
      itemCount: reversedGrouped.length,
      itemBuilder: (context, index) {
        final group = reversedGrouped[index];
        final start = group.verseIds.first;
        final end = group.verseIds.last;
        final subtitle = start == end
            ? 'Verse: $start'
            : 'Verses: $start to $end';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text('Chapter ${group.chapterId}'),
            subtitle: Text(subtitle),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VerseScreen(
                    chapterMap: chapterMap,
                    // initialChapterId: group.chapterId,
                    initialVerseId: end,
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

class _VerseView {
  final int chapterId;
  final int? verseId;

  _VerseView(this.chapterId, this.verseId);
}

class _GroupedEntry {
  final int chapterId;
  final List<int> verseIds;

  _GroupedEntry(this.chapterId, this.verseIds);
}
