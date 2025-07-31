import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Encapsulates authentication logic for the application.
/// It exposes methods for signing in with email/password or with Google,
/// registering new users, updating profile details and signing out.
/// It also uploads user avatars to Firebase Storage and updates the
/// Firebase user profile accordingly.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream of [User] objects that emits whenever the authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Returns the currently signed in user, or null if not logged in.
  User? get currentUser => _auth.currentUser;

  /// Sign in an existing user with an email and password.
  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Register a new user with an email and password. The display name is optional.
  Future<UserCredential> signUpWithEmail(String email, String password, String displayName) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (displayName.isNotEmpty) {
      await cred.user?.updateDisplayName(displayName);
    }
    return cred;
  }

  /// Signs in the user via Google Sign‑In and returns the resulting [UserCredential].
  Future<UserCredential?> signInWithGoogle() async {
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

  /// Update the user's display name and, if provided, avatar image.
  /// Returns the download URL of the avatar if uploaded.
  Future<String?> updateProfile({String? displayName, File? avatar}) async {
    User? user = _auth.currentUser;
    if (user == null) return null;
    String? avatarUrl;
    if (avatar != null) {
      final ref = _storage.ref('avatars/${user.uid}.png');
      await ref.putFile(avatar);
      avatarUrl = await ref.getDownloadURL();
      await user.updatePhotoURL(avatarUrl);
    }
    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }
    await user.reload();
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
