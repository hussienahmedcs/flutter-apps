import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// Provides authentication state and exposes actions for signing
/// in/out and registering.  The provider listens to
/// [`AuthService.authStateChanges`] and updates its state accordingly.
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSub;
  User? _user;
  bool _loading = true;

  AuthProvider() {
    _authSub = _authService.authStateChanges.listen((user) {
      _user = user;
      _loading = false;
      notifyListeners();
    });
  }

  /// Returns the currently signed in Firebase [User], or null if none.
  User? get user => _user;

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
      await _authService.signInWithEmail(email, password);
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
      await _authService.signUpWithEmail(email, password, displayName);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Sign in via Google.  The user may cancel the sign‑in flow, in
  /// which case the provider simply stops loading.
  Future<void> signInWithGoogle() async {
    _loading = true;
    notifyListeners();
    try {
      await _authService.signInWithGoogle();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Sign the user out of the application.
  Future<void> signOut() async {
    _loading = true;
    notifyListeners();
    await _authService.signOut();
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
