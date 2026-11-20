import 'dart:developer' as developer;

import 'package:sqlite3/common.dart';

import 'database_schema.dart';

/// Database migration engine managing PRAGMA user_version and incremental schema upgrades.
class DatabaseMigrations {
  const DatabaseMigrations._();

  static const int currentVersion = 3;
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
