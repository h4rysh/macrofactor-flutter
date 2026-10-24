import 'dart:developer' as developer;

import 'package:sqlite3/common.dart';

import 'database_schema.dart';

/// Database migration engine managing PRAGMA user_version and incremental schema upgrades.
class DatabaseMigrations {
  const DatabaseMigrations._();

  static const int currentVersion = 2;
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
  }

  /// Public test-friendly hook for running an isolated migration step.
  static void applyStepForTest(CommonDatabase db, int targetVersion) {
    switch (targetVersion) {
      case 1:
        _runStep(db, 1, _applyVersion1);
      case 2:
        _runStep(db, 2, _applyVersion2);
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

    final sessionColumns = _getTableColumns(db, 'user_account_session');
    if (!sessionColumns.contains('auth_provider')) {
      db.execute(
          "ALTER TABLE user_account_session ADD COLUMN auth_provider TEXT NOT NULL DEFAULT 'google.com';");
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
