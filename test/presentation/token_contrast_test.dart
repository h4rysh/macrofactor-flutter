import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/presentation/theme/tokens/app_colors.dart';

/// Calculates WCAG 2.1 relative luminance for a given [Color].
///
/// Formula: L = 0.2126 * R + 0.7152 * G + 0.0722 * B
/// where each linearized component is:
///   C <= 0.03928 ? C / 12.92 : ((C + 0.055) / 1.055) ^ 2.4
double relativeLuminance(Color color) {
  double linearize(double channel) {
    return channel <= 0.03928
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = linearize(color.r);
  final g = linearize(color.g);
  final b = linearize(color.b);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Calculates the WCAG 2.1 contrast ratio between two colors.
///
/// Formula: (L1 + 0.05) / (L2 + 0.05) where L1 is the lighter luminance.
double contrastRatio(Color foreground, Color background) {
  final l1 = relativeLuminance(foreground);
  final l2 = relativeLuminance(background);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Design System Token Contrast Verification (WCAG 2.1 AA)', () {
    test(
        'Every text token against every surface token satisfies >= 4.5:1 normal text contrast',
        () {
      final failures = <String>[];

      for (final textEntry in AppColors.textColors.entries) {
        final textName = textEntry.key;
        final textColor = textEntry.value;

        for (final surfaceEntry in AppColors.surfaces.entries) {
          final surfaceName = surfaceEntry.key;
          final surfaceColor = surfaceEntry.value;

          final ratio = contrastRatio(textColor, surfaceColor);

          // Disallow large-text exception for small/muted text:
          // All text tokens must achieve at least 4.5:1 against all surfaces.
          const minRatio = 4.5;
          if (ratio < minRatio) {
            failures.add(
              'FAIL: $textName (#${textColor.toARGB32().toRadixString(16).padLeft(8, '0')}) '
              'on $surfaceName (#${surfaceColor.toARGB32().toRadixString(16).padLeft(8, '0')}) '
              'achieved ${ratio.toStringAsFixed(2)}:1 (required >= $minRatio:1)',
            );
          }
        }
      }

      expect(
        failures,
        isEmpty,
        reason: [
          '=== Failing Text-on-Surface Contrast Pairs ===',
          ...failures,
          'All text tokens must achieve >= 4.5:1 WCAG AA contrast on every dark surface.',
        ].join('\n'),
      );
    });

    test(
        'Button foreground text achieves >= 4.5:1 contrast on calories/primary button background',
        () {
      final ratio = contrastRatio(
        AppColors.buttonForeground,
        AppColors.calories,
      );

      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'Button foreground (${AppColors.buttonForeground}) on calories (${AppColors.calories}) '
            'must satisfy WCAG AA >= 4.5:1 (achieved ${ratio.toStringAsFixed(2)}:1).',
      );
    });

    test(
        'Every graphic, accent, and macro token against every surface satisfies >= 3.0:1 non-text contrast',
        () {
      final failures = <String>[];

      for (final graphicEntry in AppColors.graphicColors.entries) {
        final graphicName = graphicEntry.key;
        final graphicColor = graphicEntry.value;

        for (final surfaceEntry in AppColors.surfaces.entries) {
          final surfaceName = surfaceEntry.key;
          final surfaceColor = surfaceEntry.value;

          final ratio = contrastRatio(graphicColor, surfaceColor);

          const minGraphicRatio = 3.0;
          if (ratio < minGraphicRatio) {
            failures.add(
              'FAIL: $graphicName (#${graphicColor.toARGB32().toRadixString(16).padLeft(8, '0')}) '
              'on $surfaceName (#${surfaceColor.toARGB32().toRadixString(16).padLeft(8, '0')}) '
              'achieved ${ratio.toStringAsFixed(2)}:1 (required >= $minGraphicRatio:1)',
            );
          }
        }
      }

      expect(
        failures,
        isEmpty,
        reason: [
          '=== Failing Graphic-on-Surface Contrast Pairs ===',
          ...failures,
          'All graphic and macro tokens must achieve >= 3.0:1 non-text contrast on all surfaces.',
        ].join('\n'),
      );
    });

    test(
        'Protein color has a visually distinct Rose/Crimson hue from Calories Flame Orange',
        () {
      final proteinHsv = HSVColor.fromColor(AppColors.protein);
      final caloriesHsv = HSVColor.fromColor(AppColors.calories);

      // Protein is in the Rose/Crimson spectrum (around 350°), distinct from Orange (around 14°)
      expect(proteinHsv.hue, greaterThanOrEqualTo(340.0));
      expect(caloriesHsv.hue, inInclusiveRange(10.0, 20.0));

      // Angular distance on 360-degree color wheel across 0° boundary
      var delta = (proteinHsv.hue - caloriesHsv.hue).abs();
      if (delta > 180) {
        delta = 360 - delta;
      }
      expect(
        delta,
        greaterThanOrEqualTo(20.0),
        reason:
            'Protein hue (${proteinHsv.hue.toStringAsFixed(1)}°) and calories hue '
            '(${caloriesHsv.hue.toStringAsFixed(1)}°) must have distinct angular separation '
            '(actual delta: ${delta.toStringAsFixed(1)}°).',
      );
    });
  });
}
