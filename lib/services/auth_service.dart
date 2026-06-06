import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Dio _dio = Dio(BaseOptions(baseUrl: "https://skillservice-backend.onrender.com"));

  // Full Auth + Sync Logic
  Future<void> signUpAndSync({
    required String email, 
    required String password, 
    required Map<String, dynamic> profile
  }) async {
    // 1. Firebase Auth
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email, 
      password: password
    );

    // 2. Email Guard
    await cred.user!.sendEmailVerification();

    // 3. FastAPI/MongoDB Sync (Based on your backend repo requirements)
    await _dio.post('/users/register', data: {
      "uid": cred.user!.uid,
      "email": email,
      "first_name": profile['firstName'],
      "last_name": profile['lastName'],
      "birth_date": profile['birthDate'],
      "location": profile['location'],
      "gender": profile['gender'],
    });
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}