import 'package:flutter/material.dart';

/// Defines application‑wide themes for light and dark modes.  The color
/// palette is based off the prompt specification: a primary blue
/// (#3B82F6) and an accent orange (#F59E0B).  Both themes use
/// Material 3 and employ rounded cards and input elements.  If the
/// [`ThemeProvider`](providers/theme_provider.dart) toggles the
/// `ThemeMode`, these themes are swapped at runtime.
class WordStoryTheme {
  /// Primary brand color used throughout the app.
  static const Color primaryColor = Color(0xFF3B82F6);

  /// Secondary accent color used for highlights and progress bars.
  static const Color accentColor = Color(0xFFF59E0B);

  /// Light mode color scheme derived from the primary seed color.  The
  /// background is set explicitly to a very light grey to match the
  /// specification (`#FAFAFA`).
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ).copyWith(
      primary: primaryColor,
      secondary: accentColor,
    ),
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      iconTheme: IconThemeData(color: Colors.black87),
    ),
  );

  /// Dark mode color scheme derived from the primary seed color.  The
  /// background is set to a near‑black to fulfil the specification
  /// (`#1E1E1E`).  Card surfaces are darkened and text colors are
  /// lightened for better contrast.
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primaryColor,
      secondary: accentColor,
    ),
    scaffoldBackgroundColor: const Color(0xFF1E1E1E),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: const Color(0xFF2A2A2A),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
  );
}
