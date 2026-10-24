import 'package:sqlite3/common.dart';
import 'database_schema.dart';

/// Database migration engine managing PRAGMA user_version and incremental schema upgrades.
class DatabaseMigrations {
  const DatabaseMigrations._();

  static const int currentVersion = 2;

  /// Applies necessary schema migrations and performance pragmas to the database.
  static void initializeAndMigrate(CommonDatabase db,
      {bool isInMemory = false}) {
    // 1. Enforce SQLite runtime integrity and performance pragmas
    db.execute('PRAGMA foreign_keys = ON;');
    if (!isInMemory) {
      try {
        db.execute('PRAGMA journal_mode = WAL;');
        db.execute('PRAGMA synchronous = NORMAL;');
      } catch (_) {
        // In-memory or restricted sandbox environments may reject WAL mode
      }
    }

    // 2. Read existing user_version
    final versionResult = db.select('PRAGMA user_version;');
    final currentDbVersion = versionResult.first.values.first as int;

    // 3. Incremental migration ladder
    if (currentDbVersion < 1) {
      _applyVersion1(db);
    }

    if (currentDbVersion < 2) {
      _applyVersion2(db);
    }

    // 4. Update user_version to currentVersion
    db.execute('PRAGMA user_version = $currentVersion;');
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
    } catch (_) {
      return <String>{};
    }
  }
}
