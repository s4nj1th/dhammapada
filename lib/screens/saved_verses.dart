import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/saved_verses_provider.dart';
import 'verse_screen.dart';

class SavedVersesScreen extends StatelessWidget {
  const SavedVersesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savedVerses = context.watch<SavedVersesProvider>().savedVerses;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Verses')),
      body: savedVerses.isEmpty
          ? const Center(child: Text('No saved verses'))
          : ListView.builder(
              itemCount: savedVerses.length,
              itemBuilder: (context, index) {
                final verse = savedVerses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${verse.id}. ',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(),
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
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VerseScreen(verse: verse),
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
