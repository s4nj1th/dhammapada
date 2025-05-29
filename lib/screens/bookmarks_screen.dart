import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chapters.dart';
import '../providers/bookmarks_provider.dart';
import '../providers/translations_provider.dart';
import 'verse_screen.dart';

class SavedVersesScreen extends StatelessWidget {
  final Map<int, Chapter> chapterMap;

  const SavedVersesScreen({super.key, required this.chapterMap});

  int _calculateCrossAxisCount(double width) {
    return width > 600 ? 2 : 1;
  }

  @override
  Widget build(BuildContext context) {
    final savedVerses = context.watch<SavedVersesProvider>().savedVerses;
    final translationsProvider = context.watch<TranslationsProvider>();
    final selectedTranslations = translationsProvider.selectedTranslations;
    final translationOrder = translationsProvider.translationOrder;

    String? firstTranslation;
    try {
      firstTranslation = translationOrder.firstWhere(
        (code) => selectedTranslations.contains(code),
      );
    } catch (e) {
      firstTranslation = null;
    }

    final verseDataByTranslation = translationsProvider.verseDataByTranslation;

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
                        childAspectRatio: 3,
                      ),
                      itemBuilder: (context, index) {
                        final verse = savedVerses[index];
                        final verseId = int.tryParse(verse.id) ?? 0;

                        String displayedText = verse.text;
                        if (firstTranslation != null &&
                            verseDataByTranslation[firstTranslation] != null) {
                          displayedText =
                              verseDataByTranslation[firstTranslation]?[verse
                                  .id] ??
                              verse.text;
                        }

                        return GridTile(
                          child: Card(
                            margin: const EdgeInsets.all(2),
                            child: InkWell(
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
                              child: Center(
                                child: ListTile(
                                  title: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Text(
                                      displayedText,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: selectedTranslations.isEmpty
                                            ? 'Serif'
                                            : null,
                                        fontStyle: selectedTranslations.isEmpty
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                        fontWeight: selectedTranslations.isEmpty
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                      ),
                                      textAlign: selectedTranslations.isEmpty
                                          ? TextAlign.center
                                          : TextAlign.left,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Verse $verseId',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
                                      ),
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis,
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
