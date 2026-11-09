import 'package:flutter/material.dart';

/// Centralized motion tokens for the Sique Clean-Room Design System.
///
/// Standardizes animation durations and easing curves across transitions,
/// tactile touches, and count-up counters.
class AppMotion {
  AppMotion._();

  // ===========================================================================
  // Standard Duration Tokens
  // ===========================================================================

  /// 150ms. Fast micro-interactions, button taps, and quick fades.
  static const Duration fast = Duration(milliseconds: 150);

  /// 250ms. Standard component transitions, sheet expansions, and dialogs.
  static const Duration normal = Duration(milliseconds: 250);

  /// 400ms. Screen transitions, hero card staggers, and layout shifts.
  static const Duration slow = Duration(milliseconds: 400);

  // ===========================================================================
  // Specialized Component Durations
  // ===========================================================================

  /// 80–100ms. Tactile pressed state dwell time on quick taps (AppleBouncy).
  static const Duration tactileDwell = Duration(milliseconds: 100);

  /// 650ms. Macro bar progression fill animation.
  static const Duration macroBar = Duration(milliseconds: 650);

  /// 750ms. Count-up numerical animation duration.
  static const Duration countUp = Duration(milliseconds: 750);

  // ===========================================================================
  // Standard Animation Curves
  // ===========================================================================

  /// Standard natural acceleration and deceleration.
  static const Curve standard = Curves.easeInOutCubic;

  /// Emphasized entrance easing with smooth deceleration.
  static const Curve emphasized = Curves.easeOutCubic;

  /// Decelerated easing for quick settle on touch or dismissal.
  static const Curve decelerated = Curves.easeOut;
}
