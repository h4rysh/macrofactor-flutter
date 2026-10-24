import 'package:flutter_test/flutter_test.dart';
import 'package:sique/domain/algorithms/coaching_engine.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/domain/models/user_profile.dart';

void main() {
  group('Adversarial Stress: Extreme Calorie Floors', () {
    const floors = [1000.0, 1200.0, 1500.0, 3500.0];

    for (final floor in floors) {
      test('Calorie floor $floor kcal strictly enforced on aggressive deficit',
          () {
        // High deficit: user weighing 80kg targeting -2.5% loss per week (-2200 kcal/day deficit)
        // With expenditure 2000, raw target = 2000 - 2200 = -200 kcal!
        final profile = UserProfile(
          id: 'stress_user_$floor',
          name: 'Floor Stress User',
          age: 30,
          isMale: true,
          heightCm: 175,
          currentWeightKg: 80.0,
          targetWeightKg: 65.0,
          goalType: GoalType.fatLoss,
          weeklyRateOfChangePct: -2.5,
          proteinPreference: ProteinPreference.high,
          programMode: ProgramMode.coached,
          calorieFloor: floor,
          baselineExpenditureKcal: 2000.0,
        );

        final dailyAvg = CoachingEngine.calculateDailyAverageCalories(
          profile: profile,
          expenditureKcal: 2000.0,
        );

        // Daily average must be clamped to the floor
        expect(dailyAvg, greaterThanOrEqualTo(floor));
        expect(dailyAvg, equals(floor));

        // Program generation across all 4 allocation types
        for (final alloc in DayAllocationType.values) {
          final program = CoachingEngine.buildWeeklyProgram(
            profile: profile,
            expenditureKcal: 2000.0,
            style: MacroProgramStyle.balanced,
            allocationType: alloc,
            workoutDays: const {1, 3, 5},
          );

          expect(program.dailyAverageCalories, greaterThanOrEqualTo(floor));

          // Verify every individual day satisfies the floor
          for (final day in program.days) {
            expect(
              day.calories,
              greaterThanOrEqualTo(floor),
              reason:
                  'Day ${day.dayName} (${day.dayOfWeek}) at ${day.calories} kcal dropped below floor $floor under $alloc',
            );
          }

          // Verify 7-day energy conservation: sum(days) == dailyAverageCalories * 7
          final weeklySum =
              program.days.fold<double>(0.0, (acc, d) => acc + d.calories);
          expect(
            weeklySum,
            equals(program.dailyAverageCalories * 7.0),
            reason:
                'Weekly energy budget not conserved for allocation $alloc at floor $floor: sum=$weeklySum, expected=${program.dailyAverageCalories * 7.0}',
          );
        }
      });
    }

    test('Higher calorie floor (3500 kcal) bounds maintenance & surplus', () {
      const highFloorProfile = UserProfile(
        id: 'high_floor_user',
        name: 'High Floor User',
        age: 25,
        isMale: true,
        heightCm: 195,
        currentWeightKg: 105.0,
        targetWeightKg: 105.0,
        goalType: GoalType.maintenance,
        weeklyRateOfChangePct: 0.0,
        proteinPreference: ProteinPreference.high,
        programMode: ProgramMode.coached,
        calorieFloor: 3500.0,
        baselineExpenditureKcal: 3200.0,
      );

      final avgCals = CoachingEngine.calculateDailyAverageCalories(
        profile: highFloorProfile,
        expenditureKcal: 3200.0,
      );

      // Raw expenditure 3200 is below 3500 floor, so it must clamp to 3500
      expect(avgCals, equals(3500.0));

      final program = CoachingEngine.buildWeeklyProgram(
        profile: highFloorProfile,
        expenditureKcal: 3200.0,
        style: MacroProgramStyle.highProtein,
        allocationType: DayAllocationType.shiftedWorkout,
        workoutDays: const {1, 2, 4, 5},
      );

      for (final day in program.days) {
        expect(day.calories, greaterThanOrEqualTo(3500.0));
      }
      final weeklySum =
          program.days.fold<double>(0.0, (acc, d) => acc + d.calories);
      expect(weeklySum, equals(3500.0 * 7.0));
    });
  });

  group('Adversarial Stress: High Protein Preference with Very Low Calories',
      () {
    final heavyWeights = [80.0, 95.0, 110.0, 130.0];
    final lowCalorieBudgets = [1000.0, 1100.0, 1200.0, 1300.0, 1400.0];

    for (final weight in heavyWeights) {
      for (final cals in lowCalorieBudgets) {
        for (final style in MacroProgramStyle.values) {
          test(
              'Weight ${weight}kg at $cals kcal ($style, extraHigh/high protein): preserves floors and reconciles within <= 2 kcal',
              () {
            final target = CoachingEngine.computeDayMacros(
              calories: cals,
              weightKg: weight,
              style: style,
              proteinPref: ProteinPreference.extraHigh,
            );

            // Physiological floors
            expect(target.proteinGrams, greaterThanOrEqualTo(30.0),
                reason: 'Protein ($target.proteinGrams) below 30g minimum');
            expect(target.fatGrams, greaterThanOrEqualTo(20.0),
                reason: 'Fat ($target.fatGrams) below 20g minimum');
            expect(target.carbsGrams, greaterThanOrEqualTo(0.0),
                reason: 'Carbs ($target.carbsGrams) must be non-negative');

            // Macro calorie calculation: 4P + 9F + 4C
            final macroCalories = (target.proteinGrams * 4.0) +
                (target.fatGrams * 9.0) +
                (target.carbsGrams * 4.0);

            // Rounding reconciliation contract: |4P + 9F + 4C - calories| <= 2.0 kcal
            final diff = (macroCalories - cals).abs();
            expect(
              diff,
              lessThanOrEqualTo(2.0),
              reason:
                  'Calorie drift |$macroCalories - $cals| = $diff > 2.0 kcal for weight=$weight, style=$style, cals=$cals (P=${target.proteinGrams}, F=${target.fatGrams}, C=${target.carbsGrams})',
            );

            // Check integer rounding: macros should be whole integers
            expect(target.proteinGrams,
                equals(target.proteinGrams.roundToDouble()));
            expect(target.fatGrams, equals(target.fatGrams.roundToDouble()));
            expect(
                target.carbsGrams, equals(target.carbsGrams.roundToDouble()));
          });
        }
      }
    }
  });

  group(
      'Adversarial Stress: Multi-day Deficit Redistribution (Sunday Below Floor)',
      () {
    test(
        'shiftedWorkout: Sunday drops below floor due to rounding up on 6 workout days -> deficit redistributes and floor is strictly maintained',
        () {
      // Setup condition where 6 workout days round up, causing delta < 0 on Sunday.
      // Floor = 1500.0, avg = 1600.0.
      // Workout days = {1, 2, 3, 4, 5, 6}. Rest day = 7 (Sunday).
      // Max rest reduction = 1600 - 1500 = 100.
      // Workout boost = (100 * 1) / 6 = 16.67.
      // workoutCals = round(1600 + 16.67) = 1617.
      // restCals = round(1600 - 100) = 1500.
      // assignedSum = 6 * 1617 + 1500 = 11202.
      // totalBudget = 1600 * 7 = 11200.
      // delta = -2.
      // Sunday would be 1500 - 2 = 1498 (below 1500 floor!).
      const profile = UserProfile(
        id: 'redistrib_user_1',
        name: 'Redistribution User',
        age: 32,
        isMale: true,
        heightCm: 180,
        currentWeightKg: 85.0,
        targetWeightKg: 78.0,
        goalType: GoalType.fatLoss,
        weeklyRateOfChangePct: -0.5,
        proteinPreference: ProteinPreference.moderate,
        programMode: ProgramMode.coached,
        calorieFloor: 1500.0,
        baselineExpenditureKcal: 2000.0,
      );

      final program = CoachingEngine.buildWeeklyProgram(
        profile: profile,
        expenditureKcal: 2000.0,
        style: MacroProgramStyle.balanced,
        allocationType: DayAllocationType.shiftedWorkout,
        workoutDays: const {1, 2, 3, 4, 5, 6},
        customDailyAverage: 1600.0,
      );

      final sunday = program.days.firstWhere((d) => d.dayOfWeek == 7);
      final saturday = program.days.firstWhere((d) => d.dayOfWeek == 6);

      // 1. Sunday MUST NOT drop below 1500.0
      expect(sunday.calories, greaterThanOrEqualTo(1500.0),
          reason:
              'Sunday calories (${sunday.calories}) dropped below floor (1500.0)');
      expect(sunday.calories, equals(1500.0));

      // 2. Saturday absorbed the deficit
      expect(saturday.calories, equals(1615.0),
          reason: 'Saturday should absorb the 2 kcal deficit from Sunday');

      // 3. All 7 days must be >= 1500.0
      for (final day in program.days) {
        expect(day.calories, greaterThanOrEqualTo(1500.0));
      }

      // 4. Exact 7-day budget conservation: sum == 1600 * 7 = 11200
      final totalSum =
          program.days.fold<double>(0.0, (acc, d) => acc + d.calories);
      expect(totalSum, equals(11200.0));
    });

    test(
        'shiftedWorkout: dailyAvg equals calorieFloor (no headroom) -> all days lock to floor',
        () {
      const profile = UserProfile(
        id: 'floor_lock_user',
        name: 'Floor Lock User',
        age: 26,
        isMale: false,
        heightCm: 162,
        currentWeightKg: 58.0,
        targetWeightKg: 52.0,
        goalType: GoalType.fatLoss,
        weeklyRateOfChangePct: -1.0,
        proteinPreference: ProteinPreference.high,
        programMode: ProgramMode.coached,
        calorieFloor: 1300.0,
        baselineExpenditureKcal: 1700.0,
      );

      final program = CoachingEngine.buildWeeklyProgram(
        profile: profile,
        expenditureKcal: 1700.0,
        style: MacroProgramStyle.balanced,
        allocationType: DayAllocationType.shiftedWorkout,
        workoutDays: const {1, 3, 5},
        customDailyAverage: 1300.0,
      );

      for (final day in program.days) {
        expect(day.calories, equals(1300.0),
            reason:
                'When avg == floor, day ${day.dayName} must equal floor exactly');
      }
      final totalSum =
          program.days.fold<double>(0.0, (acc, d) => acc + d.calories);
      expect(totalSum, equals(1300.0 * 7.0));
    });

    test(
        'weekendShift: floor enforcement and weekly budget conservation across various floors',
        () {
      const testFloors = [1000.0, 1200.0, 1400.0, 1500.0, 2000.0];

      for (final floor in testFloors) {
        final profile = UserProfile(
          id: 'weekend_user_$floor',
          name: 'Weekend User',
          age: 30,
          isMale: true,
          heightCm: 175,
          currentWeightKg: 75.0,
          targetWeightKg: 70.0,
          goalType: GoalType.fatLoss,
          weeklyRateOfChangePct: -0.75,
          proteinPreference: ProteinPreference.high,
          programMode: ProgramMode.coached,
          calorieFloor: floor,
          baselineExpenditureKcal: 2500.0,
        );

        // Test with headroom = 0, 50, 150, 500 kcal above floor
        for (final headroom in [0.0, 50.0, 150.0, 500.0]) {
          final avgCals = floor + headroom;
          final program = CoachingEngine.buildWeeklyProgram(
            profile: profile,
            expenditureKcal: avgCals + 400.0,
            style: MacroProgramStyle.balanced,
            allocationType: DayAllocationType.weekendShift,
            workoutDays: const {5, 6, 7},
            customDailyAverage: avgCals,
          );

          // All 7 days >= floor
          for (final day in program.days) {
            expect(
              day.calories,
              greaterThanOrEqualTo(floor),
              reason:
                  'weekendShift day ${day.dayName} (${day.calories}) dropped below floor $floor with headroom $headroom',
            );
          }

          // Exact weekly energy budget conservation
          final totalSum =
              program.days.fold<double>(0.0, (acc, d) => acc + d.calories);
          expect(
            totalSum,
            equals(avgCals * 7.0),
            reason:
                'weekendShift failed energy conservation: sum=$totalSum != ${avgCals * 7.0}',
          );
        }
      }
    });

    test(
        'Combinatorial Stress: 500+ configurations of allocation, workoutDays, styles, floors, and calorie levels',
        () {
      final workoutDayConfigs = [
        <int>{},
        <int>{1},
        <int>{7},
        <int>{1, 3, 5},
        <int>{2, 4, 6},
        <int>{1, 2, 3, 4},
        <int>{1, 2, 3, 4, 5},
        <int>{1, 2, 3, 4, 5, 6},
        <int>{2, 3, 4, 5, 6, 7},
        <int>{1, 2, 3, 4, 5, 6, 7},
      ];

      final calorieFloors = [1000.0, 1200.0, 1400.0, 1600.0];
      final calorieAverages = [1200.0, 1450.0, 1800.0, 2400.0, 3200.0];

      int testedCombinations = 0;

      for (final floor in calorieFloors) {
        for (final avg in calorieAverages) {
          if (avg < floor) continue;

          final profile = UserProfile(
            id: 'comb_user',
            name: 'Combinatorial User',
            age: 28,
            isMale: true,
            heightCm: 178,
            currentWeightKg: 80.0,
            targetWeightKg: 75.0,
            goalType: GoalType.fatLoss,
            weeklyRateOfChangePct: -0.5,
            proteinPreference: ProteinPreference.high,
            programMode: ProgramMode.coached,
            calorieFloor: floor,
            baselineExpenditureKcal: avg + 300.0,
          );

          for (final alloc in DayAllocationType.values) {
            for (final wDays in workoutDayConfigs) {
              for (final style in MacroProgramStyle.values) {
                final program = CoachingEngine.buildWeeklyProgram(
                  profile: profile,
                  expenditureKcal: avg + 300.0,
                  style: style,
                  allocationType: alloc,
                  workoutDays: wDays,
                  customDailyAverage: avg,
                );

                testedCombinations++;

                // 1. Every single day satisfies calorie floor
                for (final day in program.days) {
                  expect(day.calories, greaterThanOrEqualTo(floor));
                  expect(day.proteinGrams, greaterThanOrEqualTo(30.0));
                  expect(day.fatGrams, greaterThanOrEqualTo(20.0));
                  expect(day.carbsGrams, greaterThanOrEqualTo(0.0));

                  // Integer macro sum matches day calories within 2.0 kcal
                  final dayMacroCals = (day.proteinGrams * 4.0) +
                      (day.fatGrams * 9.0) +
                      (day.carbsGrams * 4.0);
                  expect((dayMacroCals - day.calories).abs(),
                      lessThanOrEqualTo(2.0));
                }

                // 2. Total weekly energy is strictly conserved
                final weeklySum = program.days
                    .fold<double>(0.0, (acc, d) => acc + d.calories);
                expect(weeklySum, equals(avg * 7.0));
              }
            }
          }
        }
      }

      expect(testedCombinations, greaterThanOrEqualTo(500),
          reason: 'Must test at least 500 combinations');
    });
  });

  group(
      'Adversarial Stress: Oil Modifiers & Serving Inputs in FoodItem.calculateNutrition',
      () {
    const defaultUnit = PortionUnit(
      id: 1,
      foodId: 101,
      unitName: 'Serving (100g)',
      gramWeight: 100.0,
      isDefault: true,
    );

    const testFood = FoodItem(
      id: 101,
      uuid: 'food-stress-101',
      name: 'Paneer Butter Masala Base',
      category: 'Curry',
      region: 'North Indian',
      caloriesPer100g: 250.0,
      proteinPer100g: 10.0,
      carbsPer100g: 8.0,
      fatPer100g: 20.0,
      fiberPer100g: 2.0,
      iconSvg: 'curry.svg',
      source: 'IFCT',
      aliases: 'paneer gravy',
      portionUnits: [defaultUnit],
    );

    test(
        'Negative oil inputs are strictly clamped to 0.0 with zero added fat/calories',
        () {
      final negativeInputs = [-0.001, -1.0, -10.0, -50.0, -1000.0, -1e6];

      for (final negOil in negativeInputs) {
        final result = testFood.calculateNutrition(
          quantity: 1.0,
          unit: defaultUnit,
          oilGrams: negOil,
        );

        // Clamped oil must equal baseline (0 added oil)
        expect(result.calories, equals(250.0),
            reason:
                'Negative oil $negOil resulted in incorrect calories ${result.calories}');
        expect(result.fat, equals(20.0),
            reason:
                'Negative oil $negOil resulted in incorrect fat ${result.fat}');
        expect(result.protein, equals(10.0));
        expect(result.carbs, equals(8.0));
      }
    });

    test('Massive oil inputs scale linearly at 9 kcal/g fat without error', () {
      final massiveInputs = [100.0, 500.0, 1000.0, 10000.0, 1e5];

      for (final massiveOil in massiveInputs) {
        final result = testFood.calculateNutrition(
          quantity: 2.0, // 2 servings = 200g base + 2 * massiveOil added
          unit: defaultUnit,
          oilGrams: massiveOil,
        );

        // Base for 2 servings (200g): 500 kcal, 40g fat
        // Added fat: 2 * massiveOil
        // Added calories: (2 * massiveOil) * 9.0
        final expectedFat = 40.0 + (massiveOil * 2.0);
        final expectedCalories = 500.0 + (massiveOil * 2.0 * 9.0);

        expect(result.fat, equals(expectedFat),
            reason:
                'Massive oil $massiveOil produced fat ${result.fat} != $expectedFat');
        expect(result.calories, equals(expectedCalories),
            reason:
                'Massive oil $massiveOil produced calories ${result.calories} != $expectedCalories');
        expect(result.protein, equals(20.0)); // 10g * 2
        expect(result.carbs, equals(16.0)); // 8g * 2
      }
    });

    test('Fractional servings scale accurately and proportionally', () {
      final fractionalQuantities = [0.001, 0.25, 0.333333, 0.5, 1.25, 2.71828];

      for (final q in fractionalQuantities) {
        final result = testFood.calculateNutrition(
          quantity: q,
          unit: defaultUnit,
          oilGrams: 10.0, // 10g oil per serving
        );

        final expectedBaseGrams = q * 100.0;
        expect(result.totalGrams, closeTo(expectedBaseGrams, 0.0001));

        final expectedProtein = 10.0 * q;
        final expectedCarbs = 8.0 * q;
        final expectedBaseFat = 20.0 * q;
        final expectedAddedFat = 10.0 * q;
        final expectedTotalFat = expectedBaseFat + expectedAddedFat;
        final expectedCalories = (250.0 * q) + (10.0 * q * 9.0);

        expect(result.protein, closeTo(expectedProtein, 0.001));
        expect(result.carbs, closeTo(expectedCarbs, 0.001));
        expect(result.fat, closeTo(expectedTotalFat, 0.001));
        expect(result.calories, closeTo(expectedCalories, 0.001));
      }
    });

    test('Zero and negative quantity edge cases', () {
      // Zero quantity
      final zeroResult = testFood.calculateNutrition(
        quantity: 0.0,
        unit: defaultUnit,
        oilGrams: 20.0,
      );
      expect(zeroResult.calories, equals(0.0));
      expect(zeroResult.fat, equals(0.0));
      expect(zeroResult.protein, equals(0.0));
      expect(zeroResult.carbs, equals(0.0));
      expect(zeroResult.totalGrams, equals(0.0));

      // Negative quantity clamped at 0.0
      final negResult = testFood.calculateNutrition(
        quantity: -2.0,
        unit: defaultUnit,
        oilGrams: 10.0,
      );
      expect(negResult.calories, equals(0.0));
      expect(negResult.fat, equals(0.0));
      expect(negResult.protein, equals(0.0));
      expect(negResult.carbs, equals(0.0));
    });

    test('oilGrams explicitly overrides OilModifier', () {
      // When oilGrams is provided, OilModifier.oneTbsp (+13.5g / +120 kcal) is overridden
      final result = testFood.calculateNutrition(
        quantity: 1.0,
        unit: defaultUnit,
        oilModifier: OilModifier.oneTbsp,
        oilGrams: 0.0, // Explicitly 0 oil
      );

      // Must have 0 added oil, ignoring OilModifier.oneTbsp
      expect(result.fat, equals(20.0));
      expect(result.calories, equals(250.0));

      // When oilGrams is null, OilModifier is respected
      final resultModifier = testFood.calculateNutrition(
        quantity: 1.0,
        unit: defaultUnit,
        oilModifier: OilModifier.oneTbsp,
        oilGrams: null,
      );

      expect(resultModifier.fat,
          equals(20.0 + OilModifier.oneTbsp.additionalFatGrams));
      expect(resultModifier.calories,
          equals(250.0 + OilModifier.oneTbsp.additionalCalories));
    });
  });
}
