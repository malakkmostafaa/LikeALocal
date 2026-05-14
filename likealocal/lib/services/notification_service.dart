import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ← Replace with your actual Firebase project ID
  static const String _projectId = 'YOUR_FIREBASE_PROJECT_ID';

  String get currentUid => _auth.currentUser!.uid;

  // ─── FCM SETUP ────────────────────────────────────────────────────────────

  Future<void> initFCM() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(currentUid).update({
        'fcmToken': token,
      });
    }

    // Refresh token if it changes (e.g. app reinstall)
    _messaging.onTokenRefresh.listen((newToken) {
      _firestore.collection('users').doc(currentUid).update({
        'fcmToken': newToken,
      });
    });

    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // You can navigate to a screen here based on message.data
    });
  }

  // ─── SEND PUSH + SAVE TO FIRESTORE ───────────────────────────────────────

  /// Sends a real FCM push notification to [toUid] AND saves it to Firestore.
  Future<void> sendNotification({
    required String toUid,
    required String title,
    required String body,
    required String type,
  }) async {
    // 1. Save to Firestore (your existing in-app notifications)
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

    // 2. Get the recipient's FCM token
    final userDoc =
        await _firestore.collection('users').doc(toUid).get();
    final fcmToken = userDoc.data()?['fcmToken'] as String?;

    if (fcmToken == null) return; // user has no token registered

    // 3. Send the actual push notification via FCM HTTP v1 API
    await _sendFcmPush(
      fcmToken: fcmToken,
      title: title,
      body: body,
      data: {'type': type, 'toUid': toUid},
    );
  }

  // ─── FCM HTTP v1 (direct, no server needed) ───────────────────────────────

  Future<void> _sendFcmPush({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    try {
      // Load service account credentials from assets
      final jsonStr =
          await rootBundle.loadString('assets/service_account.json');
      final jsonCredentials = json.decode(jsonStr);

      final credentials = ServiceAccountCredentials.fromJson(jsonCredentials);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      // Get a short-lived OAuth2 access token
      final authClient =
          await clientViaServiceAccount(credentials, scopes);

      final accessToken = authClient.credentials.accessToken.data;
      authClient.close();

      // Build the FCM v1 request body
      final payload = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data,
          'android': {
            'priority': 'high',
            'notification': {
              'sound': 'default',
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
              },
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(payload),
      );

      if (response.statusCode != 200) {
        print('FCM error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Failed to send FCM push: $e');
    }
  }

  // ─── EXISTING METHODS (unchanged) ─────────────────────────────────────────

  Stream<List<NotificationModel>> getNotifications() {
    return _firestore
        .collection('notifications')
        .doc(currentUid)
        .collection('userNotifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(NotificationModel.fromDoc).toList());
  }

  Future<void> markAsRead(String notifId) async {
    await _firestore
        .collection('notifications')
        .doc(currentUid)
        .collection('userNotifications')
        .doc(notifId)
        .update({'read': true});
  }

  Future<void> deleteNotification(String notifId) async {
    await _firestore
        .collection('notifications')
        .doc(currentUid)
        .collection('userNotifications')
        .doc(notifId)
        .delete();
  }

  Future<void> simulateNearbyNotification(String placeName) async {
    await sendNotification(
      toUid: currentUid,
      title: 'New place near you!',
      body: '$placeName is nearby — check it out!',
      type: 'nearby',
    );
  }
}