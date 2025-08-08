import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wordstory/data/models/gamification_model.dart';

class GamificationRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> _gamificationRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('gamification').doc('stats');

  /// Fetch or create gamification stats for a user.  If no stats
  /// document exists one will be created with default values.  The
  /// returned [Gamification] instance always has a non‑null ID.
  Future<Gamification> getGamification(String uid) async {
    final ref = _gamificationRef(uid);
    final doc = await ref.get();
    if (doc.exists) {
      return Gamification.fromMap(doc.id, doc.data()!);
    } else {
      final initial = Gamification(
        id: ref.id,
        userId: uid,
        xp: 0,
        level: 1,
        streak: 0,
        lastLogin: DateTime.now(),
        achievements: [],
      );
      await ref.set(initial.toMap());
      return initial;
    }
  }

  /// Award XP to the user and update the level accordingly.  This
  /// method automatically calculates the new level (every 500 XP).
  // Future<void> addXp(int amount) async {
  //   if (_stats == null || _uid == null) return;
  //   int newXp = _stats!.xp + amount;
  //   int newLevel = 1 + (newXp ~/ 500);
  //   _stats = Gamification(
  //     id: _stats!.id,
  //     userId: _uid!,
  //     xp: newXp,
  //     level: newLevel,
  //     streak: _stats!.streak,
  //     lastLogin: _stats!.lastLogin,
  //     achievements: _stats!.achievements,
  //   );
  //   await _db.updateGamification(_uid!, _stats!);
  //   notifyListeners();
  // }
}
