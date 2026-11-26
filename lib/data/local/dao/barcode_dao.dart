import 'package:sique/domain/models/recipe_models.dart';
import 'package:sqlite3/common.dart';

/// Data Access Object for offline barcode cache and sparse micronutrient queries.
class BarcodeDao {
  BarcodeDao(
    this._db, {
    this.userId = 'default_user',
    String Function()? userIdProvider,
  }) : _userIdProvider = userIdProvider;

  final CommonDatabase _db;
  String userId;
  String Function()? _userIdProvider;

  set userIdProvider(String Function()? provider) => _userIdProvider = provider;

  String get effectiveUserId =>
      _userIdProvider != null ? _userIdProvider!() : userId;

  String _resolveUserId(String? override) {
    if (override != null && override.trim().isNotEmpty) {
      return override.trim();
    }
    return effectiveUserId;
  }

  String? _normalizeBarcode(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), '');
    if (trimmed.length < 4 || trimmed.length > 32) return null;
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(trimmed)) return null;
    return trimmed;
  }

  /// Looks up a packaged food product from local SQLite `barcode_cache`.
  BarcodeFoodProduct? getByBarcode(String barcode) {
    final normalized = _normalizeBarcode(barcode);
    if (normalized == null) return null;

    final stmt = _db.prepare('''
      SELECT barcode, food_name, brand_name, serving_size_g,
             calories, protein, carbs, fat, fiber, micros_json, cached_at
      FROM barcode_cache
      WHERE barcode = ?
      LIMIT 1;
    ''');
    try {
      final rows = stmt.select([normalized]);
      if (rows.isEmpty) return null;
      final r = rows.first;
      return BarcodeFoodProduct(
        barcode: r['barcode'] as String,
        foodName: r['food_name'] as String,
        brandName: r['brand_name'] as String?,
        servingSizeG: (r['serving_size_g'] as num).toDouble(),
        caloriesPer100g: (r['calories'] as num).toDouble(),
        proteinPer100g: (r['protein'] as num).toDouble(),
        carbsPer100g: (r['carbs'] as num).toDouble(),
        fatPer100g: (r['fat'] as num).toDouble(),
        fiberPer100g: (r['fiber'] as num).toDouble(),
        microsJson: r['micros_json'] as String?,
        cachedAt: DateTime.tryParse(r['cached_at'] as String) ?? DateTime.now(),
      );
    } finally {
      stmt.dispose();
    }
  }

  /// Saves or refreshes a scanned barcode product into offline SQLite cache.
  void upsertProduct(BarcodeFoodProduct product) {
    final stmt = _db.prepare('''
      INSERT OR REPLACE INTO barcode_cache (
        barcode, food_name, brand_name, serving_size_g,
        calories, protein, carbs, fat, fiber, micros_json, cached_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''');
    try {
      stmt.execute([
        product.barcode.trim(),
        product.foodName.trim(),
        product.brandName?.trim(),
        product.servingSizeG,
        product.caloriesPer100g,
        product.proteinPer100g,
        product.carbsPer100g,
        product.fatPer100g,
        product.fiberPer100g,
        product.microsJson,
        product.cachedAt.toIso8601String(),
      ]);
    } finally {
      stmt.dispose();
    }
  }

  /// Inserts sparse micronutrient per-100g entries for a given [foodId].
  void upsertFoodNutrients(int foodId, Map<int, double> per100gByNutrientId) {
    if (per100gByNutrientId.isEmpty) return;
    final stmt = _db.prepare('''
      INSERT OR REPLACE INTO food_nutrients (food_id, nutrient_id, amount_per_100g)
      VALUES (?, ?, ?);
    ''');
    try {
      per100gByNutrientId.forEach((nutrientId, amount) {
        if (amount >= 0) {
          stmt.execute([foodId, nutrientId, amount]);
        }
      });
    } finally {
      stmt.dispose();
    }
  }

  /// Returns all tracked micronutrient definitions ordered by id.
  List<NutrientDefinition> getAllNutrientDefinitions() {
    final stmt = _db.prepare('''
      SELECT id, slug, display_name, category, unit,
             default_rda_male, default_rda_female, upper_tolerable_limit
      FROM nutrient_definitions
      ORDER BY id ASC;
    ''');
    try {
      final rows = stmt.select();
      return rows
          .map(
            (r) => NutrientDefinition(
              id: (r['id'] as num).toInt(),
              slug: r['slug'] as String,
              displayName: r['display_name'] as String,
              category: r['category'] as String,
              unit: r['unit'] as String,
              defaultRdaMale: (r['default_rda_male'] as num?)?.toDouble(),
              defaultRdaFemale: (r['default_rda_female'] as num?)?.toDouble(),
              upperTolerableLimit:
                  (r['upper_tolerable_limit'] as num?)?.toDouble(),
            ),
          )
          .toList(growable: false);
    } finally {
      stmt.dispose();
    }
  }

  /// Aggregates total micronutrient intake for [date] by joining `food_logs`
  /// with sparse `food_nutrients`, scaled by `(gram_weight / 100.0)`.
  List<DailyMicronutrientIntake> getDailyMicronutrientIntake(
    DateTime date, {
    String? userId,
    bool isFemale = false,
  }) {
    final uid = _resolveUserId(userId);
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final definitions = getAllNutrientDefinitions();
    if (definitions.isEmpty) return const [];

    final consumedByNutrientId = <int, double>{};
    final stmt = _db.prepare('''
      SELECT fn.nutrient_id AS nutrient_id,
             SUM((fl.gram_weight / 100.0) * fn.amount_per_100g) AS total_amount
      FROM food_logs fl
      INNER JOIN food_nutrients fn ON fl.food_id = fn.food_id
      WHERE fl.user_id = ? AND fl.date = ?
      GROUP BY fn.nutrient_id;
    ''');
    try {
      final rows = stmt.select([uid, dateStr]);
      for (final row in rows) {
        final nutrientId = (row['nutrient_id'] as num).toInt();
        final amount = (row['total_amount'] as num?)?.toDouble() ?? 0.0;
        consumedByNutrientId[nutrientId] = amount;
      }
    } finally {
      stmt.dispose();
    }

    return definitions
        .map(
          (def) => DailyMicronutrientIntake(
            definition: def,
            consumedAmount: consumedByNutrientId[def.id] ?? 0.0,
            targetAmount: def.targetForSex(isFemale: isFemale),
          ),
        )
        .toList(growable: false);
  }

  /// Batch-computes daily sodium intake (mg) and calorie-weighted sodium coverage [0..1]
  /// across all logged dates for heteroscedastic Kalman V5 noise estimation.
  Map<String, ({double sodiumMg, double coverageRatio})>
      getDailySodiumWithCoverage({String? userId}) {
    final uid = _resolveUserId(userId);
    final result = <String, ({double sodiumMg, double coverageRatio})>{};
    final stmt = _db.prepare('''
      SELECT fl.date AS date,
             SUM(fl.calories) AS total_kcal,
             SUM(CASE WHEN fn.nutrient_id = 4
                      THEN (fl.gram_weight / 100.0) * fn.amount_per_100g
                      ELSE 0.0 END) AS sodium_mg,
             SUM(CASE WHEN fn.nutrient_id = 4 THEN fl.calories ELSE 0.0 END) AS covered_kcal
      FROM food_logs fl
      LEFT JOIN food_nutrients fn
        ON fl.food_id = fn.food_id AND fn.nutrient_id = 4
      WHERE fl.user_id = ?
      GROUP BY fl.date;
    ''');
    try {
      final rows = stmt.select([uid]);
      for (final row in rows) {
        final date = row['date'] as String?;
        if (date == null || date.isEmpty) continue;
        final totalKcal = (row['total_kcal'] as num?)?.toDouble() ?? 0.0;
        final sodiumMg = (row['sodium_mg'] as num?)?.toDouble() ?? 0.0;
        final coveredKcal = (row['covered_kcal'] as num?)?.toDouble() ?? 0.0;
        final cov =
            totalKcal > 0 ? (coveredKcal / totalKcal).clamp(0.0, 1.0) : 0.0;
        result[date] = (sodiumMg: sodiumMg, coverageRatio: cov);
      }
      return result;
    } finally {
      stmt.dispose();
    }
  }
}
