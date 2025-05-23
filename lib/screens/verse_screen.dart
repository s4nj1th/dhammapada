import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/verses.dart';
import '../models/chapters.dart';
import '../providers/saved_verses_provider.dart';
import '../providers/verse_tracker_provider.dart';

// Abstract base class for pages (either verse or chapter divider)
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
  final Map<int, Chapter> chapterMap;

  const VerseScreen({
    super.key,
    required this.initialVerseId,
    required this.chapterMap,
  });

  @override
  State<VerseScreen> createState() => _VerseScreenState();
}

class _VerseScreenState extends State<VerseScreen> {
  late PageController _pageController;
  late List<PageItem> _pages;
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVerses();
  }

  Future<void> _loadVerses() async {
    final jsonString = await rootBundle.loadString('assets/verses.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final allVerses = jsonData.entries
        .map((e) => Verse.fromJson(e.key, e.value))
        .toList();

    // Sort verses to ensure correct order
    allVerses.sort((a, b) {
      if (a.chapter == b.chapter) {
        return int.parse(a.id).compareTo(int.parse(b.id));
      }
      return a.chapter.compareTo(b.chapter);
    });

    // Build pages list with chapter dividers
    _pages = [];
    int? lastChapter;
    for (final verse in allVerses) {
      if (verse.chapter != lastChapter) {
        final chapter = widget.chapterMap[verse.chapter];
        if (chapter != null) {
          _pages.add(ChapterDivider(chapter));
        }
        lastChapter = verse.chapter;
      }
      _pages.add(VersePage(verse));
    }

    _currentIndex = _pages.indexWhere(
      (item) =>
          item is VersePage &&
          int.parse(item.verse.id) == widget.initialVerseId,
    );
    if (_currentIndex == -1) _currentIndex = 0;

    _pageController = PageController(initialPage: _currentIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentItem = _pages[_currentIndex];
      if (currentItem is VersePage) {
        Provider.of<VerseTrackerProvider>(
          context,
          listen: false,
        ).recordVerseView(currentItem.verse.chapter, currentItem.verse.id);
      }
    });

    _pageController.addListener(() {
      final page = _pageController.page?.round();
      if (page != null && page != _currentIndex) {
        setState(() => _currentIndex = page);
        final currentItem = _pages[page];
        if (currentItem is VersePage) {
          Provider.of<VerseTrackerProvider>(
            context,
            listen: false,
          ).recordVerseView(currentItem.verse.chapter, currentItem.verse.id);
        }
      }
    });

    setState(() => _isLoading = false);
  }

  Widget _buildPage(PageItem item) {
    if (item is VersePage) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          item.verse.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontFamily: 'Castoro',
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else if (item is ChapterDivider) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Chapter ${item.chapter.id}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.chapter.pali, // assuming this is the Pali name
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
        ),
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
                    color: isSaved ? Colors.amberAccent : Colors.white,
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
