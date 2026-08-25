import 'package:audioplayers/audioplayers.dart';

import 'api_client.dart';

/// Plays admin-recorded pronunciation clips.
///
/// Audio paths are stored backend-relative (e.g. `/audio/x.mp3`) and resolved
/// against the API origin so recordings work in any environment.
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();
  String? _lastPlayed;
  double _rate = 1.0;

  /// Current playback speed (1.0, 0.75 or 0.5).
  double get rate => _rate;

  void setRate(double rate) {
    _rate = rate;
    _player.setPlaybackRate(rate);
  }

  static String resolve(String url, {String? apiBaseUrl}) {
    if (url.isEmpty || RegExp(r'^https?://').hasMatch(url)) return url;
    final origin =
        (apiBaseUrl ?? defaultApiBaseUrl).replaceFirst(RegExp(r'/api/v\d+$'), '');
    return '$origin$url';
  }

  Future<void> play(String url) async {
    if (url.isEmpty) return;
    try {
      final resolved = resolve(url);
      if (_lastPlayed == resolved) {
        await _player.stop();
      }
      _lastPlayed = resolved;
      await _player.setPlaybackRate(_rate);
      await _player.play(UrlSource(resolved));
    } catch (_) {
      // Missing/failed clips must never break a lesson.
    }
  }
}
