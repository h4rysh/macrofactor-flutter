import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sique/data/local/dao/barcode_dao.dart';
import 'package:sique/data/local/dao/body_measurements_dao.dart';
import 'package:sique/data/local/dao/challenges_dao.dart';
import 'package:sique/data/local/dao/diary_tools_dao.dart';
import 'package:sique/data/local/dao/expenditure_dao.dart';
import 'package:sique/data/local/dao/fasting_dao.dart';
import 'package:sique/data/local/dao/food_dao.dart';
import 'package:sique/data/local/dao/profile_dao.dart';
import 'package:sique/data/local/dao/recipes_dao.dart';
import 'package:sique/data/local/dao/settings_dao.dart';
import 'package:sique/data/local/dao/water_dao.dart';
import 'package:sique/data/local/dao/weight_dao.dart';
import 'package:sique/data/local/dao/workout_dao.dart';
import 'package:sique/data/local/database_migrations.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/scale_weight_entry.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/domain/models/workout_session.dart';
import 'package:sqlite3/sqlite3.dart';

export 'app_database_coaching.dart';
export 'app_database_expenditure.dart';
export 'dao/barcode_dao.dart';
export 'dao/body_measurements_dao.dart';
export 'dao/challenges_dao.dart';
export 'dao/diary_tools_dao.dart';
export 'dao/expenditure_dao.dart';
export 'dao/fasting_dao.dart';
export 'dao/food_dao.dart';
export 'dao/profile_dao.dart';
export 'dao/recipes_dao.dart';
export 'dao/settings_dao.dart';
export 'dao/water_dao.dart';
export 'dao/weight_dao.dart';
export 'dao/workout_dao.dart';
export 'database_migrations.dart';
export 'database_schema.dart';

/// Exception thrown when [AppDatabase.open] fails to initialize or open persistent storage.
class DatabaseOpenException implements Exception {
  const DatabaseOpenException(this.message, [this.cause]);
  final String message;
  final Object? cause;

  @override
  String toString() =>
      'DatabaseOpenException: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Local high-performance SQLite database facade delegating to specialized DAOs.
class AppDatabase {
  AppDatabase(this._db, {this.isInMemory = false, this.dbPath})
      : foodDao = FoodDao(_db, dbPath: dbPath),
        weightDao = WeightDao(_db),
        profileDao = ProfileDao(_db),
        workoutDao = WorkoutDao(_db),
        expenditureDao = ExpenditureDao(_db),
        settingsDao = SettingsDao(_db),
        bodyMeasurementsDao = BodyMeasurementsDao(_db),
        challengesDao = ChallengesDao(_db),
        waterDao = WaterDao(_db),
        fastingDao = FastingDao(_db),
        recipesDao = RecipesDao(_db),
        barcodeDao = BarcodeDao(_db),
        diaryToolsDao = DiaryToolsDao(_db) {
    _wireDaoUserIds();
    DatabaseMigrations.initializeAndMigrate(_db, isInMemory: isInMemory);
    _initializeFtsAndTriggers();
    _initializeIndexes();
    _ensureMultiTenancySupport();
  }

  final Database _db;
  final bool isInMemory;
  final String? dbPath;
  final FoodDao foodDao;
  final WeightDao weightDao;
  final ProfileDao profileDao;
  final WorkoutDao workoutDao;
  final ExpenditureDao expenditureDao;
  final SettingsDao settingsDao;
  final BodyMeasurementsDao bodyMeasurementsDao;
  final ChallengesDao challengesDao;
  final WaterDao waterDao;
  final FastingDao fastingDao;
  final RecipesDao recipesDao;
  final BarcodeDao barcodeDao;
  final DiaryToolsDao diaryToolsDao;

  String _currentUserId = 'default_user';

  /// Active user tenant identifier (ISS-6-03, AUD-12).
  String get currentUserId => _currentUserId;
  set currentUserId(String value) {
    if (value.trim().isNotEmpty) {
      _currentUserId = value.trim();
      foodDao.userId = _currentUserId;
      weightDao.userId = _currentUserId;
      settingsDao.userId = _currentUserId;
      expenditureDao.userId = _currentUserId;
      workoutDao.userId = _currentUserId;
      profileDao.userId = _currentUserId;
      bodyMeasurementsDao.userId = _currentUserId;
      challengesDao.userId = _currentUserId;
      waterDao.userId = _currentUserId;
      fastingDao.userId = _currentUserId;
      recipesDao.userId = _currentUserId;
      barcodeDao.userId = _currentUserId;
      diaryToolsDao.userId = _currentUserId;
    }
  }

  /// Sets active tenant user id for multi-user session isolation.
  void setUserId(String userId) => currentUserId = userId;

  /// Underlying raw sqlite3 database handle for low-level or test operations.
  Database get rawDb => _db;

  void _wireDaoUserIds() {
    foodDao.userIdProvider = () => _currentUserId;
    weightDao.userIdProvider = () => _currentUserId;
    settingsDao.userIdProvider = () => _currentUserId;
    expenditureDao.userIdProvider = () => _currentUserId;
    workoutDao.userIdProvider = () => _currentUserId;
    profileDao.userIdProvider = () => _currentUserId;
    bodyMeasurementsDao.userIdProvider = () => _currentUserId;
    challengesDao.userIdProvider = () => _currentUserId;
    waterDao.userIdProvider = () => _currentUserId;
    fastingDao.userIdProvider = () => _currentUserId;
    recipesDao.userIdProvider = () => _currentUserId;
    barcodeDao.userIdProvider = () => _currentUserId;
    diaryToolsDao.userIdProvider = () => _currentUserId;
  }

  /// Legacy initializer - retained for compatibility.
  void initUserTables() {
    _wireDaoUserIds();
    DatabaseMigrations.initializeAndMigrate(_db, isInMemory: true);
    _initializeFtsAndTriggers();
    _initializeIndexes();
    _ensureMultiTenancySupport();
  }

  /// Configures FTS5 full text search with Porter stemmer and synchronization triggers (ISS-3-02, ISS-8-06).
  void _initializeFtsAndTriggers() {
    try {
      final foodsTableCheck = _db.select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='foods';",
      );
      if (foodsTableCheck.isEmpty) return;

      final ftsCheck = _db.select(
        "SELECT sql FROM sqlite_master WHERE type='table' AND name='foods_fts';",
      );

      final hasFts = ftsCheck.isNotEmpty;
      final ftsSql = hasFts ? (ftsCheck.first['sql'] as String? ?? '') : '';
      final hasPorter = ftsSql.toLowerCase().contains('porter');

      if (!hasFts || !hasPorter) {
        if (hasFts) {
          _db.execute('DROP TABLE IF EXISTS foods_fts;');
        }
        _db.execute('''
          CREATE VIRTUAL TABLE IF NOT EXISTS foods_fts USING fts5(
            name, aliases, category, content='foods', content_rowid='id', tokenize='porter unicode61'
          );
        ''');
        try {
          _db.execute("INSERT INTO foods_fts(foods_fts) VALUES('rebuild');");
        } catch (e, st) {
          developer.log(
            'foods_fts rebuild note',
            name: 'AppDatabase',
            error: e,
            stackTrace: st,
          );
        }
      }

      // Always drop & recreate triggers when FTS table is rebuilt or an older
      // 4-column (`region`) trigger is still registered from a pre-v6 asset DB.
      final triggerCheck = _db.select(
        "SELECT sql FROM sqlite_master WHERE type='trigger' AND name='foods_ai';",
      );
      final triggerSql = triggerCheck.isNotEmpty
          ? (triggerCheck.first['sql'] as String? ?? '')
          : '';
      final triggerStale = triggerSql.contains('region') ||
          !triggerSql.contains('new.aliases') ||
          !hasFts ||
          !hasPorter;

      if (triggerStale) {
        _db.execute('DROP TRIGGER IF EXISTS foods_ai;');
        _db.execute('DROP TRIGGER IF EXISTS foods_ad;');
        _db.execute('DROP TRIGGER IF EXISTS foods_au;');
      }

      // Triggers to automatically synchronize foods_fts on all mutations (ISS-3-02, ISS-8-06)
      _db.execute('''
        CREATE TRIGGER IF NOT EXISTS foods_ai AFTER INSERT ON foods BEGIN
          INSERT INTO foods_fts(rowid, name, aliases, category) VALUES (new.id, new.name, new.aliases, new.category);
        END;
      ''');
      _db.execute('''
        CREATE TRIGGER IF NOT EXISTS foods_ad AFTER DELETE ON foods BEGIN
          INSERT INTO foods_fts(foods_fts, rowid, name, aliases, category) VALUES('delete', old.id, old.name, old.aliases, old.category);
        END;
      ''');
      _db.execute('''
        CREATE TRIGGER IF NOT EXISTS foods_au AFTER UPDATE ON foods BEGIN
          INSERT INTO foods_fts(foods_fts, rowid, name, aliases, category) VALUES('delete', old.id, old.name, old.aliases, old.category);
          INSERT INTO foods_fts(rowid, name, aliases, category) VALUES (new.id, new.name, new.aliases, new.category);
        END;
      ''');
    } catch (e, st) {
      developer.log(
        'FTS5 Porter stemmer triggers initialization note',
        name: 'AppDatabase',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Creates indexes on secondary lookup keys including portion_units(food_id) (ISS-8-07).
  void _initializeIndexes() {
    try {
      _db.execute(
        'CREATE INDEX IF NOT EXISTS idx_portion_units_food_id ON portion_units(food_id);',
      );
      _db.execute(
        'CREATE INDEX IF NOT EXISTS idx_food_logs_user_date ON food_logs(user_id, date, logged_at);',
      );
    } catch (e, st) {
      developer.log(
        'Failed to create indexes in _initializeIndexes',
        name: 'AppDatabase',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Ensures multi-tenancy user_id column and indices exist across user entity tables (ISS-6-03, AUD-12).
  void _ensureMultiTenancySupport() {
    final tables = [
      'food_logs',
      'weight_logs',
      'workout_sessions',
      'expenditure_history',
      'day_completions',
      'coaching_check_ins',
      'user_profile',
    ];

    for (final table in tables) {
      try {
        final tableCheck = _db.select(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$table';",
        );
        if (tableCheck.isEmpty) continue;

        final cols = _getTableColumns(table);
        if (!cols.contains('user_id')) {
          _db.execute(
            "ALTER TABLE $table ADD COLUMN user_id TEXT NOT NULL DEFAULT 'default_user';",
          );
        }
        _db.execute(
          'CREATE INDEX IF NOT EXISTS idx_${table}_user_id ON $table(user_id);',
        );
      } catch (e, st) {
        developer.log(
          'Multi-tenancy setup note for table $table',
          name: 'AppDatabase',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  Set<String> _getTableColumns(String tableName) {
    try {
      final rows = _db.select("PRAGMA table_info('$tableName');");
      return rows.map((r) => (r['name'] as String).toLowerCase()).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  // ==========================================
  // Food & Portion Forwarding Methods
  // ==========================================

  List<FoodItem> searchFoods(String query, {int limit = 30}) =>
      foodDao.searchFoods(query, limit: limit);

  Future<List<FoodItem>> searchFoodsAsync(String query, {int limit = 30}) =>
      foodDao.searchFoodsAsync(query, limit: limit);

  FoodItem? getFoodById(int id) => foodDao.getFoodById(id);

  List<PortionUnit> getPortionUnitsForFood(int foodId) =>
      foodDao.getPortionUnitsForFood(foodId);

  List<PortionUnit> getPortionUnits(int foodId) =>
      foodDao.getPortionUnitsForFood(foodId);

  void insertFood(FoodItem food) => foodDao.insertFood(food);

  void insertPortionUnit(PortionUnit unit) => foodDao.insertPortionUnit(unit);

  int insertFoodLog(FoodLogEntry entry) =>
      foodDao.insertFoodLog(entry, userId: _currentUserId);

  int restoreFoodLog(FoodLogEntry entry) =>
      foodDao.restoreFoodLog(entry, userId: _currentUserId);

  List<FoodLogEntry> getFoodLogsForDate(String date) =>
      foodDao.getFoodLogsForDate(date, userId: _currentUserId);

  void deleteFoodLog(int id) =>
      foodDao.deleteFoodLog(id, userId: _currentUserId);

  List<FoodLogEntry> getAllFoodLogs() =>
      foodDao.getAllFoodLogs(userId: _currentUserId);

  List<FoodItem> getRecentFoods({int limit = 10}) =>
      foodDao.getRecentFoods(limit: limit, userId: _currentUserId);

  Map<String, double> getDailyCalorieTotals() =>
      foodDao.getDailyCalorieTotals(userId: _currentUserId);

  int getFoodCount() => foodDao.getFoodCount();

  // ==========================================
  // Weight Logging Forwarding Methods
  // ==========================================

  void insertWeightLog(
    String date,
    double scaleWeight,
    String? note, {
    String source = 'manual',
  }) =>
      weightDao.insertWeightLog(
        date,
        scaleWeight,
        note,
        source: source,
        userId: _currentUserId,
      );

  void insertScaleWeight(DateTime date, double weightKg, [String? note]) =>
      weightDao.insertScaleWeight(date, weightKg, note, _currentUserId);

  List<ScaleWeightEntry> getScaleWeights(String startDate, String endDate) =>
      weightDao.getScaleWeights(startDate, endDate, userId: _currentUserId);

  List<ScaleWeightEntry> getAllWeightLogs() =>
      weightDao.getAllWeightLogs(userId: _currentUserId);

  ScaleWeightEntry? getWeightLogForDate(String date) =>
      weightDao.getWeightLogForDate(date, userId: _currentUserId);

  List<ScaleWeightEntry> getWeightEntries({int limit = 90}) =>
      weightDao.getWeightEntries(limit: limit, userId: _currentUserId);

  void deleteWeightLogForDate(String date) =>
      weightDao.deleteWeightLogForDate(date, userId: _currentUserId);

  // ==========================================
  // User Profile & Preferences Forwarding Methods
  // ==========================================

  void saveUserProfile(UserProfile profile, {String? userId}) =>
      profileDao.saveUserProfile(profile, userId: userId ?? _currentUserId);

  UserProfile? getUserProfile({String? userId}) =>
      profileDao.getUserProfile(userId: userId ?? _currentUserId);

  String getSetting(String key, String defaultValue) =>
      settingsDao.getSetting(key, defaultValue, userId: _currentUserId);

  void setSetting(String key, String value) =>
      settingsDao.setSetting(key, value, userId: _currentUserId);

  Map<String, String> getAllSettings() =>
      settingsDao.getAllSettings(userId: _currentUserId);

  void saveAccountSession(UserAccount session) =>
      profileDao.saveAccountSession(session);

  UserAccount? getAccountSession() => profileDao.getAccountSession();

  void clearAccountSession() => profileDao.clearAccountSession();

  void clearAllData() => profileDao.clearAllData();

  void clearUserData(String userId) => profileDao.clearUserData(userId);

  // ==========================================
  // Workout Sessions Forwarding Methods
  // ==========================================

  void insertWorkoutSessions(
    List<WorkoutSession> sessions, {
    bool manageTransaction = true,
  }) =>
      workoutDao.insertWorkoutSessions(
        sessions,
        userId: _currentUserId,
        manageTransaction: manageTransaction,
      );

  List<WorkoutSession> getAllWorkoutSessions() =>
      workoutDao.getAllWorkoutSessions(userId: _currentUserId);

  List<WorkoutSession> getWorkoutSessionsInRange(
          DateTime start, DateTime end) =>
      workoutDao.getWorkoutSessionsInRange(start, end, userId: _currentUserId);

  void deleteWorkoutSession(dynamic id) =>
      workoutDao.deleteWorkoutSession(id, userId: _currentUserId);

  /// Closes and disposes the database handle.
  void close() {
    _db.dispose();
  }

  /// Creates an in-memory SQLite database instance with food & user schemas.
  static AppDatabase inMemory() {
    final rawDb = sqlite3.openInMemory();
    rawDb.execute('''
      CREATE TABLE IF NOT EXISTS foods (
        id INTEGER PRIMARY KEY, uuid TEXT NOT NULL, name TEXT NOT NULL, category TEXT NOT NULL,
        region TEXT NOT NULL, calories REAL NOT NULL, protein REAL NOT NULL, carbs REAL NOT NULL,
        fat REAL NOT NULL, fiber REAL NOT NULL, icon_svg TEXT NOT NULL, source TEXT NOT NULL, aliases TEXT,
        is_verified INTEGER NOT NULL DEFAULT 1
      );
      CREATE TABLE IF NOT EXISTS portion_units (
        id INTEGER PRIMARY KEY AUTOINCREMENT, food_id INTEGER NOT NULL, unit_name TEXT NOT NULL,
        gram_weight REAL NOT NULL, is_default INTEGER NOT NULL DEFAULT 0
      );
      CREATE VIRTUAL TABLE IF NOT EXISTS foods_fts USING fts5(
        name, aliases, category, content='foods', content_rowid='id', tokenize='porter unicode61'
      );
    ''');
    final appDb = AppDatabase(rawDb, isInMemory: true);
    return appDb;
  }

  /// Opens the application database, bundling foods_master.db if first launch.
  /// Explicitly throws [DatabaseOpenException] on failure so callers know if open failed
  /// rather than silently falling back to an in-memory database.
  static Future<AppDatabase> open({String? customPath}) async {
    try {
      final String dbPath;
      if (customPath != null) {
        dbPath = customPath;
      } else {
        final docsDir = await getApplicationDocumentsDirectory();
        dbPath = p.join(docsDir.path, 'sique_local.db');
      }
      final file = File(dbPath);

      final existed = await file.exists();
      if (!existed) {
        final parentDir = file.parent;
        if (!await parentDir.exists()) {
          await parentDir.create(recursive: true);
        }

        final data = await rootBundle.load('assets/database/foods_master.db');
        final bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await file.writeAsBytes(bytes, flush: false);
      }

      final rawDb = sqlite3.open(dbPath);
      final appDb = AppDatabase(rawDb, dbPath: dbPath);
      if (existed) {
        await _syncBundledMasterCatalogIfStale(rawDb, file.parent.path);
      }
      return appDb;
    } catch (e, st) {
      developer.log(
        'AppDatabase.open failed to open persistent SQLite database; throwing explicitly',
        name: 'AppDatabase',
        error: e,
        stackTrace: st,
      );
      throw DatabaseOpenException('Failed to open database: $e', e);
    }
  }

  /// Incrementally merges newly bundled foods, portion units, sparse
  /// micronutrients, and retail barcodes from `assets/database/foods_master.db`
  /// when upgrading an existing persistent database from an older app release.
  static Future<void> _syncBundledMasterCatalogIfStale(
    Database db,
    String parentDirPath,
  ) async {
    File? tempAssetFile;
    var attached = false;
    try {
      final foodCount =
          (db.select('SELECT COUNT(*) AS cnt FROM foods;').first['cnt'] as num)
              .toInt();
      final nutrientFactCount = (db
              .select('SELECT COUNT(*) AS cnt FROM food_nutrients;')
              .first['cnt'] as num)
          .toInt();
      final barcodeCount = (db
              .select('SELECT COUNT(*) AS cnt FROM barcode_cache;')
              .first['cnt'] as num)
          .toInt();

      if (foodCount >= 2400 && nutrientFactCount > 0 && barcodeCount >= 20) {
        return;
      }

      final tempPath = p.join(parentDirPath, 'sique_master_sync.tmp.db');
      tempAssetFile = File(tempPath);
      final data = await rootBundle.load('assets/database/foods_master.db');
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await tempAssetFile.writeAsBytes(bytes, flush: true);

      final escaped = tempPath.replaceAll("'", "''");
      db.execute("ATTACH DATABASE '$escaped' AS master_cat;");
      attached = true;

      db.execute('BEGIN TRANSACTION;');
      try {
        db.execute(
          'INSERT OR IGNORE INTO foods SELECT * FROM master_cat.foods;',
        );
        db.execute(
          'INSERT OR IGNORE INTO portion_units SELECT * FROM master_cat.portion_units;',
        );
        db.execute(
          'INSERT OR IGNORE INTO nutrient_definitions SELECT * FROM master_cat.nutrient_definitions;',
        );
        db.execute(
          'INSERT OR IGNORE INTO food_nutrients SELECT * FROM master_cat.food_nutrients;',
        );
        db.execute(
          'INSERT OR IGNORE INTO barcode_cache SELECT * FROM master_cat.barcode_cache;',
        );
        db.execute("INSERT INTO foods_fts(foods_fts) VALUES('rebuild');");
        db.execute('COMMIT;');
      } catch (_) {
        try {
          db.execute('ROLLBACK;');
        } catch (_) {}
        rethrow;
      }
    } catch (e, st) {
      developer.log(
        'Master catalog upgrade sync skipped/failed',
        name: 'AppDatabase',
        error: e,
        stackTrace: st,
      );
    } finally {
      if (attached) {
        try {
          db.execute('DETACH DATABASE master_cat;');
        } catch (_) {}
      }
      if (tempAssetFile != null && await tempAssetFile.exists()) {
        try {
          await tempAssetFile.delete();
        } catch (_) {}
      }
    }
  }
}
