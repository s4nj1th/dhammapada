import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/verses.dart';
import '../models/chapters.dart';
import '../providers/saved_verses_provider.dart';
import '../providers/verse_tracker_provider.dart';
import '../providers/translations_provider.dart';

abstract class PageItem {}

class VersePage extends PageItem {
  final Verse verse;
  VersePage(this.verse);
}

class ChapterDivider extends PageItem {
  final Chapter chapter;
  ChapterDivider(this.chapter);
}

class VerseScreen extends StatefulWidget {
  final int initialVerseId;
  final int? initialChapterId;
  final Map<int, Chapter> chapterMap;

  const VerseScreen({
    super.key,
    required this.initialVerseId,
    required this.chapterMap,
    this.initialChapterId,
  });

  @override
  State<VerseScreen> createState() => _VerseScreenState();
}

class _VerseScreenState extends State<VerseScreen> {
  late PageController _pageController;
  late List<PageItem> _pages;
  Map<String, Map<String, String>> _translationsByKey = {};
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVerses();
  }

  Future<void> _loadVerses() async {
    final provider = Provider.of<TranslationsProvider>(context, listen: false);
    final selectedTranslations = provider.selectedTranslations;

    final jsonString = await rootBundle.loadString('assets/verses.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final allVerses = jsonData.entries
        .map((e) => Verse.fromJson(e.key, e.value))
        .toList();

    allVerses.sort((a, b) {
      if (a.chapter == b.chapter) {
        return int.parse(a.id).compareTo(int.parse(b.id));
      }
      return a.chapter.compareTo(b.chapter);
    });

    final pages = <PageItem>[];
    int? lastChapter;
    for (final verse in allVerses) {
      if (verse.chapter != lastChapter) {
        final chapter = widget.chapterMap[verse.chapter];
        if (chapter != null) {
          pages.add(ChapterDivider(chapter));
        }
        lastChapter = verse.chapter;
      }
      pages.add(VersePage(verse));
    }

    final Map<String, Map<String, String>> translations = {};
    for (final key in selectedTranslations) {
      final data = await rootBundle.loadString('assets/$key.json');
      final Map<String, dynamic> map = json.decode(data);
      translations[key] = map.map((k, v) => MapEntry(k, v.toString()));
    }

    if (!mounted) return;

    setState(() {
      _pages = pages;
      _translationsByKey = translations;

      _currentIndex = widget.initialChapterId != null
          ? _pages.indexWhere(
              (item) =>
                  item is ChapterDivider &&
                  item.chapter.id == widget.initialChapterId,
            )
          : _pages.indexWhere(
              (item) =>
                  item is VersePage &&
                  int.parse(item.verse.id) == widget.initialVerseId,
            );

      if (_currentIndex == -1) _currentIndex = 0;

      _pageController = PageController(initialPage: _currentIndex);
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordIfVersePage(_currentIndex);
    });

    _pageController.addListener(() {
      final page = _pageController.page?.round();
      if (page != null && page != _currentIndex && mounted) {
        setState(() => _currentIndex = page);
        _recordIfVersePage(page);
      }
    });
  }

  void _recordIfVersePage(int pageIndex) {
    final currentItem = _pages[pageIndex];
    if (currentItem is VersePage) {
      Provider.of<VerseTrackerProvider>(
        context,
        listen: false,
      ).recordVerseView(currentItem.verse.chapter, currentItem.verse.id);
    }
  }

  List<Widget> _buildTranslations(String verseId) {
    final provider = Provider.of<TranslationsProvider>(context, listen: false);
    final widgets = <Widget>[];

    for (final key in provider.selectedTranslations) {
      final text = _translationsByKey[key]?[verseId];
      if (text != null) {
        widgets.addAll([
          const SizedBox(height: 20),
          const Divider(thickness: 1),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  text,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  _getTranslatorName(key),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ]);
      }
    }

    return widgets;
  }

  String _getTranslatorName(String key) {
    final provider = Provider.of<TranslationsProvider>(context, listen: false);
    return provider.allTranslations[key] ?? key;
  }

  Widget _buildPage(PageItem item) {
    if (item is VersePage) {
      final verse = item.verse;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              verse.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontFamily: 'Castoro',
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
            ..._buildTranslations(verse.id),
          ],
        ),
      );
    } else if (item is ChapterDivider) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'Chapter ${item.chapter.id}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.chapter.pali,
            style: const TextStyle(
              fontSize: 28,
              fontFamily: 'Castoro',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            item.chapter.english,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savedProvider = Provider.of<SavedVersesProvider>(context);
    final currentItem = !_isLoading && _pages.isNotEmpty
        ? _pages[_currentIndex]
        : null;
    final currentVerse = currentItem is VersePage ? currentItem.verse : null;
    final isSaved = currentVerse != null && savedProvider.isSaved(currentVerse);

    return Scaffold(
      appBar: AppBar(
        title: currentVerse != null
            ? Text('Verse ${currentVerse.id}')
            : const Text(''),
        centerTitle: true,
        actions: currentVerse != null
            ? [
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    size: 28,
                  ),
                  onPressed: () {
                    savedProvider.toggleSave(currentVerse);
                  },
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) => _buildPage(_pages[index]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Slider(
                    min: 0,
                    max: (_pages.length - 1).toDouble(),
                    value: _currentIndex.toDouble(),
                    label: currentVerse != null
                        ? 'Verse ${currentVerse.id}'
                        : '',
                    onChanged: (value) {
                      final newIndex = value.round();
                      _pageController.jumpToPage(newIndex);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
