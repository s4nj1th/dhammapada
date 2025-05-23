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
    final currentChapter = chapterMap[_selectedChapterId]!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            final tracker = Provider.of<VerseTrackerProvider>(
              context,
              listen: false,
            );
            final chapterVerses = verses
                .where((verse) => verse.chapter == _selectedChapterId)
                .toList();

            if (chapterVerses.isEmpty) return;

            final lastViewedId = tracker.getLastViewed(_selectedChapterId);
            final initialIndex = chapterVerses.indexWhere(
              (v) => int.parse(v.id) == lastViewedId,
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VerseScreen(
                  chapterId: _selectedChapterId,
                  chapterMap: chapterMap,
                  initialIndex: initialIndex != -1 ? initialIndex : 0,
                ),
              ),
            );
          },
          child: Card(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    currentChapter.pali,
                    style: const TextStyle(
                      fontFamily: 'Castoro',
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      fontSize: 28,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
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
                setState(() {
                  _selectedChapterId = value;
                });
              }
            },
          ),
        ),
      ],
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
                onPageChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
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
                        borderRadius: BorderRadius.circular(
                          8,
                        ), // rounded rectangle for polish
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
