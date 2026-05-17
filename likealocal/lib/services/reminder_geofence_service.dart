import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';
import 'reminder_geofence_callback.dart';

/// Registers OS-level geofences for reminder places (works when app is closed).
class ReminderGeofenceService {
  static const _idPrefix = 'reminder_';
  static const _defaultRadiusMeters = 300.0;
  static const ownerUidKey = 'reminder_owner_uid';

  static String labelKey(String placeId) => 'reminder_label_$placeId';

  static String geofenceId(String placeId) => '$_idPrefix$placeId';

  static String? placeIdFromGeofenceId(String id) {
    if (!id.startsWith(_idPrefix)) return null;
    return id.substring(_idPrefix.length);
  }

  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await NativeGeofenceManager.instance.initialize();
    } catch (e) {
      debugPrint('ReminderGeofenceService init error: $e');
    }
  }

  /// Re-register all reminders from Firestore (call after login).
  static Future<void> syncFromFirestore() async {
    if (kIsWeb) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ownerUidKey, uid);

    if (!await ensurePermissions()) {
      debugPrint('ReminderGeofenceService: location permission not granted');
      return;
    }

    try {
      final registered =
          await NativeGeofenceManager.instance.getRegisteredGeofenceIds();
      for (final id in registered) {
        if (id.startsWith(_idPrefix)) {
          await NativeGeofenceManager.instance.removeGeofenceById(id);
        }
      }

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('reminders')
          .get();

      for (final doc in snap.docs) {
        await _registerFromData(doc.data());
      }
    } catch (e) {
      debugPrint('ReminderGeofenceService sync error: $e');
    }
  }

  static Future<void> registerReminder({
    required String placeId,
    required String placeName,
    required double lat,
    required double lng,
    double radiusMeters = _defaultRadiusMeters,
  }) async {
    if (kIsWeb) return;
    if (!await ensurePermissions()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ownerUidKey, uid);
      await prefs.setString(labelKey(placeId), placeName);
    }

    final id = geofenceId(placeId);
    try {
      await NativeGeofenceManager.instance.removeGeofenceById(id);
    } catch (_) {}

    final geofence = Geofence(
      id: id,
      location: Location(latitude: lat, longitude: lng),
      radiusMeters: radiusMeters.clamp(100, 10000),
      triggers: {GeofenceEvent.enter},
      iosSettings: const IosGeofenceSettings(initialTrigger: false),
      androidSettings: const AndroidGeofenceSettings(
        initialTriggers: {},
        expiration: Duration(days: 365),
      ),
    );

    try {
      await NativeGeofenceManager.instance.createGeofence(
        geofence,
        onReminderGeofenceTriggered,
      );
    } on NativeGeofenceException catch (e) {
      debugPrint('ReminderGeofenceService register error: ${e.message}');
    }
  }

  static Future<void> unregisterReminder(String placeId) async {
    if (kIsWeb) return;

    try {
      await NativeGeofenceManager.instance.removeGeofenceById(geofenceId(placeId));
    } catch (e) {
      debugPrint('ReminderGeofenceService unregister error: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(labelKey(placeId));
  }

  static Future<void> _registerFromData(Map<String, dynamic> data) async {
    final placeId = data['placeId'] as String?;
    final placeName = data['placeName'] as String? ?? 'A saved place';
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();
    final radius =
        (data['radiusMeters'] as num?)?.toDouble() ?? _defaultRadiusMeters;

    if (placeId == null || lat == null || lng == null) return;

    await registerReminder(
      placeId: placeId,
      placeName: placeName,
      lat: lat,
      lng: lng,
      radiusMeters: radius,
    );
  }

  /// Requests foreground + background location (required for geofences when app is closed).
  static Future<bool> ensurePermissions() async {
    if (kIsWeb) return false;
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var location = await Permission.location.request();
    if (!location.isGranted) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final background = await Permission.locationAlways.request();
      if (!background.isGranted) {
        // Geofencing may still work in background on some devices with whileInUse.
        debugPrint(
          'ReminderGeofenceService: background location not granted — '
          'enable "Allow all the time" in system settings for reminders when app is closed.',
        );
      }
    }

    await Permission.notification.request();
    return true;
  }

  /// ~500 m south of [lat]/[lng] — use with emulator fake GPS to simulate leaving home.
  static ({double lat, double lng}) coordinatesOutsideZone({
    required double lat,
    required double lng,
    double offsetMeters = 500,
  }) {
    const metersPerDegreeLat = 111320.0;
    final deltaLat = offsetMeters / metersPerDegreeLat;
    return (lat: lat - deltaLat, lng: lng);
  }

  /// Same notification as a real geofence enter (for testing without traveling).
  static Future<void> triggerTestNotification({
    required String placeId,
    required String placeName,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    await NotificationService.showLocal(
      title: 'You\'re near $placeName!',
      body: 'One of your reminders is nearby. Go check it out! (test)',
    );

    if (uid == null) return;

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': uid,
        'title': 'You\'re near $placeName!',
        'body': 'One of your reminders is nearby. Go check it out! (test)',
        'type': 'reminder',
        'placeId': placeId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('triggerTestNotification: $e');
    }
  }
}
