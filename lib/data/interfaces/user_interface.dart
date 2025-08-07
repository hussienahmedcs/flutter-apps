import 'dart:io';

import 'package:wordstory/data/models/center.dart';

class UserInterface {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final String? centerCode;
  final Role role;
  final bool isAdmin;
  final bool isInstructor;
  final bool isLearner;
  final bool isUser;
  final bool isPendingLearner;
  final Future<void> Function() deleteAccount;
  final Future<void> Function() signOut;
  final Future<void> Function({File? avatar, String? displayName}) updateProfile;

  UserInterface(
    this.uid, {
    this.displayName,
    this.email,
    this.photoURL,
    this.centerCode,
    this.role = Role.user,
    required this.deleteAccount,
    required this.signOut,
    required this.updateProfile,
  })  : isAdmin = role == Role.admin,
        isInstructor = role == Role.instructor,
        isLearner = role == Role.learner,
        isPendingLearner = role == Role.pendingLearner,
        isUser = role == Role.user;
}
