import 'package:flutter/material.dart';
import '../models/verses.dart';

class ChapterScreen extends StatelessWidget {
  final int chapter;
  final List<Verse> verses;

  const ChapterScreen({super.key, required this.chapter, required this.verses});

  @override
  Widget build(BuildContext context) {
    final chapterQuotes = verses.where((q) => q.chapter == chapter).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Chapter $chapter')),
      body: ListView.builder(
        itemCount: chapterQuotes.length,
        itemBuilder: (context, index) {
          final quote = chapterQuotes[index];
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              '${quote.id}. ${quote.text}',
              style: const TextStyle(fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}
