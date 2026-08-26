import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Renders notifications into the system tray locally (the "Telegram way").
///
/// FCM only auto-shows a notification while the app is in the background or
/// terminated. When our app is **foreground**, FCM hands the message to
/// `onMessage` and does NOT draw it — so we post it ourselves here, which is
/// exactly how messaging apps surface their own notifications. This also gives
/// us control over the tap behaviour (open the notifications screen).
class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'etlingo_notifications';
  static const String _channelName = 'Notifications';
  static const String _channelDesc = 'EtLingo announcements and lesson alerts';

  static bool get isSupported {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// One-time setup: create the Android channel and request permission (iOS).
  /// Must run before the app uses [show]. Safe no-op on non-mobile platforms.
  static Future<void> init() async {
    if (!isSupported) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(android: android, iOS: darwin);
      await _plugin.initialize(settings: settings);
    } catch (_) {
      // Notification rendering is best-effort; never crash app startup.
    }
  }

  /// Post a notification to the system tray. `payload` can carry a route so the
  /// tap handler knows where to go (e.g. `notifications`).
  static Future<void> show({
    required String title,
    required String body,
    String route = 'notifications',
  }) async {
    if (!isSupported) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        channelShowBadge: true,
      );
      const darwinDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );
      await _plugin.show(
        id: title.hashCode & 0x7fffffff,
        title: title,
        body: body,
        notificationDetails: details,
        payload: route,
      );
    } catch (_) {}
  }

  /// Asks the OS to show the notification permission dialog (Android 13+).
  /// Safe to call again if already granted.
  static Future<void> requestPermission() async {
    if (!isSupported) return;
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    } catch (_) {}
  }
}