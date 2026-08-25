import 'package:flutter/material.dart';

import '../../services/audio_service.dart';
import '../theme/app_theme.dart';

/// Cycles playback speed 1× → ¾× → ½× for every audio player in the app.
class AudioSpeedButton extends StatefulWidget {
  final Color color;
  const AudioSpeedButton({super.key, this.color = EtColors.green});

  @override
  State<AudioSpeedButton> createState() => _AudioSpeedButtonState();
}

class _AudioSpeedButtonState extends State<AudioSpeedButton> {
  static const _speeds = [1.0, 0.75, 0.5];

  static String _labelFor(double rate) =>
      rate == 1.0 ? '1×' : (rate == 0.75 ? '¾×' : '½×');

  void _cycle() {
    final current = AudioService.instance.rate;
    final next = _speeds[(_speeds.indexOf(current) + 1) % _speeds.length];
    setState(() => AudioService.instance.setRate(next));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _cycle,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: widget.color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _labelFor(AudioService.instance.rate),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}
