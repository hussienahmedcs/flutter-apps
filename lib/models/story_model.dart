import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user‑created short story that uses vocabulary from a
/// specific session.  The story content is stored as rich text (in
/// Markdown) and an array of used word IDs is recorded for later
/// highlighting and statistics.
class Story {
  final String id;
  final String sessionId;
  final String title;
  final String content;
  final List<String> usedWords;
  final DateTime createdAt;

  Story({
    required this.id,
    required this.sessionId,
    required this.title,
    required this.content,
    required this.usedWords,
    required this.createdAt,
  });

  factory Story.fromMap(String id, Map<String, dynamic> data) {
    return Story(
      id: id,
      sessionId: data['session_id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      usedWords: List<String>.from(data['used_words'] as List<dynamic>? ?? []),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'title': title,
      'content': content,
      'used_words': usedWords,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}