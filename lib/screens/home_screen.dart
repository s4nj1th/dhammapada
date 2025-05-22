import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/verses.dart';
import '../models/chapters.dart';
import 'chapter_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Verse>> _futureVerses;
  late Future<Map<int, Chapter>> _futureChapters;

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

  @override
  void initState() {
    super.initState();
    _futureVerses = loadVerses();
    _futureChapters = loadChapters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chapters')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add a logo or app name here
                  Text(
                    'Dhammapada',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verses of the Buddha',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withAlpha(200),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Chapters'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            // Add more options here if needed
          ],
        ),
      ),
      body: FutureBuilder<List<Verse>>(
        future: _futureVerses,
        builder: (context, versesSnapshot) {
          if (versesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (versesSnapshot.hasError) {
            return const Center(child: Text('Error loading verses'));
          }

          return FutureBuilder<Map<int, Chapter>>(
            future: _futureChapters,
            builder: (context, chaptersSnapshot) {
              if (chaptersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (chaptersSnapshot.hasError) {
                return const Center(child: Text('Error loading chapters'));
              }

              final verses = versesSnapshot.data!;
              final chapterMap = chaptersSnapshot.data!;
              final chapterIds = chapterMap.keys.toList()..sort();

              return ListView.builder(
                itemCount: chapterIds.length,
                itemBuilder: (context, index) {
                  final chapterId = chapterIds[index];
                  final chapter = chapterMap[chapterId]!;

                  return ListTile(
                    title: Text(
                      '$chapterId. ${chapter.pali} - ${chapter.english}',
                    ),
                    onTap: () {
                      final chapterVerses = verses
                          .where((verse) => verse.chapter == chapterId)
                          .toList();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChapterScreen(
                            chapter: chapterId,
                            verses: chapterVerses,
                            chapterName: chapter,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
