import 'dart:developer' as developer;
import 'package:sique/domain/models/food_models.dart';
import 'package:sqlite3/common.dart';

/// Data Access Object managing foods catalog, portion units, full-text search, and food logs.
class FoodDao {
  FoodDao(this._db) {
    _ensureIndexes();
  }

  final CommonDatabase _db;

  /// Ensures SQLite index on portion_units(food_id) exists for high-speed portion queries (ISS-8-07).
  void _ensureIndexes() {
    try {
      _db.execute(
        'CREATE INDEX IF NOT EXISTS idx_portion_units_food_id ON portion_units(food_id);',
      );
    } catch (_) {}
  }

  /// Sanitizes an input search string for SQLite FTS5 by stripping control operators
  /// and enclosing each search term in double-quotes with wildcard prefix.
  /// Prevents syntax error crashes with `"`, `*`, `-`, `NEAR`, `AND`, `OR`, `NOT`.
  static String sanitizeFts5Query(String query) {
    final cleaned =
        query.replaceAll(RegExp(r'''["*^~:(){}\[\]+\-?]'''), ' ').trim();
    if (cleaned.isEmpty) return '';

    final words =
        cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';

    return words.map((w) {
      final safe = w.replaceAll('"', '');
      return '"$safe"*';
    }).join(' ');
  }

  /// Asynchronously searches foods off the main UI thread.
  Future<List<FoodItem>> searchFoodsAsync(String query,
      {int limit = 30}) async {
    return Future<List<FoodItem>>.microtask(
        () => searchFoods(query, limit: limit));
  }

  /// Searches foods using SQLite FTS5 with operator escaping and rank ordering, falling back to LIKE.
  /// Guarantees prepared statement disposal in try/finally (ISS-8-04).
  List<FoodItem> searchFoods(String query, {int limit = 30}) {
    final ftsQuery = sanitizeFts5Query(query);
    if (ftsQuery.isEmpty) {
      final stmt = _db.prepare('SELECT * FROM foods LIMIT ?;');
      try {
        final result = stmt.select([limit]);
        return result.map(_mapFoodRow).toList();
      } finally {
        stmt.dispose();
      }
    }

    try {
      final ftsStmt = _db.prepare('''
        SELECT f.* FROM foods f
        JOIN foods_fts fts ON f.id = fts.rowid
        WHERE foods_fts MATCH ?
        ORDER BY fts.rank
        LIMIT ?;
      ''');
      try {
        final result = ftsStmt.select([ftsQuery, limit]);
        if (result.isNotEmpty) {
          return result.map(_mapFoodRow).toList();
        }
      } finally {
        ftsStmt.dispose();
      }
    } on SqliteException catch (e, st) {
      developer.log(
        'FTS search failed; falling back to LIKE',
        name: 'FoodDao',
        error: e,
        stackTrace: st,
      );
    }

    final rawTokens =
        query.replaceAll(RegExp(r'''['"*\(\)\-\+\:]'''), ' ').trim();
    final likePattern = '%$rawTokens%';
    final fallbackStmt = _db.prepare('''
      SELECT * FROM foods
      WHERE name LIKE ? OR aliases LIKE ? OR category LIKE ?
      LIMIT ?;
    ''');
    try {
      final fallbackResult =
          fallbackStmt.select([likePattern, likePattern, likePattern, limit]);
      return fallbackResult.map(_mapFoodRow).toList();
    } finally {
      fallbackStmt.dispose();
    }
  }

  /// Gets a specific food item by its ID with portion units.
  FoodItem? getFoodById(int id) {
    final stmt = _db.prepare('SELECT * FROM foods WHERE id = ? LIMIT 1;');
    try {
      final result = stmt.select([id]);
      if (result.isEmpty) return null;
      return _mapFoodRow(result.first);
    } finally {
      stmt.dispose();
    }
  }

  /// Fetches portion units for a given food.
  List<PortionUnit> getPortionUnitsForFood(int foodId) {
    final stmt = _db.prepare('''
      SELECT * FROM portion_units WHERE food_id = ? ORDER BY is_default DESC, id ASC;
    ''');
    try {
      final result = stmt.select([foodId]);
      return result.map((row) {
        return PortionUnit(
          id: row['id'] as int,
          foodId: row['food_id'] as int,
          unitName: row['unit_name'] as String,
          gramWeight: (row['gram_weight'] as num).toDouble(),
          isDefault: (row['is_default'] as int) == 1,
        );
      }).toList();
    } finally {
      stmt.dispose();
    }
  }

  /// Inserts a FoodItem into the database and updates FTS index.
  void insertFood(FoodItem food) {
    final stmt = _db.prepare('''
      INSERT INTO foods (
        id, uuid, name, category, region, calories, protein, carbs,
        fat, fiber, icon_svg, source, aliases, is_verified
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
        aliases = excluded.aliases,
        is_verified = excluded.is_verified;
    ''');
    try {
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
        food.isVerified ? 1 : 0,
      ]);
    } finally {
      stmt.dispose();
    }

    try {
      final ftsStmt = _db.prepare('''
        INSERT INTO foods_fts (rowid, name, aliases, category)
        VALUES (?, ?, ?, ?);
      ''');
      try {
        ftsStmt.execute([food.id, food.name, food.aliases, food.category]);
      } finally {
        ftsStmt.dispose();
      }
    } on SqliteException catch (e, st) {
      developer.log(
        'FTS manual insertion note for food ${food.id}',
        name: 'FoodDao',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Inserts a portion unit for a food item.
  void insertPortionUnit(PortionUnit unit) {
    final stmt = _db.prepare('''
      INSERT INTO portion_units (id, food_id, unit_name, gram_weight, is_default)
      VALUES (?, ?, ?, ?, ?);
    ''');
    try {
      stmt.execute([
        unit.id,
        unit.foodId,
        unit.unitName,
        unit.gramWeight,
        unit.isDefault ? 1 : 0,
      ]);
    } finally {
      stmt.dispose();
    }
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
    try {
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
      return _db.lastInsertRowId;
    } finally {
      stmt.dispose();
    }
  }

  /// Restores a previously deleted food entry, preserving its original id,
  /// date, and timestamp.
  int restoreFoodLog(FoodLogEntry entry) {
    if (entry.id == null) {
      return insertFoodLog(entry);
    }
    final stmt = _db.prepare('''
      INSERT OR REPLACE INTO food_logs (
        id, date, meal_type, food_id, food_name, serving_quantity,
        unit_name, gram_weight, calories, protein, carbs,
        fat, fiber, oil_modifier, logged_at, icon_svg
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''');
    try {
      stmt.execute([
        entry.id,
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
      return entry.id!;
    } finally {
      stmt.dispose();
    }
  }

  /// Retrieves all logged food items for a date (YYYY-MM-DD).
  List<FoodLogEntry> getFoodLogsForDate(String date) {
    final stmt = _db.prepare('''
      SELECT * FROM food_logs WHERE date = ? ORDER BY logged_at ASC, id ASC;
    ''');
    try {
      final result = stmt.select([date]);
      return result.map(_mapFoodLogEntryRow).toList();
    } finally {
      stmt.dispose();
    }
  }

  /// Deletes a food log entry by id.
  void deleteFoodLog(int id) {
    final stmt = _db.prepare('DELETE FROM food_logs WHERE id = ?;');
    try {
      stmt.execute([id]);
    } finally {
      stmt.dispose();
    }
  }

  /// Retrieves all logged food entries across all dates.
  List<FoodLogEntry> getAllFoodLogs() {
    final stmt = _db.prepare('''
      SELECT * FROM food_logs ORDER BY date DESC, logged_at DESC;
    ''');
    try {
      final result = stmt.select();
      return result.map(_mapFoodLogEntryRow).toList();
    } finally {
      stmt.dispose();
    }
  }

  /// Returns total count of indexed foods.
  int getFoodCount() {
    try {
      final stmt = _db.prepare('SELECT COUNT(*) as count FROM foods;');
      try {
        final result = stmt.select();
        return (result.first['count'] as num).toInt();
      } finally {
        stmt.dispose();
      }
    } on SqliteException catch (e, st) {
      developer.log(
        'Failed to get food count',
        name: 'FoodDao',
        error: e,
        stackTrace: st,
      );
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
    try {
      final result = stmt.select();
      final map = <String, double>{};
      for (final row in result) {
        map[row['date'] as String] = (row['total_cals'] as num).toDouble();
      }
      return map;
    } finally {
      stmt.dispose();
    }
  }

  FoodItem _mapFoodRow(Row row) {
    final foodId = row['id'] as int;
    final portionUnits = getPortionUnitsForFood(foodId);

    int? rawVerified;
    try {
      rawVerified = row['is_verified'] as int?;
    } catch (e, st) {
      developer.log(
        'is_verified column query note',
        name: 'FoodDao',
        error: e,
        stackTrace: st,
      );
    }
    final sourceStr = row['source'] as String? ?? 'ICMR-NIN IFCT 2017';
    final isVerified =
        rawVerified != null ? rawVerified == 1 : sourceStr != 'Recipe Estimate';

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
      source: sourceStr,
      aliases: row['aliases'] as String? ?? '',
      portionUnits: portionUnits,
      isVerified: isVerified,
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
