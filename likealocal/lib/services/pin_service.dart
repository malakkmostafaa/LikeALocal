import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Thrown when a free-tier user tries to pin past [PinService.freePinLimit].
class PinLimitReachedException implements Exception {
  const PinLimitReachedException(this.limit);
  final int limit;

  @override
  String toString() => 'Pin limit of $limit reached.';
}

/// Single source of truth for pinning a place.
///
/// Storage:
///   - `users/{uid}/pins/{placeId}` -> { placeId, savedAt }
///   - `users/{uid}.pinsCount`      -> mirror counter, kept in sync via transaction
class PinService {
  PinService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static const int freePinLimit = 5;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  Stream<bool> isPinnedStream(String placeId) {
    final uid = _uid;
    if (uid == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('pins')
        .doc(placeId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<List<String>> pinnedPlaceIdsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('pins')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  /// Atomically toggles the pin and bumps `pinsCount`. Returns the new state.
  Future<bool> togglePin(String placeId) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Must be signed in to pin a place.');
    }

    final userRef = _firestore.collection('users').doc(uid);
    final pinRef = userRef.collection('pins').doc(placeId);

    return _firestore.runTransaction<bool>((tx) async {
      final pinSnap = await tx.get(pinRef);
      final userSnap = await tx.get(userRef);
      final userData = userSnap.data();
      final rawCount = (userData?['pinsCount'] as num?)?.toInt() ?? 0;
      final currentCount = rawCount < 0 ? 0 : rawCount;
      final isPremium = userData?['isPremium'] == true;

      if (pinSnap.exists) {
        final nextCount = currentCount > 0 ? currentCount - 1 : 0;
        tx.delete(pinRef);
        tx.set(userRef, {'pinsCount': nextCount}, SetOptions(merge: true));
        return false;
      }

      if (!isPremium && currentCount >= freePinLimit) {
        throw const PinLimitReachedException(freePinLimit);
      }

      tx.set(pinRef, {
        'placeId': placeId,
        'savedAt': FieldValue.serverTimestamp(),
      });
      tx.set(userRef, {'pinsCount': currentCount + 1}, SetOptions(merge: true));
      return true;
    });
  }
}
