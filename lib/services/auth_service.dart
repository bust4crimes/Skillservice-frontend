import 'package:firebase_auth/firebase_auth.dart';
import '../core/api_client.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiClient _api = ApiClient();

  // Register -> Verify -> Sync
  Future<void> signUpAndSync({
    required String email, 
    required String password, 
    required Map<String, dynamic> profile
  }) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user!.sendEmailVerification();

    // Sync to MongoDB
    await _api.dio.post('/users/register', data: {
      "uid": cred.user!.uid,
      "email": email,
      "first_name": profile['firstName'],
      "last_name": profile['lastName'],
      "birth_date": profile['birthDate'],
      "location": profile['location'],
      "gender": profile['gender'],
    });
  }

  Future<void> login(String e, String p) async => await _auth.signInWithEmailAndPassword(email: e, password: p);
  Future<void> logout() async => await _auth.signOut();
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
}