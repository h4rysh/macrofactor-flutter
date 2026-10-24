import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sique/data/local/dao/expenditure_dao.dart';
import 'package:sique/data/local/dao/food_dao.dart';
import 'package:sique/data/local/dao/profile_dao.dart';
import 'package:sique/data/local/dao/settings_dao.dart';
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
export 'dao/expenditure_dao.dart';
export 'dao/food_dao.dart';
export 'dao/profile_dao.dart';
export 'dao/settings_dao.dart';
export 'dao/weight_dao.dart';
export 'dao/workout_dao.dart';
export 'database_migrations.dart';
export 'database_schema.dart';

/// Local high-performance SQLite database facade delegating to specialized DAOs.
class AppDatabase {
  AppDatabase(this._db, {bool isInMemory = false})
      : foodDao = FoodDao(_db),
        weightDao = WeightDao(_db),
        profileDao = ProfileDao(_db),
        workoutDao = WorkoutDao(_db),
        expenditureDao = ExpenditureDao(_db),
        settingsDao = SettingsDao(_db) {
    DatabaseMigrations.initializeAndMigrate(_db, isInMemory: isInMemory);
  }

  final Database _db;
  final FoodDao foodDao;
  final WeightDao weightDao;
  final ProfileDao profileDao;
  final WorkoutDao workoutDao;
  final ExpenditureDao expenditureDao;
  final SettingsDao settingsDao;

  /// Underlying raw sqlite3 database handle for low-level or test operations.
  Database get rawDb => _db;

  /// Legacy initializer - retained for compatibility.
  void initUserTables() {
    DatabaseMigrations.initializeAndMigrate(_db, isInMemory: true);
  }

  // ==========================================
  // Food & Portion Forwarding Methods
  // ==========================================

  List<FoodItem> searchFoods(String query, {int limit = 30}) =>
      foodDao.searchFoods(query, limit: limit);

  FoodItem? getFoodById(int id) => foodDao.getFoodById(id);

  List<PortionUnit> getPortionUnitsForFood(int foodId) =>
      foodDao.getPortionUnitsForFood(foodId);

  List<PortionUnit> getPortionUnits(int foodId) =>
      foodDao.getPortionUnitsForFood(foodId);

  void insertFood(FoodItem food) => foodDao.insertFood(food);

  void insertPortionUnit(PortionUnit unit) => foodDao.insertPortionUnit(unit);

  int insertFoodLog(FoodLogEntry entry) => foodDao.insertFoodLog(entry);

  List<FoodLogEntry> getFoodLogsForDate(String date) =>
      foodDao.getFoodLogsForDate(date);

  void deleteFoodLog(int id) => foodDao.deleteFoodLog(id);

  List<FoodLogEntry> getAllFoodLogs() => foodDao.getAllFoodLogs();

  Map<String, double> getDailyCalorieTotals() =>
      foodDao.getDailyCalorieTotals();

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
      weightDao.insertWeightLog(date, scaleWeight, note, source: source);

  void insertScaleWeight(DateTime date, double weightKg, [String? note]) =>
      weightDao.insertScaleWeight(date, weightKg, note);

  List<ScaleWeightEntry> getScaleWeights(String startDate, String endDate) =>
      weightDao.getScaleWeights(startDate, endDate);

  List<ScaleWeightEntry> getAllWeightLogs() => weightDao.getAllWeightLogs();

  ScaleWeightEntry? getWeightLogForDate(String date) =>
      weightDao.getWeightLogForDate(date);

  List<ScaleWeightEntry> getWeightEntries({int limit = 90}) =>
      weightDao.getWeightEntries(limit: limit);

  void deleteWeightLogForDate(String date) =>
      weightDao.deleteWeightLogForDate(date);

  // ==========================================
  // User Profile & Preferences Forwarding Methods
  // ==========================================

  void saveUserProfile(UserProfile profile) =>
      profileDao.saveUserProfile(profile);

  UserProfile? getUserProfile() => profileDao.getUserProfile();

  String getSetting(String key, String defaultValue) =>
      settingsDao.getSetting(key, defaultValue);

  void setSetting(String key, String value) =>
      settingsDao.setSetting(key, value);

  Map<String, String> getAllSettings() => settingsDao.getAllSettings();

  void saveAccountSession(UserAccount session) =>
      profileDao.saveAccountSession(session);

  UserAccount? getAccountSession() => profileDao.getAccountSession();

  void clearAccountSession() => profileDao.clearAccountSession();

  void clearAllData() => profileDao.clearAllData();

  // ==========================================
  // Workout Sessions Forwarding Methods
  // ==========================================

  void insertWorkoutSessions(List<WorkoutSession> sessions) =>
      workoutDao.insertWorkoutSessions(sessions);

  List<WorkoutSession> getAllWorkoutSessions() =>
      workoutDao.getAllWorkoutSessions();

  List<WorkoutSession> getWorkoutSessionsInRange(
          DateTime start, DateTime end) =>
      workoutDao.getWorkoutSessionsInRange(start, end);

  void deleteWorkoutSession(dynamic id) => workoutDao.deleteWorkoutSession(id);

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
        fat REAL NOT NULL, fiber REAL NOT NULL, icon_svg TEXT NOT NULL, source TEXT NOT NULL, aliases TEXT
      );
      CREATE TABLE IF NOT EXISTS portion_units (
        id INTEGER PRIMARY KEY AUTOINCREMENT, food_id INTEGER NOT NULL, unit_name TEXT NOT NULL,
        gram_weight REAL NOT NULL, is_default INTEGER NOT NULL DEFAULT 0
      );
      CREATE VIRTUAL TABLE IF NOT EXISTS foods_fts USING fts5(
        name, aliases, category, content='foods', content_rowid='id'
      );
    ''');
    final appDb = AppDatabase(rawDb, isInMemory: true);
    return appDb;
  }

  /// Opens the application database, bundling foods_master.db if first launch.
  static Future<AppDatabase> open() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'sique_local.db');
    final file = File(dbPath);

    if (!await file.exists()) {
      // Check legacy path first for seamless user data retention
      final legacyPath = p.join(docsDir.path, 'legacy_local.db');
      final legacyFile = File(legacyPath);
      if (await legacyFile.exists()) {
        await legacyFile.copy(dbPath);
      } else {
        final data = await rootBundle.load('assets/database/foods_master.db');
        final bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await file.writeAsBytes(bytes, flush: true);
      }
    }

    final rawDb = sqlite3.open(dbPath);
    final appDb = AppDatabase(rawDb);
    return appDb;
  }
}
