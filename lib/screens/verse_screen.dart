import 'dart:async';
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
  late List<PageItem> _pages = [];
  Map<String, Map<String, String>> _translationsByKey = {};
  int _currentIndex = 0;
  bool _isLoading = true;

  double _sliderOpacity = 0.0;
  Timer? _hideSliderTimer;

  int _leftSkipCount = 0;
  int _rightSkipCount = 0;
  int _lastLeftTapTime = 0;
  int _lastRightTapTime = 0;

  @override
  void initState() {
    super.initState();
    _loadVerses();
  }

  void _resetSliderFadeTimer() {
    _hideSliderTimer?.cancel();
    setState(() => _sliderOpacity = 1.0);

    _hideSliderTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _sliderOpacity = 0.0);
    });
  }

  Future<void> _loadVerses() async {
    final provider = context.read<TranslationsProvider>();
    final selectedTranslations = provider.selectedTranslations.toSet();
    final translationOrder = provider.translationOrder;

    final jsonString = await rootBundle.loadString('assets/verses.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    final allVerses =
        jsonData.entries.map((e) => Verse.fromJson(e.key, e.value)).toList()
          ..sort((a, b) {
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
        if (chapter != null) pages.add(ChapterDivider(chapter));
        lastChapter = verse.chapter;
      }
      pages.add(VersePage(verse));
    }

    final translations = <String, Map<String, String>>{};
    for (final key in translationOrder) {
      if (!selectedTranslations.contains(key)) continue;

      final data = await rootBundle.loadString('assets/$key.json');
      final Map<String, dynamic> map = json.decode(data);
      translations[key] = map.map((k, v) => MapEntry(k, v.toString()));
    }

    if (!mounted) return;

    setState(() {
      _pages = pages;
      _translationsByKey = translations;
      _currentIndex = _getInitialPageIndex();
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
        _resetSliderFadeTimer();
      }
    });
  }

  int _getInitialPageIndex() {
    if (widget.initialChapterId != null) {
      final idx = _pages.indexWhere(
        (item) =>
            item is ChapterDivider &&
            item.chapter.id == widget.initialChapterId,
      );
      if (idx != -1) return idx;
    }
    final idx = _pages.indexWhere(
      (item) =>
          item is VersePage &&
          int.parse(item.verse.id) == widget.initialVerseId,
    );
    return idx != -1 ? idx : 0;
  }

  void _recordIfVersePage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _pages.length) return;
    final currentItem = _pages[pageIndex];
    if (currentItem is VersePage) {
      context.read<VerseTrackerProvider>().recordVerseView(
        currentItem.verse.chapter,
        currentItem.verse.id,
      );
    }
  }

  List<Widget> _buildTranslations(String verseId) {
    final provider = context.read<TranslationsProvider>();
    final selectedTranslations = provider.selectedTranslations.toSet();
    final translationOrder = provider.translationOrder;

    final widgets = <Widget>[];

    for (final key in translationOrder) {
      if (!selectedTranslations.contains(key)) continue;
      final text = _translationsByKey[key]?[verseId];
      if (text == null) continue;

      widgets.addAll([
        const SizedBox(height: 20),
        const Divider(thickness: 1),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
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
    return widgets;
  }

  String _getTranslatorName(String key) {
    final provider = context.read<TranslationsProvider>();
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
      final chapter = item.chapter;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Chapter ${chapter.id}', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            chapter.pali,
            style: const TextStyle(
              fontSize: 32,
              fontFamily: 'Castoro',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            chapter.english,
            style: const TextStyle(fontSize: 22),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  void _handleTapOnSide({required bool isLeft}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (isLeft) {
      if (now - _lastLeftTapTime < 500) {
        _leftSkipCount++;
      } else {
        _leftSkipCount = 1;
      }
      _lastLeftTapTime = now;

      final targetPage = (_currentIndex - _leftSkipCount).clamp(
        0,
        _pages.length - 1,
      );
      _pageController.jumpToPage(targetPage);
      setState(() => _currentIndex = targetPage);
    } else {
      if (now - _lastRightTapTime < 500) {
        _rightSkipCount++;
      } else {
        _rightSkipCount = 1;
      }
      _lastRightTapTime = now;

      final targetPage = (_currentIndex + _rightSkipCount).clamp(
        0,
        _pages.length - 1,
      );
      _pageController.jumpToPage(targetPage);
      setState(() => _currentIndex = targetPage);
    }
    _resetSliderFadeTimer();
  }

  @override
  void dispose() {
    _hideSliderTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savedProvider = context.watch<SavedVersesProvider>();
    final currentItem = (!_isLoading && _pages.isNotEmpty)
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
                  onPressed: () => savedProvider.toggleSave(currentVerse),
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _resetSliderFadeTimer,
              child: Column(
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
                            onTap: () => _handleTapOnSide(isLeft: true),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: 60,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => _handleTapOnSide(isLeft: false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 30,
                    ),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _sliderOpacity,
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
                          _resetSliderFadeTimer();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
