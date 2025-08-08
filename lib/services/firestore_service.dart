import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/session_model.dart';
import '../data/models/entry_model.dart';
import '../data/models/story_model.dart';
import '../data/models/gamification_model.dart';

/// Abstraction over Firestore CRUD operations.  This class isolates
/// database logic from the UI, making it easier to unit test and to
/// mock during development.  All collections are namespaced by the
/// authenticated user's UID; the caller is responsible for passing
/// that UID into each method.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreService() {
    // Enable offline persistence.  Firestore caches data locally and
    // synchronizes with the backend when connectivity is restored.
    _db.settings = const Settings(persistenceEnabled: true);
  }

  /// Sessions collection under `/users/<uid>/sessions`.
  CollectionReference<Map<String, dynamic>> _sessionsRef(String uid) =>
      _db.collection('users').doc(uid).collection('sessions');

  /// Entries collection under a session document.
  CollectionReference<Map<String, dynamic>> _entriesRef(String uid, String sessionId) =>
      _sessionsRef(uid).doc(sessionId).collection('entries');

  /// Stories collection under `/users/<uid>/stories`.
  CollectionReference<Map<String, dynamic>> _storiesRef(String uid) =>
      _db.collection('users').doc(uid).collection('stories');

  /// Gamification document reference under `/users/<uid>/gamification`.
  DocumentReference<Map<String, dynamic>> _gamificationRef(String uid) =>
      _db.collection('users').doc(uid).collection('gamification').doc('stats');

  /// Listen to all sessions for a given user.  This stream emits
  /// whenever the sessions collection is modified.  Sessions are
  /// ordered by their date descending.
  // Stream<List<Session>> watchSessions(List<String?> uid) {
  //   return _sessionsRef(uid).orderBy('date', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) {
  //         final data = doc.data();
  //         if (data['user_id'] == uid) {
  //           data['is_shared'] = false;
  //         } else {
  //           data['is_shared'] = true;
  //         }
  //         return Session.fromMap(doc.id, data);
  //       }).toList());
  // }

  // Stream<List<Session>> watchSessions(List<String?> uidList) {
  //   final sessionsRef = FirebaseFirestore.instance.collectionGroup('sessions');

  //   return sessionsRef.where('user_id', whereIn: uidList).orderBy('date', descending: true).snapshots().map((snapshot) {
  //     return snapshot.docs.map((doc) {
  //       final data = doc.data();
  //       final sessionOwner = data['user_id'] as String;

  //       // Mark is_shared = true if session is from someone else
  //       data['is_shared'] = !uidList.contains(sessionOwner);

  //       return Session.fromMap(doc.id, data);
  //     }).toList();
  //   });
  // }

  /// Create or update a session.  If [session.id] is blank a new
  /// document will be created.  Returns the newly assigned document ID.
  Future<String> upsertSession(String uid, Session session) async {
    final ref = _sessionsRef(uid);
    if (session.id.isEmpty) {
      final doc = await ref.add(session.toMap());
      return doc.id;
    } else {
      await ref.doc(session.id).set(session.toMap(), SetOptions(merge: true));
      return session.id;
    }
  }

  /// Delete a session and all its entries.  Firestore does not
  /// automatically cascade deletes for subcollections; therefore we
  /// delete entries manually before removing the session document.
  Future<void> deleteSession(String uid, String sessionId) async {
    final entries = await _entriesRef(uid, sessionId).get();
    for (final entry in entries.docs) {
      await entry.reference.delete();
    }
    await _sessionsRef(uid).doc(sessionId).delete();
  }

  /// Listen to entries for a given session.  Entries are ordered by
  /// difficulty and then by the date they were added.  This helps the
  /// practice module surface harder items first.
  Stream<List<Entry>> watchEntries(String uid, String sessionId) {
    return _entriesRef(uid, sessionId)
        .orderBy('difficulty')
        .orderBy('added_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Entry.fromMap(doc.id, doc.data())).toList());
  }

  /// Add or update a vocabulary entry.  If [entry.id] is blank a new
  /// document will be created.  Returns the document ID.
  Future<String> upsertEntry(String uid, String sessionId, Entry entry) async {
    final ref = _entriesRef(uid, sessionId);
    if (entry.id.isEmpty) {
      final data = entry.toMap();
      data['user_id'] = uid;
      final doc = await ref.add(data);
      return doc.id;
    } else {
      final data = entry.toMap();
      data['user_id'] = uid;
      await ref.doc(entry.id).set(data, SetOptions(merge: true));
      return entry.id;
    }
  }

  /// Delete a vocabulary entry from a session.
  Future<void> deleteEntry(String uid, String sessionId, String entryId) async {
    await _entriesRef(uid, sessionId).doc(entryId).delete();
  }

  /// Listen to stories created by the user ordered by newest first.
  Stream<List<Story>> watchStories(String uid) {
    return _storiesRef(uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Story.fromMap(doc.id, doc.data())).toList());
  }

  /// Add or update a story.  Returns the document ID.
  Future<String> upsertStory(String uid, Story story) async {
    final ref = _storiesRef(uid);
    if (story.id.isEmpty) {
      final doc = await ref.add(story.toMap());
      return doc.id;
    } else {
      await ref.doc(story.id).set(story.toMap(), SetOptions(merge: true));
      return story.id;
    }
  }

  /// Delete a story document.
  Future<void> deleteStory(String uid, String storyId) async {
    await _storiesRef(uid).doc(storyId).delete();
  }

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

  /// Update gamification stats.  You may increment XP or streak or
  /// update achievements.  This performs a merge update on the
  /// underlying document.
  Future<void> updateGamification(String uid, Gamification gamification) async {
    await _gamificationRef(uid).set(gamification.toMap(), SetOptions(merge: true));
  }

  /// Fetch all entries (once) for a given session.
  Future<List<Entry>> getEntries(String uid, String sessionId) async {
    final snapshot = await _entriesRef(uid, sessionId).get();
    return snapshot.docs.map((doc) => Entry.fromMap(doc.id, doc.data())).toList();
  }
}
