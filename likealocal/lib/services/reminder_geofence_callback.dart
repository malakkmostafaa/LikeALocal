import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import 'reminder_geofence_service.dart';

/// Called by the OS when the user enters a reminder geofence (app may be closed).
@pragma('vm:entry-point')
Future<void> onReminderGeofenceTriggered(GeofenceCallbackParams params) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (params.event != GeofenceEvent.enter) return;

  final prefs = await SharedPreferences.getInstance();
  final uid = prefs.getString(ReminderGeofenceService.ownerUidKey);

  for (final geofence in params.geofences) {
    final placeId = ReminderGeofenceService.placeIdFromGeofenceId(geofence.id);
    if (placeId == null) continue;

    final placeName =
        prefs.getString(ReminderGeofenceService.labelKey(placeId)) ??
            'A saved place';

    const channelId = 'likealocal_channel';
    const channelName = 'LikeALocal';

    final fln = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await fln.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    await fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            importance: Importance.high,
          ),
        );

    await fln.show(
      placeId.hashCode,
      'You\'re near $placeName!',
      'One of your reminders is nearby. Go check it out!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.active,
        ),
      ),
    );

    if (uid == null || uid.isEmpty) continue;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': uid,
        'title': 'You\'re near $placeName!',
        'body': 'One of your reminders is nearby. Go check it out!',
        'type': 'reminder',
        'placeId': placeId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // OS notification already shown; inbox sync is best-effort in background.
    }
  }
}
