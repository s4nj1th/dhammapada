class Verse {
  final String id;
  final int chapter;
  final String text;

  Verse({required this.id, required this.chapter, required this.text});

  factory Verse.fromJson(String id, Map<String, dynamic> json) {
    return Verse(
      id: id,
      chapter: int.parse(json['chapter']),
      text: json['text'].replaceAll(r'\n', '\n'),
    );
  }
}
