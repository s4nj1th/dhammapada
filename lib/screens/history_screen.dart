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
    final rawVerseIds = Provider.of<VerseTrackerProvider>(context).viewHistory
        .expand((entry) => entry.verseIds)
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toList();

    if (rawVerseIds.isEmpty) {
      return const Center(child: Text("No history yet."));
    }

    final List<List<int>> grouped = [];
    for (final id in rawVerseIds) {
      if (grouped.isEmpty || id != grouped.last.last + 1) {
        grouped.add([id]);
      } else {
        grouped.last.add(id);
      }
    }

    final reversedGrouped = grouped.reversed.toList();

    return ListView.builder(
      itemCount: reversedGrouped.length,
      itemBuilder: (context, index) {
        final group = reversedGrouped[index];
        final start = group.first;
        final end = group.last;
        final title = start == end ? 'Verse: $start' : 'Verses: $start to $end';

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(title, textAlign: TextAlign.center),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VerseScreen(
                        chapterMap: chapterMap,
                        initialVerseId: end,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
