import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart' as gauth;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FcmService {
  static const _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging'
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
      return null;
    }
  }

  static Future<void> sendToUser({
    required String recipientUid,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (recipientUid == myUid) return;

    try {
      // 1. Get recipient FCM token
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientUid)
          .get();

      final fcmToken = userDoc.data()?['fcmToken']?.toString();
      if (fcmToken == null || fcmToken.isEmpty) return;

      // 2. Get OAuth2 token
      final accessToken = await _getAccessToken();
      if (accessToken == null) return;

      // 3. Get project ID from service account
      final jsonStr =
          await rootBundle.loadString('assets/service_account.json');
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      final projectId = jsonMap['project_id'] as String;

      // 4. Call FCM HTTP v1 API
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
              'priority': 'high',
            }
          },
          'apns': {
            'payload': {
              'aps': {'sound': 'default'}
            }
          },
          if (data != null) 'data': data,
        }
      };

      await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
    } catch (e) {
      // Fail silently — push is non-critical
    }
  }
}