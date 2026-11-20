import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/algorithms/expenditure_kalman_v4.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/app_providers.dart';

void main() {
  group('ISS-1-01: UserProfile macro calculation with >5400 kcal', () {
    test(
        'calculateTargetMacros does not throw ArgumentError when calories > 5400',
        () {
      const profile = UserProfile(
        id: 'test_high_cals',
        name: 'High Calorie Athlete',
        currentWeightKg: 95.0,
        targetWeightKg: 95.0,
        heightCm: 190.0,
        age: 25,
        isMale: true,
        goalType: GoalType.maintenance,
        programMode: ProgramMode.coached,
        weeklyRateOfChangePct: 0.0,
        proteinPreference: ProteinPreference.high,
        calorieFloor: 1200.0,
        baselineExpenditureKcal: 5800.0,
      );

      // Current expenditure of 5800 kcal (maintenance) -> targetCalories = 5800 kcal
      expect(() => profile.calculateTargetMacros(5800.0), returnsNormally);

      final macros = profile.calculateTargetMacros(5800.0);
      expect(macros.calories, 5800.0);
      expect(macros.fatGrams, closeTo(5800.0 * 0.25 / 9.0, 1.0));
      expect(macros.fatGrams, lessThanOrEqualTo(5800.0 * 0.35 / 9.0));
      expect(macros.proteinGrams, greaterThan(0.0));
      expect(macros.carbsGrams, greaterThan(0.0));

      // At maximum ceiling (6000 kcal)
      expect(() => profile.calculateTargetMacros(7000.0), returnsNormally);
      final maxMacros = profile.calculateTargetMacros(7000.0);
      expect(maxMacros.calories, 6000.0);
      expect(maxMacros.fatGrams, closeTo(6000.0 * 0.25 / 9.0, 1.0));
    });

    test(
        'calculateTargetMacros handles customCalories > 5400 without ArgumentError',
        () {
      const profile = UserProfile(
        id: 'test_custom_high',
        name: 'Custom High Calorie',
        currentWeightKg: 90.0,
        targetWeightKg: 90.0,
        heightCm: 185.0,
        age: 28,
        isMale: true,
        goalType: GoalType.muscleGain,
        programMode: ProgramMode.manual,
        weeklyRateOfChangePct: 0.5,
        proteinPreference: ProteinPreference.moderate,
        calorieFloor: 1500.0,
        baselineExpenditureKcal: 3500.0,
        customCalories: 5600.0,
      );

      expect(() => profile.calculateTargetMacros(3500.0), returnsNormally);
      final macros = profile.calculateTargetMacros(3500.0);
      expect(macros.calories, 5600.0);
      expect(macros.fatGrams, closeTo(5600.0 * 0.25 / 9.0, 1.0));
    });
  });

  group('ISS-5-01: ExpenditureKalmanV4 BMR Physiological Safety Bounds', () {
    test(
        'clamps latent expenditure within [0.8x to 2.5x BMR] under severe intake inflation',
        () {
      final filter = ExpenditureKalmanV4(
        initialExpenditureKcal: 2000.0,
        initialWeightKg: 70.0,
      );

      // Expected BMR: 70 kg * 20.0 = 1400 kcal
      // Bounds: min = 0.8 * 1400 = 1120 kcal, max = 2.5 * 1400 = 3500 kcal
      expect(filter.minExpenditureBound, closeTo(1120.0, 1.0));
      expect(filter.maxExpenditureBound, closeTo(3500.0, 1.0));

      // Simulate extreme erratic input trying to drive expenditure to infinity
      for (int i = 0; i < 60; i++) {
        filter.step(
          intakeKcal: 10000.0,
          scaleWeightKg: 70.0 + (i * 0.5),
          date: DateTime(2026, 1, 1).add(Duration(days: i)),
        );
      }

      expect(filter.expenditureKcal,
          lessThanOrEqualTo(filter.maxExpenditureBound));
      expect(filter.currentState.expenditureKcal,
          lessThanOrEqualTo(filter.maxExpenditureBound));
    });

    test(
        'clamps latent expenditure within [0.8x to 2.5x BMR] under starvation crash',
        () {
      final filter = ExpenditureKalmanV4(
        initialExpenditureKcal: 2500.0,
        initialWeightKg: 80.0,
        bmrKcal: 1600.0,
      );

      // Explicit BMR = 1600 kcal -> min = 0.8 * 1600 = 1280 kcal
      expect(filter.minExpenditureBound, 1280.0);
      expect(filter.maxExpenditureBound, 4000.0);

      // Simulate starvation intake and dropping weight
      for (int i = 0; i < 60; i++) {
        filter.step(
          intakeKcal: 50.0,
          scaleWeightKg: 80.0 - (i * 0.3),
          date: DateTime(2026, 1, 1).add(Duration(days: i)),
        );
      }

      expect(filter.expenditureKcal,
          greaterThanOrEqualTo(filter.minExpenditureBound));
      expect(filter.currentState.expenditureKcal,
          greaterThanOrEqualTo(filter.minExpenditureBound));
    });
  });

  group('ISS-2-06: loggingStreakProvider Morning Grace Period', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.inMemory();
    });

    tearDown(() {
      db.close();
    });

    test('preserves multi-day streak before logging breakfast on current day',
        () {
      final fixedClock = DateTime(2026, 3, 15, 8, 30); // 8:30 AM
      const food = FoodItem(
        id: 1,
        uuid: 'test_apple',
        name: 'Apple',
        caloriesPer100g: 52.0,
        proteinPer100g: 0.3,
        fatPer100g: 0.2,
        carbsPer100g: 13.8,
        fiberPer100g: 2.4,
        category: 'Fruits',
        region: 'Global',
        iconSvg: 'apple',
        source: 'catalog',
        aliases: 'apple,pomme',
      );
      db.insertFood(food);

      // Log food for yesterday (March 14) and 2 days ago (March 13)
      final fmt = DateFormat('yyyy-MM-dd');
      final logYesterday = FoodLogEntry(
        date: fmt.format(DateTime(2026, 3, 14)),
        mealType: MealType.breakfast,
        foodId: 1,
        foodName: 'Apple',
        servingQuantity: 1.0,
        unitName: 'medium',
        gramWeight: 182.0,
        calories: 95.0,
        protein: 0.5,
        carbs: 25.0,
        fat: 0.3,
        fiber: 4.4,
        oilModifier: OilModifier.none,
        loggedAt: DateTime(2026, 3, 14, 9, 0),
        iconSvg: 'Fruits',
      );
      final log2DaysAgo = FoodLogEntry(
        date: fmt.format(DateTime(2026, 3, 13)),
        mealType: MealType.dinner,
        foodId: 1,
        foodName: 'Apple',
        servingQuantity: 1.0,
        unitName: 'medium',
        gramWeight: 182.0,
        calories: 95.0,
        protein: 0.5,
        carbs: 25.0,
        fat: 0.3,
        fiber: 4.4,
        oilModifier: OilModifier.none,
        loggedAt: DateTime(2026, 3, 13, 19, 0),
        iconSvg: 'Fruits',
      );
      db.insertFoodLog(logYesterday);
      db.insertFoodLog(log2DaysAgo);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => fixedClock),
        ],
      );
      addTearDown(container.dispose);

      // Before breakfast on March 15, streak is preserved at 2
      expect(container.read(loggingStreakProvider), 2);

      // Log breakfast today
      final logToday = FoodLogEntry(
        date: fmt.format(DateTime(2026, 3, 15)),
        mealType: MealType.breakfast,
        foodId: 1,
        foodName: 'Apple',
        servingQuantity: 1.0,
        unitName: 'medium',
        gramWeight: 182.0,
        calories: 95.0,
        protein: 0.5,
        carbs: 25.0,
        fat: 0.3,
        fiber: 4.4,
        oilModifier: OilModifier.none,
        loggedAt: fixedClock,
        iconSvg: 'Fruits',
      );
      db.insertFoodLog(logToday);
      container.read(foodLogsRevisionProvider.notifier).state++;

      // After logging breakfast today, streak increments to 3
      expect(container.read(loggingStreakProvider), 3);
    });
  });

  group('ISS-5-05: WeightDao scale weight sync to user_profile.current_weight',
      () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.inMemory();
      const profile = UserProfile(
        id: 'user_main',
        name: 'Alex',
        currentWeightKg: 80.0,
        targetWeightKg: 75.0,
        heightCm: 178.0,
        age: 30,
        isMale: true,
        goalType: GoalType.fatLoss,
        programMode: ProgramMode.coached,
        weeklyRateOfChangePct: -0.5,
        proteinPreference: ProteinPreference.high,
        calorieFloor: 1400.0,
        baselineExpenditureKcal: 2400.0,
      );
      db.saveUserProfile(profile);
    });

    tearDown(() {
      db.close();
    });

    test('logging scale weight updates user_profile current_weight', () {
      final initialProfile = db.getUserProfile();
      expect(initialProfile?.currentWeightKg, 80.0);

      // Log a new morning scale weight
      db.weightDao.insertWeightLog('2026-03-15', 78.4, 'Morning post-void');

      final updatedProfile = db.getUserProfile();
      expect(updatedProfile?.currentWeightKg, 78.4);

      // Log another weight for the next day
      db.weightDao.insertWeightLog('2026-03-16', 78.1, 'Consistent drop');
      final nextProfile = db.getUserProfile();
      expect(nextProfile?.currentWeightKg, 78.1);
    });

    test('deleting latest scale weight syncs user_profile to previous weight',
        () {
      db.weightDao.insertWeightLog('2026-03-15', 78.4, null);
      db.weightDao.insertWeightLog('2026-03-16', 77.9, null);

      expect(db.getUserProfile()?.currentWeightKg, 77.9);

      db.weightDao.deleteWeightLogForDate('2026-03-16');
      expect(db.getUserProfile()?.currentWeightKg, 78.4);
    });
  });
}
