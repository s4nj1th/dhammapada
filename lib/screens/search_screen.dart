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

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  List<_SearchResult> _results = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _performSearch(widget.initialQuery!.trim());
    }
  }

  void _performSearch(String query) {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) {
      setState(() {
        _results.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final provider = context.read<TranslationsProvider>();
    final selectedTranslations = provider.selectedTranslations.toSet();
    final data = provider.verseDataByTranslation;

    final results = <_SearchResult>[];

    for (final translation in selectedTranslations) {
      final verses = data[translation];
      if (verses == null) continue;

      verses.forEach((verseId, text) {
        if (text.toLowerCase().contains(trimmedQuery)) {
          results.add(
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
      _results = results;
      _isSearching = false;
    });
  }

  int? _verseIdToInt(String verseId) {
    try {
      return int.parse(verseId);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        centerTitle: true,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
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
                color: colorScheme.surface,
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
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorScheme.onSurface.withAlpha(153),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withAlpha(128),
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _performSearch,
                style: TextStyle(color: colorScheme.onSurface),
                cursorColor: colorScheme.primary,
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
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: colorScheme.onSurface.withAlpha(51)),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      final verseIntId = _verseIdToInt(result.verseId);
                      return ListTile(
                        title: Text(
                          result.text,
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                        subtitle: Text(
                          'Verse ${result.verseId} • ${result.source}',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: colorScheme.outline),
                        ),
                        onTap: verseIntId == null
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VerseScreen(
                                      chapterMap: widget.chapterMap,
                                      initialVerseId: verseIntId,
                                    ),
                                  ),
                                );
                              },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
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
