import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/verses.dart';
import '../models/chapters.dart';
import '../providers/saved_verses_provider.dart';
import '../providers/verse_tracker_provider.dart';

class VerseScreen extends StatefulWidget {
  final int chapterId;
  final int initialIndex;
  final Map<int, Chapter> chapterMap;

  const VerseScreen({
    super.key,
    required this.chapterId,
    required this.chapterMap,
    this.initialIndex = 0,
  });

  @override
  State<VerseScreen> createState() => _VerseScreenState();
}

class _VerseScreenState extends State<VerseScreen> {
  late PageController _pageController;
  late List<Verse> _verses;
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

    _verses = allVerses.where((v) => v.chapter == widget.chapterId).toList();

    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = _verses[_currentIndex];
      Provider.of<VerseTrackerProvider>(
        context,
        listen: false,
      ).recordVerseView(current.chapter, current.id);
    });

    _pageController.addListener(() {
      final page = _pageController.page?.round();
      if (page != null && page != _currentIndex) {
        setState(() => _currentIndex = page);
        final current = _verses[page];
        Provider.of<VerseTrackerProvider>(
          context,
          listen: false,
        ).recordVerseView(current.chapter, current.id);
      }
    });

    setState(() => _isLoading = false);
  }

  Widget _buildPage(Verse verse) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Text(
        verse.text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          fontFamily: 'Castoro',
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savedProvider = Provider.of<SavedVersesProvider>(context);
    final currentVerse = !_isLoading && _verses.isNotEmpty
        ? _verses[_currentIndex]
        : null;
    final isSaved = currentVerse != null && savedProvider.isSaved(currentVerse);

    return Scaffold(
      appBar: AppBar(
        title: currentVerse != null
            ? Text('Verse ${currentVerse.id}')
            : const Text('Verse'),
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
                    itemCount: _verses.length,
                    itemBuilder: (context, index) => _buildPage(_verses[index]),
                  ),
                ),
                if (currentVerse != null)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Slider(
                      min: 0,
                      max: (_verses.length - 1).toDouble(),
                      value: _currentIndex.toDouble(),
                      label: 'Verse ${currentVerse.id}',
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
