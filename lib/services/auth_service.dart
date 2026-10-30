import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'notification_service.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authChanges => _auth.authStateChanges();

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(name);
    // role is ALWAYS 'customer' here; Firestore rules reject anything else.
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name,
      'email': email,
      'phone': '',
      'address': '',
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> login({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> logout() async {
    await NotificationService.instance.removeToken();
    await _auth.signOut();
  }

  Stream<AppUser?> watchUser(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? AppUser.fromDoc(d) : null);

  Future<AppUser?> getCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final d = await _db.collection('users').doc(uid).get();
    return d.exists ? AppUser.fromDoc(d) : null;
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String address,
  }) =>
      _db.collection('users').doc(_auth.currentUser!.uid).update({
        'name': name,
        'phone': phone,
        'address': address,
      });

  static String errorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters)';
      case 'invalid-email':
        return 'Invalid email address';
      case 'network-request-failed':
        return 'No internet connection';
      case 'too-many-requests':
        return 'Too many attempts, please try again later';
      default:
        return e.message ?? 'Something went wrong';
    }
  }
}
