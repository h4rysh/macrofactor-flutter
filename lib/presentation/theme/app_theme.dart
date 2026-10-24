import 'package:flutter/material.dart';

/// Sique Clean-Room Design System: Deep Obsidian Dark Mode with Adherence-Neutral Accents.
class AppTheme {
  AppTheme._();

  // Core Palette (Authentic Obsidian Dark Mode extracted from com.sbs.diet APK)
  static const Color background =
      Color(0xFF0B0B0E); // Authentic Obsidian Pitch Black
  static const Color surface = Color(0xFF141418); // Elevated Dark Card
  static const Color cardSurface = Color(0xFF16161C); // Card Background
  static const Color cardElevated = Color(0xFF1F1F26); // Pill & Input Surface
  static const Color cardBorder = Color(0xFF26262E); // Subtle Hairline Divider

  // Signature Sique Nutritional Accents (Matching log_revamp.png)
  static const Color calories = Color(0xFFFF5722); // Vibrant Flame Orange
  static const Color protein = Color(0xFFFB923C); // Warm Coral / Peach
  static const Color fat = Color(0xFFFACC15); // Bright Golden Amber
  static const Color carbs = Color(0xFF38BDF8); // Electric Cyan Aqua
  static const Color expenditure = Color(0xFF34D399); // Dynamic Emerald Green
  static const Color trendWeight =
      Color(0xFFC084FC); // Smoothed Lavender / Violet
  static const Color activeBlue =
      Color(0xFF0055E1); // Authentic Sique Sapphire Blue

  // Neutral Text & Icons
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9D9DA8);
  static const Color textMuted = Color(0xFF63636E);
  static const Color textTertiary = textMuted;

  // Status & Informative
  static const Color neutralInfo = Color(0xFF38BDF8);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: calories,
      fontFamily: 'MacroSans',
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: calories,
        secondary: expenditure,
        tertiary: protein,
        onSurface: textPrimary,
        outline: cardBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'MacroSans',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: cardBorder,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'MacroSans',
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'MacroSans',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'MacroSans',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'MacroSans',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodySmall: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
        labelLarge: TextStyle(
          fontFamily: 'MacroSans',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: calories,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
