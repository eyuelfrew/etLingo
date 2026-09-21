import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Soft parchment card used across home surfaces.
class EtCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final Color? color;
  final List<BoxShadow>? boxShadow;
  final BorderRadius? borderRadius;
  final Border? border;

  const EtCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.gradient,
    this.color,
    this.boxShadow,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? EtColors.card) : null,
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(22),
        border: border ?? Border.all(color: EtColors.line, width: 1),
        boxShadow: boxShadow ?? EtShadows.soft,
      ),
      child: child,
    );
  }
}

/// Circular XP / goal progress ring.
class EtProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double stroke;
  final Color color;
  final Color track;
  final Widget? center;
  final String? label;

  const EtProgressRing({
    super.key,
    required this.progress,
    this.size = 48,
    this.stroke = 4.5,
    this.color = Colors.white,
    this.track = Colors.white24,
    this.center,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: stroke,
            backgroundColor: track,
            valueColor: AlwaysStoppedAnimation(color),
            strokeCap: StrokeCap.round,
          ),
          center ??
              Text(
                label ?? '${(value * 100).round()}%',
                style: TextStyle(
                  color: color,
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
        ],
      ),
    );
  }
}

/// Compact stat pill for streak / XP / hearts.
class EtStatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color iconColor;
  final String? label;

  const EtStatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.iconColor,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.1,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Section title with Amharic primary + optional English helper.
class EtSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry padding;

  const EtSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                color: EtColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Flag-stripe accent bar (green / yellow / red).
class EtFlagStripe extends StatelessWidget {
  final double height;
  final BorderRadius? borderRadius;

  const EtFlagStripe({super.key, this.height = 4, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? BorderRadius.circular(4);
    return ClipRRect(
      borderRadius: r,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(child: ColoredBox(color: EtColors.green)),
            Expanded(child: ColoredBox(color: EtColors.yellow)),
            Expanded(child: ColoredBox(color: EtColors.red)),
          ],
        ),
      ),
    );
  }
}
