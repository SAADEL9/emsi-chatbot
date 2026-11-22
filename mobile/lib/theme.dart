import 'package:flutter/material.dart';

class EmsiColors {
  static const navy = Color(0xFF1B2B4A);
  static const navyDeep = Color(0xFF15233D);
  static const ink = Color(0xFF1A2744);
  static const muted = Color(0xFF6B7A90);
  static const canvas = Color(0xFFF4F7FC);
  static const mist = Color(0xFFD7E6F6);
  static const bubbleUser = Color(0xFF1E3358);
  static const online = Color(0xFF3DDC84);
}

ThemeData emsiTheme() {
  const scheme = ColorScheme.light(
    primary: EmsiColors.navy,
    onPrimary: Colors.white,
    secondary: EmsiColors.mist,
    surface: EmsiColors.canvas,
    onSurface: EmsiColors.ink,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: EmsiColors.canvas,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w800,
        color: EmsiColors.ink,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(fontWeight: FontWeight.w800, color: EmsiColors.ink),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, color: EmsiColors.ink),
      bodyMedium: TextStyle(height: 1.4, color: EmsiColors.ink),
      bodySmall: TextStyle(color: EmsiColors.muted),
    ),
  );
}
