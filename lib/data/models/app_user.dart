import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wordstory/data/models/center.dart';
import 'package:wordstory/data/models/center_with_role.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final Role role; // "admin", "instructor", "learner", "user"
  final String? createdAt;
  final String? updatedAt;
  final bool isActive;
  final CenterWithRole? centerWithRole;

  // From Class 1
  final ThemeMode themeMode;
  final bool syncEnabled;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.centerWithRole,
    this.themeMode = ThemeMode.system,
    this.syncEnabled = true,
  });

  /// Deserialize from Firestore
  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    // Handle ThemeMode conversion
    final themeString = map['settings']?['theme'] as String?;
    ThemeMode mode;
    switch (themeString) {
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'dark':
        mode = ThemeMode.dark;
        break;
      default:
        mode = ThemeMode.system;
    }

    return AppUser(
      id: map['id'] ?? id ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'] ?? map['avatar'], // support both keys
      role: Role.values.firstWhere((r) => r.name == map['role'], orElse: () => Role.user),
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate().toIso8601String()
          : map['createdAt'],
      updatedAt: (map['updatedAt'] is Timestamp)
          ? (map['updatedAt'] as Timestamp).toDate().toIso8601String()
          : map['updatedAt'],
      isActive: map['isActive'] ?? true,
      centerWithRole: (map['centerWithRole'] != null && map['centerWithRole'] is Map)
          ? CenterWithRole.fromMap(map['centerWithRole'])
          : null,
      themeMode: mode,
      syncEnabled: map['settings']?['sync_enabled'] as bool? ?? true,
    );
  }

  /// Serialize to Firestore
  Map<String, dynamic> toMap() {
    // Handle ThemeMode conversion
    String mode;
    switch (themeMode) {
      case ThemeMode.light:
        mode = 'light';
        break;
      case ThemeMode.dark:
        mode = 'dark';
        break;
      default:
        mode = 'system';
    }

    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role.name,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
      'updatedAt': updatedAt ?? DateTime.now().toIso8601String(),
      'isActive': isActive,
      'centerWithRole': centerWithRole?.toMap(),
      'settings': {
        'theme': mode,
        'sync_enabled': syncEnabled,
      },
    };
  }

  /// CopyWith for immutability updates
  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    Role? role,
    String? createdAt,
    String? updatedAt,
    bool? isActive,
    CenterWithRole? centerWithRole,
    ThemeMode? themeMode,
    bool? syncEnabled,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      centerWithRole: centerWithRole ?? this.centerWithRole,
      themeMode: themeMode ?? this.themeMode,
      syncEnabled: syncEnabled ?? this.syncEnabled,
    );
  }
}
