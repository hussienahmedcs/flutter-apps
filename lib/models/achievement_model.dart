import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a gamification achievement.  Achievements are defined
/// centrally and then referenced in a user's `gamification.achievements` array
/// when unlocked.  An optional `icon` string can point to a local
/// asset or network image used when rendering the badge.
class Achievement {
  final String id;
  final String title;
  final String description;
  final String? icon;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.icon,
    this.unlockedAt,
  });

  factory Achievement.fromMap(String id, Map<String, dynamic> data) {
    return Achievement(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      icon: data['icon'] as String?,
      unlockedAt: (data['unlocked_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      if (icon != null) 'icon': icon,
      if (unlockedAt != null)
        'unlocked_at': Timestamp.fromDate(unlockedAt!),
    };
  }
}