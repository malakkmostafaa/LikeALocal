import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String get currentUid => _auth.currentUser!.uid;

  // Call this on login — saves FCM token to user doc
  Future<void> initFCM() async {
    await _messaging.requestPermission();
    final token = await _messaging.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(currentUid).update({
        'fcmToken': token,
      });
    }
  }

  // Save a notification to Firestore for a user
  Future<void> sendNotification({
    required String toUid,
    required String title,
    required String body,
    required String type,
  }) async {
    await _firestore
        .collection('notifications')
        .doc(toUid)
        .collection('userNotifications')
        .add({
      'title': title,
      'body': body,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  // Stream notifications for current user (real-time)
  Stream<List<NotificationModel>> getNotifications() {
    return _firestore
        .collection('notifications')
        .doc(currentUid)
        .collection('userNotifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(NotificationModel.fromDoc).toList());
  }

  // Mark notification as read
  Future<void> markAsRead(String notifId) async {
    await _firestore
        .collection('notifications')
        .doc(currentUid)
        .collection('userNotifications')
        .doc(notifId)
        .update({'read': true});
  }

  // Delete notification
  Future<void> deleteNotification(String notifId) async {
    await _firestore
        .collection('notifications')
        .doc(currentUid)
        .collection('userNotifications')
        .doc(notifId)
        .delete();
  }

  // Simulate a "near place" notification
  Future<void> simulateNearbyNotification(String placeName) async {
    await sendNotification(
      toUid: currentUid,
      title: 'New place near you!',
      body: '$placeName is nearby — check it out!',
      type: 'nearby',
    );
  }
}
