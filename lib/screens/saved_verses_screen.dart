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
                final verseId = int.tryParse(verse.id) ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Verse $verseId',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            verse.text,
                            style: const TextStyle(
                              fontFamily: 'Castoro',
                              fontWeight: FontWeight.w500,
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VerseScreen(
                              initialVerseId: verseId,
                              chapterMap: chapterMap,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
