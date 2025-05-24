import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/verses.dart';
import '../models/chapters.dart';
import '../providers/saved_verses_provider.dart';
import '../providers/verse_tracker_provider.dart';

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

int _leftSkipCount = 0;
int _rightSkipCount = 0;
int _lastLeftTapTime = 0;
int _lastRightTapTime = 0;

class _VerseScreenState extends State<VerseScreen> {
  late PageController _pageController;
  late List<PageItem> _pages;
  Map<String, String> _maxMullerTranslations = {};
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVerses();
  }

  Future<void> _loadVerses() async {
    final jsonString = await rootBundle.loadString('assets/verses.json');
    final maxMullerString = await rootBundle.loadString(
      'assets/max_muller.json',
    );

    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final Map<String, dynamic> mullerData = json.decode(maxMullerString);
    _maxMullerTranslations = mullerData.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    final allVerses = jsonData.entries
        .map((e) => Verse.fromJson(e.key, e.value))
        .toList();

    allVerses.sort((a, b) {
      if (a.chapter == b.chapter) {
        return int.parse(a.id).compareTo(int.parse(b.id));
      }
      return a.chapter.compareTo(b.chapter);
    });

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordIfVersePage(_currentIndex);
    });

    _pageController.addListener(() {
      final page = _pageController.page?.round();
      if (page != null && page != _currentIndex) {
        setState(() => _currentIndex = page);
        _recordIfVersePage(page);
      }
    });

    setState(() => _isLoading = false);
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

  Widget _buildPage(PageItem item) {
    if (item is VersePage) {
      final verse = item.verse;
      final maxMullerText = _maxMullerTranslations[verse.id];

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
            if (maxMullerText != null) ...[
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
                      maxMullerText,
                      textAlign: TextAlign.left,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Max Müller',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length,
                        itemBuilder: (context, index) =>
                            _buildPage(_pages[index]),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 60,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            final now = DateTime.now().millisecondsSinceEpoch;
                            if (now - _lastLeftTapTime < 500) {
                              _leftSkipCount++;
                            } else {
                              _leftSkipCount = 1;
                            }
                            _lastLeftTapTime = now;

                            final targetPage = (_currentIndex - _leftSkipCount)
                                .clamp(0, _pages.length - 1);
                            _pageController.jumpToPage(targetPage);
                            setState(() {
                              _currentIndex = targetPage;
                            });
                          },
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: 60,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            final now = DateTime.now().millisecondsSinceEpoch;
                            if (now - _lastRightTapTime < 500) {
                              _rightSkipCount++;
                            } else {
                              _rightSkipCount = 1;
                            }
                            _lastRightTapTime = now;

                            final targetPage = (_currentIndex + _rightSkipCount)
                                .clamp(0, _pages.length - 1);
                            _pageController.jumpToPage(targetPage);
                            setState(() {
                              _currentIndex = targetPage;
                            });
                          },
                        ),
                      ),
                    ],
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
