import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/api_client.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background messages are handled by the OS notification tray.
  // No additional processing needed here.
}

/// Firebase Cloud Messaging setup for the HIV/TB Monitor mobile app.
///
/// Usage:
///   1. Call [FcmService.initialize] once in main() after Firebase.initializeApp()
///   2. Call [FcmService.registerToken] after each successful login
///   3. The service handles foreground notification display automatically
///
/// If Firebase is not configured (no google-services.json), initialization
/// fails silently and push notifications are simply not received.
class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'hivtb_alerts';
  static const _channelName = 'HIV/TB Alerts';
  static const _channelDesc = 'LTFU tracing, missed dose, and clinical alerts';

  /// Initialize FCM — call once in main() after Firebase.initializeApp().
  static Future<void> initialize() async {
    // Request permission (Android 13+ and iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Set up local notification channel (Android)
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    // Show local notification for foreground FCM messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    });
  }

  /// Get the current device FCM token.
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Register FCM token with the backend after login.
  /// Silent failure — if FCM or network is unavailable the app works normally.
  static Future<void> registerToken(ApiClient client) async {
    try {
      final token = await getToken();
      if (token == null) return;
      await client.post('/api/auth/fcm-token', data: {'token': token});
    } catch (_) {
      // Not critical — push notifications simply won't work for this session
    }
  }
}
