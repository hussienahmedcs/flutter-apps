import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wordstory/data/models/app_user.dart';
import 'package:wordstory/data/models/center.dart';

class Learner extends AppUser {
  final List<String> enrolledClasses;

  Learner({
    required String id,
    required String name,
    required String email,
    String? avatarUrl,
    String? createdAt,
    String? updatedAt,
    bool isActive = true,
    this.enrolledClasses = const [],
  }) : super(
          id: id,
          name: name,
          email: email,
          avatarUrl: avatarUrl,
          role: Role.instructor,
          createdAt: createdAt,
          updatedAt: updatedAt,
          isActive: isActive,
        );

  factory Learner.fromMap(String id, Map<String, dynamic> map) {
    return Learner(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'],
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate().toIso8601String()
          : map['createdAt'],
      updatedAt: (map['updatedAt'] is Timestamp)
          ? (map['updatedAt'] as Timestamp).toDate().toIso8601String()
          : map['updatedAt'],
      isActive: map['isActive'] ?? true,
      enrolledClasses: (map['enrolledClasses'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'enrolledClasses': enrolledClasses,
    };
  }
}
