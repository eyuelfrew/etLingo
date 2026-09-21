import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Plays admin-recorded pronunciation clips (local /audio or S3 proxy /api/v1/media/…).
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();
  String? _lastPlayed;
  double _rate = 1.0;
  String? lastError;

  /// Current playback speed (1.0, 0.75 or 0.5).
  double get rate => _rate;

  /// API origin used to resolve relative media paths (e.g. http://192.168.x.x:5050).
  static String get apiOrigin =>
      defaultApiBaseUrl.replaceFirst(RegExp(r'/api/v\d+/?$'), '');

  void setRate(double rate) {
    _rate = rate;
    _player.setPlaybackRate(rate);
  }

  /// Turns `/api/v1/media/…` or `/audio/…` into an absolute URL on the API host.
  static String resolve(String url, {String? apiBaseUrl}) {
    if (url.isEmpty || RegExp(r'^https?://').hasMatch(url)) return url;
    final origin =
        (apiBaseUrl ?? defaultApiBaseUrl).replaceFirst(RegExp(r'/api/v\d+/?$'), '');
    final path = url.startsWith('/') ? url : '/$url';
    return '$origin$path';
  }

  Future<void> play(String url) async {
    if (url.isEmpty) {
      debugPrint('[audio] empty url — nothing to play');
      return;
    }
    final resolved = resolve(url);
    lastError = null;
    try {
      if (_lastPlayed == resolved) {
        await _player.stop();
      }
      _lastPlayed = resolved;
      await _player.setPlaybackRate(_rate);
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(UrlSource(resolved));
      debugPrint('[audio] play $resolved');
    } catch (e) {
      lastError = e.toString();
      // Typical causes: wrong API host on a physical phone, backend down,
      // or Android blocking cleartext HTTP.
      debugPrint('[audio] FAILED $resolved → $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }
}
