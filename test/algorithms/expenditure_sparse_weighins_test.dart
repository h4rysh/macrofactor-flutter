import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:macro_factor_app/data/local/app_database.dart';
import 'package:macro_factor_app/domain/models/food_models.dart';
import 'package:macro_factor_app/domain/models/user_profile.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';

void main() {
  group('Issue 2 Regression: Expenditure Algorithm with Sparse Weigh-ins', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.inMemory();
      db.saveUserProfile(const UserProfile(
        id: 'test_athlete',
        name: 'Athlete',
        age: 28,
        isMale: true,
        heightCm: 178,
        currentWeightKg: 75.0,
        targetWeightKg: 75.0,
        goalType: GoalType.maintenance,
        weeklyRateOfChangePct: 0.0,
        proteinPreference: ProteinPreference.moderate,
        programMode: ProgramMode.coached,
        calorieFloor: 1400.0,
        baselineExpenditureKcal: 2500.0,
      ));
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      db.close();
    });

    test(
        'Weigh-ins every 3 days with constant weight & 2500 kcal intake maintains ~2500 kcal TDEE',
        () {
      final startDate = DateTime(2026, 1, 1);
      const sampleFood = FoodItem(
        id: 1,
        uuid: 'food-1',
        name: 'Meal Portion',
        category: 'Cooked',
        region: 'India',
        caloriesPer100g: 2500.0,
        proteinPer100g: 100.0,
        carbsPer100g: 300.0,
        fatPer100g: 50.0,
        fiberPer100g: 20.0,
        iconSvg: 'meal',
        source: 'custom',
        aliases: '',
        portionUnits: [
          PortionUnit(foodId: 1, unitName: 'day_ration', gramsPerUnit: 100.0),
        ],
      );

      // Log food every calendar day for 21 days (2500 kcal/day)
      for (int day = 0; day <= 21; day++) {
        final d = startDate.add(Duration(days: day));
        final dateStr = DateFormat('yyyy-MM-dd').format(d);
        db.insertFoodLog(FoodLogEntry(
          id: 0,
          date: dateStr,
          mealType: MealType.lunch,
          foodId: 1,
          foodName: sampleFood.name,
          servingQuantity: 1.0,
          unitName: 'day_ration',
          gramWeight: 100.0,
          calories: 2500.0,
          protein: 100.0,
          carbs: 300.0,
          fat: 50.0,
          fiber: 20.0,
          oilModifier: OilModifier.standard,
          loggedAt: d,
        ));
      }

      // Log scale weights ONLY every 3 days at constant 75.0 kg
      for (int day = 0; day <= 21; day += 3) {
        final d = startDate.add(Duration(days: day));
        final dateStr = DateFormat('yyyy-MM-dd').format(d);
        db.insertWeightLog(dateStr, 75.0, '3-day check');
      }

      // Refresh weight logs provider so container picks them up
      container.read(weightLogsProvider.notifier).refresh();

      final state = container.read(expenditureStateProvider);

      // With previous flawed algorithm, sparse weigh-ins drifted to 3,571 kcal!
      // With calendar-day distribution, expenditure stays stably within +/- 100 kcal of 2500.
      expect(state.expenditureKcal, inInclusiveRange(2400.0, 2600.0),
          reason:
              'TDEE should remain ~2500 kcal instead of blowing up to 3500+ with 3-day weigh-ins');
    });

    test(
        'Weigh-ins every 7 days with 0.5 kg loss over 14 days converges to correct TDEE',
        () {
      final startDate = DateTime(2026, 1, 1);

      // 0.5 kg loss in 14 days = 0.5 * 7700 = 3850 kcal deficit over 14 days = 275 kcal/day deficit.
      // User ate 2225 kcal/day. True expenditure = 2225 + 275 = 2500 kcal.
      for (int day = 0; day <= 14; day++) {
        final d = startDate.add(Duration(days: day));
        final dateStr = DateFormat('yyyy-MM-dd').format(d);
        db.insertFoodLog(FoodLogEntry(
          id: 0,
          date: dateStr,
          mealType: MealType.dinner,
          foodId: 1,
          foodName: 'Standard Meal',
          servingQuantity: 1.0,
          unitName: 'ration',
          gramWeight: 100.0,
          calories: 2225.0,
          protein: 120.0,
          carbs: 250.0,
          fat: 60.0,
          fiber: 25.0,
          oilModifier: OilModifier.standard,
          loggedAt: d,
        ));
      }

      // Log weight only on Day 0 (75.0 kg), Day 7 (74.75 kg), and Day 14 (74.5 kg)
      db.insertWeightLog('2026-01-01', 75.0, 'Day 0');
      db.insertWeightLog('2026-01-08', 74.75, 'Day 7');
      db.insertWeightLog('2026-01-15', 74.5, 'Day 14');

      container.read(weightLogsProvider.notifier).refresh();

      final state = container.read(expenditureStateProvider);

      // Should converge close to 2500 kcal without explosive drift (EWMA edge attenuation over 14 days)
      expect(state.expenditureKcal, inInclusiveRange(2350.0, 2600.0),
          reason:
              'Weekly weigh-in cadence should correctly distribute trend slope across intermediate days');
    });
  });
}
