import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wordstory/data/models/session_model.dart';

class SessionRepository {
  final sessionsRef = FirebaseFirestore.instance.collectionGroup('sessions');

  Future<List<Session>> getSessions(List<String?> uidList, String userId) async {
    List<Session> sessions = [];
    try {
      if (uidList.isEmpty) return [];

      final querySnapshot =
          await sessionsRef.where('user_id', whereIn: uidList).orderBy('date', descending: true).get();

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
}
