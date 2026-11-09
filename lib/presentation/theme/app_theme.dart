import 'package:flutter/material.dart';
import 'package:sique/presentation/theme/extensions/macro_colors.dart';
import 'package:sique/presentation/theme/tokens/app_colors.dart';
import 'package:sique/presentation/theme/tokens/app_radii.dart';
import 'package:sique/presentation/theme/tokens/app_spacing.dart';
import 'package:sique/presentation/theme/tokens/app_typography.dart';

export 'extensions/macro_colors.dart';
export 'tokens/app_colors.dart';
export 'tokens/app_motion.dart';
export 'tokens/app_radii.dart';
export 'tokens/app_spacing.dart';
export 'tokens/app_typography.dart';

/// Sique Clean-Room Design System: Deep Obsidian Dark Mode with Adherence-Neutral Accents.
///
/// Centralizes all visual styling tokens, component themes, and macro color extensions.
class AppTheme {
  AppTheme._();

  // ===========================================================================
  // Surface Tokens (Forwarded from AppColors)
  // ===========================================================================
  static const Color background = AppColors.background;
  static const Color surface = AppColors.surface;
  static const Color cardSurface = AppColors.cardSurface;
  static const Color cardElevated = AppColors.cardElevated;
  static const Color cardBorder = AppColors.cardBorder;

  // ===========================================================================
  // Signature Sique Nutritional Accents (Forwarded from AppColors)
  // ===========================================================================
  static const Color calories = AppColors.calories;
  static const Color protein = AppColors.protein;
  static const Color fat = AppColors.fat;
  static const Color fats = AppColors.fats;
  static const Color carbs = AppColors.carbs;
  static const Color expenditure = AppColors.expenditure;
  static const Color trendWeight = AppColors.trendWeight;
  static const Color activeBlue = AppColors.activeBlue;
  static const Color buttonForeground = AppColors.buttonForeground;

  // ===========================================================================
  // Neutral Text Tokens (Forwarded from AppColors)
  // ===========================================================================
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textMuted = AppColors.textMuted;
  static const Color textTertiary = AppColors.textTertiary;

  // ===========================================================================
  // Status & Informative Tokens (Forwarded from AppColors)
  // ===========================================================================
  static const Color neutralInfo = AppColors.neutralInfo;
  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;

  // ===========================================================================
  // Centralized Dark ThemeData
  // ===========================================================================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: calories,
      fontFamily: AppTypography.fontFamily,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: calories,
        secondary: expenditure,
        tertiary: protein,
        onSurface: textPrimary,
        outline: cardBorder,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineSmall,
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: cardBorder,
        thickness: 1,
        space: 1,
      ),

      // Typography Scale (15 M3 Roles via AppTypography)
      textTheme: AppTypography.textTheme,

      // SnackBar Component Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cardElevated,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: textPrimary,
        ),
        actionTextColor: calories,
      ),

      // Dialog Component Theme
      dialogTheme: DialogThemeData(
        backgroundColor: cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: textPrimary,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: textSecondary,
        ),
      ),

      // Input Decoration Component Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: cardBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: cardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: activeBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: protein, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: protein, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: textSecondary,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: textMuted,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(
          color: protein,
        ),
      ),

      // Elevated Button Component Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: calories,
          foregroundColor: buttonForeground,
          disabledBackgroundColor: cardElevated,
          disabledForegroundColor: textMuted,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: buttonForeground,
          ),
        ),
      ),

      // Outlined Button Component Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          disabledForegroundColor: textMuted,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          side: const BorderSide(color: cardBorder, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ),

      // Bottom Sheet Component Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.lg),
          ),
          side: BorderSide(color: cardBorder, width: 1),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      ),

      // Page Transitions Theme
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),

      // Bottom Navigation Bar Component Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: calories,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Theme Extensions (Macro Semantic Colors)
      extensions: const [
        MacroColorsExtension.dark,
      ],
    );
  }
}
