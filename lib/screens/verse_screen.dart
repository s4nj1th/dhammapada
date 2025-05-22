import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/verses.dart';
import '../providers/saved_verses_provider.dart';

class VerseScreen extends StatelessWidget {
  final Verse verse;

  const VerseScreen({super.key, required this.verse});

  @override
  Widget build(BuildContext context) {
    final savedProvider = Provider.of<SavedVersesProvider>(context);
    final isSaved = savedProvider.isSaved(verse);

    return Scaffold(
      appBar: AppBar(
        title: Text('Verse - ${verse.id}'),
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved ? Colors.amberAccent : Colors.white,
              size: 28,
            ),
            onPressed: () {
              savedProvider.toggleSave(verse);
            },
          ),
        ],
      ),
      body: Card(
        elevation: 8,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            verse.text,
            style: const TextStyle(
              fontSize: 28,
              height: 1.6,
              fontWeight: FontWeight.w500,
              fontFamily: 'Castoro',
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ),
    );
  }
}
