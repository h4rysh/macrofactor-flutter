import 'package:flutter/material.dart';
import 'package:sique/presentation/theme/tokens/app_colors.dart';

/// Centralized typography tokens for the Sique Clean-Room Design System.
///
/// Implements deterministic static typography with the open-licensed 'Inter'
/// font family across all 15 Material 3 scale roles, plus tabular figures
/// for jitter-free numeric readouts and animations.
class AppTypography {
  AppTypography._();

  /// Default typeface family across the application.
  static const String fontFamily = 'Inter';

  // ===========================================================================
  // Material 3 Scale Roles (Static Definitions)
  // ===========================================================================

  /// Display Large: 32px, Bold 800, -0.5 letter spacing, tabular figures.
  /// Used for prominent splash and welcome screen headers.
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -0.5,
    height: 1.25,
  );

  /// Display Medium: 28px, Bold 800, -0.5 letter spacing, tabular figures.
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -0.5,
    height: 1.25,
  );

  /// Display Small: 24px, Bold 800, -0.25 letter spacing, tabular figures.
  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -0.25,
    height: 1.25,
  );

  /// Headline Large: 28px, Bold 700, tabular figures.
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -0.25,
    height: 1.3,
  );

  /// Headline Medium: 24px, Bold 700, tabular figures.
  /// Standard screen top-level headings and major card titles.
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: 0.0,
    height: 1.3,
  );

  /// Headline Small: 20px, Bold 700, tabular figures.
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: 0.0,
    height: 1.35,
  );

  /// Title Large: 18px, SemiBold 600, tabular figures.
  /// Card titles, dialog titles, and modal headers.
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: 0.0,
    height: 1.4,
  );

  /// Title Medium: 15px, SemiBold 600.
  /// Section subheaders and list item titles.
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
    height: 1.4,
  );

  /// Title Small: 14px, SemiBold 600.
  /// Compact group headers and table column titles.
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
    height: 1.4,
  );

  /// Body Large: 16px, Regular 400.
  /// Primary paragraph text and body reading content.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0.15,
    height: 1.5,
  );

  /// Body Medium: 14px, Regular 400.
  /// Standard UI descriptions, subtexts, and form fields.
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.25,
    height: 1.5,
  );

  /// Body Small: 12px, Regular 400.
  /// Secondary captions, hints, and timestamp text.
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    letterSpacing: 0.4,
    height: 1.4,
  );

  /// Label Large: 14px, Bold 700, 0.5 letter spacing.
  /// Primary button text, pill button text, and action labels.
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.25,
  );

  /// Label Medium: 12px, SemiBold 600, 0.5 letter spacing.
  /// Compact action badges, status tags, and chips.
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.25,
  );

  /// Label Small: 11px, SemiBold 600, 0.5 letter spacing.
  /// Micro badges and bottom nav bar indicator text.
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
    height: 1.25,
  );

  // ===========================================================================
  // Tabular Numeric Styles & Helpers
  // Applies FontFeature.tabularFigures() to eliminate horizontal digit jitter.
  // ===========================================================================

  /// Base numeric style with tabular figures enabled.
  static const TextStyle numeric = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Helper to enforce tabular figures on any [base] style.
  static TextStyle tabularNumber(TextStyle base) => withTabularFigures(base);

  /// Wraps any given [base] style with tabular figures enabled.
  static TextStyle withTabularFigures(TextStyle base) {
    final existing = base.fontFeatures ?? const [];
    return base.copyWith(
      fontFamily: base.fontFamily ?? fontFamily,
      fontFeatures: [
        ...existing.where((f) => f.feature != 'tnum'),
        const FontFeature.tabularFigures(),
      ],
    );
  }

  /// Large numeric readout (e.g. Hero calories: 36px, Bold).
  static const TextStyle numericDisplay = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -0.5,
    height: 1.2,
  );

  /// Prominent numeric stat readout (e.g. Energy balance / Expenditure: 30-32px, Bold).
  static const TextStyle numericLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -0.25,
    height: 1.2,
  );

  /// Medium numeric stat readout (e.g. Card metrics: 24px, Bold).
  static const TextStyle numericMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.25,
  );

  /// Small numeric stat readout (e.g. Table numbers / targets: 16px, SemiBold).
  static const TextStyle numericSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.3,
  );

  /// Micro numeric readout (e.g. Macro grams / bar labels: 11-12px, SemiBold).
  static const TextStyle numericCaption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.3,
  );

  // ===========================================================================
  // Complete Material 3 TextTheme
  // ===========================================================================

  /// Assembled Material 3 [TextTheme] containing all 15 standardized roles.
  static const TextTheme textTheme = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
