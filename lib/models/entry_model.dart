import 'package:cloud_firestore/cloud_firestore.dart';

/// Defines the type of vocabulary entry.  Words are single terms,
/// idioms consist of multiple words with figurative meaning, and
/// phrasal verbs are verb + particle constructions.
enum EntryType { word, idiom, phrasal }

/// Difficulty rating for an entry.  It influences the spaced
/// repetition algorithm in the practice module.
enum Difficulty { easy, medium, hard }

/// Represents a single vocabulary entry associated with a session.  An
/// entry contains the term (`content`), its definition (`meaning`),
/// an example usage and the difficulty rating.  It also keeps a
/// timestamp of when it was added for spaced repetition.
class Entry {
  final String id;
  final String sessionId;
  final EntryType type;
  final String content;
  final String meaning;
  final String example;
  final Difficulty difficulty;
  final DateTime addedAt;

  Entry({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.content,
    required this.meaning,
    required this.example,
    required this.difficulty,
    required this.addedAt,
  });

  factory Entry.fromMap(String id, Map<String, dynamic> data) {
    final typeString = data['type'] as String? ?? 'word';
    final difficultyString = data['difficulty'] as String? ?? 'easy';
    return Entry(
      id: id,
      sessionId: data['session_id'] as String? ?? '',
      type: EntryType.values.firstWhere(
        (e) => e.toString().split('.').last == typeString,
        orElse: () => EntryType.word,
      ),
      content: data['content'] as String? ?? '',
      meaning: data['meaning'] as String? ?? '',
      example: data['example'] as String? ?? '',
      difficulty: Difficulty.values.firstWhere(
        (e) => e.toString().split('.').last == difficultyString,
        orElse: () => Difficulty.easy,
      ),
      addedAt: (data['added_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'type': type.toString().split('.').last,
      'content': content,
      'meaning': meaning,
      'example': example,
      'difficulty': difficulty.toString().split('.').last,
      'added_at': Timestamp.fromDate(addedAt),
    };
  }
}