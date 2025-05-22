import 'package:flutter/material.dart';
import '../models/verses.dart';
import '../models/chapters.dart';

class ChapterScreen extends StatelessWidget {
  final int chapter;
  final List<Verse> verses;
  final Chapter chapterName;

  const ChapterScreen({
    super.key,
    required this.chapter,
    required this.verses,
    required this.chapterName,
  });

  @override
  Widget build(BuildContext context) {
    final chapterVerses = verses
        .where((verse) => verse.chapter == chapter)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${chapterName.pali} - ${chapterName.english}'),
      ),
      body: ListView.builder(
        itemCount: chapterVerses.length,
        itemBuilder: (context, index) {
          final verse = chapterVerses[index];
          return ListTile(title: Text('${verse.id}. ${verse.text}'));
        },
      ),
    );
  }
}
