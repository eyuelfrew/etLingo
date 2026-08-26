import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

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

  /// One-time setup. Must be called before the token is used so that:
  ///   - Android 13+ runtime notification permission is requested, and
  ///   - messages still appear in the system tray while the app is open.
  static Future<void> init() async {
    if (!isSupported) return;
    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {
      // Foreground presentation is optional; token registration still works.
    }
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