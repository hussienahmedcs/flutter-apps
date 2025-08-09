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
  CollectionReference<Map<String, dynamic>> sessionRef(String uid) =>
      _db.collection('users').doc(uid).collection('sessions');

  /// Sessions collection under `/users/<uid>/sessions`.
  Query<Map<String, dynamic>> sessionsRef() => _db.collectionGroup('sessions');

  /// Entries collection under a session document.
  CollectionReference<Map<String, dynamic>> entriesRef(String uid, String sessionId) =>
      sessionRef(uid).doc(sessionId).collection('entries');

  /// Stories collection under `/users/<uid>/stories`.
  CollectionReference<Map<String, dynamic>> storiesRef(String uid) =>
      _db.collection('users').doc(uid).collection('stories');

  /// Gamification document reference under `/users/<uid>/gamification`.
  DocumentReference<Map<String, dynamic>> gamificationRef(String uid) =>
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


  // /// Add or update a story.  Returns the document ID.
  // Future<String> upsertStory(String uid, Story story) async {
  //   final ref = _storiesRef(uid);
  //   if (story.id.isEmpty) {
  //     final doc = await ref.add(story.toMap());
  //     return doc.id;
  //   } else {
  //     await ref.doc(story.id).set(story.toMap(), SetOptions(merge: true));
  //     return story.id;
  //   }
  // }

  // /// Delete a story document.
  // Future<void> deleteStory(String uid, String storyId) async {
  //   await _storiesRef(uid).doc(storyId).delete();
  // }

  // /// Update gamification stats.  You may increment XP or streak or
  // /// update achievements.  This performs a merge update on the
  // /// underlying document.
  // Future<void> updateGamification(String uid, Gamification gamification) async {
  //   await _gamificationRef(uid).set(gamification.toMap(), SetOptions(merge: true));
  // }

  // /// Fetch all entries (once) for a given session.
  // Future<List<Entry>> getEntries(String uid, String sessionId) async {
  //   final snapshot = await _entriesRef(uid, sessionId).get();
  //   return snapshot.docs.map((doc) => Entry.fromMap(doc.id, doc.data())).toList();
  // }
}
