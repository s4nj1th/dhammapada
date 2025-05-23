import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/verses.dart';
import '../models/chapters.dart';
import 'verse_screen.dart';
import 'saved_verses.dart';
import 'history_screen.dart';
import 'package:provider/provider.dart';
import '../providers/verse_tracker_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Verse>> _futureVerses;
  late Future<Map<int, Chapter>> _futureChapters;

  int _selectedIndex = 0;
  int _selectedChapterId = 1;
  String _verseInput = '';

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _futureVerses = loadVerses();
    _futureChapters = loadChapters();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<List<Verse>> loadVerses() async {
    final jsonString = await rootBundle.loadString('assets/verses.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    return jsonData.entries
        .map((entry) => Verse.fromJson(entry.key, entry.value))
        .toList();
  }

  Future<Map<int, Chapter>> loadChapters() async {
    final jsonString = await rootBundle.loadString('assets/chapters.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final chapters = <int, Chapter>{};
    jsonData.forEach((key, value) {
      chapters[int.parse(key)] = Chapter.fromJson(key, value);
    });
    return chapters;
  }

  Widget _buildSliderPage(
    List<Verse> verses,
    Map<int, Chapter> chapterMap,
    BuildContext context,
  ) {
    final chapterIds = chapterMap.keys.toList()..sort();
    final tracker = Provider.of<VerseTrackerProvider>(context, listen: false);
    final lastVerse = tracker.getLastViewed();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VerseScreen(
                      chapterMap: chapterMap,
                      initialVerseId: lastVerse,
                    ),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(lastVerse == 1 ? Icons.auto_awesome : Icons.history),
                  SizedBox(width: 8),
                  Text(
                    lastVerse == 1
                        ? 'Start a new'
                        : 'Continue where you left off',
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 30),
            child: Text('Jump to Chapter'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100.0),
            child: DropdownButton<int>(
              value: _selectedChapterId,
              isExpanded: true,
              items: chapterIds.map((id) {
                final chapter = chapterMap[id]!;
                return DropdownMenuItem(
                  value: id,
                  child: Text('$id. ${chapter.english}'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedChapterId = value);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ElevatedButton(
              onPressed: () {
                final verseId = verses
                    .firstWhere(
                      (v) => v.chapter == _selectedChapterId,
                      orElse: () => verses.first,
                    )
                    .id;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VerseScreen(
                      chapterMap: chapterMap,
                      initialVerseId: int.parse(verseId),
                    ),
                  ),
                );
              },
              child: const Text('Go to Chapter'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Text('Jump to Verse', textAlign: TextAlign.center),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100.0),
            child: TextField(
              decoration: const InputDecoration(labelText: 'Verse Number'),
              keyboardType: TextInputType.number,
              onChanged: (val) => _verseInput = val,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ElevatedButton(
              onPressed: () {
                final targetVerse = int.tryParse(_verseInput) ?? 0;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VerseScreen(
                      chapterMap: chapterMap,
                      initialVerseId: targetVerse,
                    ),
                  ),
                );
              },
              child: const Text('Go to Verse'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Verse>>(
      future: _futureVerses,
      builder: (context, versesSnapshot) {
        if (!versesSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final verses = versesSnapshot.data!;

        return FutureBuilder<Map<int, Chapter>>(
          future: _futureChapters,
          builder: (context, chaptersSnapshot) {
            if (!chaptersSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final chapters = chaptersSnapshot.data!;

            if (!chapters.containsKey(_selectedChapterId)) {
              _selectedChapterId = chapters.keys.first;
            }

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  _selectedIndex == 0
                      ? 'Chapters'
                      : _selectedIndex == 1
                      ? 'Saved Verses'
                      : 'History',
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ],
              ),
              body: PageView(
                controller: _pageController,
                onPageChanged: (index) =>
                    setState(() => _selectedIndex = index),
                children: [
                  _buildSliderPage(verses, chapters, context),
                  SavedVersesScreen(chapterMap: chapters),
                  HistoryScreen(chapterMap: chapters),
                ],
              ),
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                },
                items: List.generate(3, (index) {
                  final isSelected = _selectedIndex == index;
                  final icons = [Icons.book, Icons.bookmark, Icons.history];
                  return BottomNavigationBarItem(
                    label: '',
                    icon: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(38)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icons[index],
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        size: 28,
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        );
      },
    );
  }
}
