import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/verses.dart';
import '../models/chapters.dart';
import 'verse_screen.dart';
import 'saved_verses_screen.dart';
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
  final PageController _pageController = PageController();

  int _selectedIndex = 0;
  int _selectedChapterId = 1;
  String _verseInput = '';

  @override
  void initState() {
    super.initState();
    _futureVerses = _loadVerses();
    _futureChapters = _loadChapters();
  }

  Future<List<Verse>> _loadVerses() async {
    final jsonString = await rootBundle.loadString('assets/verses.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    return data.entries.map((e) => Verse.fromJson(e.key, e.value)).toList();
  }

  Future<Map<int, Chapter>> _loadChapters() async {
    final jsonString = await rootBundle.loadString('assets/chapters.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(int.parse(k), Chapter.fromJson(k, v)));
  }

  Widget _buildSliderPage(List<Verse> verses, Map<int, Chapter> chapterMap) {
    final tracker = Provider.of<VerseTrackerProvider>(context, listen: false);
    final lastViewed = tracker.getLastViewed();
    final chapterIds = chapterMap.keys.toList()..sort();

    return Center(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        children: [
          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: Icon(lastViewed == null ? Icons.auto_awesome : Icons.history),
            label: Text(
              lastViewed == null ? 'Start anew' : 'Continue where you left off',
            ),
            onPressed: () {
              if (lastViewed != null && lastViewed.verseId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VerseScreen(
                      chapterMap: chapterMap,
                      initialVerseId: int.parse(lastViewed.verseId!),
                    ),
                  ),
                );
              } else if (lastViewed != null && lastViewed.verseId == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VerseScreen(
                      initialChapterId: lastViewed.chapterId,
                      chapterMap: chapterMap,
                      initialVerseId: 1,
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VerseScreen(
                      initialChapterId: 1,
                      chapterMap: chapterMap,
                      initialVerseId: 1,
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 40),
          const Center(child: Text('Jump to Chapter')),
          DropdownButton<int>(
            value: _selectedChapterId,
            isExpanded: true,
            onChanged: (val) => setState(() => _selectedChapterId = val!),
            items: chapterIds.map((id) {
              final chapter = chapterMap[id]!;
              return DropdownMenuItem(
                value: id,
                child: Text('$id. ${chapter.english}'),
              );
            }).toList(),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VerseScreen(
                    chapterMap: chapterMap,
                    initialChapterId: _selectedChapterId,
                    initialVerseId: 1,
                  ),
                ),
              );
            },
            child: const Text('Go to Chapter'),
          ),
          const SizedBox(height: 40),
          const Center(child: Text('Jump to Verse')),
          TextField(
            textAlign: TextAlign.center,
            decoration: const InputDecoration(labelText: 'Verse Number'),
            keyboardType: TextInputType.number,
            onChanged: (val) => _verseInput = val,
          ),
          ElevatedButton(
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
        ],
      ),
    );
  }

  Widget _buildScaffold(List<Verse> verses, Map<int, Chapter> chapters) {
    _selectedChapterId = chapters.containsKey(_selectedChapterId)
        ? _selectedChapterId
        : chapters.keys.first;

    const titles = ['Chapters', 'Saved Verses', 'History'];
    const icons = [Icons.book, Icons.bookmark, Icons.history];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: [
          _buildSliderPage(verses, chapters),
          SavedVersesScreen(chapterMap: chapters),
          HistoryScreen(chapterMap: chapters),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: List.generate(3, (index) {
          final isSelected = _selectedIndex == index;
          return BottomNavigationBarItem(
            label: '',
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withAlpha(38)
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
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Verse>>(
      future: _futureVerses,
      builder: (context, verseSnap) {
        if (!verseSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return FutureBuilder<Map<int, Chapter>>(
          future: _futureChapters,
          builder: (context, chapterSnap) {
            if (!chapterSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildScaffold(verseSnap.data!, chapterSnap.data!);
          },
        );
      },
    );
  }
}
