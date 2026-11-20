import 'package:flutter/material.dart';

/// Centralized corner radius tokens for the Sique Clean-Room Design System.
///
/// Standardizes component rounding from micro tags and badges to pill buttons.
class AppRadii {
  AppRadii._();

  // ===========================================================================
  // Corner Radius Tokens
  // ===========================================================================

  /// 0.0 logical pixels. Sharp rectangular edges.
  static const double none = 0.0;

  /// 8.0 logical pixels. Small tags, status chips, and micro badges.
  static const double sm = 8.0;

  /// 12.0 logical pixels. Form inputs, secondary buttons, and mini cards.
  static const double md = 12.0;

  /// 16.0 logical pixels. Standard cards, dialogs, and primary containers.
  static const double lg = 16.0;

  /// 20.0 logical pixels. Tactile bouncy cards and prominent sheets.
  static const double xl = 20.0;

  /// 999.0 logical pixels. Pill buttons, search bars, and circular indicators.
  static const double pill = 999.0;

  // ===========================================================================
  // BorderRadius Tokens
  // ===========================================================================

  static const BorderRadius noneBorderRadius = BorderRadius.zero;
  static const BorderRadius smBorderRadius =
      BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdBorderRadius =
      BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgBorderRadius =
      BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlBorderRadius =
      BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillBorderRadius =
      BorderRadius.all(Radius.circular(pill));

  /// Semantic BorderRadius Aliases
  static const BorderRadius card = lgBorderRadius;
  static const BorderRadius cardLarge = xlBorderRadius;
  static const BorderRadius button = mdBorderRadius;
  static const BorderRadius pillShape = pillBorderRadius;

  // ===========================================================================
  // Sheet Top Rounded BorderRadius Tokens
  // ===========================================================================

  static const BorderRadius topMdBorderRadius = BorderRadius.vertical(
    top: Radius.circular(md),
  );

  static const BorderRadius topLgBorderRadius = BorderRadius.vertical(
    top: Radius.circular(lg),
  );

  static const BorderRadius topXlBorderRadius = BorderRadius.vertical(
    top: Radius.circular(xl),
  );

  // ===========================================================================
  // Radius Objects (for Shapes and Sliders)
  // ===========================================================================

  static const Radius noneRadius = Radius.zero;
  static const Radius smRadius = Radius.circular(sm);
  static const Radius mdRadius = Radius.circular(md);
  static const Radius lgRadius = Radius.circular(lg);
  static const Radius xlRadius = Radius.circular(xl);
  static const Radius pillRadius = Radius.circular(pill);
}
