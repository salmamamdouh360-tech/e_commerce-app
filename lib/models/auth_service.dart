import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;

    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      'email': email,
      'phone': '',
      'address': '',
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;

    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();

    if (!doc.exists) return null;

    return AppUser.fromDoc(doc);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  static String errorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'Invalid email or password';

      case 'wrong-password':
        return 'Incorrect password';

      case 'email-already-in-use':
        return 'This email is already registered';

      case 'weak-password':
        return 'Password is too weak';

      case 'invalid-email':
        return 'Invalid email address';

      case 'network-request-failed':
        return 'Please check your internet connection';

      default:
        return e.message ?? 'Something went wrong';
    }
  }
}
