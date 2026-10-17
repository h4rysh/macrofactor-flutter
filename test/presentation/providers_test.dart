import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:macro_factor_app/data/local/app_database.dart';
import 'package:macro_factor_app/domain/models/food_models.dart';
import 'package:macro_factor_app/domain/models/user_profile.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';

void main() {
  group('App Riverpod Providers Reactive Logic Tests', () {
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

    test('Loads default user profile and updates reactively', () {
      final profile = container.read(userProfileProvider);
      expect(profile.name, equals('Athlete'));
      expect(profile.goalType, equals(GoalType.fatLoss));

      container.read(userProfileProvider.notifier).updateProfile(
            profile.copyWith(name: 'Vikram', currentWeightKg: 80.0),
          );

      final updated = container.read(userProfileProvider);
      expect(updated.name, equals('Vikram'));
      expect(updated.currentWeightKg, equals(80.0));
    });

    test('Computes daily nutrition aggregate from food logs', () {
      final notifier = container.read(dailyFoodLogsProvider.notifier);

      notifier.addFood(FoodLogEntry(
        date: container.read(selectedDateProvider),
        mealType: MealType.breakfast,
        foodId: 1,
        foodName: 'Idli',
        servingQuantity: 2.0,
        unitName: 'Piece',
        gramWeight: 80.0,
        calories: 120.0,
        protein: 4.0,
        carbs: 24.0,
        fat: 1.0,
        fiber: 2.0,
        oilModifier: OilModifier.standard,
        loggedAt: DateTime.now(),
      ));

      notifier.addFood(FoodLogEntry(
        date: container.read(selectedDateProvider),
        mealType: MealType.lunch,
        foodId: 2,
        foodName: 'Paneer Rice',
        servingQuantity: 1.0,
        unitName: 'Plate',
        gramWeight: 250.0,
        calories: 450.0,
        protein: 18.0,
        carbs: 55.0,
        fat: 16.0,
        fiber: 4.0,
        oilModifier: OilModifier.standard,
        loggedAt: DateTime.now(),
      ));

      final summary = container.read(dailyNutritionSummaryProvider);
      expect(summary.calories, equals(570.0));
      expect(summary.protein, equals(22.0));
      expect(summary.carbs, equals(79.0));
      expect(summary.fat, equals(17.0));
    });

    test('Calculates dynamic macro targets based on Bayesian expenditure', () {
      final targets = container.read(dailyMacroTargetProvider);
      expect(targets.calories, greaterThan(1200.0));
      expect(targets.proteinGrams, greaterThan(0.0));
      expect(targets.fatGrams, greaterThan(0.0));
      expect(targets.carbsGrams, greaterThan(0.0));
    });

    test('Calculates Weight Trend and latest point from logged weights', () {
      final notifier = container.read(weightLogsProvider.notifier);
      notifier.logWeight('2026-10-10', 80.0, null);
      notifier.logWeight('2026-10-11', 79.8, null);
      notifier.logWeight('2026-10-12', 79.5, null);

      final series = container.read(weightTrendSeriesProvider);
      expect(series.length, equals(3));
      final latest = container.read(latestTrendWeightProvider);
      expect(latest, isNotNull);
      expect(latest!.scaleWeightKg, equals(79.5));
      expect(latest.trendWeightKg, lessThan(80.0));
    });
  });
}
