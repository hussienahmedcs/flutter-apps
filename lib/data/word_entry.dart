class WordEntry {
  String word;
  String pronounce;
  String meaning;
  String example;

  WordEntry({
    required this.word,
    required this.pronounce,
    required this.meaning,
    required this.example,
  });

  // From JSON map (e.g., from Gemini OCR)
  factory WordEntry.fromJson(Map<String, dynamic> json) => WordEntry(
        word: json['word'] ?? '',
        pronounce: json['pronounce'] ?? '',
        meaning: json['meaning'] ?? '',
        example: json['example'] ?? '',
      );

  // To JSON (if needed)
  Map<String, dynamic> toJson() => {
        'word': word,
        'pronounce': pronounce,
        'meaning': meaning,
        'example': example,
      };

  // For form editing (can be helpful for controllers, etc.)
  WordEntry copyWith({
    String? word,
    String? pronounce,
    String? meaning,
    String? example,
  }) {
    return WordEntry(
      word: word ?? this.word,
      pronounce: pronounce ?? this.pronounce,
      meaning: meaning ?? this.meaning,
      example: example ?? this.example,
    );
  }
}
