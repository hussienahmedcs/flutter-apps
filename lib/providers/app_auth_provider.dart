import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:wordstory/data/interfaces/user_interface.dart';
import 'package:wordstory/data/repositories/auth_repository.dart';
// import '../services/auth_service.dart';

/// Provides authentication state and exposes actions for signing
/// in/out and registering.  The provider listens to
/// [`AuthService.authStateChanges`] and updates its state accordingly.
class AppAuthProvider with ChangeNotifier {
  // final AuthService _authService = AuthService();
  final AuthRepository _authRepository = AuthRepository();
  StreamSubscription<User?>? _authSub;
  UserInterface? _user;
  bool _loading = true;

  AppAuthProvider() {
    //1- check if user already signed in and has locale data as well
    // final bool isUserLoaded = isLoggedIn;
    // final bool isUserSignedIn = _authRepository;

    // _authSub = _authRepository.authStateChanges.listen((user) {
    // _user = user;
    // _user = user != null
    //     ? UserInterface(user.uid, displayName: user.displayName, email: user.email, photoURL: user.photoURL,
    //         deleteAccount: () async {
    //         await user.delete();
    //       })
    //     : null;
    // _loading = false;
    // notifyListeners();
    // });
    loader();
  }

  void loader() async {
    if (isLoggedIn) {
      print('>>>>>>>>>>>>user already logged in');
      //user already logged in and has active variable
      // _loading = false;
    } else if (await _authRepository.isLoggedIn && await _authRepository.getUserDetails() != null) {
      // user var not loaded but user is logged in and has locale data
      print('>>>>>>>>>>>>Load User Var');
      final localUser = await _authRepository.getUserDetails();
      final fbUser = _authRepository.currentUser;
      _user = UserInterface(
        fbUser!.uid,
        displayName: fbUser.displayName,
        email: fbUser.email,
        photoURL: fbUser.photoURL,
        role: localUser!.role,
        deleteAccount: () async {
          await fbUser.delete();
          notifyListeners();
        },
        signOut: () async {
          await _authRepository.signOut();
          _user = null;
          notifyListeners();
        },
        updateProfile: ({avatar, displayName}) {
          return _authRepository.updateProfile(avatar: avatar, displayName: displayName);
        },
      );
      // _loading = false;
    } else if (await _authRepository.isLoggedIn) {
      //if user logged in but no data saved locally, logout
      _authRepository.signOut();
      print('>>>>>>>>>>>>LOGEDINWITHNODATA');
      //user not logged in and no locale data
      _user = null;
      // _loading = false;
    } else {
      print('>>>>>>>>>>>>ELSESSSSSSSSSSSSSSSSS');
      _user = null;
    }
    //load user from sharedpref.
    // final fbUser = _authRepository.currentUser;

    // if (localUser != null && isLoggedIn && fbUser != null) {
    //   _user = user != null
    //       ? UserInterface(user.uid, displayName: user.displayName, email: user.email, photoURL: user.photoURL,
    //           deleteAccount: () async {
    //           await user.delete();
    //         })
    //       : null;
    // }
    _loading = false;
    notifyListeners();
  }

  /// Returns the currently signed in Firebase [User], or null if none.
  UserInterface? get user => _user;

  /// Indicates whether an authentication operation is currently in
  /// progress.  This is true on provider initialization until the
  /// first auth event is received.
  bool get isLoading => _loading;

  /// Indicates if a user is signed in.
  bool get isLoggedIn => _user != null;

  /// Sign the user in using an email and password.
  Future<void> signInWithEmail(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      await _authRepository.signInWithEmail(email, password);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Register a new user with an email and password and display name.
  Future<void> signUpWithEmail(String email, String password, String displayName) async {
    _loading = true;
    notifyListeners();
    try {
      await _authRepository.signUpWithEmail(this, email, password, displayName);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Sign in via Google.  The user may cancel the sign‑in flow, in
  /// which case the provider simply stops loading.
  Future<void> signInWithGoogle(BuildContext context, bool isSignUp, {String? centerCode}) async {
    // _loading = true;
    // notifyListeners();
    try {
      final result = await _authRepository.signInWithGoogle(this, isSignUp: isSignUp, centerCode: centerCode);

      if (result.success) {
        // ✅ Success
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message)),
          );
        }
      } else {
        // ❌ Error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message)),
          );
        }
      }
    } catch (e) {
      // Handle unexpected errors
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unexpected error: ${e.toString()}")),
        );
      }
    } finally {
      // _loading = false;
      // notifyListeners();
    }
  }

  /// Sign the user out of the application.
  // Future<void> signOut() async {
  //   _loading = true;
  //   notifyListeners();
  //   await _authRepository.signOut();
  //   _loading = false;
  //   notifyListeners();
  // }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // Future<void> deleteAccount() async {
  //   if (user != null) await user!.deleteAccount();
  //   await signOut();
  // }
}
