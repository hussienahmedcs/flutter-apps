import 'package:flutter/material.dart';

/// Model representing the current authenticated user.  User settings
/// such as the preferred theme and whether cloud sync is enabled are
/// stored here.  When loading from Firestore, the UID is supplied
/// externally as the document ID.
class AppUser {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final ThemeMode themeMode;
  final bool syncEnabled;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.themeMode = ThemeMode.system,
    this.syncEnabled = true,
  });

  /// Create an [AppUser] from a Firestore document map.  Since
  /// Firestore stores the theme as a string ("light", "dark" or
  /// "system"), convert it back into a [ThemeMode].
  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    final themeString = data['settings']?['theme'] as String?;
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
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      avatarUrl: data['avatar'] as String?,
      themeMode: mode,
      syncEnabled: data['settings']?['sync_enabled'] as bool? ?? true,
    );
  }

  /// Convert this user into a map suitable for Firestore.  The theme
  /// mode is persisted as a string.
  Map<String, dynamic> toMap() {
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
      'name': name,
      'email': email,
      if (avatarUrl != null) 'avatar': avatarUrl,
      'settings': {
        'theme': mode,
        'sync_enabled': syncEnabled,
      },
    };
  }
}