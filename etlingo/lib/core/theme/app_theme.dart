import 'package:flutter/material.dart';

class EtColors {
  static const green = Color(0xFF078930);
  static const greenDark = Color(0xFF056B24);
  static const yellow = Color(0xFFF7C60A);
  static const yellowDark = Color(0xFFC99E00);
  static const red = Color(0xFFDA121A);
  static const redDark = Color(0xFFA80E14);
  static const blue = Color(0xFF0F47AF);
  static const blueDark = Color(0xFF0B3685);
  static const ink = Color(0xFF241C12);
  static const paper = Color(0xFFFFFBF1);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE8DFCB);
  static const muted = Color(0xFF918A78);
  static const locked = Color(0xFFB9B2A2);

  static const flag = [green, yellow, red];

  static const tibebPalette = [yellow, green, red, blue];
}

class EtShadows {
  static List<BoxShadow> lift(Color base) => [
        BoxShadow(
          color: base,
          offset: const Offset(0, 4),
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
  );
}
