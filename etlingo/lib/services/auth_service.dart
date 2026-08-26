import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'content_service.dart';
import 'push_notification_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AuthService() {
    _api = ApiClient(tokenProvider: () async => token);
    _content = ContentService(_api);
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _loadPersistedAuth();
  }

  late final ApiClient _api;
  late final ContentService _content;

  ContentService get content => _content;

  User? _user;
  String? _token;
  String? _displayName;
  String? _email;
  String? _photoUrl;
  bool _loading = false;

  static const String _tokenKey = 'etlingo_app_token';
  static const String _userKey = 'etlingo_app_user';

  User? get user => _user;
  String? get token => _token;
  String? get displayName => _displayName;
  String? get email => _email;
  String? get photoUrl => _photoUrl;
  bool get loading => _loading;
  bool get isSignedIn => _user != null || _token != null;

  Future<void> _loadPersistedAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      final data = jsonDecode(userJson) as Map<String, dynamic>;
      _displayName = data['displayName'] as String?;
      _email = data['email'] as String?;
      _photoUrl = data['photoUrl'] as String?;
      notifyListeners();
    }
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      _displayName = user.displayName ?? _displayName;
      _email = user.email ?? _email;
      _photoUrl = user.photoURL ?? _photoUrl;
    }
    notifyListeners();
  }

  Future<void> _persistUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) await prefs.setString(_tokenKey, _token!);
    final userJson = jsonEncode({
      'displayName': _displayName,
      'email': _email,
      'photoUrl': _photoUrl,
    });
    await prefs.setString(_userKey, userJson);
  }

  Future<void> signInWithGoogle() async {
    try {
      _loading = true;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _loading = false;
        notifyListeners();
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;

      _displayName = _user?.displayName ?? googleUser.displayName;
      _email = _user?.email ?? googleUser.email;
      _photoUrl = _user?.photoURL ?? googleUser.photoUrl;

      final idToken = await _user?.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      final data = await _api.post('/app/auth/google', body: {'idToken': idToken}, auth: false);
      if (data is Map<String, dynamic>) {
        _token = data['token'] as String?;
        final userData = data['user'];
        if (userData is Map<String, dynamic>) {
          _displayName = userData['displayName'] as String? ?? _displayName;
          _email = userData['email'] as String? ?? _email;
        }
        await _persistUser();
      }
      // Register this device for push once the app session exists.
      await registerPushToken();
    } catch (e) {
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── FCM device-token registration ───────────────────────────────────────────
  // The push token is treated as a hard requirement on mobile: it is registered
  // every time a session goes live (fresh sign-in and persisted cold-start) and
  // removed on sign-out. Desktop/unsupported platforms are skipped so the app
  // still works, but a mobile device will always attach its token.

  /// Register the current device's FCM token for the signed-in user.
  ///
  /// Returns `true` when the token was uploaded, `false` when there is no
  /// session, FCM is unsupported here, permission was denied, or the upload
  /// failed (the [onTokenRefresh] listener will retry on the next rotation).
  Future<bool> registerPushToken() async {
    if (_token == null) return false;
    if (!PushNotificationService.isSupported) {
      debugPrint('FCM not supported on this platform — skipping token upload');
      return false;
    }
    final fcm = await PushNotificationService.obtainToken();
    if (fcm == null) {
      debugPrint('FCM token unavailable (permission denied?) — not uploaded');
      return false;
    }
    try {
      await _api.post('/app/devices/token', body: {'fcmToken': fcm});
      debugPrint('FCM token registered for user $_user ($_email)');
      return true;
    } catch (e) {
      // Retried next session / token rotation. Sign-in itself still succeeds.
      debugPrint('FCM token upload failed: $e');
      return false;
    }
  }

  /// Remove the device from push on sign-out so it stops receiving messages.
  Future<void> unregisterPushToken() async {
    if (_token == null || !PushNotificationService.isSupported) return;
    try {
      await _api.delete('/app/devices/token');
      debugPrint('FCM token removed for user on sign-out');
    } catch (e) {
      debugPrint('FCM token removal failed (best-effort): $e');
    }
  }

  /// Keep the stored token in sync with the OS whenever Firebase rotates it.
  /// Call once from the widget tree (e.g. root) after auth is ready.
  void listenForTokenRefresh() {
    PushNotificationService.onTokenRefresh().listen((_) => registerPushToken());
  }

  /// Pull the latest profile (xp/hearts/streak/name) from the backend.
  Future<void> refreshProfile() async {
    if (_token == null) return;
    try {
      final data = await _api.get('/app/auth/profile');
      if (data is Map<String, dynamic>) {
        _displayName = data['displayName'] as String? ?? _displayName;
        _email = data['email'] as String? ?? _email;
        await _persistUser();
        notifyListeners();
      }
    } on ApiException catch (e) {
      // Token expired/revoked → force a clean sign-out so the app re-auths.
      if (e.statusCode == 401) await signOut();
    }
  }

  /// Update the user's display name on the backend.
  Future<void> updateDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final data = await _api.put('/app/auth/profile', body: {'display_name': trimmed});
    if (data is Map<String, dynamic> && data['displayName'] != null) {
      _displayName = data['displayName'] as String?;
      await _persistUser();
      notifyListeners();
    }
  }

  /// Notifications addressed to this user + broadcasts.
  Future<List<AppNotification>> fetchNotifications() async {
    final data = await _api.get('/app/notifications');
    if (data is! List) return const [];
    return data
        .map((j) => AppNotification.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationRead(int id) async {
    await _api.post('/app/notifications/$id/read');
  }

  /// Load this learner's notification opt-in/out settings.
  Future<AppNotificationPrefs> fetchNotificationPrefs() async {
    final data = await _api.get('/app/notifications/preferences');
    if (data is! Map<String, dynamic>) return const AppNotificationPrefs();
    return AppNotificationPrefs.fromJson(data);
  }

  /// Persist a change to the learner's notification settings.
  Future<AppNotificationPrefs> saveNotificationPrefs(
      AppNotificationPrefs prefs) async {
    final data = await _api.put('/app/notifications/preferences', body: prefs.toJson());
    if (data is! Map<String, dynamic>) return prefs;
    return AppNotificationPrefs.fromJson(data);
  }

  Future<void> signOut() async {
    // Deregister this device from push before we drop the session token.
    await unregisterPushToken();
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (_) {}

    _user = null;
    _token = null;
    _displayName = null;
    _email = null;
    _photoUrl = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);

    notifyListeners();
  }
}
