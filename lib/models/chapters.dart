class Chapter {
  final int id;
  final String pali;
  final String english;

  Chapter({required this.id, required this.pali, required this.english});

  factory Chapter.fromJson(String id, Map<String, dynamic> json) {
    return Chapter(
      id: int.parse(id),
      pali: json['pali'],
      english: json['english'],
    );
  }
}
