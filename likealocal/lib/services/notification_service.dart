import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles FCM when the app is in the background or terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // System tray already shows the notification payload; no extra work needed.
}

class NotificationService {
  static final _fln = FlutterLocalNotificationsPlugin();
  static const _channelId = 'likealocal_channel';
  static const _channelName = 'LikeALocal';

  static Future<void> init() async {
    if (kIsWeb) return;
    // 1. flutter_local_notifications setup
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _fln.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // 2. Create Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
    );
    await _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Request permission
    await FirebaseMessaging.instance.requestPermission();

    // 4. Handle foreground FCM messages — show as local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final enabled = doc.data()?['notificationsEnabled'] ?? true;
        if (!enabled) return;
      }

      final n = message.notification;
      if (n == null) return;
      _fln.show(
        message.hashCode,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });
  }

  /// Call after login to save the FCM token to Firestore
  static Future<void> saveFcmToken() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );

      // Refresh token when it rotates
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance.collection('users').doc(uid).set(
          {'fcmToken': newToken},
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Show a local notification immediately (used for in-app triggers)
  static Future<void> showLocal({
    required String title,
    required String body,
  }) async {
    await _fln.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
