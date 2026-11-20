import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/domain/models/workout_session.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('Sique v2.0.0 Database Remediation Test Suite (Wave 1 db-core)', () {
    late Database rawDb;
    late AppDatabase appDb;

    setUp(() {
      appDb = AppDatabase.inMemory();
      rawDb = appDb.rawDb;
    });

    tearDown(() {
      appDb.close();
    });

    test('1. Migration v4 establishes composite keys and new schema columns',
        () {
      // PRAGMA user_version is 4
      final ver = rawDb.select('PRAGMA user_version;').first.values.first;
      expect(ver, equals(4));

      // user_profile has date_of_birth and user_id
      final profileCols = rawDb
          .select("PRAGMA table_info('user_profile');")
          .map((r) => r['name'] as String)
          .toSet();
      expect(profileCols.contains('date_of_birth'), isTrue);
      expect(profileCols.contains('user_id'), isTrue);

      // coaching_check_ins has user_id
      final coachingCols = rawDb
          .select("PRAGMA table_info('coaching_check_ins');")
          .map((r) => r['name'] as String)
          .toSet();
      expect(coachingCols.contains('user_id'), isTrue);

      // food_logs has user_id
      final foodCols = rawDb
          .select("PRAGMA table_info('food_logs');")
          .map((r) => r['name'] as String)
          .toSet();
      expect(foodCols.contains('user_id'), isTrue);

      // idx_food_logs_user_date exists
      final indices = rawDb
          .select(
              "SELECT name FROM sqlite_master WHERE type='index' AND name='idx_food_logs_user_date';")
          .map((r) => r['name'] as String)
          .toSet();
      expect(indices.contains('idx_food_logs_user_date'), isTrue);

      // Multi-tenancy on weight_logs: two users can log on the same calendar date
      rawDb.execute('''
        INSERT INTO weight_logs (user_id, date, scale_weight, source, logged_at)
        VALUES ('user_alpha', '2026-11-20', 75.0, 'manual', '2026-11-20T08:00:00Z');
      ''');
      rawDb.execute('''
        INSERT INTO weight_logs (user_id, date, scale_weight, source, logged_at)
        VALUES ('user_beta', '2026-11-20', 82.5, 'manual', '2026-11-20T08:05:00Z');
      ''');

      final weightRows = rawDb.select('SELECT * FROM weight_logs;');
      expect(weightRows.length, equals(2));

      // Multi-tenancy on day_completions: two users can complete the same date
      rawDb.execute('''
        INSERT INTO day_completions (user_id, date, is_complete, updated_at)
        VALUES ('user_alpha', '2026-11-20', 1, '2026-11-20T20:00:00Z');
      ''');
      rawDb.execute('''
        INSERT INTO day_completions (user_id, date, is_complete, updated_at)
        VALUES ('user_beta', '2026-11-20', 0, '2026-11-20T20:05:00Z');
      ''');

      final dayRows = rawDb.select('SELECT * FROM day_completions;');
      expect(dayRows.length, equals(2));

      // Multi-tenancy on expenditure_history: two users can store expenditures for the same date
      rawDb.execute('''
        INSERT INTO expenditure_history (user_id, date, expenditure_kcal, trend_weight_kg, variance, confidence)
        VALUES ('user_alpha', '2026-11-20', 2400.0, 74.8, 150.0, 0.95);
      ''');
      rawDb.execute('''
        INSERT INTO expenditure_history (user_id, date, expenditure_kcal, trend_weight_kg, variance, confidence)
        VALUES ('user_beta', '2026-11-20', 2900.0, 82.3, 160.0, 0.92);
      ''');

      final expRows = rawDb.select('SELECT * FROM expenditure_history;');
      expect(expRows.length, equals(2));
    });

    test(
        '2. WeightDao scopes read and write operations to user_id and syncs weight profile',
        () {
      const profileAlpha = UserProfile(
        id: 'user_alpha',
        name: 'Alpha Athlete',
        currentWeightKg: 80.0,
        targetWeightKg: 75.0,
        heightCm: 178.0,
        age: 28,
        isMale: true,
        goalType: GoalType.fatLoss,
        programMode: ProgramMode.coached,
        weeklyRateOfChangePct: -0.5,
        proteinPreference: ProteinPreference.high,
        calorieFloor: 1400.0,
        baselineExpenditureKcal: 2500.0,
      );
      appDb.saveUserProfile(profileAlpha);

      // Insert weight for user_alpha
      appDb.weightDao.insertWeightLog('2026-11-20', 78.5, 'Alpha Morning',
          userId: 'user_alpha');

      // Insert weight for user_beta on same date
      appDb.weightDao.insertWeightLog('2026-11-20', 88.0, 'Beta Morning',
          userId: 'user_beta');

      // Verify read queries are isolated
      final alphaLogs = appDb.weightDao.getAllWeightLogs(userId: 'user_alpha');
      expect(alphaLogs.length, equals(1));
      expect(alphaLogs.first.weightKg, equals(78.5));

      final betaLogs = appDb.weightDao.getAllWeightLogs(userId: 'user_beta');
      expect(betaLogs.length, equals(1));
      expect(betaLogs.first.weightKg, equals(88.0));

      // Check single date query isolation
      expect(
          appDb.weightDao
              .getWeightLogForDate('2026-11-20', userId: 'user_alpha')
              ?.weightKg,
          equals(78.5));
      expect(
          appDb.weightDao
              .getWeightLogForDate('2026-11-20', userId: 'user_beta')
              ?.weightKg,
          equals(88.0));

      // Verify user_profile weight synchronization for user_alpha
      final profile = appDb.getUserProfile(userId: 'user_alpha');
      expect(profile?.currentWeightKg, equals(78.5));
    });

    test(
        '3. FoodDao stores user_id and scopes getFoodLogsForDate / getAllFoodLogs',
        () {
      final entryAlpha = FoodLogEntry(
        date: '2026-11-20',
        mealType: MealType.breakfast,
        foodId: 101,
        foodName: 'Oatmeal Porridge',
        servingQuantity: 1.0,
        unitName: 'bowl',
        gramWeight: 250.0,
        calories: 320.0,
        protein: 12.0,
        carbs: 55.0,
        fat: 6.0,
        fiber: 8.0,
        oilModifier: OilModifier.standard,
        loggedAt: DateTime(2026, 11, 20, 8, 30),
      );

      final entryBeta = FoodLogEntry(
        date: '2026-11-20',
        mealType: MealType.breakfast,
        foodId: 102,
        foodName: 'Egg White Scramble',
        servingQuantity: 1.0,
        unitName: 'plate',
        gramWeight: 200.0,
        calories: 210.0,
        protein: 28.0,
        carbs: 4.0,
        fat: 8.0,
        fiber: 0.0,
        oilModifier: OilModifier.lowOil,
        loggedAt: DateTime(2026, 11, 20, 8, 45),
      );

      final idAlpha =
          appDb.foodDao.insertFoodLog(entryAlpha, userId: 'user_alpha');
      final idBeta =
          appDb.foodDao.insertFoodLog(entryBeta, userId: 'user_beta');
      expect(idAlpha, isPositive);
      expect(idBeta, isPositive);

      // Verify raw database has user_id populated
      final rows = rawDb.select('SELECT user_id, food_name FROM food_logs;');
      expect(rows.length, equals(2));
      expect(rows.any((r) => r['user_id'] == 'user_alpha'), isTrue);
      expect(rows.any((r) => r['user_id'] == 'user_beta'), isTrue);

      // Verify date query is tenant-isolated
      final alphaLogs =
          appDb.foodDao.getFoodLogsForDate('2026-11-20', userId: 'user_alpha');
      expect(alphaLogs.length, equals(1));
      expect(alphaLogs.first.foodName, equals('Oatmeal Porridge'));

      final betaLogs =
          appDb.foodDao.getFoodLogsForDate('2026-11-20', userId: 'user_beta');
      expect(betaLogs.length, equals(1));
      expect(betaLogs.first.foodName, equals('Egg White Scramble'));

      // Test restoreFoodLog preserves user_id
      appDb.foodDao.deleteFoodLog(idAlpha, userId: 'user_alpha');
      expect(
          appDb.foodDao.getFoodLogsForDate('2026-11-20', userId: 'user_alpha'),
          isEmpty);

      appDb.foodDao.restoreFoodLog(
        FoodLogEntry(
          id: idAlpha,
          date: entryAlpha.date,
          mealType: entryAlpha.mealType,
          foodId: entryAlpha.foodId,
          foodName: entryAlpha.foodName,
          servingQuantity: entryAlpha.servingQuantity,
          unitName: entryAlpha.unitName,
          gramWeight: entryAlpha.gramWeight,
          calories: entryAlpha.calories,
          protein: entryAlpha.protein,
          carbs: entryAlpha.carbs,
          fat: entryAlpha.fat,
          fiber: entryAlpha.fiber,
          oilModifier: entryAlpha.oilModifier,
          loggedAt: entryAlpha.loggedAt,
        ),
        userId: 'user_alpha',
      );

      final restored =
          appDb.foodDao.getFoodLogsForDate('2026-11-20', userId: 'user_alpha');
      expect(restored.length, equals(1));
      expect(restored.first.id, equals(idAlpha));
    });

    test('4. SettingsDao scopes settings per user using <user_id>:<key>', () {
      appDb.settingsDao.setSetting('theme', 'dark', userId: 'user_alpha');
      appDb.settingsDao.setSetting('theme', 'light', userId: 'user_beta');

      // Check underlying table stores with user_id prefix
      final rawSettings = rawDb.select('SELECT key, value FROM app_settings;');
      expect(rawSettings.any((r) => r['key'] == 'user_alpha:theme'), isTrue);
      expect(rawSettings.any((r) => r['key'] == 'user_beta:theme'), isTrue);

      // Verify getSetting reads tenant-isolated values
      expect(appDb.settingsDao.getSetting('theme', '', userId: 'user_alpha'),
          equals('dark'));
      expect(appDb.settingsDao.getSetting('theme', '', userId: 'user_beta'),
          equals('light'));

      // Verify getAllSettings strips user prefix for consumer convenience
      final alphaAll = appDb.settingsDao.getAllSettings(userId: 'user_alpha');
      expect(alphaAll['theme'], equals('dark'));

      final betaAll = appDb.settingsDao.getAllSettings(userId: 'user_beta');
      expect(betaAll['theme'], equals('light'));
    });

    test(
        '5. ProfileDao.clearAllData commits in transaction, runs VACUUM outside, and preserves seed marker',
        () {
      // Pre-seed static foods catalog and catalog seed marker
      rawDb.execute('''
        INSERT INTO foods (id, uuid, name, category, region, calories, protein, carbs, fat, fiber, icon_svg, source, aliases)
        VALUES (999, 'uuid_seed_1', 'Static Banana', 'Fruit', 'India', 89.0, 1.1, 23.0, 0.3, 2.6, 'fruit', 'ICMR', 'kela');
      ''');
      rawDb.execute('''
        INSERT INTO portion_units (id, food_id, unit_name, gram_weight, is_default)
        VALUES (999, 999, 'medium', 118.0, 1);
      ''');
      rawDb.execute('''
        INSERT INTO app_settings (key, value)
        VALUES ('static_foods_seed_marker', 'v2_complete');
      ''');
      rawDb.execute('''
        INSERT INTO app_settings (key, value)
        VALUES ('user_alpha:personal_pref', 'some_value');
      ''');

      // Populate user data
      rawDb.execute('''
        INSERT INTO weight_logs (user_id, date, scale_weight, source, logged_at)
        VALUES ('user_alpha', '2026-11-20', 70.0, 'manual', '2026-11-20T08:00:00Z');
      ''');
      rawDb.execute('''
        INSERT INTO food_logs (user_id, date, meal_type, food_id, food_name, serving_quantity, unit_name, gram_weight, calories, protein, carbs, fat, fiber, oil_modifier, logged_at, icon_svg)
        VALUES ('user_alpha', '2026-11-20', 'lunch', 999, 'Static Banana', 1.0, 'medium', 118.0, 89.0, 1.1, 23.0, 0.3, 2.6, 'none', '2026-11-20T12:00:00Z', 'fruit');
      ''');

      // Execute clearAllData
      appDb.clearAllData();

      // Verify user tables wiped
      expect(rawDb.select('SELECT * FROM weight_logs;'), isEmpty);
      expect(rawDb.select('SELECT * FROM food_logs;'), isEmpty);

      // Verify static catalog preserved
      final remainingFoods = rawDb.select('SELECT id, name FROM foods;');
      expect(remainingFoods.length, equals(1));
      expect(remainingFoods.first['name'], equals('Static Banana'));

      final remainingPortions = rawDb.select('SELECT id FROM portion_units;');
      expect(remainingPortions.length, equals(1));

      // Verify static food seed marker is strictly preserved while user setting was removed
      final remainingSettings =
          rawDb.select('SELECT key, value FROM app_settings;');
      expect(remainingSettings.length, equals(1));
      expect(
          remainingSettings.first['key'], equals('static_foods_seed_marker'));
      expect(remainingSettings.first['value'], equals('v2_complete'));
    });

    test(
        '6. WorkoutDao deduplicates on workout_uuid and deterministic ID mapping',
        () {
      final start = DateTime(2026, 11, 20, 17, 30);
      final end = DateTime(2026, 11, 20, 18, 30);

      // Two sessions representing same workout: one has no ID (empty or temp)
      final session1 = WorkoutSession(
        id: '',
        source: WorkoutSource.healthConnect,
        title: 'Strength Training',
        startTime: start,
        endTime: end,
        durationMinutes: 60,
        caloriesBurned: 350.0,
        createdAt: DateTime(2026, 11, 20, 18, 35),
      );

      final session2 = WorkoutSession(
        id: '',
        source: WorkoutSource.healthConnect,
        title: 'Strength Training',
        startTime: start,
        endTime: end,
        durationMinutes: 60,
        caloriesBurned: 375.0, // updated calories on re-sync
        createdAt: DateTime(2026, 11, 20, 18, 40),
      );

      appDb.workoutDao.insertWorkoutSessions([session1, session2]);

      final all = appDb.workoutDao.getAllWorkoutSessions();
      expect(all.length, equals(1)); // Deduplicated to single record
      expect(all.first.caloriesBurned, equals(375.0));
      expect(all.first.id, startsWith('workout_health_connect_'));
    });

    test(
        '7. FTS5 search handles boolean keywords and internal quotes without syntax crash',
        () {
      // Seed foods with words that could trigger boolean parser issues
      rawDb.execute('''
        INSERT INTO foods (id, uuid, name, category, region, calories, protein, carbs, fat, fiber, icon_svg, source, aliases)
        VALUES (1, 'u1', 'Fish and Chips', 'Dinner', 'Global', 500.0, 25.0, 60.0, 20.0, 3.0, 'fish', 'Source', 'fries and fish');
      ''');
      rawDb.execute('''
        INSERT INTO foods (id, uuid, name, category, region, calories, protein, carbs, fat, fiber, icon_svg, source, aliases)
        VALUES (2, 'u2', 'Sweet or Sour Chicken', 'Dinner', 'Asian', 450.0, 30.0, 40.0, 15.0, 2.0, 'chicken', 'Source', 'sweet not sour');
      ''');

      // Search with FTS boolean keywords: AND, OR, NOT, NEAR
      expect(() => appDb.searchFoods('AND'), returnsNormally);
      expect(() => appDb.searchFoods('OR'), returnsNormally);
      expect(() => appDb.searchFoods('NOT'), returnsNormally);
      expect(() => appDb.searchFoods('NEAR'), returnsNormally);
      expect(() => appDb.searchFoods('Fish AND Chips'), returnsNormally);
      expect(() => appDb.searchFoods('Chicken NOT sour'), returnsNormally);

      // Search with quotes and special characters
      expect(() => appDb.searchFoods('Fish "and" Chips'), returnsNormally);
      expect(() => appDb.searchFoods('"""'), returnsNormally);
      expect(() => appDb.searchFoods('""*'), returnsNormally);
      expect(() => appDb.searchFoods('test -term (bracket)'), returnsNormally);

      final results = appDb.searchFoods('Fish AND Chips');
      expect(results, isNotEmpty);
      expect(results.first.name, equals('Fish and Chips'));
    });

    test(
        '8. AppDatabase.open throws DatabaseOpenException on inaccessible or corrupt path',
        () async {
      // Attempting to open at an illegal file path (e.g. directory as file or impossible path)
      final impossiblePath = Platform.isWindows
          ? 'Z:\\non_existent_drive\\cannot_open.db'
          : '/non_existent_root_dir_impossible/sub/cannot_open.db';

      expect(
        () async => await AppDatabase.open(customPath: impossiblePath),
        throwsA(isA<DatabaseOpenException>()),
      );
    });

    test(
        '9. date_of_birth persists across database close and reopen via canonical 29-column upsert',
        () {
      final tempDir = Directory.systemTemp.createTempSync('sique_dob_test_');
      final dbFile = File('${tempDir.path}/dob_test.db');
      try {
        // Open file-backed DB, write user profile with DOB
        var diskDb = sqlite3.open(dbFile.path);
        var dbInstance = AppDatabase(diskDb, dbPath: dbFile.path);

        const profileWithDob = UserProfile(
          id: 'user_dob_123',
          name: 'Athlete DOB',
          currentWeightKg: 78.5,
          targetWeightKg: 72.0,
          heightCm: 180.0,
          age: 26,
          dateOfBirth: '1998-05-14',
          isMale: true,
          goalType: GoalType.fatLoss,
          programMode: ProgramMode.coached,
          weeklyRateOfChangePct: -0.5,
          proteinPreference: ProteinPreference.high,
          calorieFloor: 1500.0,
          baselineExpenditureKcal: 2500.0,
        );

        dbInstance.profileDao.saveUserProfile(profileWithDob);
        final initialRead =
            dbInstance.profileDao.getUserProfile(userId: 'user_dob_123');
        expect(initialRead, isNotNull);
        expect(initialRead!.dateOfBirth, equals('1998-05-14'));
        expect(initialRead.age, equals(26));

        // Close database cleanly
        dbInstance.close();

        // Reopen database from same file path
        diskDb = sqlite3.open(dbFile.path);
        dbInstance = AppDatabase(diskDb, dbPath: dbFile.path);

        final reopenedRead =
            dbInstance.profileDao.getUserProfile(userId: 'user_dob_123');
        expect(reopenedRead, isNotNull);
        expect(reopenedRead!.dateOfBirth, equals('1998-05-14'));
        expect(reopenedRead.name, equals('Athlete DOB'));
        expect(reopenedRead.age, equals(26));

        dbInstance.close();
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    test('10. Multi-tenancy on coaching_check_ins scopes check-ins per user_id',
        () {
      final checkInAlpha = CoachingCheckIn(
        id: 'checkin_alpha_1',
        checkInDate: DateTime.parse('2026-11-15T08:00:00Z'),
        previousCalories: 2200.0,
        recommendedCalories: 2150.0,
        expenditureKcal: 2500.0,
        weightTrendKg: 75.0,
        isAccepted: true,
        statusNote: 'Alpha checkin note',
        createdAt: DateTime.parse('2026-11-15T08:00:00Z'),
      );

      final checkInBeta = CoachingCheckIn(
        id: 'checkin_beta_1',
        checkInDate: DateTime.parse('2026-11-15T09:00:00Z'),
        previousCalories: 2800.0,
        recommendedCalories: 2750.0,
        expenditureKcal: 3100.0,
        weightTrendKg: 85.0,
        isAccepted: false,
        statusNote: 'Beta checkin note',
        createdAt: DateTime.parse('2026-11-15T09:00:00Z'),
      );

      // Insert for user_alpha and user_beta
      appDb.insertCoachingCheckIn(checkInAlpha, userId: 'user_alpha');
      appDb.insertCoachingCheckIn(checkInBeta, userId: 'user_beta');

      final alphaList = appDb.getCoachingCheckIns(userId: 'user_alpha');
      final betaList = appDb.getCoachingCheckIns(userId: 'user_beta');

      expect(alphaList.length, equals(1));
      expect(alphaList.first.id, equals('checkin_alpha_1'));
      expect(alphaList.first.previousCalories, equals(2200.0));

      expect(betaList.length, equals(1));
      expect(betaList.first.id, equals('checkin_beta_1'));
      expect(betaList.first.previousCalories, equals(2800.0));
    });

    test(
        '11. clearUserData wipes only the target tenant and preserves static foods catalog',
        () {
      // Seed data for user_alpha and user_beta
      appDb.foodDao.insertFoodLog(
        FoodLogEntry(
          date: '2026-11-20',
          mealType: MealType.breakfast,
          foodId: 101,
          foodName: 'Oats',
          servingQuantity: 1,
          unitName: 'bowl',
          gramWeight: 100,
          calories: 350,
          protein: 12,
          carbs: 60,
          fat: 6,
          fiber: 8,
          oilModifier: OilModifier.standard,
          loggedAt: DateTime.now(),
        ),
        userId: 'user_alpha',
      );

      appDb.foodDao.insertFoodLog(
        FoodLogEntry(
          date: '2026-11-20',
          mealType: MealType.breakfast,
          foodId: 102,
          foodName: 'Eggs',
          servingQuantity: 2,
          unitName: 'egg',
          gramWeight: 100,
          calories: 140,
          protein: 12,
          carbs: 1,
          fat: 10,
          fiber: 0,
          oilModifier: OilModifier.standard,
          loggedAt: DateTime.now(),
        ),
        userId: 'user_beta',
      );

      // Verify both have 1 food entry
      expect(
          appDb.foodDao
              .getFoodLogsForDate('2026-11-20', userId: 'user_alpha')
              .length,
          equals(1));
      expect(
          appDb.foodDao
              .getFoodLogsForDate('2026-11-20', userId: 'user_beta')
              .length,
          equals(1));

      // Wipe only user_alpha
      appDb.clearUserData('user_alpha');

      // user_alpha food logs are gone, user_beta logs remain
      expect(
          appDb.foodDao.getFoodLogsForDate('2026-11-20', userId: 'user_alpha'),
          isEmpty);
      expect(
          appDb.foodDao
              .getFoodLogsForDate('2026-11-20', userId: 'user_beta')
              .length,
          equals(1));
    });
  });
}
