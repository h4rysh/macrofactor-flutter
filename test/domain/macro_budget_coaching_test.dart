import 'package:flutter_test/flutter_test.dart';
import 'package:macro_factor_app/domain/algorithms/coaching_engine.dart';
import 'package:macro_factor_app/domain/models/macro_program.dart';
import 'package:macro_factor_app/domain/models/user_profile.dart';

void main() {
  group('Issue 6 Regression: Macro Target Budget & Clamp Crash', () {
    test(
        '100 kg user at 1400 kcal on high-protein plan does not exceed calorie target or yield 0 carbs',
        () {
      // 100 kg user on a 1400 kcal budget
      final target = CoachingEngine.computeDayMacros(
        calories: 1400.0,
        weightKg: 100.0,
        style: MacroProgramStyle.highProtein,
        proteinPref: ProteinPreference.high,
      );

      final totalMacroCalories = (target.proteinGrams * 4.0) +
          (target.carbsGrams * 4.0) +
          (target.fatGrams * 9.0);

      // 1. Total macro calories must match the calorie target (within rounding tolerance of 2 kcal)
      expect(totalMacroCalories, closeTo(1400.0, 2.0),
          reason:
              'Macro calorie sum ($totalMacroCalories) must equal total calories (1400.0)');

      // 2. Carbs must not be starved to 0
      expect(target.carbsGrams, greaterThanOrEqualTo(20.0),
          reason: 'Carbs should have a physiological floor');

      // 3. Protein and fat must be non-negative
      expect(target.proteinGrams, greaterThanOrEqualTo(30.0));
      expect(target.fatGrams, greaterThanOrEqualTo(20.0));
    });

    test(
        'Macro targets do not throw ArgumentError on high calorie budgets (up to 6500 kcal)',
        () {
      for (final style in MacroProgramStyle.values) {
        for (final calories in [3000.0, 4500.0, 5800.0, 6000.0, 6500.0]) {
          expect(
            () => CoachingEngine.computeDayMacros(
              calories: calories,
              weightKg: 85.0,
              style: style,
              proteinPref: ProteinPreference.high,
            ),
            returnsNormally,
            reason:
                'Should not throw ArgumentError on style $style at $calories kcal',
          );

          final target = CoachingEngine.computeDayMacros(
            calories: calories,
            weightKg: 85.0,
            style: style,
            proteinPref: ProteinPreference.high,
          );

          final totalMacroCalories = (target.proteinGrams * 4.0) +
              (target.carbsGrams * 4.0) +
              (target.fatGrams * 9.0);

          expect(totalMacroCalories, closeTo(calories, 2.0),
              reason: 'Energy conservation must hold across high budgets');
        }
      }
    });

    test(
        'Property Test: Macro calorie sum matches target across wide parameter combinations',
        () {
      final weights = [50.0, 70.0, 90.0, 120.0];
      final calorieBudgets = [1200.0, 1500.0, 2000.0, 2800.0, 3500.0];

      for (final style in MacroProgramStyle.values) {
        for (final w in weights) {
          for (final c in calorieBudgets) {
            final target = CoachingEngine.computeDayMacros(
              calories: c,
              weightKg: w,
              style: style,
              proteinPref: ProteinPreference.moderate,
            );

            final macroCalorieSum = (target.proteinGrams * 4.0) +
                (target.carbsGrams * 4.0) +
                (target.fatGrams * 9.0);

            expect(macroCalorieSum, closeTo(c, 2.5),
                reason:
                    'Failed energy conservation for style: $style, weight: $w, calories: $c');
          }
        }
      }
    });
  });
}
