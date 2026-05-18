import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'incoming_notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
    List<String> interests = const [],
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: cleanPassword,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Signup failed. No Firebase user was returned.');
    }

    await user.updateDisplayName(cleanName);
    await user.reload();

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': cleanName,
      'email': cleanEmail,

      // Preferences
      'preferences': interests,
      'maxDistance': 10.0,
      'priceRange': 1,

      // Activity
      'pinsCount': 0,
      'placesAdded': 0,
      'reviewsCount': 0,

      // Status
      'isSuperUser': false,
      'isPremium': false,

      // Settings
      'chatEnabled': true,
      'notificationsEnabled': true,

      // Gamification
      'badges': [],

      // Profile
      'profileImageUrl': '',
      'bio': '',

      // Dates
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return credential;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    final credential = await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: cleanPassword,
    );

    await ensureUserDocumentExists();

    return credential;
  }

  Future<void> ensureUserDocumentExists() async {
    final user = _auth.currentUser;

    if (user == null) return;

    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'preferences': [],
        'maxDistance': 10.0,
        'priceRange': 1,
        'pinsCount': 0,
        'placesAdded': 0,
        'reviewsCount': 0,
        'isSuperUser': false,
        'isPremium': false,
        'chatEnabled': true,
        'notificationsEnabled': true,
        'badges': [],
        'profileImageUrl': '',
        'bio': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> logout() async {
    IncomingNotificationService.stop();
    await _auth.signOut();
  }
}
