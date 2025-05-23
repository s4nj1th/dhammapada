import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chapters.dart';
import '../providers/saved_verses_provider.dart';
import 'verse_screen.dart';

class SavedVersesScreen extends StatelessWidget {
  final Map<int, Chapter> chapterMap;

  const SavedVersesScreen({super.key, required this.chapterMap});

  @override
  Widget build(BuildContext context) {
    final savedVerses = context.watch<SavedVersesProvider>().savedVerses;

    return Scaffold(
      body: savedVerses.isEmpty
          ? const Center(child: Text('No saved verses'))
          : ListView.builder(
              itemCount: savedVerses.length,
              itemBuilder: (context, index) {
                final verse = savedVerses[index];
                final chapterVerses = savedVerses
                    .where((v) => v.chapter == verse.chapter)
                    .toList();
                final initialIndex = chapterVerses.indexOf(verse);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${verse.id}. ',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Expanded(
                          child: Text(
                            verse.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Castoro',
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VerseScreen(
                            chapterId: verse.chapter,
                            initialIndex: initialIndex,
                            chapterMap: chapterMap,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
