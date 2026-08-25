import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TibebBand extends StatelessWidget {
  final double height;
  final double opacity;

  const TibebBand({super.key, this.height = 20, this.opacity = 1});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _TibebPainter(),
      ),
    );
  }
}

class _TibebPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final midY = h * 0.5;
    final amp = h * 0.26;
    final step = math.max(size.width / 14, 26).toDouble();

    final zigzag = Path()..moveTo(0, midY + amp);
    var i = 0;
    for (double x = step; x <= size.width + step; x += step) {
      zigzag.lineTo(x, i.isEven ? midY - amp : midY + amp);
      i++;
    }
    canvas.drawPath(
      zigzag,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.13
        ..strokeCap = StrokeCap.round
        ..color = EtColors.green.withValues(alpha: 0.85),
    );

    var colorIdx = 0;
    for (double cx = step / 2; cx < size.width + step / 2; cx += step) {
      final dw = step * 0.30;
      final dh = h * 0.30;
      final diamond = Path()
        ..moveTo(cx, midY - dh)
        ..lineTo(cx + dw, midY)
        ..lineTo(cx, midY + dh)
        ..lineTo(cx - dw, midY)
        ..close();
      canvas.drawPath(diamond, Paint()..color = EtColors.tibebPalette[colorIdx % 4]);
      canvas.drawPath(
        diamond,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.7),
      );
      colorIdx++;

      canvas.drawCircle(
        Offset(cx + step / 2, midY),
        h * 0.055,
        Paint()..color = EtColors.red.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
