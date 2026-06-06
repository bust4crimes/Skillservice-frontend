import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillservice_frontend/core/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _api = ApiService();
  User? _user;

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Register user and sync to FastAPI/MongoDB
  Future<void> register({
    required String email, 
    required String password, 
    required Map<String, dynamic> profileData
  }) async {
    try {
      // 1. Firebase Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      // 2. Sync to Backend (Match your FastAPI endpoints)
      await _api.dio.post('/auth/register', data: {
        "uid": cred.user!.uid,
        "email": email,
        ...profileData
      });
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Secure Login
  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Secure Logout
  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }
}