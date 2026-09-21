import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Named icon palette so every surface uses the same Ethio color language.
class EtIcons {
  static const learn = EtColors.green;
  static const words = EtColors.yellowDark;
  static const rank = EtColors.gold;
  static const you = EtColors.blue;

  static const streak = Color(0xFFFF8A3D);
  static const xp = EtColors.yellowDark;
  static const hearts = EtColors.heart;
  static const lessons = EtColors.green;
  static const league = Color(0xFFE6A817);
  static const language = EtColors.blue;
  static const baseLang = EtColors.green;
  static const appLang = Color(0xFF6B5BD2);
  static const notify = Color(0xFFD4890A);
  static const notifySettings = EtColors.blueDark;
  static const signOut = EtColors.red;
  static const audio = EtColors.green;
  static const search = EtColors.muted;
  static const settings = EtColors.ink;

  /// Soft circular tile behind an icon.
  static Widget tile({
    required IconData icon,
    required Color color,
    double size = 44,
    double? iconSize,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: color, size: iconSize ?? size * 0.48),
    );
  }

  /// Square-ish rounded badge tile for settings rows.
  static Widget rowTile({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

/// Full-bleed hero card with Ethio gradient + optional child.
class EtHeroCard extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  const EtHeroCard({
    super.key,
    required this.child,
    this.colors = const [EtColors.greenMid, EtColors.greenDeep],
    this.padding = const EdgeInsets.all(18),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Settings list row used on Profile.
class EtSettingsRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const EtSettingsRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: EtColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: EtColors.line.withValues(alpha: 0.8)),
          ),
          child: Row(
            children: [
              EtIcons.rowTile(icon: icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: EtColors.ink,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: EtColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: color.withValues(alpha: 0.7),
                    size: 22,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
