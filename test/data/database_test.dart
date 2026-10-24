import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/data/local/app_database.dart';

void main() {
  group('AppDatabase Local Storage & Search Tests', () {
    late Database rawDb;
    late AppDatabase appDb;

    setUp(() {
      rawDb = sqlite3.openInMemory();

      // Setup foods and portion_units schema matching foods_master.db
      rawDb.execute('''
        CREATE TABLE foods (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uuid TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          region TEXT NOT NULL,
          calories REAL NOT NULL,
          protein REAL NOT NULL,
          carbs REAL NOT NULL,
          fat REAL NOT NULL,
          fiber REAL NOT NULL,
          icon_svg TEXT NOT NULL,
          source TEXT NOT NULL,
          aliases TEXT NOT NULL
        );

        CREATE TABLE portion_units (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          food_id INTEGER NOT NULL,
          unit_name TEXT NOT NULL,
          gram_weight REAL NOT NULL,
          is_default INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE CASCADE
        );

        CREATE VIRTUAL TABLE foods_fts USING fts5(
          name,
          category,
          region,
          aliases,
          content='foods',
          content_rowid='id'
        );

        CREATE TRIGGER foods_ai AFTER INSERT ON foods BEGIN
          INSERT INTO foods_fts(rowid, name, category, region, aliases)
          VALUES (new.id, new.name, new.category, new.region, new.aliases);
        END;
      ''');

      // Seed sample Indian foods
      rawDb.execute('''
        INSERT INTO foods (id, uuid, name, category, region, calories, protein, carbs, fat, fiber, icon_svg, source, aliases)
        VALUES 
        (1, 'uuid-idli', 'Idli (Steamed Rice Cake)', 'Breakfast', 'South Indian', 132.0, 3.8, 27.2, 0.4, 1.4, 'i10.svg', 'COOKED_INDIAN', 'idly idlis steamed cake'),
        (2, 'uuid-dosa', 'Masala Dosa', 'Breakfast', 'South Indian', 215.0, 4.8, 32.4, 7.6, 2.8, 'i12.svg', 'COOKED_INDIAN', 'dosai masala potato aloo'),
        (3, 'uuid-paneer', 'Paneer Butter Masala', 'Curry', 'North Indian', 260.0, 9.2, 8.5, 21.0, 1.8, 'i15.svg', 'COOKED_INDIAN', 'paneer makhani cottage cheese');

        INSERT INTO portion_units (food_id, unit_name, gram_weight, is_default)
        VALUES
        (1, 'Standard Piece', 40.0, 1),
        (1, 'Plate (2 Idlis)', 80.0, 0),
        (1, 'Grams', 1.0, 0),
        (2, 'Standard Dosa', 120.0, 1),
        (3, 'Katori (150g)', 150.0, 1);
      ''');

      appDb = AppDatabase(rawDb);
      appDb.initUserTables();
    });

    tearDown(() {
      rawDb.dispose();
    });

    test('Searches foods using FTS5 match and loads portion units', () {
      final results = appDb.searchFoods('idli');
      expect(results, isNotEmpty);
      final idli = results.first;
      expect(idli.name, contains('Idli'));
      expect(idli.portionUnits.length, equals(3));
      expect(idli.defaultPortionUnit.unitName, equals('Standard Piece'));
      expect(idli.defaultPortionUnit.gramWeight, equals(40.0));
    });

    test('Searches foods by alias keyword', () {
      final results = appDb.searchFoods('makhani');
      expect(results, isNotEmpty);
      expect(results.first.name, equals('Paneer Butter Masala'));
    });

    test('Computes nutrition with oil modifiers correctly', () {
      final paneer = appDb.getFoodById(3);
      expect(paneer, isNotNull);

      // Standard Katori (150g)
      final standard = paneer!.calculateNutrition(
        quantity: 1.0,
        unit: paneer.defaultPortionUnit,
        oilModifier: OilModifier.standard,
      );
      // 150g = 1.5 * 100g values
      expect(standard.totalGrams, equals(150.0));
      expect(standard.calories, closeTo(390.0, 0.1));
      expect(standard.fat, closeTo(31.5, 0.1));

      // Low Oil (Homestyle)
      final lowOil = paneer.calculateNutrition(
        quantity: 1.0,
        unit: paneer.defaultPortionUnit,
        oilModifier: OilModifier.lowOil,
      );
      expect(lowOil.fat, lessThan(standard.fat));
      expect(lowOil.calories, lessThan(standard.calories));

      // Extra Ghee / Restaurant
      final extraGhee = paneer.calculateNutrition(
        quantity: 1.0,
        unit: paneer.defaultPortionUnit,
        oilModifier: OilModifier.extraGheeOrOil,
      );
      expect(extraGhee.fat, equals(standard.fat + 5.0));
      expect(extraGhee.calories, equals(standard.calories + 45.0));
    });

    test('Inserts and retrieves daily food log entries', () {
      final entry = FoodLogEntry(
        date: '2026-10-17',
        mealType: MealType.breakfast,
        foodId: 1,
        foodName: 'Idli (Steamed Rice Cake)',
        servingQuantity: 2.0,
        unitName: 'Standard Piece',
        gramWeight: 80.0,
        calories: 105.6,
        protein: 3.04,
        carbs: 21.76,
        fat: 0.32,
        fiber: 1.12,
        oilModifier: OilModifier.standard,
        loggedAt: DateTime(2026, 10, 17, 8, 30),
      );

      final id = appDb.insertFoodLog(entry);
      expect(id, greaterThan(0));

      final logs = appDb.getFoodLogsForDate('2026-10-17');
      expect(logs.length, equals(1));
      expect(logs.first.foodName, equals('Idli (Steamed Rice Cake)'));
      expect(logs.first.servingQuantity, equals(2.0));
      expect(logs.first.calories, closeTo(105.6, 0.01));

      // Delete log
      appDb.deleteFoodLog(id);
      expect(appDb.getFoodLogsForDate('2026-10-17'), isEmpty);
    });

    test('Inserts, retrieves and updates scale weight entries', () {
      appDb.insertWeightLog('2026-10-15', 76.2, 'Morning fasted');
      appDb.insertWeightLog('2026-10-16', 75.9, 'Post walk');
      appDb.insertWeightLog('2026-10-17', 75.8, null);

      final weights = appDb.getAllWeightLogs();
      expect(weights.length, equals(3));
      expect(weights[0].date, equals(DateTime(2026, 10, 15)));
      expect(weights[0].weightKg, equals(76.2));
      expect(weights[2].weightKg, equals(75.8));

      // Overwrite/update existing date
      appDb.insertWeightLog('2026-10-17', 75.7, 'Updated note');
      final updated = appDb.getWeightLogForDate('2026-10-17');
      expect(updated?.weightKg, equals(75.7));
      expect(updated?.note, equals('Updated note'));
    });

    test('Saves and loads UserProfile with macro targets', () {
      const profile = UserProfile(
        id: 'usr_default',
        name: 'Arjun',
        currentWeightKg: 76.0,
        targetWeightKg: 70.0,
        heightCm: 175.0,
        age: 28,
        isMale: true,
        goalType: GoalType.fatLoss,
        programMode: ProgramMode.coached,
        weeklyRateOfChangePct: -0.6,
        proteinPreference: ProteinPreference.high,
        calorieFloor: 1400.0,
        baselineExpenditureKcal: 2350.0,
      );

      appDb.saveUserProfile(profile);
      final loaded = appDb.getUserProfile();
      expect(loaded, isNotNull);
      expect(loaded!.name, equals('Arjun'));
      expect(loaded.goalType, equals(GoalType.fatLoss));
      expect(loaded.weeklyRateOfChangePct, equals(-0.6));

      // Calculate target macros based on Bayesian expenditure
      final macros = loaded.calculateTargetMacros(2350.0);
      expect(macros.calories, lessThan(2350.0));
      expect(macros.proteinGrams, equals(152.0)); // 76kg * 2.0g/kg
      expect(macros.fatGrams, greaterThanOrEqualTo(53.0));
      expect(macros.carbsGrams, greaterThan(0.0));
    });
  });
}
