import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/translations_provider.dart';
import '../models/chapters.dart';
import '/screens/verse_screen.dart';

class SearchScreen extends StatefulWidget {
  final Map<int, Chapter> chapterMap;
  final String? initialQuery;

  const SearchScreen({super.key, required this.chapterMap, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchResult {
  final String verseId;
  final String text;
  final String source;

  _SearchResult({
    required this.verseId,
    required this.text,
    required this.source,
  });
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  List<_SearchResult> _results = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    final query = widget.initialQuery?.trim();
    if (query?.isNotEmpty == true) _performSearch(query!);
  }

  void _performSearch(String query) {
    final provider = context.read<TranslationsProvider>();
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      setState(() {
        _results.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final selected = provider.selectedTranslations.toSet();
    final data = provider.verseDataByTranslation;
    final matches = <_SearchResult>[];

    for (final translation in selected) {
      final verses = data[translation];
      if (verses == null) continue;

      verses.forEach((verseId, text) {
        if (text.toLowerCase().contains(trimmed)) {
          matches.add(
            _SearchResult(
              verseId: verseId,
              text: text,
              source: provider.allTranslations[translation] ?? translation,
            ),
          );
        }
      });
    }

    setState(() {
      _results = matches;
      _isSearching = false;
    });
  }

  int? _verseIdToInt(String verseId) => int.tryParse(verseId);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        centerTitle: true,
        elevation: 0,
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('Search'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: _performSearch,
                cursorColor: cs.primary,
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: cs.onSurface.withAlpha(153),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  hintStyle: TextStyle(color: cs.onSurface.withAlpha(128)),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                ? Center(
                    child: Text(
                      'No results found.',
                      style: TextStyle(color: cs.onSurface.withAlpha(153)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    itemCount: _results.length + 1,
                    separatorBuilder: (_, __) =>
                        Divider(color: cs.onSurface.withAlpha(51)),
                    itemBuilder: (context, i) {
                      if (i == _results.length) {
                        return const SizedBox(height: 64);
                      }

                      final r = _results[i];
                      final verseId = _verseIdToInt(r.verseId);
                      return ListTile(
                        title: Text(
                          r.text,
                          style: TextStyle(color: cs.onSurface),
                        ),
                        subtitle: Text(
                          'Verse ${r.verseId} • ${r.source}',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: cs.outline),
                        ),
                        onTap: verseId == null
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VerseScreen(
                                    chapterMap: widget.chapterMap,
                                    initialVerseId: verseId,
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
