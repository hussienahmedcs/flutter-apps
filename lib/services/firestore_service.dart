import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wordstory/data/interfaces/user_interface.dart';
import 'package:wordstory/data/models/entry_model.dart';
import 'package:wordstory/data/models/gamification_model.dart';
import 'package:wordstory/data/models/session_model.dart';
import 'package:wordstory/data/models/story_model.dart';
import 'package:wordstory/data/repositories/center_repository.dart';

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

  /// Sessions collection under `sessions`.
  Query<Map<String, dynamic>> sessionsRef() => _db.collectionGroup('sessions');

  /// Sessions collection under `/users/<uid>/sessions`.
  CollectionReference<Map<String, dynamic>> sessionRef(String uid) =>
      _db.collection('users').doc(uid).collection('sessions');

  /// Entries collection under a session document.
  CollectionReference<Map<String, dynamic>> _entriesRef(String uid, String sessionId) =>
      sessionRef(uid).doc(sessionId).collection('entries');

  /// Stories collection under `/users/<uid>/stories`.
  CollectionReference<Map<String, dynamic>> _storiesRef(String uid) =>
      _db.collection('users').doc(uid).collection('stories');

  /// Gamification document reference under `/users/<uid>/gamification`.
  DocumentReference<Map<String, dynamic>> _gamificationRef(String uid) =>
      _db.collection('users').doc(uid).collection('gamification').doc('stats');

  DocumentReference<Map<String, dynamic>> centerRef(String centerCode) =>
      FirebaseFirestore.instance.collection('centers').doc(centerCode);

  CollectionReference<Map<String, dynamic>> usersRef() => FirebaseFirestore.instance.collection('users');

  /// Listen to all sessions for a given user.  This stream emits
  /// whenever the sessions collection is modified.  Sessions are
  /// ordered by their date descending.
  // Stream<List<Session>> watchSessions(String uid) {
  //   return sessionsRef()
  //       .orderBy('date', descending: true)
  //       .snapshots()
  //       .map((snapshot) => snapshot.docs.map((doc) => Session.fromMap(doc.id, doc.data())).toList());
  // }

  Future<List<String>> getSessionOwnersIds(UserInterface user) async {
    List<String> sessionOwnersIds = [];

    if (user.isLearner && user.centerCode != null) {
      final CenterRepository centerRepository = CenterRepository();
      var config = await centerRepository.getCenterConfig(user.centerCode!);
      if (config != null && config.shareSessionsWithLearners) {
        //get admin id
        final centerInfo = await centerRepository.getCenter(user.centerCode!);
        if (centerInfo != null) sessionOwnersIds.add(centerInfo.admin);
      }
    }
    // else {
    sessionOwnersIds.add(user.uid); // user/ admin/ instructor/ or event learner with no center code
    // }
    return sessionOwnersIds;
  }

  Stream<List<Session>> watchSessions(List<String> userIds) {
    // 1) Fast‑fail for empty lists
    if (userIds.isEmpty) return Stream.value(const []);

    // 2) Firestore whereIn supports max 10 values; trim or chunk as needed
    final ids = userIds.length > 10 ? userIds.sublist(0, 10) : userIds;

    final query = sessionsRef().where('user_id', whereIn: ids).orderBy('date', descending: true);

    // 3) Use asyncMap so we can await per‑document work
    return query.snapshots().asyncMap((snapshot) async {
      final sessions = await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();

        // Defensive types
        final userId = (data['user_id'] ?? '') as String;

        // Get word entries asynchronously
        final words = await getEntries(userId, doc.id);

        // Build the model with the enriched field
        return Session.fromMap(doc.id, {
          ...data,
          'word_entries': words,
        });
      }));

      return sessions;
    });
  }

  /// Create or update a session.  If [session.id] is blank a new
  /// document will be created.  Returns the newly assigned document ID.
  Future<String> upsertSession(String uid, Session session) async {
    final ref = sessionRef(uid);
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
    await sessionRef(uid).doc(sessionId).delete();
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

  Future<List<Session>> getSessions(List<String?> uidList, String userId) async {
    try {
      // 1) Clean the list
      final owners = uidList.whereType<String>().toSet().toList(); // remove nulls & dups
      if (owners.isEmpty) return [];

      // 2) Firestore whereIn limit = 10 → chunk
      const chunkSize = 10;
      final chunks = <List<String>>[];
      for (var i = 0; i < owners.length; i += chunkSize) {
        chunks.add(owners.sublist(i, i + chunkSize > owners.length ? owners.length : i + chunkSize));
      }

      // 3) Query each chunk, build sessions, and gather all in parallel
      final allSessionsPerChunk = await Future.wait(chunks.map((chunk) async {
        final qs = await sessionsRef().where('user_id', whereIn: chunk).orderBy('date', descending: true).get();

        // important: await the async map with Future.wait
        final sessions = await Future.wait(qs.docs.map((doc) async {
          final data = doc.data();
          final sessionOwner = data['user_id'] as String? ?? '';
          final isShared = sessionOwner != userId;

          final words = await getEntries(sessionOwner, doc.id); // if you meant entries by *owner*, pass sessionOwner

          return Session.fromMap(doc.id, {
            ...data,
            'is_shared': isShared,
            'word_entries': words,
          });
        }));

        return sessions;
      }));

      // 4) Flatten and keep global ordering by date desc
      final sessions = allSessionsPerChunk.expand((x) => x).toList();
      // sessions.sort((a, b) {
      //   final ad = a.date; // adjust field name if different
      //   final bd = b.date;
      //   if (ad == null && bd == null) return 0;
      //   if (ad == null) return 1;
      //   if (bd == null) return -1;
      //   return bd.compareTo(ad); // desc
      // });

      return sessions;
    } catch (e) {
      return [];
    }
  }
}
