import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/presentation/providers/app_providers.dart';

void main() {
  group('Riverpod Expenditure Reactive Wiring & Boundary Stress Tests', () {
    late Database rawDb;
    late AppDatabase appDb;
    late ProviderContainer container;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      rawDb.execute('''
        CREATE TABLE foods (
          id INTEGER PRIMARY KEY, uuid TEXT, name TEXT, category TEXT, region TEXT,
          calories REAL, protein REAL, carbs REAL, fat REAL, fiber REAL, icon_svg TEXT,
          source TEXT, aliases TEXT
        );
        CREATE TABLE portion_units (
          id INTEGER PRIMARY KEY, food_id INTEGER, unit_name TEXT, gram_weight REAL, is_default INTEGER
        );
      ''');

      appDb = AppDatabase(rawDb);
      appDb.initUserTables();

      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(appDb),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      rawDb.dispose();
    });

    FoodLogEntry buildMealEntry({
      required String date,
      required double calories,
      MealType mealType = MealType.lunch,
      String foodName = 'Test Meal',
    }) {
      return FoodLogEntry(
        date: date,
        mealType: mealType,
        foodId: 101,
        foodName: foodName,
        servingQuantity: 1.0,
        unitName: 'Serving',
        gramWeight: 200.0,
        calories: calories,
        protein: calories * 0.1 / 4.0,
        carbs: calories * 0.6 / 4.0,
        fat: calories * 0.3 / 9.0,
        fiber: 5.0,
        oilModifier: OilModifier.standard,
        loggedAt: DateTime.parse('${date}T12:00:00Z'),
      );
    }

    // =========================================================================
    // 1. Reactive Recomputes via foodLogsRevisionProvider
    // =========================================================================

    test(
        'Rapid meal additions and deletions trigger foodLogsRevisionProvider and reactive recomputes',
        () {
      const pastDate = '2026-03-01';

      // Seed initial scale weights
      final weightNotifier = container.read(weightLogsProvider.notifier);
      weightNotifier.logWeight(pastDate, 80.0, 'Baseline');
      weightNotifier.logWeight('2026-03-02', 80.0, 'Day 2');

      final initialState = container.read(expenditureStateProvider);
      expect(initialState.trendWeightKg, equals(80.0));
      final initialRevision = container.read(foodLogsRevisionProvider);

      // Set selected date to pastDate and log food via DailyFoodLogsNotifier
      container.read(selectedDateProvider.notifier).state = pastDate;
      final foodNotifier = container.read(dailyFoodLogsProvider.notifier);

      final mealId1 = foodNotifier.addFood(buildMealEntry(
        date: pastDate,
        calories: 600.0,
        foodName: 'Breakfast Oats',
      ));

      // Revision counter must increment
      expect(container.read(foodLogsRevisionProvider),
          equals(initialRevision + 1));

      // Expenditure provider must recompute reactively
      final stateAfterMeal1 = container.read(expenditureStateProvider);
      expect(stateAfterMeal1, isNotNull);

      // Add a second meal
      final mealId2 = foodNotifier.addFood(buildMealEntry(
        date: pastDate,
        calories: 800.0,
        foodName: 'Lunch Bowl',
      ));
      expect(container.read(foodLogsRevisionProvider),
          equals(initialRevision + 2));

      // Daily totals in DB should reflect 1400 kcal
      final totals = appDb.getDailyCalorieTotals();
      expect(totals[pastDate], equals(1400.0));

      // Rapidly add and delete 20 meals in sequence
      for (var i = 0; i < 20; i++) {
        final id = foodNotifier.addFood(buildMealEntry(
          date: pastDate,
          calories: 100.0,
          foodName: 'Snack #$i',
        ));
        foodNotifier.deleteFood(id);
      }

      // Final calorie total should remain 1400 kcal
      final finalTotals = appDb.getDailyCalorieTotals();
      expect(finalTotals[pastDate], equals(1400.0));

      // Now remove meal 1
      foodNotifier.deleteFood(mealId1);
      expect(appDb.getDailyCalorieTotals()[pastDate], equals(800.0));

      // Remove meal 2
      foodNotifier.deleteFood(mealId2);
      expect(appDb.getDailyCalorieTotals()[pastDate], isNull);
    });

    // =========================================================================
    // 2. Reactive Recomputes via Weight Updates
    // =========================================================================

    test('Weight logging and updates trigger reactive expenditure recomputes',
        () {
      final weightNotifier = container.read(weightLogsProvider.notifier);

      // Initially no weights -> returns baseline state
      var expState = container.read(expenditureStateProvider);
      expect(expState.variance, equals(300.0 * 300.0));

      // Add day 1 weight
      weightNotifier.logWeight('2026-04-01', 75.0, null);
      expState = container.read(expenditureStateProvider);
      expect(expState.trendWeightKg, equals(75.0));

      // Add consecutive days with gradual drop
      weightNotifier.logWeight('2026-04-02', 74.9, null);
      weightNotifier.logWeight('2026-04-03', 74.8, null);
      weightNotifier.logWeight('2026-04-04', 74.7, null);

      final state4 = container.read(expenditureStateProvider);
      expect(state4.trendWeightKg, lessThan(75.0));

      // Deleting a weight entry recomputes state
      weightNotifier.deleteWeight('2026-04-04');
      final stateAfterDelete = container.read(expenditureStateProvider);
      expect(stateAfterDelete.date, isNotNull);
    });

    // =========================================================================
    // 3. Reactive Day Completion Toggling
    // =========================================================================

    test(
        'Toggling day completion reactively re-evaluates expenditure gating & persistence',
        () {
      const testDate = '2026-05-10';

      final weightNotifier = container.read(weightLogsProvider.notifier);
      weightNotifier.logWeight(testDate, 70.0, null);
      weightNotifier.logWeight('2026-05-11', 70.0, null);

      container.read(selectedDateProvider.notifier).state = testDate;
      final foodNotifier = container.read(dailyFoodLogsProvider.notifier);
      foodNotifier.addFood(buildMealEntry(date: testDate, calories: 2200.0));

      final completionsNotifier =
          container.read(dayCompletionsProvider.notifier);

      // Toggle testDate to incomplete
      completionsNotifier.setDayComplete(testDate, false);
      expect(completionsNotifier.isDayComplete(testDate), isFalse);

      // When testDate is incomplete, it is not persisted in expenditure_history
      final stateIncomplete = container.read(expenditureStateProvider);
      expect(stateIncomplete, isNotNull);

      // Toggle testDate to complete
      completionsNotifier.setDayComplete(testDate, true);
      expect(completionsNotifier.isDayComplete(testDate), isTrue);

      // Re-read provider to trigger recompute
      final stateComplete = container.read(expenditureStateProvider);
      expect(stateComplete, isNotNull);

      // Complete record was persisted in expenditure_history
      final record = appDb.getExpenditureForDate(testDate);
      expect(record, isNotNull);
      expect(record!.date, equals(testDate));
    });

    // =========================================================================
    // 4. Time Boundary Consistency Across Month / Year Roll Boundaries
    // =========================================================================

    test(
        'Calendar day stepper transitions seamlessly across leap year (Feb 28 -> Feb 29 -> Mar 1)',
        () {
      final weightNotifier = container.read(weightLogsProvider.notifier);

      // 2024 is a leap year
      weightNotifier.logWeight('2024-02-28', 80.0, null);
      weightNotifier.logWeight('2024-02-29', 79.9, null);
      weightNotifier.logWeight('2024-03-01', 79.8, null);

      container.read(selectedDateProvider.notifier).state = '2024-02-28';
      final foodNotifier = container.read(dailyFoodLogsProvider.notifier);
      foodNotifier
          .addFood(buildMealEntry(date: '2024-02-28', calories: 2000.0));
      foodNotifier
          .addFood(buildMealEntry(date: '2024-02-29', calories: 2000.0));
      foodNotifier
          .addFood(buildMealEntry(date: '2024-03-01', calories: 2000.0));

      final state = container.read(expenditureStateProvider);
      expect(state, isNotNull);

      // Verify that records were persisted for each date
      expect(appDb.getExpenditureForDate('2024-02-28'), isNotNull);
      expect(appDb.getExpenditureForDate('2024-02-29'), isNotNull);
      expect(appDb.getExpenditureForDate('2024-03-01'), isNotNull);
    });

    test(
        'Calendar day stepper transitions seamlessly across non-leap year (Feb 28 -> Mar 1)',
        () {
      final weightNotifier = container.read(weightLogsProvider.notifier);

      // 2025 is NOT a leap year
      weightNotifier.logWeight('2025-02-28', 80.0, null);
      weightNotifier.logWeight('2025-03-01', 79.9, null);

      container.read(selectedDateProvider.notifier).state = '2025-02-28';
      final foodNotifier = container.read(dailyFoodLogsProvider.notifier);
      foodNotifier
          .addFood(buildMealEntry(date: '2025-02-28', calories: 2100.0));
      foodNotifier
          .addFood(buildMealEntry(date: '2025-03-01', calories: 2100.0));

      final state = container.read(expenditureStateProvider);
      expect(state, isNotNull);

      expect(appDb.getExpenditureForDate('2025-02-28'), isNotNull);
      expect(appDb.getExpenditureForDate('2025-02-29'), isNull);
      expect(appDb.getExpenditureForDate('2025-03-01'), isNotNull);
    });

    test(
        'Calendar day stepper transitions seamlessly across year boundary (Dec 31 -> Jan 1)',
        () {
      final weightNotifier = container.read(weightLogsProvider.notifier);

      weightNotifier.logWeight('2025-12-31', 82.0, null);
      weightNotifier.logWeight('2026-01-01', 81.9, null);
      weightNotifier.logWeight('2026-01-02', 81.8, null);

      container.read(selectedDateProvider.notifier).state = '2025-12-31';
      final foodNotifier = container.read(dailyFoodLogsProvider.notifier);
      foodNotifier
          .addFood(buildMealEntry(date: '2025-12-31', calories: 2300.0));
      foodNotifier
          .addFood(buildMealEntry(date: '2026-01-01', calories: 2300.0));
      foodNotifier
          .addFood(buildMealEntry(date: '2026-01-02', calories: 2300.0));

      final state = container.read(expenditureStateProvider);
      expect(state, isNotNull);

      expect(appDb.getExpenditureForDate('2025-12-31'), isNotNull);
      expect(appDb.getExpenditureForDate('2026-01-01'), isNotNull);
      expect(appDb.getExpenditureForDate('2026-01-02'), isNotNull);
    });

    test('Stepping across 365 continuous days preserves convergence', () {
      final baseDate = DateTime(2025, 1, 1);
      final weightNotifier = container.read(weightLogsProvider.notifier);

      // Seed 365 days of weights and food logs directly in DB for efficiency
      for (var i = 0; i < 365; i++) {
        final dStr =
            DateFormat('yyyy-MM-dd').format(baseDate.add(Duration(days: i)));
        appDb.insertWeightLog(dStr, 80.0 - (i * 0.01), null);
        appDb.insertFoodLog(buildMealEntry(date: dStr, calories: 2400.0));
      }

      weightNotifier.refresh();

      final state = container.read(expenditureStateProvider);
      expect(state, isNotNull);
      expect(state.trendWeightKg, closeTo(80.0 - (364 * 0.01), 0.5));
      // TDEE should be bounded and stabilized
      expect(state.expenditureKcal, greaterThan(1500.0));
      expect(state.expenditureKcal, lessThan(3500.0));

      // Check that 365 expenditure history rows were written to DB
      final history = appDb.getExpenditureHistory();
      expect(history.length, equals(365));
      expect(history.first.date, equals('2025-01-01'));
      expect(history.last.date, equals('2025-12-31'));
    });
  });
}
