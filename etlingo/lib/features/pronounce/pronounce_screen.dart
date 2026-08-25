import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/audio_speed_button.dart';
import '../../core/widgets/et_button.dart';
import '../../data/models.dart';
import '../../services/audio_service.dart';

/// Repeat-after-me trainer: hear the native clip, record yourself,
/// then compare both side by side.
class PronounceScreen extends StatefulWidget {
  final Phrase phrase;
  final Color accent;

  const PronounceScreen({super.key, required this.phrase, required this.accent});

  @override
  State<PronounceScreen> createState() => _PronounceScreenState();
}

enum _RecState { idle, recording, done }

class _PronounceScreenState extends State<PronounceScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _mePlayer = AudioPlayer();

  _RecState _state = _RecState.idle;
  int _seconds = 0;
  String? _myClipPath;
  Timer? _timer;
  bool _playingMine = false;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _mePlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_state == _RecState.recording) {
      final path = await _recorder.stop();
      _timer?.cancel();
      setState(() {
        _state = _RecState.done;
        _myClipPath = path ?? _myClipPath;
      });
      return;
    }
    if (!await _recorder.hasPermission()) return;
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/etlingo_pronounce_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100, bitRate: 96000),
      path: path,
    );
    setState(() {
      _state = _RecState.recording;
      _seconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _seconds++));
  }

  Future<void> _playMine() async {
    final path = _myClipPath;
    if (path == null) return;
    try {
      await _mePlayer.play(DeviceFileSource(path));
      setState(() => _playingMine = true);
      await _mePlayer.onPlayerComplete.first;
      if (mounted) setState(() => _playingMine = false);
    } catch (_) {
      if (mounted) setState(() => _playingMine = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.phrase;
    return PopScope(
      canPop: _state != _RecState.recording,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: EtColors.muted),
                    ),
                    Text('Pronounce',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: EtColors.ink)),
                  ],
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        decoration: BoxDecoration(
                          color: EtColors.card,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: EtColors.line, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Text(p.target,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15)),
                            if (p.translit.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(p.translit,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w600,
                                      color: EtColors.muted)),
                            ],
                            const SizedBox(height: 6),
                            Text(p.meaning,
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: widget.accent.computeLuminance() > 0.6
                                        ? EtColors.greenDark
                                        : widget.accent)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      _sectionLabel('1 · Hear it'),
                      Row(
                        children: [
                          Expanded(
                            child: EtButton(
                              'Native audio',
                              icon: Icons.volume_up_rounded,
                              style: EtStyle.primary,
                              onPressed: () =>
                                  AudioService.instance.play(p.audioUrl),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const AudioSpeedButton(),
                        ],
                      ),

                      const SizedBox(height: 22),
                      _sectionLabel('2 · Say it'),
                      Center(child: _buildRecordArea()),
                      if (_state == _RecState.recording)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('Recording… $_seconds s',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: EtColors.red)),
                        ),

                      const SizedBox(height: 22),
                      _sectionLabel('3 · Compare'),
                      Row(
                        children: [
                          Expanded(
                            child: _compareChip('Native', Icons.record_voice_over_rounded,
                                () => AudioService.instance.play(p.audioUrl)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _compareChip('You', Icons.mic_rounded,
                                _playMine,
                                enabled: _state == _RecState.done,
                                active: _playingMine),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  'Tip: play both clips back to back and match the rhythm, not just the sounds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: EtColors.locked.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: EtColors.muted)),
      );

  Widget _buildRecordArea() {
    final recording = _state == _RecState.recording;
    return GestureDetector(
      onTap: _toggleRecord,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: recording ? EtColors.red : (_state == _RecState.done ? EtColors.green : widget.accent),
          boxShadow: EtShadows.lift(recording ? EtColors.red : widget.accent),
        ),
        child: Icon(
          recording ? Icons.stop_rounded : Icons.mic_rounded,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _compareChip(String label, IconData icon, VoidCallback onTap,
      {bool enabled = true, bool active = false}) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? widget.accent.withValues(alpha: 0.12) : EtColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: active ? widget.accent : EtColors.line, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: enabled ? EtColors.greenDark : EtColors.locked),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: enabled ? EtColors.ink : EtColors.locked)),
            ],
          ),
        ),
      ),
    );
  }
}
