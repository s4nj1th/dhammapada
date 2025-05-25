import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chapters.dart';
import '../providers/saved_verses_provider.dart';
import 'verse_screen.dart';

class SavedVersesScreen extends StatelessWidget {
  final Map<int, Chapter> chapterMap;

  const SavedVersesScreen({super.key, required this.chapterMap});

  int _calculateCrossAxisCount(double width) {
    // If width > 600, use 2 columns, else 1
    return width > 600 ? 2 : 1;
  }

  @override
  Widget build(BuildContext context) {
    final savedVerses = context.watch<SavedVersesProvider>().savedVerses;

    return Scaffold(
      body: savedVerses.isEmpty
          ? const Center(child: Text('No saved verses.'))
          : LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = _calculateCrossAxisCount(
                  constraints.maxWidth,
                );

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      // Limit the max width so 2 columns don't stretch too wide
                      maxWidth: crossAxisCount == 2 ? 800 : double.infinity,
                    ),
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      itemCount: savedVerses.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 3, // wide cards, adjust as needed
                      ),
                      itemBuilder: (context, index) {
                        final verse = savedVerses[index];
                        final verseId = int.tryParse(verse.id) ?? 0;

                        return GestureDetector(
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
                          child: SizedBox(
                            height:
                                200, // fixed height for the card so grid knows how tall it is
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Verse $verseId',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.outline,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          verse.text,
                                          style: const TextStyle(
                                            fontFamily: 'Castoro',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 18,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
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
