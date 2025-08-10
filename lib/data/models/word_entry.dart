// class WordEntry {
//   String word;
//   String pronounce;
//   String meaning;
//   String example;
//   String? type;

//   WordEntry({required this.word, required this.pronounce, required this.meaning, required this.example, this.type});

//   // From JSON map (e.g., from Gemini OCR)
//   factory WordEntry.fromJson(Map<String, dynamic> json) => WordEntry(
//         word: json['word'] ?? '',
//         pronounce: json['pronounce'] ?? '',
//         meaning: json['meaning'] ?? '',
//         example: json['example'] ?? '',
//         type: json['type'] ?? 'word',
//       );

//   // To JSON (if needed)
//   Map<String, dynamic> toJson() => {
//         'word': word,
//         'pronounce': pronounce,
//         'meaning': meaning,
//         'example': example,
//         'type': type ?? 'word',
//       };

//   // For form editing (can be helpful for controllers, etc.)
//   WordEntry copyWith({
//     String? word,
//     String? pronounce,
//     String? meaning,
//     String? example,
//     String? type,
//   }) {
//     return WordEntry(
//       word: word ?? this.word,
//       pronounce: pronounce ?? this.pronounce,
//       meaning: meaning ?? this.meaning,
//       example: example ?? this.example,
//       type: type ?? this.type ?? 'word',
//     );
//   }
// }
