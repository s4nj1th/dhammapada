import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chapter.dart';
import '../models/chapters.dart';
import 'chapter_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Quote>> _futureQuotes;

  Future<List<Quote>> loadQuotes() async {
    final jsonString = await rootBundle.loadString('assets/quotes.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final quotes = jsonData.entries
        .map((entry) => Quote.fromJson(entry.key, entry.value))
        .toList();
    return quotes;
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
    _futureQuotes = loadQuotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chapters')),
      body: FutureBuilder<List<Quote>>(
        future: _futureQuotes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading quotes'));
          } else {
            final quotes = snapshot.data!;
            final chapters = quotes.map((q) => q.chapter).toSet().toList()
              ..sort();

            return ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                return ListTile(
                  title: Text('Chapter $chapter'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChapterScreen(chapter: chapter, quotes: quotes),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
