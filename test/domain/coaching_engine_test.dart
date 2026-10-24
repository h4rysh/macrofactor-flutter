import 'package:flutter_test/flutter_test.dart';
import 'package:sique/domain/algorithms/coaching_engine.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/domain/models/user_profile.dart';

void main() {
  group('CoachingEngine - Daily Average Calories Calculation', () {
    const baseProfile = UserProfile(
      id: 'athlete_1',
      name: 'Athlete One',
      age: 28,
      isMale: true,
      heightCm: 178,
      currentWeightKg: 75.0,
      targetWeightKg: 70.0,
      goalType: GoalType.fatLoss,
      weeklyRateOfChangePct: -0.75, // -0.75% of bodyweight per week
      proteinPreference: ProteinPreference.high,
      programMode: ProgramMode.coached,
      calorieFloor: 1400.0,
      baselineExpenditureKcal: 2500.0,
    );

    test('Fat Loss: correctly calculates caloric deficit from weekly rate', () {
      // 75kg * 0.75% = 0.5625 kg/week -> 0.5625 * 1100 = 618.75 kcal deficit
      const expenditure = 2500.0;
      final calories = CoachingEngine.calculateDailyAverageCalories(
        profile: baseProfile,
        expenditureKcal: expenditure,
      );

      // 2500 - 618.75 = 1881.25 -> rounded to 1881
      expect(calories, 1881.0);
    });

    test('Maintenance: calories exactly equal expenditure', () {
      final maintenanceProfile = baseProfile.copyWith(
        goalType: GoalType.maintenance,
        weeklyRateOfChangePct: 0.0,
      );
      const expenditure = 2450.0;
      final calories = CoachingEngine.calculateDailyAverageCalories(
        profile: maintenanceProfile,
        expenditureKcal: expenditure,
      );

      expect(calories, 2450.0);
    });

    test('Muscle Gain: adds surplus according to rate of gain', () {
      final gainProfile = baseProfile.copyWith(
        goalType: GoalType.muscleGain,
        weeklyRateOfChangePct: 0.25, // +0.25% bodyweight / week
      );
      // 75kg * 0.25% = 0.1875 kg/week -> 0.1875 * 1100 = 206.25 kcal surplus
      const expenditure = 2300.0;
      final calories = CoachingEngine.calculateDailyAverageCalories(
        profile: gainProfile,
        expenditureKcal: expenditure,
      );

      // 2300 + 206.25 = 2506.25 -> rounded to 2506
      expect(calories, 2506.0);
    });

    test('Calorie Floor: deficit is bounded by user calorie floor', () {
      final aggressiveProfile = baseProfile.copyWith(
        weeklyRateOfChangePct: -2.0, // Aggressive deficit
        calorieFloor: 1600.0,
      );
      const expenditure = 2000.0;
      // Raw: 2000 - (75 * 0.02 * 1100) = 2000 - 1650 = 350 kcal -> clamped to 1600
      final calories = CoachingEngine.calculateDailyAverageCalories(
        profile: aggressiveProfile,
        expenditureKcal: expenditure,
      );

      expect(calories, 1600.0);
    });

    test('Custom Calories override ignores goal calculation', () {
      final customProfile = baseProfile.copyWith(
        customCalories: 2150.0,
      );
      final calories = CoachingEngine.calculateDailyAverageCalories(
        profile: customProfile,
        expenditureKcal: 2800.0,
      );

      expect(calories, 2150.0);
    });
  });

  group('CoachingEngine - 5 Macro Program Styles', () {
    const weightKg = 70.0;
    const calories = 2000.0;

    test('Balanced style distributes ~28% fat, high protein, rest carbs', () {
      final target = CoachingEngine.computeDayMacros(
        calories: calories,
        weightKg: weightKg,
        style: MacroProgramStyle.balanced,
        proteinPref: ProteinPreference.high, // 2.0 g/kg
      );

      // Protein: 70 * 2.0 = 140g (560 kcal)
      expect(target.proteinGrams, 140.0);
      // Fat: 2000 * 0.28 = 560 kcal / 9 = 62.2g -> 62g (558 kcal)
      expect(target.fatGrams, closeTo(62.0, 1.0));
      // Remaining for carbs: 2000 - 560 - 558 = 882 kcal / 4 = 220.5g -> 221g
      expect(target.carbsGrams, closeTo(221.0, 2.0));

      final totalMacroCals = (target.proteinGrams * 4) +
          (target.fatGrams * 9) +
          (target.carbsGrams * 4);
      expect(totalMacroCals, closeTo(calories, 15.0));
    });

    test('Low Fat style minimizes fat to ~18% and maximizes carbs', () {
      final target = CoachingEngine.computeDayMacros(
        calories: calories,
        weightKg: weightKg,
        style: MacroProgramStyle.lowFat,
        proteinPref: ProteinPreference.moderate, // 1.6 g/kg -> 112g
      );

      expect(target.proteinGrams, 112.0);
      // Fat ~18%: 2000 * 0.18 = 360 kcal / 9 = 40g
      expect(target.fatGrams, closeTo(40.0, 1.0));
      // Carbs receives the bulk: (2000 - 448 - 360) / 4 = 298g
      expect(target.carbsGrams, closeTo(298.0, 2.0));
    });

    test('Low Carb style restricts carbs to ~20% and allocates rest to fat',
        () {
      final target = CoachingEngine.computeDayMacros(
        calories: calories,
        weightKg: weightKg,
        style: MacroProgramStyle.lowCarb,
        proteinPref: ProteinPreference.high, // 140g
      );

      expect(target.proteinGrams, 140.0);
      // Carbs ~20%: 2000 * 0.20 = 400 kcal / 4 = 100g
      expect(target.carbsGrams, closeTo(100.0, 1.0));
      // Fat takes remaining: (2000 - 560 - 400) / 9 = 115.5g -> 116g
      expect(target.fatGrams, closeTo(116.0, 1.0));
    });

    test('Keto style enforces strict carb ceiling (<= 45g) and high fat', () {
      final target = CoachingEngine.computeDayMacros(
        calories: calories,
        weightKg: weightKg,
        style: MacroProgramStyle.keto,
        proteinPref: ProteinPreference.high, // 140g
      );

      expect(target.proteinGrams, 140.0);
      // Carbs <= 45g
      expect(target.carbsGrams, inInclusiveRange(25.0, 45.0));
      // Fat takes ~75%: (2000 - 560 - 100) / 9 ~ 148g
      expect(target.fatGrams, greaterThan(135.0));
    });

    test('High Protein style elevates protein (2.4 - 2.8 g/kg)', () {
      final target = CoachingEngine.computeDayMacros(
        calories: calories,
        weightKg: weightKg,
        style: MacroProgramStyle.highProtein,
        proteinPref: ProteinPreference.high,
      );

      // High protein factor: (2.0 * 1.25).clamp(2.4, 2.8) = 2.5 g/kg -> 175g
      expect(target.proteinGrams, 175.0);
      // Fat ~25%: 500 kcal / 9 = 56g
      expect(target.fatGrams, closeTo(56.0, 2.0));
      expect(target.carbsGrams, greaterThan(100.0));
    });
  });

  group('CoachingEngine - Strict 7-Day Energy Conservation', () {
    const profile = UserProfile(
      id: 'test_user',
      name: 'Test Athlete',
      age: 26,
      isMale: true,
      heightCm: 175,
      currentWeightKg: 72.0,
      targetWeightKg: 68.0,
      goalType: GoalType.fatLoss,
      weeklyRateOfChangePct: -0.6,
      proteinPreference: ProteinPreference.high,
      programMode: ProgramMode.coached,
      calorieFloor: 1400.0,
      baselineExpenditureKcal: 2400.0,
    );

    test('ShiftedWorkout preserves exact 7-day caloric sum', () {
      const expenditure = 2400.0;
      final program = CoachingEngine.buildWeeklyProgram(
        profile: profile,
        expenditureKcal: expenditure,
        style: MacroProgramStyle.balanced,
        allocationType: DayAllocationType.shiftedWorkout,
        workoutDays: {1, 3, 5, 6},
      );

      final totalWeeklyCalories =
          program.days.map((d) => d.calories).reduce((a, b) => a + b);
      final expectedWeeklyCalories = program.dailyAverageCalories * 7.0;

      expect(totalWeeklyCalories, expectedWeeklyCalories);
      // Verify workout days have higher calories than rest days
      final monWorkout = program.days.firstWhere((d) => d.dayOfWeek == 1);
      final tueRest = program.days.firstWhere((d) => d.dayOfWeek == 2);
      expect(monWorkout.calories, greaterThan(tueRest.calories));
      expect(monWorkout.isWorkoutDay, isTrue);
      expect(tueRest.isWorkoutDay, isFalse);
    });

    test('WeekendShift allocates surplus to Fri/Sat/Sun with weekly balance',
        () {
      const expenditure = 2200.0;
      final program = CoachingEngine.buildWeeklyProgram(
        profile: profile,
        expenditureKcal: expenditure,
        style: MacroProgramStyle.lowCarb,
        allocationType: DayAllocationType.weekendShift,
        workoutDays: {1, 3, 5},
      );

      final totalWeeklyCalories =
          program.days.map((d) => d.calories).reduce((a, b) => a + b);
      final expectedWeeklyCalories = program.dailyAverageCalories * 7.0;

      expect(totalWeeklyCalories, closeTo(expectedWeeklyCalories, 1.0));

      final wedWeekday = program.days.firstWhere((d) => d.dayOfWeek == 3);
      final satWeekend = program.days.firstWhere((d) => d.dayOfWeek == 6);
      expect(satWeekend.calories, greaterThan(wedWeekday.calories));
      // Difference should be ~385 kcal (220 boost + 165 reduction)
      expect(satWeekend.calories - wedWeekday.calories, closeTo(385.0, 5.0));
    });

    test('Even allocation assigns identical calories to all 7 days', () {
      final program = CoachingEngine.buildWeeklyProgram(
        profile: profile,
        expenditureKcal: 2500.0,
        style: MacroProgramStyle.balanced,
        allocationType: DayAllocationType.even,
        workoutDays: {1, 3, 5},
      );

      for (final day in program.days) {
        expect(day.calories, program.dailyAverageCalories);
      }
    });
  });

  group('CoachingEngine - Weekly Check-In Evaluation', () {
    final now = DateTime.now();
    const profile = UserProfile(
      id: 'checkin_user',
      name: 'Checkin Athlete',
      age: 30,
      isMale: false,
      heightCm: 165,
      currentWeightKg: 62.0,
      targetWeightKg: 58.0,
      goalType: GoalType.fatLoss,
      weeklyRateOfChangePct: -0.5,
      proteinPreference: ProteinPreference.high,
      programMode: ProgramMode.coached,
      calorieFloor: 1300.0,
      baselineExpenditureKcal: 2100.0,
    );

    final initialProgram = CoachingEngine.buildWeeklyProgram(
      profile: profile,
      expenditureKcal: 2100.0,
      style: MacroProgramStyle.balanced,
      allocationType: DayAllocationType.even,
      workoutDays: {1, 3, 5},
      lastCheckInDate: now.subtract(const Duration(days: 7)),
    );

    test('Check-in is due when >= 7 days elapsed', () {
      final recommendation = CoachingEngine.evaluateWeeklyCheckIn(
        currentProgram: initialProgram,
        profile: profile,
        currentExpenditureKcal: 2200.0, // Expenditure went up
        currentDate: now,
      );

      expect(recommendation.isDue, isTrue);
      expect(recommendation.daysUntilNextCheckIn, 0);
      expect(recommendation.calorieDelta, greaterThan(0));
      expect(recommendation.metabolicInsight, contains('has risen'));
      expect(recommendation.suggestedProgram.dailyAverageCalories,
          greaterThan(initialProgram.dailyAverageCalories));
    });

    test('Check-in is not due when < 7 days elapsed', () {
      final recentProgram = initialProgram.copyWith(
        lastCheckInDate: now.subtract(const Duration(days: 3)),
      );

      final recommendation = CoachingEngine.evaluateWeeklyCheckIn(
        currentProgram: recentProgram,
        profile: profile,
        currentExpenditureKcal: 2100.0,
        currentDate: now,
      );

      expect(recommendation.isDue, isFalse);
      expect(recommendation.daysUntilNextCheckIn, 4);
    });

    test('Steady expenditure results in stable metabolic insight', () {
      final recommendation = CoachingEngine.evaluateWeeklyCheckIn(
        currentProgram: initialProgram,
        profile: profile,
        currentExpenditureKcal: 2105.0, // negligible change
        currentDate: now,
      );

      expect(recommendation.metabolicInsight, contains('tracking steadily'));
      expect(recommendation.calorieDelta.abs(), lessThan(15.0));
    });

    test('Metabolic slowdown produces downward calorie adjustment', () {
      final recommendation = CoachingEngine.evaluateWeeklyCheckIn(
        currentProgram: initialProgram,
        profile: profile,
        currentExpenditureKcal: 1900.0, // expenditure dropped 200 kcal
        currentDate: now,
      );

      expect(recommendation.isDue, isTrue);
      expect(recommendation.calorieDelta, lessThan(0));
      expect(recommendation.metabolicInsight, contains('metabolic adaptation'));
      expect(recommendation.suggestedProgram.dailyAverageCalories,
          lessThan(initialProgram.dailyAverageCalories));
    });
  });

  group('CoachingEngine - Integer Macro Rounding and Calorie Floor Invariants',
      () {
    test(
        'Macro rounding preserves |4P + 9F + 4C - calories| <= 2.0 kcal across styles and caloric ranges',
        () {
      final styles = [
        MacroProgramStyle.balanced,
        MacroProgramStyle.lowFat,
        MacroProgramStyle.lowCarb,
        MacroProgramStyle.keto,
        MacroProgramStyle.highProtein,
      ];
      final calorieLevels = [
        1200.0,
        1450.0,
        1800.0,
        2033.0,
        2450.0,
        2875.0,
        3200.0,
        3500.0
      ];
      const weightKg = 72.5;

      for (final style in styles) {
        for (final cal in calorieLevels) {
          final target = CoachingEngine.computeDayMacros(
            calories: cal,
            weightKg: weightKg,
            proteinPref: ProteinPreference.high,
            style: style,
          );

          final actualKcal = (target.proteinGrams * 4.0) +
              (target.fatGrams * 9.0) +
              (target.carbsGrams * 4.0);
          final diff = (actualKcal - cal).abs();

          expect(diff, lessThanOrEqualTo(2.0),
              reason:
                  'Style $style at $cal kcal: diff $diff exceeds 2.0 kcal (P:${target.proteinGrams}, F:${target.fatGrams}, C:${target.carbsGrams})');
          expect(target.proteinGrams, greaterThanOrEqualTo(30.0));
          expect(target.fatGrams, greaterThanOrEqualTo(20.0));
          expect(target.carbsGrams, greaterThanOrEqualTo(0.0));
        }
      }
    });

    test(
        'All 7 days enforce calorieFloor in shiftedWorkout and weekendShift programs',
        () {
      const lowCalProfile = UserProfile(
        id: 'floor_test_user',
        name: 'Floor Tester',
        age: 32,
        isMale: false,
        heightCm: 155.0,
        currentWeightKg: 52.0,
        targetWeightKg: 48.0,
        goalType: GoalType.fatLoss,
        weeklyRateOfChangePct: -1.2,
        proteinPreference: ProteinPreference.moderate,
        programMode: ProgramMode.coached,
        calorieFloor: 1250.0,
        baselineExpenditureKcal: 1450.0,
      );

      for (final allocation in [
        DayAllocationType.shiftedWorkout,
        DayAllocationType.weekendShift,
      ]) {
        final program = CoachingEngine.buildWeeklyProgram(
          profile: lowCalProfile,
          expenditureKcal: 1450.0,
          style: MacroProgramStyle.balanced,
          allocationType: allocation,
          workoutDays: const {2, 4, 6}, // Tue, Thu, Sat
        );

        expect(program.days.length, equals(7));
        for (final day in program.days) {
          expect(day.calories, greaterThanOrEqualTo(lowCalProfile.calorieFloor),
              reason:
                  'Day ${day.dayOfWeek} (${day.dayName}) calories (${day.calories}) fell below floor (${lowCalProfile.calorieFloor}) for $allocation');
        }

        // Sunday specifically
        final sunday = program.days.firstWhere((d) => d.dayOfWeek == 7);
        expect(
            sunday.calories, greaterThanOrEqualTo(lowCalProfile.calorieFloor));
      }
    });
  });
}
