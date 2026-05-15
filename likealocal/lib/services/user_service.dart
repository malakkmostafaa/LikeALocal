import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<AppUser?> currentUserStream() {
    return _auth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) {
        return Stream<AppUser?>.value(null);
      }

      return _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .map((doc) {
        if (!doc.exists || doc.data() == null) {
          return null;
        }

        return AppUser.fromMap(doc.data()!);
      });
    });
  }

  Future<AppUser?> getCurrentUserOnce() async {
    final user = _auth.currentUser;

    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return AppUser.fromMap(doc.data()!);
  }

  Future<AppUser?> getUserById(String uid) async {
    if (uid.trim().isEmpty) return null;

    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return AppUser.fromMap(doc.data()!);
  }

  Future<Map<String, AppUser>> getUsersByIds(List<String> ids) async {
    final uniqueIds = ids.where((id) => id.trim().isNotEmpty).toSet().toList();

    if (uniqueIds.isEmpty) return {};

    final Map<String, AppUser> users = {};

    for (final uid in uniqueIds) {
      try {
        final user = await getUserById(uid);
        if (user != null) {
          users[uid] = user;
        }
      } catch (_) {
        // Ignore missing/broken users so feed still loads.
      }
    }

    return users;
  }

  Future<void> updateCurrentUser(Map<String, dynamic> data) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    await _firestore.collection('users').doc(user.uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    if (uid.trim().isEmpty) {
      throw Exception('UID cannot be empty.');
    }

    await _firestore.collection('users').doc(uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
