import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'local_notification_service.dart';

/// Top-level background handler — required by Firebase Messaging registration.
/// Runs in its own isolate when the app is backgrounded/terminated.
///
/// IMPORTANT: do NOT post a local notification here for messages that carry a
/// `notification` payload — Android/iOS already render those into the tray
/// themselves while the app is not in the foreground. Re-showing them here
/// would produce duplicates. This hook exists so future data-only payloads can
/// be handled explicitly.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Data-only messages are not rendered by the OS; surface them ourselves.
  // Notification-payload messages fall through — the OS already showed them.
  if (message.notification == null) {
    final title = message.data['title'];
    final body = message.data['body'];
    if (title != null && body != null) {
      await LocalNotificationService.show(title: title, body: body);
    }
  }
}

/// Thin wrapper around [FirebaseMessaging] that keeps FCM concerns out of the
/// auth layer. It exposes the current device token and listens for OS-driven
/// rotations, leaving *who* gets registered (the signed-in learner) to
/// [AuthService].
///
/// FCM is only supported on Android/iOS/macOS (+ web). Windows / Linux desktop
/// have no Firebase Messaging, so [isSupported] guards every call to keep those
/// builds safe while still letting the mobile app guarantee registration.
class PushNotificationService {
  PushNotificationService._();

  /// Whether this platform can obtain an FCM token / receive push at all.
  static bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  /// One-time setup. Call before the UI is shown so that:
  ///   - the local-notification channel is ready to draw tray notifications,
  ///   - Android 13+ notification permission is requested,
  ///   - the background handler is registered,
  ///   - message streams (foreground) are wired to our local renderer.
  static Future<void> init({void Function(String route)? onOpen}) async {
    if (!isSupported) return;

    // Request permission up front so tray notifications are allowed.
    await LocalNotificationService.init();
    await LocalNotificationService.requestPermission();

    // Foreground: FCM will NOT draw it — we must post it ourselves.
    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n != null) {
        LocalNotificationService.show(title: n.title ?? '', body: n.body ?? '');
      }
    });

    // App opened by tapping a notification (background/terminated).
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final n = message.notification;
      if (n != null) onOpen?.call(n.title ?? '');
    });

    // App launched cold by tapping a notification that arrived while terminated.
    final initial = await _messaging.getInitialMessage();
    if (initial?.notification != null) {
      onOpen?.call(initial!.notification!.title ?? '');
    }

    // Background/terminated delivery (also declare at top of file).
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Keep foreground presentation enabled as a belt-and-braces extra.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Requests notification permission and returns the current FCM token for
  /// this device.
  ///
  /// Returns `null` when FCM is unsupported here, permission was denied, or no
  /// token is currently available. On mobile this is a real attempt; [AuthService]
  /// treats mobile failure as something to retry/flag rather than silently pass.
  static Future<String?> obtainToken() async {
    if (!isSupported) return null;
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }
      return await _messaging.getToken();
    } catch (_) {
      return null; // never crash startup over push availability
    }
  }

  /// Fires every time Firebase rotates the device token (re-sign-in, expiry).
  static Stream<String> onTokenRefresh() {
    if (!isSupported) return const Stream.empty();
    return _messaging.onTokenRefresh;
  }
}