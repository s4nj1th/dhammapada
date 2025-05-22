class Quote {
  final String id;
  final int chapter;
  final String text;

  Quote({required this.id, required this.chapter, required this.text});

  factory Quote.fromJson(String id, Map<String, dynamic> json) {
    return Quote(
      id: id,
      chapter: int.parse(json['chapter']),
      text: json['text'].replaceAll(r'\n', '\n'),
    );
  }
}
