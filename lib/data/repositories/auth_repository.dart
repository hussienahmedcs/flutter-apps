import 'dart:convert';
import 'dart:io';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  final FirebaseStorage _storage = FirebaseStorage.instance;
  // Stream<User?> get authStateChanges => _auth.authStateChanges();
  Future<bool> get isLoggedIn => _googleSignIn.isSignedIn();
  User? get currentUser => _auth.currentUser;

  Future<Result<UserCredential>> signUpWithEmail(
      AppAuthProvider auth, String email, String password, String displayName,
      {bool signUpAsCenter = false, String? centerCode, Role? role}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (displayName.isNotEmpty) {
        await cred.user?.updateDisplayName(displayName);
        await cred.user?.reload();
      }
      if (cred.user?.emailVerified == false) {
        await cred.user?.sendEmailVerification();
      }
      // Role role = Role.user;
      if (signUpAsCenter) {
        role = Role.admin;
        String centerCode = displayName.toLowerCase().replaceAll(' ', '');
        final centerDetails = CenterDetails(name: displayName, code: centerCode, admin: cred.user!.uid);
        await CenterRepository.saveCenterInfo(centerDetails);
      } else if (!signUpAsCenter && centerCode != null) {
        role = role ?? Role.learner;
        CenterRequest joinRequest = CenterRequest(
            id: '-1', requesterRole: role, requesterId: cred.user!.uid, type: RequestType.join, centerCode: centerCode);
        await CenterRepository.sendJoinRequest(joinRequest);
      } else {
        role = role ?? Role.user;
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

  Future<Result<UserCredential>> signInWithGoogle(AppAuthProvider auth,
      {bool? isSignUp, String? centerCode, Role? role}) async {
    print('=================$isSignUp $centerCode $role');
    try {
      // Role role = Role.user;
      final userCred = await _signInWithGoogle();
      final uid = userCred?.user?.uid;
      if (uid == null) {
        return Result.error("Failed to sign ${isSignUp == true ? 'up' : 'in'} with Google");
      }

      //learner signup -> send join request
      if (isSignUp == true) {
        if (centerCode != null) {
          //send join center request
          print('=================joinRequest');
          role = role ?? Role.learner;
          CenterRequest joinRequest = CenterRequest(
            id: '-1',
            requesterRole: role,
            requesterId: userCred?.user!.uid ?? '',
            type: RequestType.join,
            centerCode: centerCode,
          );
          await CenterRepository.sendJoinRequest(joinRequest);
          print('=================joinRequest sent');
        } else if (centerCode == null) {
          role = Role.user;
        }
        //User/learner signup
        final AppUser user = AppUser(
            id: userCred?.user!.uid ?? '',
            name: userCred?.user!.displayName ?? '',
            email: userCred?.user!.email ?? '',
            role: role ?? Role.user);
        await saveUserDetails(user, 'online');
      }

      print('=================login');
      final cwr = await CenterRepository.fetchUserCenterWithRole(uid);
      await saveCenterLocally(cwr);
      print('=================data saved locally');

      // Get user info from online and save locally
      AppUser? u = await getUserDetailsFromFB(uid);
      print('=================getUserDetailsFromFB ${u?.name}');
      if (u != null) {
        await saveUserDetails(u, 'offline');
        print('=================saveUserDetails offline');
      } else {
        // Not registered, signout, and show error
        await signOut();
        return Result.error("User not registered. Please sign up first.");
      }
      auth.loader();
      print('================= auth.loader()');

      return Result.success(userCred,
          message: "Sign in successful, Welcome ${isSignUp == true ? '' : 'back'} ${u.name}!");
    } catch (e) {
      print("Error during Google sign-in: $e");
      return Result.error("Failed: ${e.toString()}");
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
    print('=================$uid');
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists || doc.data() == null) {
        return null; // Or handle as you need (throw, return default)
      }

      return AppUser.fromMap(uid, doc.data()!);
    } catch (e) {
      print('Failed to get user details: $e');
      return null;
    }
  }

  Future<AppUser?> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_info');
    print(userJson);
    if (userJson != null) {
      final userMap = jsonDecode(userJson);
      return AppUser.fromMap(userMap['id'] ?? '', userMap);
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

  Future<String?> updateProfile({String? displayName, File? avatar}) async {
    if (currentUser == null) return null;
    String? avatarUrl;
    if (avatar != null) {
      final ref = _storage.ref('avatars/${currentUser!.uid}.png');
      await ref.putFile(avatar);
      avatarUrl = await ref.getDownloadURL();
      await currentUser!.updatePhotoURL(avatarUrl);
    }
    if (displayName != null) {
      await currentUser!.updateDisplayName(displayName);
    }
    await currentUser!.reload();
    return avatarUrl;
  }

  /// Sign the current user out of Firebase and Google, if applicable.
  Future<void> signOut() async {
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }
}
