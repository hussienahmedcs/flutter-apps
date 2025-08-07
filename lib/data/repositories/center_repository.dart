import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wordstory/data/models/center.dart';
import 'package:wordstory/data/models/center_config.dart';
import 'package:wordstory/data/models/center_request.dart';
import 'package:wordstory/data/models/center_with_role.dart';

class CenterRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<CenterWithRole?> fetchUserCenterWithRole(String uid) async {
    // 1. Check if user is admin
    var adminSnap = await _firestore.collection('centers').where('admin', isEqualTo: uid).limit(1).get();
    if (adminSnap.docs.isNotEmpty) {
      final doc = adminSnap.docs.first;
      return CenterWithRole(CenterDetails.fromMap(doc.id, doc.data()), Role.admin);
    }

    // 2. Check if user is in admins list
    var adminsSnap = await _firestore.collection('centers').where('admins', arrayContains: uid).limit(1).get();
    if (adminsSnap.docs.isNotEmpty) {
      final doc = adminsSnap.docs.first;
      return CenterWithRole(CenterDetails.fromMap(doc.id, doc.data()), Role.admin);
    }

    // 3. Check if user is instructor
    var teachersSnap = await _firestore.collection('centers').where('teachers', arrayContains: uid).limit(1).get();
    if (teachersSnap.docs.isNotEmpty) {
      final doc = teachersSnap.docs.first;
      return CenterWithRole(CenterDetails.fromMap(doc.id, doc.data()), Role.instructor);
    }

    // 4. Check if user is learner
    var learnersSnap = await _firestore.collection('centers').where('learners', arrayContains: uid).limit(1).get();
    if (learnersSnap.docs.isNotEmpty) {
      final doc = learnersSnap.docs.first;
      return CenterWithRole(CenterDetails.fromMap(doc.id, doc.data()), Role.learner);
    }

    // 5. Check if user has a pending join request
    var pendingRequests = await _firestore
        .collectionGroup('requests')
        .where('requester', isEqualTo: uid)
        .where('type', isEqualTo: RequestType.join.name)
        .where('status', isEqualTo: 'pending')
        .get();

    if (pendingRequests.docs.isNotEmpty) {
      final reqDoc = pendingRequests.docs.first;
      final centerId = reqDoc.reference.parent.parent!.id; // get parent center ID
      final centerDoc = await _firestore.collection('centers').doc(centerId).get();

      if (centerDoc.exists) {
        return CenterWithRole(
          CenterDetails.fromMap(centerDoc.id, centerDoc.data()!),
          Role.pendingLearner,
        );
      }
    }
    // No match found
    return null;
  }

  static Future<void> saveCenterInfo(CenterDetails? center) async {
    if (center == null) return;
    if (center.logoUrl != null) {
      // TODO: Upload to Firebase Storage
    }
    await _firestore.collection('centers').doc(center.code).set(center.toMap());
  }

  static Future<void> sendJoinRequest(CenterRequest joinRequest) async {
    try {
      final collectionRef = _firestore.collection('centers').doc(joinRequest.centerCode).collection('requests');

      // Check if ID is null or invalid (-1)
      final isNew = joinRequest.id == null || joinRequest.id == -1 || joinRequest.id == '-1';

      final docId = isNew ? collectionRef.doc().id : joinRequest.id.toString();

      // If we created a new ID, also update the joinRequest object
      final updatedRequest = joinRequest.copyWith(id: docId);

      await collectionRef.doc(docId).set(updatedRequest.toMap());
    } catch (e) {
      throw Exception('Failed to send join request: $e');
    }
  }

  Future<CenterConfig?> getCenterConfig(String centerCode) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('centers').doc(centerCode).get();
      final raw = doc.data()?['config'];
      final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      return CenterConfig.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  Future<bool> isInstructorPending(String uid) async {
    final query = await _firestore
        .collectionGroup('requests') // in case requests are nested in center documents
        .where('requesterRole', isEqualTo: Role.instructor.name)
        .where('requesterId', isEqualTo: uid)
        .where('status', isEqualTo: RequestStatus.pending.name)
        .where('type', isEqualTo: RequestType.join.name)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }
}
