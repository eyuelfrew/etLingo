import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum EtStyle { primary, danger, info, gold, neutral }

class EtButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final EtStyle style;
  final IconData? icon;
  final bool expanded;
  final double height;
  final double fontSize;

  const EtButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.style = EtStyle.primary,
    this.icon,
    this.expanded = true,
    this.height = 48,
    this.fontSize = 14.5,
  });

  @override
  State<EtButton> createState() => _EtButtonState();
}

class _EtButtonState extends State<EtButton> {
  bool _pressed = false;

  (Color, Color) get _palette {
    switch (widget.style) {
      case EtStyle.primary:
        return (EtColors.green, EtColors.greenDark);
      case EtStyle.danger:
        return (EtColors.red, EtColors.redDark);
      case EtStyle.info:
        return (EtColors.blue, EtColors.blueDark);
      case EtStyle.gold:
        return (EtColors.yellow, EtColors.yellowDark);
      case EtStyle.neutral:
        return (const Color(0xFFF1EBDD), const Color(0xFFD8D0BC));
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    var (fill, shadow) = _palette;
    if (!enabled) {
      fill = EtColors.locked.withValues(alpha: 0.45);
      shadow = EtColors.locked.withValues(alpha: 0.3);
    }

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon,
              color: widget.style == EtStyle.neutral ? EtColors.ink : Colors.white,
              size: widget.fontSize + 6),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: TextStyle(
            color: widget.style == EtStyle.neutral ? EtColors.ink : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: widget.fontSize,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );

    final btn = AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: shadow,
                  offset: Offset(0, _pressed ? 1 : 3),
                )
              ]
            : [],
      ),
      child: Center(child: content),
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 90),
        offset: _pressed ? const Offset(0, 0.06) : Offset.zero,
        child: widget.expanded
            ? SizedBox(width: double.infinity, child: Center(child: btn))
            : btn,
      ),
    );
  }
}
