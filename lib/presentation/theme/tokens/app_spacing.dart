import 'package:flutter/material.dart';

/// Centralized spacing tokens for the Sique Clean-Room Design System.
///
/// Provides a consistent 8-point geometric scale with micro and macro steps.
class AppSpacing {
  AppSpacing._();

  // ===========================================================================
  // Spacing Scale Tokens
  // ===========================================================================

  /// 2.0 logical pixels. Micro hairline separation.
  static const double xxs = 2.0;

  /// 4.0 logical pixels. Tight grouping and compact badge paddings.
  static const double xs = 4.0;

  /// 8.0 logical pixels. Component internal padding and row spacing.
  static const double sm = 8.0;

  /// 12.0 logical pixels. Form field spacing and standard element separation.
  static const double md = 12.0;

  /// 16.0 logical pixels. Standard card padding and screen edge insets.
  static const double lg = 16.0;

  /// 20.0 logical pixels. Generous section gaps and major card padding.
  static const double xl = 20.0;

  /// 24.0 logical pixels. Header spacing and modal sheet top padding.
  static const double xxl = 24.0;

  /// 32.0 logical pixels. Section division and onboarding hero spacing.
  static const double xxxl = 32.0;

  // ===========================================================================
  // Uniform EdgeInsets Insets
  // ===========================================================================

  static const EdgeInsets edgeInsetsZero = EdgeInsets.zero;
  static const EdgeInsets edgeInsetsAllXxs = EdgeInsets.all(xxs);
  static const EdgeInsets edgeInsetsAllXs = EdgeInsets.all(xs);
  static const EdgeInsets edgeInsetsAllSm = EdgeInsets.all(sm);
  static const EdgeInsets edgeInsetsAllMd = EdgeInsets.all(md);
  static const EdgeInsets edgeInsetsAllLg = EdgeInsets.all(lg);
  static const EdgeInsets edgeInsetsAllXl = EdgeInsets.all(xl);
  static const EdgeInsets edgeInsetsAllXxl = EdgeInsets.all(xxl);
  static const EdgeInsets edgeInsetsAllXxxl = EdgeInsets.all(xxxl);

  // ===========================================================================
  // Horizontal & Vertical Symmetric Insets
  // ===========================================================================

  static const EdgeInsets edgeInsetsHorizontalSm =
      EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets edgeInsetsHorizontalMd =
      EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets edgeInsetsHorizontalLg =
      EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets edgeInsetsHorizontalXl =
      EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets edgeInsetsHorizontalXxl =
      EdgeInsets.symmetric(horizontal: xxl);

  static const EdgeInsets edgeInsetsVerticalSm =
      EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets edgeInsetsVerticalMd =
      EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets edgeInsetsVerticalLg =
      EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets edgeInsetsVerticalXl =
      EdgeInsets.symmetric(vertical: xl);
  static const EdgeInsets edgeInsetsVerticalXxl =
      EdgeInsets.symmetric(vertical: xxl);

  // ===========================================================================
  // SizedBox Gap Helpers
  // ===========================================================================

  static const SizedBox gapXxs = SizedBox(width: xxs, height: xxs);
  static const SizedBox gapXs = SizedBox(width: xs, height: xs);
  static const SizedBox gapSm = SizedBox(width: sm, height: sm);
  static const SizedBox gapMd = SizedBox(width: md, height: md);
  static const SizedBox gapLg = SizedBox(width: lg, height: lg);
  static const SizedBox gapXl = SizedBox(width: xl, height: xl);
  static const SizedBox gapXxl = SizedBox(width: xxl, height: xxl);
  static const SizedBox gapXxxl = SizedBox(width: xxxl, height: xxxl);

  static const SizedBox gapHorizontalXxs = SizedBox(width: xxs);
  static const SizedBox gapHorizontalXs = SizedBox(width: xs);
  static const SizedBox gapHorizontalSm = SizedBox(width: sm);
  static const SizedBox gapHorizontalMd = SizedBox(width: md);
  static const SizedBox gapHorizontalLg = SizedBox(width: lg);
  static const SizedBox gapHorizontalXl = SizedBox(width: xl);
  static const SizedBox gapHorizontalXxl = SizedBox(width: xxl);
  static const SizedBox gapHorizontalXxxl = SizedBox(width: xxxl);

  static const SizedBox gapVerticalXxs = SizedBox(height: xxs);
  static const SizedBox gapVerticalXs = SizedBox(height: xs);
  static const SizedBox gapVerticalSm = SizedBox(height: sm);
  static const SizedBox gapVerticalMd = SizedBox(height: md);
  static const SizedBox gapVerticalLg = SizedBox(height: lg);
  static const SizedBox gapVerticalXl = SizedBox(height: xl);
  static const SizedBox gapVerticalXxl = SizedBox(height: xxl);
  static const SizedBox gapVerticalXxxl = SizedBox(height: xxxl);
}
