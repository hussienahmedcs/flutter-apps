// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:wordstory/data/interfaces/user_interface.dart';
// import 'package:wordstory/data/models/session_model.dart';
// import 'package:wordstory/data/repositories/center_repository.dart';
// import 'package:wordstory/services/firestore_service.dart';

// class SessionRepository {
//   FirestoreService db = FirestoreService();
//   final CenterRepository _centerRepository = CenterRepository();


//   /// Create or update a session.  If [session.id] is blank a new
//   /// document will be created.  Returns the newly assigned document ID.
//   // Future<String> upsertSession(String uid, Session session) async {
//   //   if (session.id.isEmpty) {
//   //     final doc = await db.sessionRef(uid).add(session.toMap());
//   //     return doc.id;
//   //   } else {
//   //     await db.sessionRef(uid).doc(session.id).set(session.toMap(), SetOptions(merge: true));
//   //     return session.id;
//   //   }
//   // }

//   // /// Listen to entries for a given session.  Entries are ordered by
//   // /// difficulty and then by the date they were added.  This helps the
//   // /// practice module surface harder items first.
//   // Stream<List<Entry>> watchEntries(String uid, String sessionId) {
//   //   return db
//   //       .entriesRef(uid, sessionId)
//   //       .orderBy('difficulty')
//   //       .orderBy('added_at', descending: true)
//   //       .snapshots()
//   //       .map((snapshot) => snapshot.docs.map((doc) => Entry.fromMap(doc.id, doc.data())).toList());
//   // }
// }
