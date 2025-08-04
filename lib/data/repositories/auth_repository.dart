import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordstory/data/models/app_user.dart';
import 'package:wordstory/data/models/center.dart';
import 'package:wordstory/data/models/center_request.dart';
import 'package:wordstory/data/models/center_with_role.dart';
import 'package:wordstory/data/repositories/center_repository.dart';
import 'package:wordstory/data/repositories/response_handler.dart';
import 'package:wordstory/providers/app_auth_provider.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<Result<UserCredential>> signUpWithEmail(
      // AppAuthProvider auth,
      String email,
      String password,
      String displayName,
      {bool signUpAsCenter = false,
      String? centerCode}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (displayName.isNotEmpty) {
        await cred.user?.updateDisplayName(displayName);
        await cred.user?.reload();
      }
      if (cred.user?.emailVerified == false) {
        await cred.user?.sendEmailVerification();
      }
      Role role = Role.user;
      if (signUpAsCenter) {
        role = Role.admin;
        String centerCode = displayName.toLowerCase().replaceAll(' ', '');
        final centerDetails = CenterDetails(name: displayName, code: centerCode, admin: cred.user!.uid);
        await CenterRepository.saveCenterInfo(centerDetails);
      } else if (!signUpAsCenter && centerCode != null) {
        CenterRequest joinRequest = CenterRequest(
            id: '-1',
            requesterRole: Role.learner,
            requesterId: cred.user!.uid,
            type: RequestType.join,
            centerCode: centerCode);
        await CenterRepository.sendJoinRequest(joinRequest);
      }

      final AppUser user = AppUser(id: cred.user!.uid, name: displayName, email: email, role: role);
      await saveUserDetails(user, 'both');
      final cwr = await CenterRepository.fetchUserCenterWithRole(cred.user!.uid);
      await saveCenterLocally(cwr);
      return Result.success(cred, message: "Sign up successful");
    } on FirebaseAuthException catch (e) {
      return Result.error(_mapAuthError(e));
    } catch (e) {
      return Result.error("Unexpected error: ${e.toString()}");
    }
  }

  Future<Result<UserCredential>> signInWithEmail(
      // AppAuthProvider auth,
      String email,
      String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final cwr = await CenterRepository.fetchUserCenterWithRole(cred.user!.uid);
      await saveCenterLocally(cwr);
      //get user info from online and save locally
      AppUser? u = await getUserDetailsFromFB(cred.user!.uid);
      if (u != null) {
        await saveUserDetails(u, 'offline');
      }
      // await auth.loader(); //TODO
      return Result.success(cred, message: "Login successful");
    } on FirebaseAuthException catch (e) {
      return Result.error(_mapAuthError(e));
    } catch (e) {
      return Result.error("Unexpected error: ${e.toString()}");
    }
  }

  Future<void> signInWithGoogle(AppAuthProvider auth, {bool? isSignUp, String? centerCode}) async {
    try {
      final userCred = await _signInWithGoogle();
      if (centerCode != null && userCred?.user?.uid != null) {
        CenterRequest joinRequest = CenterRequest(
            id: '-1',
            requesterRole: Role.learner,
            requesterId: userCred?.user!.uid ?? '',
            type: RequestType.join,
            centerCode: centerCode);
        await CenterRepository.sendJoinRequest(joinRequest);
      } else if (centerCode == null /*Not signup and not a Learner (login admin)*/) {
        final cwr = await CenterRepository.fetchUserCenterWithRole(userCred?.user!.uid ?? '');
        await saveCenterLocally(cwr);
      }

      //get user info from online and save locally
      AppUser? u = await getUserDetailsFromFB(userCred?.user!.uid ?? '');
      if (u != null) {
        await saveUserDetails(u, 'offline');
      }
    } finally {
      // _loading = false;
      // notifyListeners();
    }
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      // Ask the user to sign in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }

      // Retrieve authentication tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'wrong-password':
        return 'Wrong password. Please try again.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'invalid-credential':
        return 'Invalid Credentials';
      default:
        return 'Authentication error';
    }
  }

  Future<void> saveUserDetails(AppUser user, String mode) async {
    if (mode == 'online' || mode == 'both') {
      try {
        await _firestore.collection('users').doc(user.id).set(
              user.toMap(),
              SetOptions(merge: true), // merge to avoid overwriting existing data
            );
      } catch (e) {
        throw Exception('Failed to save user details: $e');
      }
    }
    if (mode == 'offline' || mode == 'both') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_info', jsonEncode(user.toMap()));
    }
  }

  Future<AppUser?> getUserDetailsFromFB(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return AppUser.fromMap(uid, doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get user details: $e');
    }
  }

  Future<AppUser?> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_info');
    if (userJson != null) {
      final userMap = jsonDecode(userJson);
      return AppUser.fromMap(userMap['id'], userMap);
    }
    return null;
  }

  Future<void> saveCenterLocally(CenterWithRole? centerWithRoles) async {
    if (centerWithRoles == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('center_info', jsonEncode(centerWithRoles.toMap()));
    // notifyListeners();
  }

  static Future<CenterWithRole?> getCenterLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('center_info');
    if (str == null) return null; // Handle if not found
    final map = jsonDecode(str) as Map<String, dynamic>;
    return CenterWithRole.fromMap(map);
  }

  static Future<void> removeCenterLocally() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('center_info');
  }
}
