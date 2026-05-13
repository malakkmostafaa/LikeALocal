import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

class UserService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Stream<AppUser?> getCurrentUser() {
    final uid = _auth.currentUser?.uid;

    if (uid == null) return const Stream.empty();

    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.data()!);
    });
  }

  Future<void> updateCurrentUser(Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      throw Exception("No logged-in user found");
    }

    debugPrint("🔥 Updating Firestore user doc:");
    debugPrint("uid = $uid");
    debugPrint("data = $data");

    try {
      await _firestore.collection('users').doc(uid).update(data);
      debugPrint("✅ Firestore user updated successfully");
    } catch (e) {
      debugPrint("❌ Error updating Firestore user: $e");
      rethrow;
    }
  }

  /// Update a user document by UID. Allows updating any user, not just the current one.
  /// Use [updateCurrentUser] for simpler updates to the authenticated user.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    if (uid.isEmpty) {
      throw Exception("UID cannot be empty");
    }

    debugPrint("🔥 Updating Firestore user doc:");
    debugPrint("uid = $uid");
    debugPrint("data = $data");

    try {
      await _firestore.collection('users').doc(uid).update(data);
      debugPrint("✅ Firestore user updated successfully");
    } catch (e) {
      debugPrint("❌ Error updating Firestore user: $e");
      rethrow;
    }
  }
}
