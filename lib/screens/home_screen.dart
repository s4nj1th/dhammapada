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

class VersesAndChapters {
  final List<Verse> verses;
  final Map<int, Chapter> chapters;

  VersesAndChapters(this.verses, this.chapters);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<VersesAndChapters> _futureVersesAndChapters;
  final PageController _pageController = PageController();

  int _selectedIndex = 0;
  int _selectedChapterId = 1;
  String _verseInput = '';

  @override
  void initState() {
    super.initState();
    _futureVersesAndChapters = Future.wait([_loadVerses(), _loadChapters()])
        .then(
          (results) => VersesAndChapters(
            results[0] as List<Verse>,
            results[1] as Map<int, Chapter>,
          ),
        );
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            const SizedBox(height: 40),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: ElevatedButton.icon(
                  icon: Icon(
                    lastViewed == null ? Icons.auto_awesome : Icons.history,
                  ),
                  label: Text(
                    lastViewed == null
                        ? 'Start anew'
                        : 'Continue where you left',
                  ),
                  onPressed: () async {
                    if (lastViewed != null && lastViewed.verseId != null) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VerseScreen(
                            chapterMap: chapterMap,
                            initialVerseId: int.parse(lastViewed.verseId!),
                          ),
                        ),
                      );
                    } else if (lastViewed != null &&
                        lastViewed.verseId == null) {
                      await Navigator.push(
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
                      await Navigator.push(
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
                    setState(() {});
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Random Verse'),
                  onPressed: () async {
                    final random = (verses.toList()..shuffle()).first;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VerseScreen(
                          chapterMap: chapterMap,
                          initialVerseId: int.parse(random.id),
                        ),
                      ),
                    );
                    setState(() {});
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Center(child: Text('Jump to Chapter')),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: DropdownButton<int>(
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
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VerseScreen(
                          chapterMap: chapterMap,
                          initialChapterId: _selectedChapterId,
                          initialVerseId: 1,
                        ),
                      ),
                    );
                    setState(() {});
                  },
                  child: const Text('Go to Chapter'),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Center(child: Text('Jump to Verse')),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: TextField(
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(labelText: 'Verse Number'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => _verseInput = val,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: ElevatedButton(
                  onPressed: () async {
                    final targetVerse = int.tryParse(_verseInput) ?? 0;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VerseScreen(
                          chapterMap: chapterMap,
                          initialVerseId: targetVerse,
                        ),
                      ),
                    );
                    setState(() {});
                  },
                  child: const Text('Go to Verse'),
                ),
              ),
            ),
          ],
        ),
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
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: Container(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          color: Theme.of(context).colorScheme.surface,
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<VersesAndChapters>(
      future: _futureVersesAndChapters,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final verses = snapshot.data!.verses;
        final chapters = snapshot.data!.chapters;
        return _buildScaffold(verses, chapters);
      },
    );
  }
}
