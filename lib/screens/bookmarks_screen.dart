import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chapters.dart';
import '../providers/bookmarks_provider.dart';
import '../providers/translations_provider.dart';
import 'verse_screen.dart';

class SavedVersesScreen extends StatelessWidget {
  final Map<int, Chapter> chapterMap;

  const SavedVersesScreen({super.key, required this.chapterMap});

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
    } catch (_) {
      firstTranslation = null;
    }

    final verseDataByTranslation = translationsProvider.verseDataByTranslation;

    return Scaffold(
      body: savedVerses.isEmpty
          ? const Center(child: Text('No saved verses.'))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: savedVerses.length + 1,
              separatorBuilder: (_, __) => Divider(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(51),
              ),
              itemBuilder: (context, index) {
                if (index == savedVerses.length) {
                  return const SizedBox(height: 80);
                }

                final verse = savedVerses[index];
                final verseId = int.tryParse(verse.id) ?? 0;

                String displayedText = verse.text;
                if (firstTranslation != null &&
                    verseDataByTranslation[firstTranslation] != null) {
                  displayedText =
                      verseDataByTranslation[firstTranslation]?[verse.id] ??
                      verse.text;
                }

                return ListTile(
                  title: Text(
                    displayedText,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: selectedTranslations.isEmpty ? 'Serif' : null,
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
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Verse $verseId',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                );
              },
            ),
    );
  }
}
