import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wordstory/data/models/story_model.dart';
import 'package:wordstory/services/firestore_service.dart';

class StoryRepository {
  final FirestoreService _db = FirestoreService();

  Future<String> saveStory(String uid, Story story) async {
    final ref = _db.storiesRef(uid);
    if (story.id.isEmpty) {
      final doc = await ref.add(story.toMap());
      return doc.id;
    } else {
      await ref.doc(story.id).set(story.toMap(), SetOptions(merge: true));
      return story.id;
    }
  }

  Future<void> deleteStory(String userId, String storyId) async {
    await _db.storiesRef(userId).doc(storyId).delete();
  }

  Future<List<Story>> getStories(String uid) async {
    List<Story> lst = [];
    try {
      final res = await _db.storiesRef(uid).orderBy('created_at', descending: true).get();
      lst = res.docs.map((doc) => Story.fromMap(doc.id, doc.data())).toList();
    } finally {}
    return lst;
  }
}
