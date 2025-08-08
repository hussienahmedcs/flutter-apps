// import 'dart:async';
// import 'package:flutter/foundation.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:wordstory/data/interfaces/user_interface.dart';

// import '../data/models/session_model.dart';
// import '../services/firestore_service.dart';

// /// Handles loading and mutating vocabulary sessions.  When the
// /// authenticated user changes, this provider re‑subscribes to the
// /// appropriate Firestore stream and exposes the sessions list.
// class SessionProvider with ChangeNotifier {
//   final FirestoreService _db = FirestoreService();
//   String? _uid;
//   List<Session> _sessions = [];
//   StreamSubscription<List<Session>>? _sub;

//   List<Session> get sessions => _sessions;

//   /// Call this whenever the authenticated user changes.  Passing
//   /// `null` clears the sessions list and cancels any active Firestore
//   /// subscription.
//   void updateUser(List<String?> ids) {
//     if (ids.isEmpty) return;
//     _uid = ids[0];
//     _sub?.cancel();
//     if (_uid != null) {
//       _sub = _db.watchSessions(ids).listen((data) {
//         _sessions = data;
//         notifyListeners();
//       });
//     } else {
//       _sessions = [];
//       notifyListeners();
//     }
//   }





//   @override
//   void dispose() {
//     _sub?.cancel();
//     super.dispose();
//   }
// }
