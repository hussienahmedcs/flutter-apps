import 'package:cloud_firestore/cloud_firestore.dart';

class ClassDetails {
  final String id;
  final String name;
  final String level;
  final String? startDate;
  final String? endDate;
  final String? createdAt;
  final String? instructor;
  final String? description;
  final String? updatedAt;
  final List<String> students;
  final bool isActive;

  ClassDetails({
    required this.id,
    required this.name,
    required this.level,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.instructor,
    this.description,
    this.updatedAt,
    this.students = const [],
    this.isActive = true,
  });

  /// Convert Firestore document into a ClassDetails object
  factory ClassDetails.fromMap(String id, Map<String, dynamic> map) {
    return ClassDetails(
      id: id,
      name: map['name'] ?? '',
      level: map['level'] ?? '',
      startDate: (map['startDate'] as Timestamp?)?.toDate().toIso8601String() ?? map['startDate'],
      endDate: (map['endDate'] as Timestamp?)?.toDate().toIso8601String() ?? map['endDate'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate().toIso8601String() ?? map['createdAt'],
      instructor: map['instructor'],
      description: map['description'],
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate().toIso8601String() ?? map['updatedAt'],
      students: (map['students'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isActive: map['isActive'] ?? true,
    );
  }

  /// Convert ClassDetails object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'level': level,
      'startDate': startDate != null ? DateTime.parse(startDate!) : null,
      'endDate': endDate != null ? DateTime.parse(endDate!) : null,
      'createdAt': createdAt != null ? DateTime.parse(createdAt!) : DateTime.now(),
      'instructor': instructor,
      'description': description,
      'updatedAt': updatedAt != null ? DateTime.parse(updatedAt!) : DateTime.now(),
      'students': students,
      'isActive': isActive,
    };
  }
}
