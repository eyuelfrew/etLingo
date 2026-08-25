import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConfettiRain extends StatefulWidget {
  final bool active;
  final int count;
  const ConfettiRain({super.key, this.active = true, this.count = 90});

  @override
  State<ConfettiRain> createState() => _ConfettiRainState();
}

class _ConfettiRainState extends State<ConfettiRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(7);
    _particles = List.generate(widget.count, (i) {
      return _Particle(
        x: rng.nextDouble(),
        speed: 0.10 + rng.nextDouble() * 0.16,
        phase: rng.nextDouble(),
        sway: 0.01 + rng.nextDouble() * 0.03,
        size: 6 + rng.nextDouble() * 7,
        spin: rng.nextDouble() * 2 * math.pi,
        color: EtColors.tibebPalette[rng.nextInt(EtColors.tibebPalette.length)],
        round: rng.nextBool(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(_particles, _controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  final double x;
  final double speed;
  final double phase;
  final double sway;
  final double size;
  final double spin;
  final Color color;
  final bool round;
  const _Particle({
    required this.x,
    required this.speed,
    required this.phase,
    required this.sway,
    required this.size,
    required this.spin,
    required this.color,
    required this.round,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final progress = ((t * p.speed + p.phase) % 1.2);
      final y = progress * (size.height * 1.15) - size.height * 0.08;
      final x = p.x * size.width +
          math.sin(progress * math.pi * 3 + p.spin) * p.sway * size.width;
      final fade = progress < 0.06
          ? progress / 0.06
          : progress > 1.05
              ? (1.2 - progress) / 0.15
              : 1.0;
      final paint = Paint()..color = p.color.withValues(alpha: fade.clamp(0, 1));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 6 * math.pi + p.spin);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size * 0.7, height: p.size),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
