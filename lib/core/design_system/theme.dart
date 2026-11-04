import 'package:flutter/material.dart';

class PgTheme {
  static const blue = Color(0xff3156f5);
  static const analyticsCanvas = Color(0xfff7f7fb);
  static const positive = Color(0xff13bd88);
  static const negative = Color(0xffed747b);
  static const analyticsInk = Color(0xff171923);
  static const canvas = Color(0xfff1f4ff);
  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? scheme.surface : canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: blue,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
    );
  }
}
