import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:macro_factor_app/domain/algorithms/weight_trend_v2.dart';
import 'package:macro_factor_app/domain/models/food_models.dart';
import 'package:macro_factor_app/domain/models/user_profile.dart';

/// Local high-performance SQLite database for MacroFactor clean-room engine.
class AppDatabase {
  AppDatabase(this._db);

  final Database _db;

  /// Initializes user-specific logging tables if they don't already exist.
  void initUserTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS food_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        food_id INTEGER NOT NULL,
        food_name TEXT NOT NULL,
        serving_quantity REAL NOT NULL,
        unit_name TEXT NOT NULL,
        gram_weight REAL NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        fiber REAL NOT NULL,
        oil_modifier TEXT NOT NULL,
        logged_at TEXT NOT NULL,
        icon_svg TEXT NOT NULL
      );

      CREATE INDEX IF NOT EXISTS idx_food_logs_date ON food_logs(date);

      CREATE TABLE IF NOT EXISTS weight_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        scale_weight REAL NOT NULL,
        note TEXT,
        logged_at TEXT NOT NULL
      );

      CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);

      CREATE TABLE IF NOT EXISTS user_profile (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        current_weight REAL NOT NULL,
        target_weight REAL NOT NULL,
        height_cm REAL NOT NULL,
        age INTEGER NOT NULL,
        is_male INTEGER NOT NULL,
        goal_type TEXT NOT NULL,
        program_mode TEXT NOT NULL,
        weekly_rate REAL NOT NULL,
        protein_preference TEXT NOT NULL,
        calorie_floor REAL NOT NULL,
        baseline_expenditure REAL NOT NULL
      );

      CREATE TABLE IF NOT EXISTS expenditure_history (
        date TEXT PRIMARY KEY,
        expenditure_kcal REAL NOT NULL,
        trend_weight_kg REAL NOT NULL,
        variance REAL NOT NULL,
        confidence REAL NOT NULL
      );
    ''');
  }

  /// Searches the pre-indexed Indian & international food database using FTS5 with prefix matching.
  List<FoodItem> searchFoods(String query, {int limit = 30}) {
    final sanitized =
        query.replaceAll(RegExp(r'''['"*\(\)\-\+\:]'''), ' ').trim();
    if (sanitized.isEmpty) {
      final stmt = _db.prepare('''
        SELECT * FROM foods LIMIT ?;
      ''');
      final result = stmt.select([limit]);
      stmt.dispose();
      return result.map(_mapFoodRow).toList();
    }

    try {
      final ftsQuery = '$sanitized*';
      final stmt = _db.prepare('''
        SELECT f.* FROM foods f
        JOIN foods_fts fts ON f.id = fts.rowid
        WHERE foods_fts MATCH ?
        LIMIT ?;
      ''');
      final result = stmt.select([ftsQuery, limit]);
      stmt.dispose();

      if (result.isNotEmpty) {
        return result.map(_mapFoodRow).toList();
      }
    } catch (_) {
      // Fallback to LIKE if FTS expression error
    }

    final likePattern = '%$sanitized%';
    final fallbackStmt = _db.prepare('''
      SELECT * FROM foods
      WHERE name LIKE ? OR aliases LIKE ? OR category LIKE ?
      LIMIT ?;
    ''');
    final fallbackResult =
        fallbackStmt.select([likePattern, likePattern, likePattern, limit]);
    fallbackStmt.dispose();
    return fallbackResult.map(_mapFoodRow).toList();
  }

  /// Gets a specific food item by its ID, with its full suite of portion units.
  FoodItem? getFoodById(int id) {
    final stmt = _db.prepare('SELECT * FROM foods WHERE id = ? LIMIT 1;');
    final result = stmt.select([id]);
    stmt.dispose();
    if (result.isEmpty) return null;
    return _mapFoodRow(result.first);
  }

  /// Fetches portion units for a given food.
  List<PortionUnit> getPortionUnitsForFood(int foodId) {
    final stmt = _db.prepare('''
      SELECT * FROM portion_units WHERE food_id = ? ORDER BY is_default DESC, id ASC;
    ''');
    final result = stmt.select([foodId]);
    stmt.dispose();
    return result.map((row) {
      return PortionUnit(
        id: row['id'] as int,
        foodId: row['food_id'] as int,
        unitName: row['unit_name'] as String,
        gramWeight: (row['gram_weight'] as num).toDouble(),
        isDefault: (row['is_default'] as int) == 1,
      );
    }).toList();
  }

  FoodItem _mapFoodRow(Row row) {
    final foodId = row['id'] as int;
    final portionUnits = getPortionUnitsForFood(foodId);

    return FoodItem(
      id: foodId,
      uuid: row['uuid'] as String,
      name: row['name'] as String,
      category: row['category'] as String,
      region: row['region'] as String,
      caloriesPer100g: (row['calories'] as num).toDouble(),
      proteinPer100g: (row['protein'] as num).toDouble(),
      carbsPer100g: (row['carbs'] as num).toDouble(),
      fatPer100g: (row['fat'] as num).toDouble(),
      fiberPer100g: (row['fiber'] as num).toDouble(),
      iconSvg: row['icon_svg'] as String,
      source: row['source'] as String,
      aliases: row['aliases'] as String,
      portionUnits: portionUnits,
    );
  }

  /// Logs a food entry.
  int insertFoodLog(FoodLogEntry entry) {
    final stmt = _db.prepare('''
      INSERT INTO food_logs (
        date, meal_type, food_id, food_name, serving_quantity,
        unit_name, gram_weight, calories, protein, carbs,
        fat, fiber, oil_modifier, logged_at, icon_svg
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''');

    stmt.execute([
      entry.date,
      entry.mealType.name,
      entry.foodId,
      entry.foodName,
      entry.servingQuantity,
      entry.unitName,
      entry.gramWeight,
      entry.calories,
      entry.protein,
      entry.carbs,
      entry.fat,
      entry.fiber,
      entry.oilModifier.name,
      entry.loggedAt.toIso8601String(),
      entry.iconSvg,
    ]);
    stmt.dispose();

    return _db.lastInsertRowId;
  }

  /// Retrieves all logged food items for a date (YYYY-MM-DD).
  List<FoodLogEntry> getFoodLogsForDate(String date) {
    final stmt = _db.prepare('''
      SELECT * FROM food_logs WHERE date = ? ORDER BY logged_at ASC, id ASC;
    ''');
    final result = stmt.select([date]);
    stmt.dispose();

    return result.map((row) {
      return FoodLogEntry(
        id: row['id'] as int,
        date: row['date'] as String,
        mealType: MealType.values.firstWhere(
          (m) => m.name == row['meal_type'],
          orElse: () => MealType.lunch,
        ),
        foodId: row['food_id'] as int,
        foodName: row['food_name'] as String,
        servingQuantity: (row['serving_quantity'] as num).toDouble(),
        unitName: row['unit_name'] as String,
        gramWeight: (row['gram_weight'] as num).toDouble(),
        calories: (row['calories'] as num).toDouble(),
        protein: (row['protein'] as num).toDouble(),
        carbs: (row['carbs'] as num).toDouble(),
        fat: (row['fat'] as num).toDouble(),
        fiber: (row['fiber'] as num).toDouble(),
        oilModifier: OilModifier.values.firstWhere(
          (o) => o.name == row['oil_modifier'],
          orElse: () => OilModifier.standard,
        ),
        loggedAt: DateTime.parse(row['logged_at'] as String),
        iconSvg: row['icon_svg'] as String,
      );
    }).toList();
  }

  /// Deletes a food log entry by id.
  void deleteFoodLog(int id) {
    final stmt = _db.prepare('DELETE FROM food_logs WHERE id = ?;');
    stmt.execute([id]);
    stmt.dispose();
  }

  /// Logs or updates scale weight for a given date.
  void insertWeightLog(String date, double scaleWeight, String? note) {
    final stmt = _db.prepare('''
      INSERT INTO weight_logs (date, scale_weight, note, logged_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(date) DO UPDATE SET
        scale_weight = excluded.scale_weight,
        note = excluded.note,
        logged_at = excluded.logged_at;
    ''');
    stmt.execute([date, scaleWeight, note, DateTime.now().toIso8601String()]);
    stmt.dispose();
  }

  /// Retrieves all weight logs chronologically.
  List<ScaleWeightEntry> getAllWeightLogs() {
    final stmt = _db.prepare('''
      SELECT date, scale_weight, note FROM weight_logs ORDER BY date ASC;
    ''');
    final result = stmt.select();
    stmt.dispose();

    return result.map((row) {
      return ScaleWeightEntry(
        date: DateTime.parse(row['date'] as String),
        weightKg: (row['scale_weight'] as num).toDouble(),
        note: row['note'] as String?,
      );
    }).toList();
  }

  /// Gets scale weight log for a specific date.
  ScaleWeightEntry? getWeightLogForDate(String date) {
    final stmt = _db.prepare('''
      SELECT date, scale_weight, note FROM weight_logs WHERE date = ? LIMIT 1;
    ''');
    final result = stmt.select([date]);
    stmt.dispose();
    if (result.isEmpty) return null;
    final row = result.first;
    return ScaleWeightEntry(
      date: DateTime.parse(row['date'] as String),
      weightKg: (row['scale_weight'] as num).toDouble(),
      note: row['note'] as String?,
    );
  }

  /// Deletes weight log by id or date.
  void deleteWeightLogForDate(String date) {
    final stmt = _db.prepare('DELETE FROM weight_logs WHERE date = ?;');
    stmt.execute([date]);
    stmt.dispose();
  }

  /// Saves user profile and coaching settings.
  void saveUserProfile(UserProfile profile) {
    final stmt = _db.prepare('''
      INSERT INTO user_profile (
        id, name, current_weight, target_weight, height_cm, age,
        is_male, goal_type, program_mode, weekly_rate,
        protein_preference, calorie_floor, baseline_expenditure
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        current_weight = excluded.current_weight,
        target_weight = excluded.target_weight,
        height_cm = excluded.height_cm,
        age = excluded.age,
        is_male = excluded.is_male,
        goal_type = excluded.goal_type,
        program_mode = excluded.program_mode,
        weekly_rate = excluded.weekly_rate,
        protein_preference = excluded.protein_preference,
        calorie_floor = excluded.calorie_floor,
        baseline_expenditure = excluded.baseline_expenditure;
    ''');

    stmt.execute([
      profile.id,
      profile.name,
      profile.currentWeightKg,
      profile.targetWeightKg,
      profile.heightCm,
      profile.age,
      profile.isMale ? 1 : 0,
      profile.goalType.name,
      profile.programMode.name,
      profile.weeklyRateOfChangePct,
      profile.proteinPreference.name,
      profile.calorieFloor,
      profile.baselineExpenditureKcal,
    ]);
    stmt.dispose();
  }

  /// Retrieves user profile or default if none saved.
  UserProfile? getUserProfile() {
    final stmt = _db.prepare('SELECT * FROM user_profile LIMIT 1;');
    final result = stmt.select();
    stmt.dispose();
    if (result.isEmpty) return null;

    final row = result.first;
    return UserProfile(
      id: row['id'] as String,
      name: row['name'] as String,
      currentWeightKg: (row['current_weight'] as num).toDouble(),
      targetWeightKg: (row['target_weight'] as num).toDouble(),
      heightCm: (row['height_cm'] as num).toDouble(),
      age: row['age'] as int,
      isMale: (row['is_male'] as int) == 1,
      goalType: GoalType.values.firstWhere((g) => g.name == row['goal_type']),
      programMode:
          ProgramMode.values.firstWhere((p) => p.name == row['program_mode']),
      weeklyRateOfChangePct: (row['weekly_rate'] as num).toDouble(),
      proteinPreference: ProteinPreference.values
          .firstWhere((p) => p.name == row['protein_preference']),
      calorieFloor: (row['calorie_floor'] as num).toDouble(),
      baselineExpenditureKcal: (row['baseline_expenditure'] as num).toDouble(),
    );
  }

  /// Closes and disposes the database handle.
  void close() {
    _db.dispose();
  }

  /// Creates an in-memory SQLite database instance with food & user schemas for fast, isolated testing.
  static AppDatabase inMemory() {
    final rawDb = sqlite3.openInMemory();
    final appDb = AppDatabase(rawDb);
    rawDb.execute('''
      CREATE TABLE IF NOT EXISTS foods (
        id INTEGER PRIMARY KEY,
        uuid TEXT NOT NULL,
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
        aliases TEXT
      );
      CREATE TABLE IF NOT EXISTS portion_units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        food_id INTEGER NOT NULL,
        unit_name TEXT NOT NULL,
        gram_weight REAL NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
      );
      CREATE VIRTUAL TABLE IF NOT EXISTS foods_fts USING fts5(
        name,
        aliases,
        category,
        content='foods',
        content_rowid='id'
      );
    ''');
    appDb.initUserTables();
    return appDb;
  }

  /// Opens the application database, bundling foods_master.db if first launch.
  static Future<AppDatabase> open() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'macrofactor_local.db');
    final file = File(dbPath);

    if (!await file.exists()) {
      // Copy pre-compiled foods_master.db asset to documents folder
      final data = await rootBundle.load('assets/database/foods_master.db');
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await file.writeAsBytes(bytes, flush: true);
    }

    final rawDb = sqlite3.open(dbPath);
    final appDb = AppDatabase(rawDb);
    appDb.initUserTables();
    return appDb;
  }
}
