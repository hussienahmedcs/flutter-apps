class WordEntry {
  String word;
  String meaning;
  String example;

  WordEntry({
    required this.word,
    required this.meaning,
    required this.example,
  });

  // From JSON map (e.g., from Gemini OCR)
  factory WordEntry.fromJson(Map<String, dynamic> json) => WordEntry(
        word: json['word'] ?? '',
        meaning: json['meaning'] ?? '',
        example: json['example'] ?? '',
      );

  // To JSON (if needed)
  Map<String, dynamic> toJson() => {
        'word': word,
        'meaning': meaning,
        'example': example,
      };

  // For form editing (can be helpful for controllers, etc.)
  WordEntry copyWith({
    String? word,
    String? meaning,
    String? example,
  }) {
    return WordEntry(
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      example: example ?? this.example,
    );
  }
}
