import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wordstory/data/interfaces/user_interface.dart';

import '../data/models/session_model.dart';
import '../services/firestore_service.dart';

/// Handles loading and mutating vocabulary sessions.  When the
/// authenticated user changes, this provider re‑subscribes to the
/// appropriate Firestore stream and exposes the sessions list.
class SessionProvider with ChangeNotifier {
  final FirestoreService _db = FirestoreService();
  String? _uid;
  List<Session> _sessions = [];
  StreamSubscription<List<Session>>? _sub;

  List<Session> get sessions => _sessions;

  /// Call this whenever the authenticated user changes.  Passing
  /// `null` clears the sessions list and cancels any active Firestore
  /// subscription.
  void updateUser(UserInterface? user) {
    _uid = user?.uid;
    _sub?.cancel();
    if (_uid != null) {
      _sub = _db.watchSessions(_uid!).listen((data) {
        _sessions = data;
        notifyListeners();
      });
    } else {
      _sessions = [];
      notifyListeners();
    }
  }

  /// Persist the given session.  If the session ID is empty a new
  /// document will be created.  Returns the ID of the saved session.
  Future<String> saveSession(Session session) async {
    if (_uid == null) throw StateError('Not authenticated');
    return _db.upsertSession(_uid!, session);
  }

  /// Delete the session with the given ID and all its entries.
  Future<void> deleteSession(String sessionId) async {
    if (_uid == null) throw StateError('Not authenticated');
    await _db.deleteSession(_uid!, sessionId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}