import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart' as gauth;
import 'package:http/http.dart' as http;

class FcmService {
  static const _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  static Future<String?> _getAccessToken() async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/service_account.json');
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;

      final credentials = gauth.ServiceAccountCredentials.fromJson(jsonMap);

      final httpClient = http.Client();
      final authClient = await gauth.clientViaServiceAccount(
        credentials,
        _scopes,
        baseClient: httpClient,
      );

      final token = authClient.credentials.accessToken.data;
      authClient.close();
      httpClient.close();
      return token;
    } catch (e) {
      debugPrint('FcmService: access token error: $e');
      return null;
    }
  }

  /// Best-effort remote push. Primary delivery uses [IncomingNotificationService].
  static Future<void> sendToUser({
    required String recipientUid,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (recipientUid == myUid) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientUid)
          .get();

      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken']?.toString();
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('FcmService: no token for $recipientUid');
        return;
      }

      final notificationsEnabled = userData?['notificationsEnabled'] ?? true;
      if (notificationsEnabled != true) return;

      final accessToken = await _getAccessToken();
      if (accessToken == null) return;

      final jsonStr =
          await rootBundle.loadString('assets/service_account.json');
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      final projectId = jsonMap['project_id'] as String;

      final url =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final payload = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'android': {
            'notification': {
              'channel_id': 'likealocal_channel',
              'priority': 'HIGH',
            },
          },
          'apns': {
            'payload': {
              'aps': {'sound': 'default'},
            },
          },
          if (data != null)
            'data': data.map((k, v) => MapEntry(k, v.toString())),
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'FcmService: send failed (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('FcmService: send error: $e');
    }
  }
}
