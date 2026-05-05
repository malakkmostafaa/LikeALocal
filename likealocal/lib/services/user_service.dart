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

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      // NOTE: If the collection name is different, change 'users' here as well.
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      debugPrint("Error updating profile: $e");
      rethrow;
    }
  }
}
