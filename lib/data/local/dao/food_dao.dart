import 'package:sique/domain/models/food_models.dart';
import 'package:sqlite3/common.dart';

/// Data Access Object managing foods catalog, portion units, full-text search, and food logs.
class FoodDao {
  FoodDao(this._db);

  final CommonDatabase _db;

  /// Searches foods using SQLite FTS5 with prefix matching, falling back to LIKE.
  List<FoodItem> searchFoods(String query, {int limit = 30}) {
    final sanitized =
        query.replaceAll(RegExp(r'''['"*\(\)\-\+\:]'''), ' ').trim();
    if (sanitized.isEmpty) {
      final stmt = _db.prepare('SELECT * FROM foods LIMIT ?;');
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
      // Fall back to LIKE if FTS expression error
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

  /// Gets a specific food item by its ID with portion units.
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

  /// Inserts a FoodItem into the database and updates FTS index.
  void insertFood(FoodItem food) {
    final stmt = _db.prepare('''
      INSERT INTO foods (
        id, uuid, name, category, region, calories, protein, carbs,
        fat, fiber, icon_svg, source, aliases
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        category = excluded.category,
        region = excluded.region,
        calories = excluded.calories,
        protein = excluded.protein,
        carbs = excluded.carbs,
        fat = excluded.fat,
        fiber = excluded.fiber,
        icon_svg = excluded.icon_svg,
        source = excluded.source,
        aliases = excluded.aliases;
    ''');
    stmt.execute([
      food.id,
      food.uuid,
      food.name,
      food.category,
      food.region,
      food.caloriesPer100g,
      food.proteinPer100g,
      food.carbsPer100g,
      food.fatPer100g,
      food.fiberPer100g,
      food.iconSvg,
      food.source,
      food.aliases,
    ]);
    stmt.dispose();

    try {
      final ftsStmt = _db.prepare('''
        INSERT INTO foods_fts (rowid, name, aliases, category)
        VALUES (?, ?, ?, ?);
      ''');
      ftsStmt.execute([food.id, food.name, food.aliases, food.category]);
      ftsStmt.dispose();
    } catch (_) {}
  }

  /// Inserts a portion unit for a food item.
  void insertPortionUnit(PortionUnit unit) {
    final stmt = _db.prepare('''
      INSERT INTO portion_units (id, food_id, unit_name, gram_weight, is_default)
      VALUES (?, ?, ?, ?, ?);
    ''');
    stmt.execute([
      unit.id,
      unit.foodId,
      unit.unitName,
      unit.gramWeight,
      unit.isDefault ? 1 : 0,
    ]);
    stmt.dispose();
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

    return result.map(_mapFoodLogEntryRow).toList();
  }

  /// Deletes a food log entry by id.
  void deleteFoodLog(int id) {
    final stmt = _db.prepare('DELETE FROM food_logs WHERE id = ?;');
    stmt.execute([id]);
    stmt.dispose();
  }

  /// Retrieves all logged food entries across all dates.
  List<FoodLogEntry> getAllFoodLogs() {
    final stmt = _db.prepare('''
      SELECT * FROM food_logs ORDER BY date DESC, logged_at DESC;
    ''');
    final result = stmt.select();
    stmt.dispose();
    return result.map(_mapFoodLogEntryRow).toList();
  }

  /// Returns total count of indexed foods.
  int getFoodCount() {
    try {
      final stmt = _db.prepare('SELECT COUNT(*) as count FROM foods;');
      final result = stmt.select();
      stmt.dispose();
      return (result.first['count'] as num).toInt();
    } catch (_) {
      return 0;
    }
  }

  /// Returns total logged calories mapped by date string 'YYYY-MM-DD'.
  Map<String, double> getDailyCalorieTotals() {
    final stmt = _db.prepare('''
      SELECT date, SUM(calories) as total_cals
      FROM food_logs
      GROUP BY date;
    ''');
    final result = stmt.select();
    stmt.dispose();
    final map = <String, double>{};
    for (final row in result) {
      map[row['date'] as String] = (row['total_cals'] as num).toDouble();
    }
    return map;
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

  FoodLogEntry _mapFoodLogEntryRow(Row row) {
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
  }
}
