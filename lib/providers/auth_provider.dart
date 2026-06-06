import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

enum AuthStatus { 
  unauthenticated, 
  authenticating, 
  needsEmailVerification, 
  onboardingRequired, 
  authenticated 
}

class AuthProvider with ChangeNotifier {
  
  // ⚙️ GLOBAL TOGGLE: Set to true for local mock data, false for real Firebase (Web + Mobile)
  static const bool isDevTestingMode = false; 

  final FirebaseAuth? _auth = isDevTestingMode ? null : FirebaseAuth.instance;
  final GoogleSignIn? _googleSignIn = isDevTestingMode ? null : GoogleSignIn();
  
  AuthStatus _status = AuthStatus.unauthenticated;
  String? _userId;
  String? _userEmail;
  String? _firebaseIdToken;

  AuthStatus get status => _status;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get firebaseIdToken => _firebaseIdToken;

  // 📧 REAL EMAIL & PASSWORD SIGN-UP FLOW BUNDLED WITH PROFILE PROVISIONING
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String birthday,
    required String location,
    required String gender,
  }) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    
    if (isDevTestingMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      _userEmail = email;
      _userId = "mobile_test_user_777";
      _firebaseIdToken = "mock_mobile_token";
      _status = AuthStatus.needsEmailVerification; 
      notifyListeners();
      return true;
    }

    try {
      // 1. Create the secure login credentials record inside Firebase Auth
      UserCredential result = await _auth!.createUserWithEmailAndPassword(
          email: email, password: password);
      
      User? user = result.user;
      if (user == null) throw Exception("Firebase Auth creation failed to yield a valid user.");

      // Send the real verification link to their Gmail box immediately
      await user.sendEmailVerification();
      
      // Extract the initial registration token (Carries email_verified: false)
      _firebaseIdToken = await user.getIdToken();
      _userEmail = user.email;
      _userId = user.uid;

      // 2. Transmit the profile details to your FastAPI backend to create your MongoDB document
      print("🔵 [Backend Sync] Provisioning profile into MongoDB for UID: $_userId...");
      
      final response = await http.post(
        Uri.parse('${AppConstants.backendBaseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': _firebaseIdToken,
          'first_name': firstName,
          'last_name': lastName,
          'birthday': birthday,
          'location': location,
          'gender': gender,
        }),
      ).timeout(const Duration(seconds: 7));

      print("🟩 [Backend Sync Response]: Status ${response.statusCode} | Body: ${response.body}");

      // 🚨 CRITICAL PROTECTION: If backend profile setup fails, throw an exception to stop registration track
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("FastAPI sync failed with status ${response.statusCode}: ${response.body}");
      }
      
      // Lock the UI layout on your verification screen waiting state
      _status = AuthStatus.needsEmailVerification;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      print("❌ [Firebase Auth Error - Registration]: Code: ${e.code} | Message: ${e.message}");
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow; // Pass up to display explicit snackbar alerts inside your register UI
    } catch (e) {
      print("❌ [Fatal Error - Registration Sync Pipeline Broken]: ${e.toString()}");
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  // 🔑 LOGIN FLOW WITH EMAIL VERIFICATION SAFETY CHECK
  Future<void> loginWithEmail(String email, String password) async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    if (isDevTestingMode) {
      try {
        final response = await http.post(
          Uri.parse('${AppConstants.backendBaseUrl}/auth/login-verify'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id_token': 'mock_mobile_token'}),
        ).timeout(const Duration(seconds: 4));

        final data = jsonDecode(response.body);
        if (data['status'] == 'Onboarding Required') {
          _userId = "mobile_test_user_777";
          _userEmail = email;
          _status = AuthStatus.onboardingRequired;
        } else {
          _userId = data['user_id'] ?? "mobile_test_user_777";
          _status = AuthStatus.authenticated;
        }
      } catch (e) {
        _userId = "mobile_test_user_777";
        _userEmail = email;
        _status = AuthStatus.onboardingRequired;
      }
      notifyListeners();
      return;
    }

    try {
      UserCredential result = await _auth!.signInWithEmailAndPassword(
          email: email, password: password);
      
      // Catch users logging in who registered but never confirmed their email link
      if (result.user != null && !result.user!.emailVerified) {
        _firebaseIdToken = await result.user?.getIdToken();
        _userEmail = result.user?.email;
        _userId = result.user?.uid;
        _status = AuthStatus.needsEmailVerification;
        notifyListeners();
        return;
      }

      _firebaseIdToken = await result.user?.getIdToken();
      
      final response = await http.post(
        Uri.parse('${AppConstants.backendBaseUrl}/auth/login-verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': _firebaseIdToken}),
      );
      final data = jsonDecode(response.body);

      if (data['status'] == 'Onboarding Required') {
        _userId = data['uid'];
        _userEmail = data['email'];
        _status = AuthStatus.onboardingRequired;
      } else if (data['status'] == 'Authenticated') {
        _userId = data['user_id'];
        _status = AuthStatus.authenticated;
      }
      notifyListeners();
      
    } on FirebaseAuthException catch (e) {
      print("❌ [Firebase Auth Error - Login]: Code: ${e.code} | Message: ${e.message}");
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow; // <--- CRITICAL FIX: Ensures the login_screen catches the error
    } catch (e) {
      print("❌ [Unknown Error - Login]: ${e.toString()}");
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow; // <--- CRITICAL FIX: Ensures the login_screen catches the error
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (isDevTestingMode) {
      await Future.delayed(const Duration(seconds: 1));
      return; // Simulate success in dev mode
    }
    
    try {
      await _auth!.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print("❌ [Firebase Auth Error - Reset]: ${e.message}");
      rethrow; // Pass error back to UI to show a SnackBar
    } catch (e) {
      print("❌ [Unknown Error - Reset]: $e");
      rethrow;
    }
  }

  // 🔄 METHOD TO CHECK IF USER CLICKED THE VERIFICATION LINK IN THEIR GMAIL
  Future<void> checkEmailVerificationStatus() async {
    if (isDevTestingMode) {
      _status = AuthStatus.onboardingRequired;
      notifyListeners();
      return;
    }

    User? user = _auth?.currentUser;
    if (user != null) {
      try {
        await user.reload(); // Re-sync user payload context directly with Google servers
        
        if (user.emailVerified) {
          // 💡 CRITICAL CHANGE: Force a token refresh so the new claim token contains email_verified: true
          _firebaseIdToken = await user.getIdToken(true);
          _userEmail = user.email;
          _userId = user.uid;

          print("🔵 Sending verification token confirmation to FastAPI login gate...");
          final response = await http.post(
            Uri.parse('${AppConstants.backendBaseUrl}/auth/login-verify'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id_token': _firebaseIdToken}),
          ).timeout(const Duration(seconds: 5));

          final data = jsonDecode(response.body);

          if (response.statusCode == 200 || response.statusCode == 201) {
            if (data['status'] == 'Onboarding Required') {
              _status = AuthStatus.onboardingRequired;
            } else {
              _status = AuthStatus.authenticated; // Everything cleared! User is pushed inside app
            }
          } else {
            print("⚠️ Backend registration login gate mismatch: ${response.body}");
          }
        } else {
          print("📲 Log: User checked status but hasn't opened verification email link yet.");
        }
      } on FirebaseAuthException catch (e) {
        print("❌ [Firebase Auth Error - Verification Check]: Code: ${e.code} | Message: ${e.message}");
      } catch (e) {
        print("❌ [Unknown Error - Verification Check]: ${e.toString()}");
      }
      notifyListeners();
    }
  }

  // 📝 SUBMIT CUSTOM ONBOARDING PROFILE FORM TO MONGODB (Fallback Support Block)
  Future<bool> submitOnboarding({
    required String firstName,
    required String lastName,
    required String birthday,
    required String location,
    required String gender,
  }) async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    if (_firebaseIdToken == null && isDevTestingMode) {
      _firebaseIdToken = "mock_mobile_token";
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.backendBaseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': _firebaseIdToken,
          'first_name': firstName,
          'last_name': lastName,
          'birthday': birthday,
          'location': location,
          'gender': gender,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _userId = data['user_id'] ?? "mobile_test_user_777";
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        print("❌ Backend onboarding failure: ${response.body}");
        _status = AuthStatus.onboardingRequired;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print("❌ Connection error during onboarding transmission: $e");
      
      if (isDevTestingMode) {
        _userId = "mobile_test_user_777";
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      
      _status = AuthStatus.onboardingRequired;
      notifyListeners();
      return false;
    }
  }

  // 🚪 LOGOUT
  Future<void> logout() async {
    if (!isDevTestingMode) {
      await _auth?.signOut();
      await _googleSignIn?.signOut();
    }
    _status = AuthStatus.unauthenticated;
    _userId = null;
    _firebaseIdToken = null;
    notifyListeners();
  }
}