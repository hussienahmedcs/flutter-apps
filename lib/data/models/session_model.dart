import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a vocabulary session created by the user.  A session
/// groups together words, idioms and phrasal verbs entered on a
/// particular date.  Notes allow the user to describe the context of
/// learning.  Timestamps are stored in UTC.
class Session {
  final String id;
  final String userId;
  final bool isShared;
  final String title;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  Session({
    required this.id,
    required this.userId,
    this.isShared = false,
    required this.title,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  factory Session.fromMap(String id, Map<String, dynamic> data) {
    return Session(
      id: id,
      userId: data['user_id'] as String? ?? '',
      isShared: data['is_shared'] as bool? ?? false,
      title: data['title'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'] as String?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'is_shared': isShared,
      'title': title,
      'date': Timestamp.fromDate(date),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
