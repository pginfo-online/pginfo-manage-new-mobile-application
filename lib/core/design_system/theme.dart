import 'package:flutter/material.dart';

class PgTheme {
  static const blue = Color(0xff3156f5);
  static const royalBlue = Color(0xff2563eb);
  static const lightBlueBg = Color(0xffedf1ff);
  static const analyticsCanvas = Color(0xfff7f7fb);
  static const positive = Color(0xff13bd88);
  static const negative = Color(0xffed747b);
  static const analyticsInk = Color(0xff171923);
  static const canvas = Color(0xfff1f4ff);
  static const darkCanvas = Color(0xff12141c);
  static const darkCard = Color(0xff1a1d29);
  static const darkHeader = Color(0xff1c2136);

  static Color availableBedBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xff143521)
          : const Color(0xffe8f7e8);

  static Color availableBedFg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xff4ade80)
          : const Color(0xff16a34a);

  static Color occupiedBedBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xff3f1a1d)
          : const Color(0xffffe9e9);

  static Color occupiedBedFg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xfff87171)
          : const Color(0xffdc2626);

  static Color subtleHeaderBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkHeader
          : lightBlueBg;

  static Color cardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkCard
          : Colors.white;

  static Color secondaryBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xff141724)
          : const Color(0xfff8f9fd);

  static Color skeletonBase(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xff22273a)
          : const Color(0xffeceef3);

  static Color skeletonHighlight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xff2d334d)
          : const Color(0xfffafbfc);

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
