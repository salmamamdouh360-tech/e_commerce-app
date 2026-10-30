import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// users/{currentUid}
DocumentReference<Map<String, dynamic>> currentUserDoc() => FirebaseFirestore
    .instance
    .collection('users')
    .doc(FirebaseAuth.instance.currentUser!.uid);
