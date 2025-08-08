// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:wordstory/data/interfaces/user_interface.dart';
// import '../data/models/gamification_model.dart';
// import '../services/firestore_service.dart';

// /// Tracks the user's XP, level, streak and achievements.  This provider
// /// loads the current stats on login and offers methods for updating
// /// them.  The level is derived from XP (1 level per 500 XP).  Streaks
// /// increment when the user performs an action each day.
// class GamificationProvider with ChangeNotifier {
//   final FirestoreService _db = FirestoreService();
//   String? _uid;
//   Gamification? _stats;
//   bool _loading = true;

//   Gamification? get stats => _stats;
//   bool get isLoading => _loading;

//   void updateUser(UserInterface? user) {
//     _uid = user?.uid;
//     if (_uid != null) {
//       _load();
//     } else {
//       _stats = null;
//       _loading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> _load() async {
//     if (_uid == null) return;
//     _loading = true;
//     notifyListeners();
//     _stats = await _db.getGamification(_uid!);
//     _loading = false;
//     notifyListeners();
//   }



//   /// Increment the streak if the user has logged in today.  If the
//   /// last login date was yesterday, the streak increments; if it was
//   /// more than one day ago, the streak resets.  Updating the
//   /// `lastLogin` ensures correct streak calculations going forward.
//   Future<void> registerDailyActivity() async {
//     if (_stats == null || _uid == null) return;
//     final now = DateTime.now();
//     final last = _stats!.lastLogin;
//     final difference = now.difference(DateTime(last.year, last.month, last.day));
//     int newStreak;
//     if (difference.inDays == 1) {
//       newStreak = _stats!.streak + 1;
//     } else if (difference.inDays > 1) {
//       newStreak = 1;
//     } else {
//       // Already counted today
//       return;
//     }
//     _stats = Gamification(
//       id: _stats!.id,
//       userId: _uid!,
//       xp: _stats!.xp,
//       level: _stats!.level,
//       streak: newStreak,
//       lastLogin: now,
//       achievements: _stats!.achievements,
//     );
//     await _db.updateGamification(_uid!, _stats!);
//     notifyListeners();
//   }

//   /// Unlock an achievement if not already present.  Adds the ID to the
//   /// achievements list and persists to Firestore.
//   Future<void> unlockAchievement(String achievementId) async {
//     if (_stats == null || _uid == null) return;
//     if (_stats!.achievements.contains(achievementId)) return;
//     final updatedAchievements = List<String>.from(_stats!.achievements)
//       ..add(achievementId);
//     _stats = Gamification(
//       id: _stats!.id,
//       userId: _uid!,
//       xp: _stats!.xp,
//       level: _stats!.level,
//       streak: _stats!.streak,
//       lastLogin: _stats!.lastLogin,
//       achievements: updatedAchievements,
//     );
//     await _db.updateGamification(_uid!, _stats!);
//     notifyListeners();
//   }
// }