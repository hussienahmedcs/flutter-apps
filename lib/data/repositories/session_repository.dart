import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wordstory/data/models/entry_model.dart';
import 'package:wordstory/data/models/session_model.dart';
import 'package:wordstory/services/firestore_service.dart';

class SessionRepository {
  FirestoreService db = FirestoreService();

  Future<List<Session>> getSessions(List<String?> uidList, String userId) async {
    List<Session> sessions = [];
    try {
      if (uidList.isEmpty) return [];

      final querySnapshot =
          await db.sessionsRef().where('user_id', whereIn: uidList).orderBy('date', descending: true).get();

      sessions = querySnapshot.docs.map((doc) {
        final data = doc.data();
        final sessionOwner = data['user_id'] as String;

        // Mark is_shared = true if session is from someone else
        data['is_shared'] = sessionOwner != userId;
        return Session.fromMap(doc.id, data);
      }).toList();
    } catch (e, stack) {
      debugPrint('Error fetching sessions: $e\n$stack');
    }

    return sessions;
  }

  /// Create or update a session.  If [session.id] is blank a new
  /// document will be created.  Returns the newly assigned document ID.
  Future<String> upsertSession(String uid, Session session) async {
    if (session.id.isEmpty) {
      final doc = await db.sessionRef(uid).add(session.toMap());
      return doc.id;
    } else {
      await db.sessionRef(uid).doc(session.id).set(session.toMap(), SetOptions(merge: true));
      return session.id;
    }
  }

  /// Delete a session and all its entries.  Firestore does not
  /// automatically cascade deletes for subcollections; therefore we
  /// delete entries manually before removing the session document.
  Future<void> deleteSession(String uid, String sessionId) async {
    final entries = await db.entriesRef(uid, sessionId).get();
    for (final entry in entries.docs) {
      await entry.reference.delete();
    }
    await db.sessionRef(uid).doc(sessionId).delete();
  }

  /// Listen to entries for a given session.  Entries are ordered by
  /// difficulty and then by the date they were added.  This helps the
  /// practice module surface harder items first.
  Stream<List<Entry>> watchEntries(String uid, String sessionId) {
    return db
        .entriesRef(uid, sessionId)
        .orderBy('difficulty')
        .orderBy('added_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Entry.fromMap(doc.id, doc.data())).toList());
  }

  /// Add or update a vocabulary entry.  If [entry.id] is blank a new
  /// document will be created.  Returns the document ID.
  Future<String> upsertEntry(String uid, String sessionId, Entry entry) async {
    final ref = db.entriesRef(uid, sessionId);
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
    await db.entriesRef(uid, sessionId).doc(entryId).delete();
  }

  /// Fetch all entries (once) for a given session.
  Future<List<Entry>> getEntries(String uid, String sessionId) async {
    final snapshot = await db.entriesRef(uid, sessionId).get();
    return snapshot.docs.map((doc) => Entry.fromMap(doc.id, doc.data())).toList();
  }

  /// Persist the given session.  If the session ID is empty a new
  /// document will be created.  Returns the ID of the saved session.
  Future<String> saveSession(Session session) async {
    return upsertSession(session.userId, session);
  }
}
