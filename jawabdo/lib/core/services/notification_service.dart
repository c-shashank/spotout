import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages — Firebase already initialised by main()
  debugPrint('Background FCM: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init(Function(RemoteMessage) onMessageTap) async {
    // Request permission (iOS)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground FCM: ${message.notification?.title}');
      // Show in-app banner (handled by app's notification overlay)
    });

    // Tap from background
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageTap);

    // Tap from terminated state
    final initial = await _fcm.getInitialMessage();
    if (initial != null) onMessageTap(initial);
  }

  Future<String?> getToken() async {
    return _fcm.getToken();
  }

  Future<void> subscribeToWard(String wardId) async {
    await _fcm.subscribeToTopic('ward_$wardId');
  }

  Future<void> unsubscribeFromWard(String wardId) async {
    await _fcm.unsubscribeFromTopic('ward_$wardId');
  }

  Future<void> updateFcmToken(String userId, String token) async {
    // Store FCM token in Supabase for server-side push targeting
    // Implemented server-side; just log here
    debugPrint('FCM token for $userId: $token');
  }
}
