import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents gamification metrics for a user.  XP drives the level
/// progression (every 500 XP yields a new level).  The streak counts
/// consecutive days of activity.  Achievements are stored as a list of
/// IDs referring to unlocked badges.
class Gamification {
  final String id;
  final String userId;
  final int xp;
  final int level;
  final int streak;
  final DateTime lastLogin;
  final List<String> achievements;

  Gamification({
    required this.id,
    required this.userId,
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    required this.lastLogin,
    this.achievements = const [],
  });

  factory Gamification.fromMap(String id, Map<String, dynamic> data) {
    return Gamification(
      id: id,
      userId: data['user_id'] as String? ?? '',
      xp: data['xp'] as int? ?? 0,
      level: data['level'] as int? ?? 1,
      streak: data['streak'] as int? ?? 0,
      lastLogin: (data['last_login'] as Timestamp?)?.toDate() ?? DateTime.now(),
      achievements: List<String>.from(data['achievements'] as List<dynamic>? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'xp': xp,
      'level': level,
      'streak': streak,
      'last_login': Timestamp.fromDate(lastLogin),
      'achievements': achievements,
    };
  }
}