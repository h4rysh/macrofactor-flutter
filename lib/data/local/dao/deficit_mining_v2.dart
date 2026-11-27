import 'package:sique/data/local/dao/challenges_dao.dart';
import 'package:sqlite3/common.dart';

/// Full-spectrum deficit metrics mined across all 6 local SQLite tables.
class MinedDeficitMetricsV2 extends MinedDeficitMetrics {
  const MinedDeficitMetricsV2({
    required super.totalLoggedDays,
    required super.proteinHitDays,
    required super.avgFiberG,
    required super.produceDays,
    required super.weighInDays,
    required super.avgHydrationMl,
    required this.avgDailyProteinG,
    required this.workoutDays,
    required this.extendedFastCount,
    required this.lateNightSnackDays,
    required this.daysSinceLastMeasurement,
    required this.adaptiveWaterTargetMl,
    this.worstNutrientId,
    this.worstNutrientName,
    this.worstNutrientUnit,
    this.worstNutrientRda,
    this.worstNutrientDailyAvg,
    this.worstNutrientDeficitRatio,
  });

  final double avgDailyProteinG;
  final int workoutDays;
  final int extendedFastCount;
  final int lateNightSnackDays;
  final int daysSinceLastMeasurement;
  final int adaptiveWaterTargetMl;
  final int? worstNutrientId;
  final String? worstNutrientName;
  final String? worstNutrientUnit;
  final double? worstNutrientRda;
  final double? worstNutrientDailyAvg;
  final double? worstNutrientDeficitRatio;
}

/// Executes full-spectrum 6-table deficit mining with >=75% sparse micronutrient coverage gating.
class DeficitMiningV2 {
  const DeficitMiningV2._();

  static MinedDeficitMetricsV2 mine(
    CommonDatabase db, {
    required String userId,
    required double proteinTargetG,
    double weightKg = 70.0,
    bool isFemale = false,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final sixDaysAgo = DateTime(now.year, now.month, now.day - 6);
    final startDateStr =
        '${sixDaysAgo.year.toString().padLeft(4, '0')}-${sixDaysAgo.month.toString().padLeft(2, '0')}-${sixDaysAgo.day.toString().padLeft(2, '0')}';
    final endDateStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 1. Food logs: protein, fiber, expanded produce, late-night snacks, total kcal
    final foodStmt = db.prepare('''
      SELECT
        COUNT(CASE WHEN daily_protein >= ? THEN 1 END) AS protein_hit_days,
        AVG(daily_protein) AS avg_protein_g,
        AVG(daily_fiber) AS avg_fiber_g,
        COUNT(CASE WHEN has_produce = 1 THEN 1 END) AS produce_days,
        COUNT(CASE WHEN late_snacks > 0 THEN 1 END) AS late_snack_days,
        COUNT(*) AS total_logged_days,
        COALESCE(SUM(daily_kcal), 0.0) AS total_kcal_7d
      FROM (
        SELECT
          date,
          SUM(protein) AS daily_protein,
          SUM(fiber) AS daily_fiber,
          SUM(calories) AS daily_kcal,
          MAX(CASE
            WHEN LOWER(food_name) LIKE '%apple%' OR LOWER(food_name) LIKE '%banana%'
              OR LOWER(food_name) LIKE '%orange%' OR LOWER(food_name) LIKE '%spinach%'
              OR LOWER(food_name) LIKE '%broccoli%' OR LOWER(food_name) LIKE '%salad%'
              OR LOWER(food_name) LIKE '%fruit%' OR LOWER(food_name) LIKE '%vegetable%'
              OR LOWER(food_name) LIKE '%palak%' OR LOWER(food_name) LIKE '%bhindi%'
              OR LOWER(food_name) LIKE '%lauki%' OR LOWER(food_name) LIKE '%methi%'
              OR LOWER(food_name) LIKE '%karela%' OR LOWER(food_name) LIKE '%amla%'
              OR LOWER(food_name) LIKE '%pomegranate%' OR LOWER(food_name) LIKE '%tomato%'
              OR LOWER(food_name) LIKE '%cucumber%' OR LOWER(food_name) LIKE '%sabzi%'
              OR LOWER(food_name) LIKE '%raita%' OR LOWER(food_name) LIKE '%mango%'
              OR LOWER(food_name) LIKE '%papaya%' OR LOWER(food_name) LIKE '%guava%'
            THEN 1 ELSE 0 END) AS has_produce,
          SUM(CASE
            WHEN meal_type IN ('snack', 'snacks')
              AND substr(logged_at, 1, 10) = date
              AND CAST(substr(logged_at, 12, 2) AS INTEGER) >= 21
            THEN 1 ELSE 0 END) AS late_snacks
        FROM food_logs
        WHERE user_id = ? AND date >= ? AND date <= ?
        GROUP BY date
      );
    ''');

    var proteinHitDays = 0;
    var avgDailyProteinG = 0.0;
    var avgFiberG = 0.0;
    var produceDays = 0;
    var lateNightSnackDays = 0;
    var totalLoggedDays = 0;
    var totalKcal7d = 0.0;
    try {
      final rows =
          foodStmt.select([proteinTargetG, userId, startDateStr, endDateStr]);
      if (rows.isNotEmpty) {
        final r = rows.first;
        proteinHitDays = (r['protein_hit_days'] as int?) ?? 0;
        avgDailyProteinG = (r['avg_protein_g'] as num?)?.toDouble() ?? 0.0;
        avgFiberG = (r['avg_fiber_g'] as num?)?.toDouble() ?? 0.0;
        produceDays = (r['produce_days'] as int?) ?? 0;
        lateNightSnackDays = (r['late_snack_days'] as int?) ?? 0;
        totalLoggedDays = (r['total_logged_days'] as int?) ?? 0;
        totalKcal7d = (r['total_kcal_7d'] as num?)?.toDouble() ?? 0.0;
      }
    } finally {
      foodStmt.dispose();
    }

    // 2. Weigh-ins & Water
    var weighIns = 0;
    final wStmt = db.prepare(
      'SELECT COUNT(*) AS c FROM weight_logs WHERE user_id = ? AND date >= ?;',
    );
    try {
      final rows = wStmt.select([userId, startDateStr]);
      if (rows.isNotEmpty) weighIns = (rows.first['c'] as int?) ?? 0;
    } finally {
      wStmt.dispose();
    }

    var avgWater = 0;
    final waStmt = db.prepare('''
      SELECT AVG(d) AS avg_w FROM (
        SELECT SUM(amount_ml) AS d FROM water_logs
        WHERE user_id = ? AND date >= ? GROUP BY date
      );
    ''');
    try {
      final rows = waStmt.select([userId, startDateStr]);
      if (rows.isNotEmpty && rows.first['avg_w'] != null) {
        avgWater = (rows.first['avg_w'] as num).toInt();
      }
    } finally {
      waStmt.dispose();
    }

    // 3. Workouts, Fasting & Measurements
    var workoutDays = 0;
    final woStmt = db.prepare('''
      SELECT COUNT(DISTINCT substr(start_time, 1, 10)) AS c
      FROM workout_sessions
      WHERE user_id = ? AND substr(start_time, 1, 10) >= ? AND duration_minutes >= 20;
    ''');
    try {
      final rows = woStmt.select([userId, startDateStr]);
      if (rows.isNotEmpty) workoutDays = (rows.first['c'] as int?) ?? 0;
    } finally {
      woStmt.dispose();
    }

    var extendedFasts = 0;
    final fStmt = db.prepare('''
      SELECT COUNT(*) AS c FROM fasting_sessions
      WHERE user_id = ? AND substr(start_time, 1, 10) >= ? AND state = 'completed';
    ''');
    try {
      final rows = fStmt.select([userId, startDateStr]);
      if (rows.isNotEmpty) extendedFasts = (rows.first['c'] as int?) ?? 0;
    } finally {
      fStmt.dispose();
    }

    var daysSinceMeas = 99;
    final mStmt = db.prepare(
      'SELECT MAX(date) AS last_d FROM body_measurements WHERE user_id = ? AND waist_cm IS NOT NULL;',
    );
    try {
      final rows = mStmt.select([userId]);
      if (rows.isNotEmpty && rows.first['last_d'] != null) {
        final d = DateTime.tryParse(rows.first['last_d'] as String);
        if (d != null) daysSinceMeas = now.difference(d).inDays.clamp(0, 365);
      }
    } finally {
      mStmt.dispose();
    }

    // 4. Coverage-gated (>=75% kcal & >=4 logged days) micronutrient deficit scoring
    int? worstId;
    String? worstName;
    String? worstUnit;
    double? worstRda;
    double? worstAvg;
    double? worstRatio;

    if (totalLoggedDays >= 4 && totalKcal7d > 0) {
      final microStmt = db.prepare('''
        SELECT nd.id AS id, nd.display_name AS name, nd.unit AS unit,
               nd.default_rda_male AS rda_m, nd.default_rda_female AS rda_f,
               SUM((fl.gram_weight / 100.0) * fn.amount_per_100g) AS total_amt,
               SUM(fl.calories) AS covered_kcal
        FROM food_logs fl
        INNER JOIN food_nutrients fn ON fl.food_id = fn.food_id
        INNER JOIN nutrient_definitions nd ON fn.nutrient_id = nd.id
        WHERE fl.user_id = ? AND fl.date >= ?
        GROUP BY nd.id;
      ''');
      try {
        var maxDeficit = 0.0;
        for (final r in microStmt.select([userId, startDateStr])) {
          final id = (r['id'] as num).toInt();
          // Skip Sodium (4), Omega-6 (30), Saturated Fat (31), Cholesterol (32)
          if (const {4, 30, 31, 32}.contains(id)) continue;
          final cov =
              ((r['covered_kcal'] as num?)?.toDouble() ?? 0.0) / totalKcal7d;
          if (cov < 0.75) continue;
          final rda = isFemale
              ? (r['rda_f'] as num?)?.toDouble() ?? 0.0
              : (r['rda_m'] as num?)?.toDouble() ?? 0.0;
          if (rda <= 0) continue;
          final totalAmt = (r['total_amt'] as num?)?.toDouble() ?? 0.0;
          final dailyEst = (totalAmt / totalLoggedDays) / cov;
          final deficit = 1.0 - (dailyEst / rda);
          if (deficit > 0.25 && deficit > maxDeficit) {
            maxDeficit = deficit;
            worstId = id;
            worstName = r['name'] as String?;
            worstUnit = r['unit'] as String?;
            worstRda = rda;
            worstAvg = dailyEst;
            worstRatio = deficit;
          }
        }
      } finally {
        microStmt.dispose();
      }
    }

    final safeWeight = weightKg.isFinite && weightKg > 0 ? weightKg : 70.0;
    final waterTarget = (35.0 * safeWeight).round().clamp(2000, 3800);

    return MinedDeficitMetricsV2(
      totalLoggedDays: totalLoggedDays,
      proteinHitDays: proteinHitDays,
      avgFiberG: avgFiberG,
      produceDays: produceDays,
      weighInDays: weighIns,
      avgHydrationMl: avgWater,
      avgDailyProteinG: avgDailyProteinG,
      workoutDays: workoutDays,
      extendedFastCount: extendedFasts,
      lateNightSnackDays: lateNightSnackDays,
      daysSinceLastMeasurement: daysSinceMeas,
      adaptiveWaterTargetMl: waterTarget,
      worstNutrientId: worstId,
      worstNutrientName: worstName,
      worstNutrientUnit: worstUnit,
      worstNutrientRda: worstRda,
      worstNutrientDailyAvg: worstAvg,
      worstNutrientDeficitRatio: worstRatio,
    );
  }
}
