import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class MessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get FCM token: $e');
      }
      return null;
    }
  }

  void listenToForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        if (kDebugMode) {
          print('Message also contained a notification: ${message.notification}');
        }
      }
    });
  }
}
