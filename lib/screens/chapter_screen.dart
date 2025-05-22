import 'package:flutter/material.dart';
import '../models/verses.dart';
import '../models/chapters.dart';
import 'verse_screen.dart';

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

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${verse.id}. ',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(),
                  ),
                  Expanded(
                    child: Text(
                      verse.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Castoro',
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VerseScreen(verse: verse)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
