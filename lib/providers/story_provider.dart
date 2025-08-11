import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:wordstory/data/interfaces/user_interface.dart';

import '../data/models/story_model.dart';
import '../services/firestore_service.dart';

/// Provides access to the user's stories.  When the authenticated
/// user changes this provider resubscribes to the Firestore collection
/// for the new UID.  Stories are exposed as a list and methods are
/// available to create, update and delete them.
class StoryProvider with ChangeNotifier {
  final FirestoreService _db = FirestoreService();
  String? _uid;
  List<Story> _stories = [];
  StreamSubscription<List<Story>>? _sub;

  List<Story> get stories => _stories;

  void updateUser(UserInterface? user) {
    _uid = user?.uid;
    _sub?.cancel();
    if (_uid != null) {
      _sub = _db.watchStories(_uid!).listen((data) {
        _stories = data;
        notifyListeners();
      });
    } else {
      _stories = [];
      notifyListeners();
    }
  }

  /// Save the given [Story].  If the ID is empty a new story document
  /// is created; otherwise the existing document is updated.  Returns
  /// the document ID.
  Future<String> saveStory(Story story) async {
    if (_uid == null) throw StateError('Not authenticated');
    return _db.upsertStory(_uid!, story);
  }

  /// Delete the story with the given ID.
  Future<void> deleteStory(String storyId) async {
    if (_uid == null) throw StateError('Not authenticated');
    await _db.deleteStory(_uid!, storyId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}