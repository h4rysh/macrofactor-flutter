import 'dart:developer' as developer;

import 'package:sqlite3/common.dart';

import 'database_schema.dart';

/// Database migration engine managing PRAGMA user_version and incremental schema upgrades.
class DatabaseMigrations {
  const DatabaseMigrations._();

  static const int currentVersion = 7;
  static const int busyTimeoutMs = 5000;

  /// Applies necessary schema migrations and performance pragmas to the database.
  static void initializeAndMigrate(CommonDatabase db,
      {bool isInMemory = false}) {
    // 1. Enforce SQLite runtime integrity and performance pragmas
    db.execute('PRAGMA foreign_keys = ON;');
    db.execute('PRAGMA busy_timeout = $busyTimeoutMs;');
    if (!isInMemory) {
      try {
        db.execute('PRAGMA journal_mode = WAL;');
        db.execute('PRAGMA synchronous = NORMAL;');
      } on SqliteException catch (e, st) {
        developer.log(
          'WAL journal_mode rejected or unsupported in current environment',
          name: 'DatabaseMigrations',
          error: e,
          stackTrace: st,
        );
      }
    }

    // 2. Read existing user_version
    final versionResult = db.select('PRAGMA user_version;');
    final currentDbVersion = versionResult.first.values.first as int;

    // Guard against downgrading future database versions
    if (currentDbVersion > currentVersion) {
      developer.log(
        'Database version $currentDbVersion is newer than app currentVersion $currentVersion; skipping migration to prevent downgrade overwrite',
        name: 'DatabaseMigrations',
      );
      return;
    }

    // 3. Incremental migration ladder with transactional safety
    if (currentDbVersion < 1) {
      _runStep(db, 1, _applyVersion1);
    }

    if (currentDbVersion < 2) {
      _runStep(db, 2, _applyVersion2);
    }

    if (currentDbVersion < 3) {
      _runStep(db, 3, _applyVersion3);
    }

    if (currentDbVersion < 4) {
      _runStep(db, 4, _applyVersion4);
    }

    if (currentDbVersion < 5) {
      _runStep(db, 5, _applyVersion5);
    }

    if (currentDbVersion < 6) {
      _runStep(db, 6, _applyVersion6);
    }

    if (currentDbVersion < 7) {
      _runStep(db, 7, _applyVersion7);
    }
  }

  /// Public test-friendly hook for running an isolated migration step.
  static void applyStepForTest(CommonDatabase db, int targetVersion) {
    switch (targetVersion) {
      case 1:
        _runStep(db, 1, _applyVersion1);
      case 2:
        _runStep(db, 2, _applyVersion2);
      case 3:
        _runStep(db, 3, _applyVersion3);
      case 4:
        _runStep(db, 4, _applyVersion4);
      case 5:
        _runStep(db, 5, _applyVersion5);
      case 6:
        _runStep(db, 6, _applyVersion6);
      case 7:
        _runStep(db, 7, _applyVersion7);
      default:
        throw ArgumentError('Unknown migration target version: $targetVersion');
    }
  }

  /// Public test-friendly hook for transactional execution and rollback testing.
  static void runStepForTest(CommonDatabase db, int targetVersion,
      void Function(CommonDatabase) step) {
    _runStep(db, targetVersion, step);
  }

  static void _runStep(CommonDatabase db, int targetVersion,
      void Function(CommonDatabase) step) {
    db.execute('BEGIN TRANSACTION;');
    try {
      step(db);
      db.execute('PRAGMA user_version = $targetVersion;');
      db.execute('COMMIT;');
    } catch (e, st) {
      try {
        db.execute('ROLLBACK;');
      } on SqliteException catch (rollbackErr, rollbackSt) {
        developer.log(
          'Rollback failed during step $targetVersion',
          name: 'DatabaseMigrations',
          error: rollbackErr,
          stackTrace: rollbackSt,
        );
      }
      developer.log(
        'Migration step $targetVersion failed, rolled back',
        name: 'DatabaseMigrations',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  static void _applyVersion1(CommonDatabase db) {
    for (final statement in DatabaseSchema.allCreateStatements) {
      db.execute(statement);
    }
  }

  static void _applyVersion2(CommonDatabase db) {
    for (final statement in DatabaseSchema.allCreateStatements) {
      db.execute(statement);
    }

    final columns = _getTableColumns(db, 'user_profile');

    if (!columns.contains('diet_type')) {
      db.execute(
          "ALTER TABLE user_profile ADD COLUMN diet_type TEXT NOT NULL DEFAULT 'standard';");
    }
    if (!columns.contains('calorie_floor_type')) {
      db.execute(
          "ALTER TABLE user_profile ADD COLUMN calorie_floor_type TEXT NOT NULL DEFAULT 'standard';");
    }
    if (!columns.contains('lifting_experience')) {
      db.execute(
          "ALTER TABLE user_profile ADD COLUMN lifting_experience TEXT NOT NULL DEFAULT 'beginner';");
    }
    if (!columns.contains('cardio_experience')) {
      db.execute(
          "ALTER TABLE user_profile ADD COLUMN cardio_experience TEXT NOT NULL DEFAULT 'beginner';");
    }
    if (!columns.contains('body_fat_range')) {
      db.execute("ALTER TABLE user_profile ADD COLUMN body_fat_range TEXT;");
    }
    if (!columns.contains('weight_history_max')) {
      db.execute(
          "ALTER TABLE user_profile ADD COLUMN weight_history_max REAL;");
    }
    if (!columns.contains('distribution_mode')) {
      db.execute(
          "ALTER TABLE user_profile ADD COLUMN distribution_mode TEXT NOT NULL DEFAULT 'even';");
    }
    if (!columns.contains('recent_weight_trend')) {
      db.execute(
          "ALTER TABLE user_profile ADD COLUMN recent_weight_trend TEXT NOT NULL DEFAULT 'stable';");
    }
    if (!columns.contains('exercise_frequency')) {
      db.execute(
          "ALTER TABLE user_profile ADD COLUMN exercise_frequency TEXT NOT NULL DEFAULT '1-3';");
    }
    if (!columns.contains('daily_activity')) {
      db.execute(
          "ALTER TABLE user_profile ADD COLUMN daily_activity TEXT NOT NULL DEFAULT 'moderate';");
    }

    final sessionColumns = _getTableColumns(db, 'user_account_session');
    if (!sessionColumns.contains('auth_provider')) {
      db.execute(
          "ALTER TABLE user_account_session ADD COLUMN auth_provider TEXT NOT NULL DEFAULT 'google.com';");
    }
  }

  static void _applyVersion3(CommonDatabase db) {
    for (final statement in DatabaseSchema.allCreateStatements) {
      db.execute(statement);
    }

    // 1. user_profile: add date_of_birth and user_id if missing
    final profileCols = _getTableColumns(db, 'user_profile');
    if (profileCols.isNotEmpty) {
      if (!profileCols.contains('date_of_birth')) {
        db.execute('ALTER TABLE user_profile ADD COLUMN date_of_birth TEXT;');
      }
      if (!profileCols.contains('user_id')) {
        db.execute(
            "ALTER TABLE user_profile ADD COLUMN user_id TEXT NOT NULL DEFAULT 'default_user';");
      }
    }

    // 2. food_logs: add user_id column if missing, and create idx_food_logs_user_date
    final foodLogCols = _getTableColumns(db, 'food_logs');
    if (foodLogCols.isNotEmpty) {
      if (!foodLogCols.contains('user_id')) {
        db.execute(
            "ALTER TABLE food_logs ADD COLUMN user_id TEXT NOT NULL DEFAULT 'default_user';");
      }
      db.execute(
        'CREATE INDEX IF NOT EXISTS idx_food_logs_user_date ON food_logs(user_id, date, logged_at);',
      );
    }

    // 3. Table-rebuild weight_logs with composite UNIQUE(user_id, date)
    final weightCols = _getTableColumns(db, 'weight_logs');
    if (weightCols.isNotEmpty) {
      db.execute('''
        CREATE TABLE weight_logs_v3_temp (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL DEFAULT 'default_user',
          date TEXT NOT NULL,
          scale_weight REAL NOT NULL,
          note TEXT,
          source TEXT NOT NULL DEFAULT 'manual',
          logged_at TEXT NOT NULL,
          UNIQUE(user_id, date)
        );
      ''');

      if (weightCols.contains('user_id')) {
        db.execute('''
          INSERT OR IGNORE INTO weight_logs_v3_temp (id, user_id, date, scale_weight, note, source, logged_at)
          SELECT id, user_id, date, scale_weight, note, source, logged_at FROM weight_logs;
        ''');
      } else {
        db.execute('''
          INSERT OR IGNORE INTO weight_logs_v3_temp (id, user_id, date, scale_weight, note, source, logged_at)
          SELECT id, 'default_user', date, scale_weight, note, source, logged_at FROM weight_logs;
        ''');
      }

      db.execute('DROP TABLE weight_logs;');
      db.execute('ALTER TABLE weight_logs_v3_temp RENAME TO weight_logs;');
      db.execute(
          'CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);');
      db.execute(
          'CREATE INDEX IF NOT EXISTS idx_weight_logs_user_date ON weight_logs(user_id, date);');
    }

    // 4. Table-rebuild day_completions with composite PRIMARY KEY(user_id, date)
    final dayCols = _getTableColumns(db, 'day_completions');
    if (dayCols.isNotEmpty) {
      db.execute('''
        CREATE TABLE day_completions_v3_temp (
          user_id TEXT NOT NULL DEFAULT 'default_user',
          date TEXT NOT NULL,
          is_complete INTEGER NOT NULL,
          updated_at TEXT NOT NULL,
          PRIMARY KEY(user_id, date)
        );
      ''');

      if (dayCols.contains('user_id')) {
        db.execute('''
          INSERT OR IGNORE INTO day_completions_v3_temp (user_id, date, is_complete, updated_at)
          SELECT user_id, date, is_complete, updated_at FROM day_completions;
        ''');
      } else {
        db.execute('''
          INSERT OR IGNORE INTO day_completions_v3_temp (user_id, date, is_complete, updated_at)
          SELECT 'default_user', date, is_complete, updated_at FROM day_completions;
        ''');
      }

      db.execute('DROP TABLE day_completions;');
      db.execute(
          'ALTER TABLE day_completions_v3_temp RENAME TO day_completions;');
      db.execute(
          'CREATE INDEX IF NOT EXISTS idx_day_completions_date ON day_completions(date);');
    }

    // 5. Table-rebuild expenditure_history with composite PRIMARY KEY(user_id, date)
    final expCols = _getTableColumns(db, 'expenditure_history');
    if (expCols.isNotEmpty) {
      db.execute('''
        CREATE TABLE expenditure_history_v3_temp (
          user_id TEXT NOT NULL DEFAULT 'default_user',
          date TEXT NOT NULL,
          expenditure_kcal REAL NOT NULL,
          trend_weight_kg REAL NOT NULL,
          variance REAL NOT NULL,
          confidence REAL NOT NULL,
          PRIMARY KEY(user_id, date)
        );
      ''');

      if (expCols.contains('user_id')) {
        db.execute('''
          INSERT OR IGNORE INTO expenditure_history_v3_temp (user_id, date, expenditure_kcal, trend_weight_kg, variance, confidence)
          SELECT user_id, date, expenditure_kcal, trend_weight_kg, variance, confidence FROM expenditure_history;
        ''');
      } else {
        db.execute('''
          INSERT OR IGNORE INTO expenditure_history_v3_temp (user_id, date, expenditure_kcal, trend_weight_kg, variance, confidence)
          SELECT 'default_user', date, expenditure_kcal, trend_weight_kg, variance, confidence FROM expenditure_history;
        ''');
      }

      db.execute('DROP TABLE expenditure_history;');
      db.execute(
          'ALTER TABLE expenditure_history_v3_temp RENAME TO expenditure_history;');
    }
  }

  static void _applyVersion4(CommonDatabase db) {
    // 1. coaching_check_ins: add user_id column if missing, and create idx_coaching_check_ins_user_date
    final coachingCols = _getTableColumns(db, 'coaching_check_ins');
    if (coachingCols.isNotEmpty) {
      if (!coachingCols.contains('user_id')) {
        db.execute(
            "ALTER TABLE coaching_check_ins ADD COLUMN user_id TEXT NOT NULL DEFAULT 'default_user';");
      }
      db.execute(
        'CREATE INDEX IF NOT EXISTS idx_coaching_check_ins_user_date ON coaching_check_ins(user_id, check_in_date);',
      );
    }

    // 2. Drop redundant single-column indexes superseded by composite (user_id, date) indexes
    db.execute('DROP INDEX IF EXISTS idx_food_logs_date;');
    db.execute('DROP INDEX IF EXISTS idx_weight_logs_date;');
    db.execute('DROP INDEX IF EXISTS idx_day_completions_date;');
    db.execute('DROP INDEX IF EXISTS idx_coaching_check_ins_date;');
  }

  static void _applyVersion5(CommonDatabase db) {
    // 1. Create new Wave 4 tables and composite indices if they do not exist
    db.execute(DatabaseSchema.createBodyMeasurementsTable);
    db.execute(DatabaseSchema.createBodyMeasurementsIndex);
    db.execute(DatabaseSchema.createWeeklyChallengesTable);
    db.execute(DatabaseSchema.createWeeklyChallengesIndex);
    db.execute(DatabaseSchema.createChallengeDailyProgressTable);
    db.execute(DatabaseSchema.createChallengeDailyProgressIndex);
    db.execute(DatabaseSchema.createWaterLogsTable);
    db.execute(DatabaseSchema.createWaterLogsIndex);
    db.execute(DatabaseSchema.createFastingSessionsTable);
    db.execute(DatabaseSchema.createFastingSessionsIndex);

    // 2. Add profile strategy extension columns if missing
    final profileCols = _getTableColumns(db, 'user_profile');
    if (profileCols.isNotEmpty) {
      if (!profileCols.contains('reverse_diet_pacing')) {
        db.execute(
            "ALTER TABLE user_profile ADD COLUMN reverse_diet_pacing TEXT NOT NULL DEFAULT 'none';");
      }
      if (!profileCols.contains('is_in_diet_break')) {
        db.execute(
            'ALTER TABLE user_profile ADD COLUMN is_in_diet_break INTEGER NOT NULL DEFAULT 0;');
      }
      if (!profileCols.contains('daily_water_target_ml')) {
        db.execute(
            'ALTER TABLE user_profile ADD COLUMN daily_water_target_ml INTEGER NOT NULL DEFAULT 2500;');
      }
      if (!profileCols.contains('default_fasting_protocol')) {
        db.execute(
            "ALTER TABLE user_profile ADD COLUMN default_fasting_protocol TEXT NOT NULL DEFAULT 'none';");
      }
      if (!profileCols.contains('peri_workout_timing_enabled')) {
        db.execute(
            'ALTER TABLE user_profile ADD COLUMN peri_workout_timing_enabled INTEGER NOT NULL DEFAULT 0;');
      }
      if (!profileCols.contains('neck_circumference_cm')) {
        db.execute(
            'ALTER TABLE user_profile ADD COLUMN neck_circumference_cm REAL;');
      }
    }

    // 3. Add coaching check-ins audit trail enrichment columns
    final coachingCols = _getTableColumns(db, 'coaching_check_ins');
    if (coachingCols.isNotEmpty) {
      if (!coachingCols.contains('raw_calorie_delta')) {
        db.execute(
            'ALTER TABLE coaching_check_ins ADD COLUMN raw_calorie_delta REAL;');
      }
      if (!coachingCols.contains('damped_calorie_delta')) {
        db.execute(
            'ALTER TABLE coaching_check_ins ADD COLUMN damped_calorie_delta REAL;');
      }
      if (!coachingCols.contains('was_clamped')) {
        db.execute(
            'ALTER TABLE coaching_check_ins ADD COLUMN was_clamped INTEGER NOT NULL DEFAULT 0;');
      }
      if (!coachingCols.contains('silent_recomp_detected')) {
        db.execute(
            'ALTER TABLE coaching_check_ins ADD COLUMN silent_recomp_detected INTEGER NOT NULL DEFAULT 0;');
      }
    }
  }

  static void _applyVersion6(CommonDatabase db) {
    db.execute(DatabaseSchema.createCustomRecipesTable);
    db.execute(DatabaseSchema.createCustomRecipesIndex);
    db.execute(DatabaseSchema.createRecipeIngredientsTable);
    db.execute(DatabaseSchema.createRecipeIngredientsIndex);
    db.execute(DatabaseSchema.createBarcodeCacheTable);
    db.execute(DatabaseSchema.createNutrientDefinitionsTable);
    db.execute(DatabaseSchema.createFoodNutrientsTable);
    db.execute(DatabaseSchema.createFoodNutrientsIndex);

    // Seed the 10 key ICMR-NIN / USDA micronutrient definitions idempotently so
    // fresh in-memory databases and upgraded v5->v6 users have RDAs ready immediately.
    const nutrientSeeds =
        <(int, String, String, String, String, double, double, double?)>[
      (1, 'iron', 'Iron', 'mineral', 'mg', 19.0, 29.0, 45.0),
      (2, 'calcium', 'Calcium', 'mineral', 'mg', 1000.0, 1000.0, 2500.0),
      (3, 'potassium', 'Potassium', 'mineral', 'mg', 3500.0, 3500.0, null),
      (4, 'sodium', 'Sodium', 'mineral', 'mg', 2000.0, 2000.0, 2300.0),
      (5, 'vitamin_c', 'Vitamin C', 'vitamin', 'mg', 80.0, 65.0, 2000.0),
      (6, 'vitamin_d', 'Vitamin D', 'vitamin', 'IU', 600.0, 600.0, 4000.0),
      (7, 'vitamin_b12', 'Vitamin B12', 'vitamin', 'mcg', 2.2, 2.2, null),
      (8, 'magnesium', 'Magnesium', 'mineral', 'mg', 440.0, 370.0, null),
      (9, 'zinc', 'Zinc', 'mineral', 'mg', 17.0, 13.2, 40.0),
      (10, 'folate', 'Folate (B9)', 'vitamin', 'mcg', 300.0, 220.0, 1000.0),
    ];

    final stmt = db.prepare('''
      INSERT OR IGNORE INTO nutrient_definitions (
        id, slug, display_name, category, unit,
        default_rda_male, default_rda_female, upper_tolerable_limit
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    ''');
    try {
      for (final row in nutrientSeeds) {
        stmt.execute([
          row.$1,
          row.$2,
          row.$3,
          row.$4,
          row.$5,
          row.$6,
          row.$7,
          row.$8,
        ]);
      }
    } finally {
      stmt.dispose();
    }
  }

  static void _applyVersion7(CommonDatabase db) {
    db.execute(DatabaseSchema.createRepeatItemsTable);
    db.execute(DatabaseSchema.createRepeatItemsIndex);
    db.execute(DatabaseSchema.createDayNotesTable);
    db.execute(DatabaseSchema.createMicroGoalsTable);

    final recipeCols = _getTableColumns(db, 'custom_recipes');
    if (recipeCols.isNotEmpty && !recipeCols.contains('cooked_weight_g')) {
      db.execute('ALTER TABLE custom_recipes ADD COLUMN cooked_weight_g REAL;');
    }

    // Expand nutrient_definitions from 10 to 36 biomarkers (Vitamins, Minerals, Lipids, Amino Acids)
    const v7Nutrients =
        <(int, String, String, String, String, double, double, double?)>[
      (11, 'vitamin_a', 'Vitamin A', 'vitamin', 'mcg', 1000.0, 840.0, 3000.0),
      (12, 'vitamin_e', 'Vitamin E', 'vitamin', 'mg', 10.0, 10.0, 1000.0),
      (13, 'vitamin_k', 'Vitamin K', 'vitamin', 'mcg', 55.0, 55.0, null),
      (14, 'vitamin_b1', 'Thiamine (B1)', 'vitamin', 'mg', 1.4, 1.4, null),
      (15, 'vitamin_b2', 'Riboflavin (B2)', 'vitamin', 'mg', 2.0, 1.9, null),
      (16, 'vitamin_b3', 'Niacin (B3)', 'vitamin', 'mg', 14.0, 11.0, 35.0),
      (
        17,
        'vitamin_b5',
        'Pantothenic Acid (B5)',
        'vitamin',
        'mg',
        5.0,
        5.0,
        null
      ),
      (18, 'vitamin_b6', 'Vitamin B6', 'vitamin', 'mg', 1.9, 1.9, 100.0),
      (19, 'biotin', 'Biotin (B7)', 'vitamin', 'mcg', 30.0, 30.0, null),
      (20, 'choline', 'Choline', 'vitamin', 'mg', 550.0, 425.0, 3500.0),
      (21, 'phosphorus', 'Phosphorus', 'mineral', 'mg', 1000.0, 1000.0, 4000.0),
      (22, 'copper', 'Copper', 'mineral', 'mg', 1.7, 1.7, 10.0),
      (23, 'manganese', 'Manganese', 'mineral', 'mg', 4.0, 4.0, 11.0),
      (24, 'selenium', 'Selenium', 'mineral', 'mcg', 40.0, 40.0, 400.0),
      (25, 'iodine', 'Iodine', 'mineral', 'mcg', 140.0, 140.0, 1100.0),
      (26, 'chromium', 'Chromium', 'mineral', 'mcg', 50.0, 50.0, null),
      (27, 'omega3_ala', 'Omega-3 (ALA)', 'lipid', 'g', 1.6, 1.1, null),
      (28, 'omega3_epa', 'Omega-3 (EPA)', 'lipid', 'mg', 250.0, 250.0, null),
      (29, 'omega3_dha', 'Omega-3 (DHA)', 'lipid', 'mg', 250.0, 250.0, null),
      (30, 'omega6_la', 'Omega-6 (LA)', 'lipid', 'g', 17.0, 12.0, null),
      (31, 'saturated_fat', 'Saturated Fat', 'lipid', 'g', 22.0, 20.0, 25.0),
      (32, 'cholesterol', 'Cholesterol', 'lipid', 'mg', 300.0, 300.0, 300.0),
      (33, 'leucine', 'Leucine', 'amino', 'g', 2.7, 2.3, null),
      (34, 'isoleucine', 'Isoleucine', 'amino', 'g', 1.4, 1.2, null),
      (35, 'valine', 'Valine', 'amino', 'g', 1.8, 1.5, null),
      (36, 'lysine', 'Lysine', 'amino', 'g', 2.1, 1.8, null),
    ];

    final stmt = db.prepare('''
      INSERT OR IGNORE INTO nutrient_definitions (
        id, slug, display_name, category, unit,
        default_rda_male, default_rda_female, upper_tolerable_limit
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    ''');
    try {
      for (final row in v7Nutrients) {
        stmt.execute([
          row.$1,
          row.$2,
          row.$3,
          row.$4,
          row.$5,
          row.$6,
          row.$7,
          row.$8,
        ]);
      }
    } finally {
      stmt.dispose();
    }
  }

  static Set<String> _getTableColumns(CommonDatabase db, String tableName) {
    try {
      final rows = db.select("PRAGMA table_info('$tableName');");
      return rows.map((r) => (r['name'] as String).toLowerCase()).toSet();
    } on SqliteException catch (e, st) {
      developer.log(
        'Failed to query table_info for "$tableName"',
        name: 'DatabaseMigrations',
        error: e,
        stackTrace: st,
      );
      return <String>{};
    }
  }
}
