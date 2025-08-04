import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wordstory/data/models/center.dart';

class UserCenter {
  final String? id;
  final String? userId;
  final String? centerId;
  final Role? role; // e.g., admin, instructor, learner, pending
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final String? status; // e.g., active, pending, rejected

  UserCenter({
    this.id,
    this.userId,
    this.centerId,
    this.role,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.status,
  });

  /// Deserialize from Firestore
  factory UserCenter.fromMap(String id, Map<String, dynamic> map) {
    return UserCenter(
      id: id,
      userId: map['userId'],
      centerId: map['centerId'],
      role: Role.values.firstWhere((r) => r.name == map['role'].toString(), orElse: () => Role.user),
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate().toIso8601String()
          : map['createdAt'],
      updatedAt: (map['updatedAt'] is Timestamp)
          ? (map['updatedAt'] as Timestamp).toDate().toIso8601String()
          : map['updatedAt'],
      deletedAt: (map['deletedAt'] is Timestamp)
          ? (map['deletedAt'] as Timestamp).toDate().toIso8601String()
          : map['deletedAt'],
      status: map['status'],
    );
  }

  /// Serialize to Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'centerId': centerId,
      'role': role?.name ?? Role.user.name,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
      'updatedAt': updatedAt ?? DateTime.now().toIso8601String(),
      'deletedAt': deletedAt,
      'status': status,
    };
  }
}
