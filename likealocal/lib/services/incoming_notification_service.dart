import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

/// Listens for new Firestore notification docs for the logged-in user and
/// shows a local OS notification. Reliable even when client-side FCM send fails.
class IncomingNotificationService {
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  static final Set<String> _seenIds = {};
  static bool _skipInitialSnapshot = true;

  static void start() {
    stop();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _sub = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .listen(
      (snapshot) {
        if (_skipInitialSnapshot) {
          _skipInitialSnapshot = false;
          for (final doc in snapshot.docs) {
            _seenIds.add(doc.id);
          }
          return;
        }

        for (final change in snapshot.docChanges) {
          if (change.type != DocumentChangeType.added) continue;

          final doc = change.doc;
          if (_seenIds.contains(doc.id)) continue;
          _seenIds.add(doc.id);

          final data = doc.data();
          if (data == null) continue;

          _showIfEnabled(
            title: data['title']?.toString() ?? 'LikeALocal',
            body: data['body']?.toString() ?? '',
          );
        }
      },
      onError: (e) {
        debugPrint('IncomingNotificationService error: $e');
      },
    );
  }

  static void stop() {
    _sub?.cancel();
    _sub = null;
    _seenIds.clear();
    _skipInitialSnapshot = true;
  }

  static Future<void> _showIfEnabled({
    required String title,
    required String body,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final enabled = userDoc.data()?['notificationsEnabled'] ?? true;
        if (!enabled) return;
      } catch (_) {
        return;
      }
    }

    await NotificationService.showLocal(title: title, body: body);
  }
}
