import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skillservice_frontend/core/api_service.dart';

class AuthMessageException implements Exception {
  final String message;
  const AuthMessageException(this.message);

  @override
  String toString() => message;
}

class SkillAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _api = ApiService();

  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  SkillAuthProvider() {
    _auth.authStateChanges().listen((User? u) {
      _user = u;
      notifyListeners();
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> profile,
  }) async {
    _setLoading(true);
    final cleanEmail = email.trim();

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw const AuthMessageException(
            "Account creation failed. Please try again.");
      }

      await _syncBackendProfile(user, profile);
      final displayName = "${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}".trim();
      if (displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        await user.reload();
      }
      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        await _signInExistingAccount(cleanEmail, password, profile);
        return;
      }
      throw AuthMessageException(_firebaseMessage(e));
    } on DioException catch (e) {
      throw AuthMessageException(_backendMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user != null && user.emailVerified) {
        await _tryVerifyLoginWithBackend(user);
      }
    } on FirebaseAuthException catch (e) {
      throw AuthMessageException(_firebaseMessage(e));
    } on DioException catch (e) {
      throw AuthMessageException(_backendMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkManualVerification() async {
    _setLoading(true);
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      if (user?.emailVerified ?? false) {
        await _verifyLoginWithBackend(user!);
        notifyListeners();
        return true;
      }
      return false;
    } on DioException catch (e) {
      throw AuthMessageException(_backendMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthMessageException(
          "Please log in first before requesting a verification email.");
    }
    await user.sendEmailVerification();
  }

  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<void> sendPasswordReset(String email) async {
    _setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthMessageException(_firebaseMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _signInExistingAccount(
    String email,
    String password,
    Map<String, dynamic> profile,
  ) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw const AuthMessageException(
            "This email already has an account. Please log in instead.");
      }

      await _syncBackendProfile(user, profile);
      final displayName = "${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}".trim();
      if (displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        await user.reload();
      }
      if (!user.emailVerified) {
        await user.sendEmailVerification();
      } else {
        await _tryVerifyLoginWithBackend(user);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw const AuthMessageException(
          "This email already has an account. Log in with the correct password, or use Forgot Password.",
        );
      }
      throw AuthMessageException(_firebaseMessage(e));
    }
  }

  Future<void> _syncBackendProfile(
      User user, Map<String, dynamic> profile) async {
    final token = await user.getIdToken(true);
    try {
      await _api.dio.post('/auth/register', data: {
        "id_token": token,
        "first_name": profile['first_name'],
        "last_name": profile['last_name'],
        "birthday": profile['birthday'],
        "location": profile['location'],
        "gender": profile['gender'],
      });
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final detail = e.response?.data is Map
          ? e.response?.data['detail']?.toString().toLowerCase()
          : '';
      if (status == 400 &&
          detail != null &&
          detail.contains('already registered')) {
        return;
      }
      rethrow;
    }
  }

  Future<void> _verifyLoginWithBackend(User user) async {
    final token = await user.getIdToken(true);
    await _api.dio.post('/auth/login-verify', data: {"id_token": token});
  }

  Future<void> _tryVerifyLoginWithBackend(User user) async {
    try {
      await _verifyLoginWithBackend(user);
    } on DioException catch (e) {
      debugPrint("Backend login sync failed: ${_backendMessage(e)}");
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _firebaseMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return "This email already has an account. Please log in instead.";
      case 'invalid-email':
        return "Please enter a valid email address.";
      case 'weak-password':
        return "Password is too weak. Use at least 6 characters.";
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
        return "Incorrect email or password.";
      case 'user-disabled':
        return "This account has been disabled.";
      case 'network-request-failed':
        return "Network error. Check your internet connection and try again.";
      default:
        return e.message ?? "Authentication failed. Please try again.";
    }
  }

  String _backendMessage(DioException e) {
    final detail =
        e.response?.data is Map ? e.response?.data['detail']?.toString() : null;
    if (detail != null && detail.isNotEmpty) {
      return detail;
    }
    final status = e.response?.statusCode;
    if (status != null) {
      return "Backend error (HTTP $status). Account saved in Firebase, but sync failed. Please try logging in again.";
    }
    return "Network error. Account saved in Firebase, but backend sync failed. Please try logging in again.";
  }
}
