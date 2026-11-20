import 'package:flutter/services.dart';

/// Centralized haptic feedback coordinator for the Sique Clean-Room Design System.
///
/// Wraps native platform haptics with defensive error handling so haptic failures
/// never interrupt UI interactions or crash headless test harnesses.
class AppHaptics {
  AppHaptics._();

  /// Extremely subtle micro-tap for incremental stepper changes and sliders.
  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Light tactile confirmation for card presses, button clicks, and chip selections.
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium tactile confirmation for modal opens, major state toggles, and sync completions.
  static Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy tactile feedback for destructive confirmations or significant threshold events.
  static Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Success completion pattern (quick sequence of light taps or medium vibrate).
  static Future<void> successFeedback() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Cautionary alert or invalid input bounce.
  static Future<void> warningFeedback() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
