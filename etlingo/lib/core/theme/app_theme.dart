import 'package:flutter/material.dart';

/// Ethiopian flag + white/dark design system for etLingo.
class EtColors {
  static const green = Color(0xFF078930);
  static const greenDark = Color(0xFF056B24);
  static const greenDeep = Color(0xFF04150C);
  static const greenMid = Color(0xFF0A3D1F);
  static const yellow = Color(0xFFF7C60A);
  static const yellowSoft = Color(0xFFFFE97A);
  static const yellowDark = Color(0xFFC99E00);
  static const red = Color(0xFFDA121A);
  static const redDark = Color(0xFFA80E14);
  static const blue = Color(0xFF0F47AF);
  static const blueDark = Color(0xFF0B3685);

  // White / dark chrome (no cream/grey wash)
  static const ink = Color(0xFF111111);
  static const paper = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFFFF);
  static const cream = Color(0xFFFFFFFF);
  static const line = Color(0xFFE8E8E8);
  static const muted = Color(0xFF6B6B6B);
  static const locked = Color(0xFFA3A3A3);
  static const gold = Color(0xFFE8A800);
  static const heart = Color(0xFFFF6B7A);

  static const flag = [green, yellow, red];
  static const tibebPalette = [yellow, green, red, blue];

  static const courseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A3D1F), Color(0xFF04150C)],
  );
}

class EtShadows {
  static List<BoxShadow> lift(Color base, {double y = 4}) => [
        BoxShadow(
          color: base.withValues(alpha: 0.9),
          offset: Offset(0, y),
          blurRadius: 0,
        ),
      ];

  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      offset: const Offset(0, 6),
      blurRadius: 16,
    ),
  ];

  static List<BoxShadow> glow(Color color, {double blur = 22, double y = 8}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.32),
          blurRadius: blur,
          offset: Offset(0, y),
        ),
      ];
}

ThemeData buildEtTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: EtColors.green,
    brightness: Brightness.light,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: EtColors.paper,
    textTheme: base.textTheme.apply(
      bodyColor: EtColors.ink,
      displayColor: EtColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: EtColors.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: EtColors.ink),
      titleTextStyle: TextStyle(
        color: EtColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: EtColors.ink,
    ),
    dividerTheme: const DividerThemeData(color: EtColors.line),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
