import 'package:sqlite3/common.dart';

class BiomarkerSummary {
  const BiomarkerSummary({
    required this.nutrientId,
    required this.slug,
    required this.displayName,
    required this.category,
    required this.unit,
    required this.avgDailyIntake,
    required this.targetAmount,
    required this.upperLimit,
    required this.isCustomGoal,
    required this.coverageRatio,
  });

  final int nutrientId;
  final String slug;
  final String displayName;
  final String category;
  final String unit;
  final double avgDailyIntake;
  final double targetAmount;
  final double? upperLimit;
  final bool isCustomGoal;
  final double coverageRatio;

  double get ratio => targetAmount > 0 ? (avgDailyIntake / targetAmount) : 0.0;
}

class NutrientFoodContributor {
  const NutrientFoodContributor({
    required this.foodName,
    required this.totalAmount,
  });

  final String foodName;
  final double totalAmount;
}

/// Queries 36-biomarker rolling intake (7d/14d/30d), coverage transparency,
/// custom micro_goals, and top food contributors / catalog gap-fillers.
class NutrientExplorerDao {
  const NutrientExplorerDao._();

  static ({double coveragePct, List<BiomarkerSummary> items}) loadWindow(
    CommonDatabase db, {
    required String userId,
    required int windowDays,
    required bool isFemale,
    required DateTime referenceDate,
  }) {
    final start = referenceDate.subtract(Duration(days: windowDays - 1));
    final startStr =
        '${start.year.toString().padLeft(4, '0')}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';

    final endStr =
        '${referenceDate.year.toString().padLeft(4, '0')}-${referenceDate.month.toString().padLeft(2, '0')}-${referenceDate.day.toString().padLeft(2, '0')}';

    var loggedDays = 0;
    var totalKcal = 0.0;
    final dayStmt = db.prepare('''
      SELECT COUNT(DISTINCT date) AS d, COALESCE(SUM(calories), 0.0) AS k
      FROM food_logs WHERE user_id = ? AND date >= ? AND date <= ?;
    ''');
    try {
      final rows = dayStmt.select([userId, startStr, endStr]);
      if (rows.isNotEmpty) {
        loggedDays = (rows.first['d'] as int?) ?? 0;
        totalKcal = (rows.first['k'] as num?)?.toDouble() ?? 0.0;
      }
    } finally {
      dayStmt.dispose();
    }

    final effectiveDays = loggedDays > 0 ? loggedDays : 1;

    final customGoals = <int, double>{};
    final gStmt = db.prepare(
      'SELECT nutrient_id, custom_target FROM micro_goals WHERE user_id = ?;',
    );
    try {
      for (final r in gStmt.select([userId])) {
        customGoals[(r['nutrient_id'] as num).toInt()] =
            (r['custom_target'] as num).toDouble();
      }
    } finally {
      gStmt.dispose();
    }

    final intakeById = <int, ({double totalAmt, double covKcal})>{};
    final nStmt = db.prepare('''
      SELECT fn.nutrient_id AS nid,
             SUM((fl.gram_weight / 100.0) * fn.amount_per_100g) AS amt,
             SUM(fl.calories) AS cov
      FROM food_logs fl
      INNER JOIN food_nutrients fn ON fl.food_id = fn.food_id
      WHERE fl.user_id = ? AND fl.date >= ? AND fl.date <= ?
      GROUP BY fn.nutrient_id;
    ''');
    try {
      for (final r in nStmt.select([userId, startStr, endStr])) {
        intakeById[(r['nid'] as num).toInt()] = (
          totalAmt: (r['amt'] as num?)?.toDouble() ?? 0.0,
          covKcal: (r['cov'] as num?)?.toDouble() ?? 0.0,
        );
      }
    } finally {
      nStmt.dispose();
    }

    final items = <BiomarkerSummary>[];
    var sumCov = 0.0;
    final defStmt = db.prepare(
      'SELECT * FROM nutrient_definitions ORDER BY id ASC;',
    );
    try {
      for (final r in defStmt.select()) {
        final id = (r['id'] as num).toInt();
        final rda = isFemale
            ? ((r['default_rda_female'] as num?)?.toDouble() ?? 0.0)
            : ((r['default_rda_male'] as num?)?.toDouble() ?? 0.0);
        final custom = customGoals[id];
        final stats = intakeById[id];
        final avgDaily = (stats?.totalAmt ?? 0.0) / effectiveDays;
        final cov = totalKcal > 0
            ? ((stats?.covKcal ?? 0.0) / totalKcal).clamp(0.0, 1.0)
            : 0.0;
        sumCov += cov;
        items.add(
          BiomarkerSummary(
            nutrientId: id,
            slug: r['slug'] as String,
            displayName: r['display_name'] as String,
            category: r['category'] as String,
            unit: r['unit'] as String,
            avgDailyIntake: avgDaily,
            targetAmount: custom ?? rda,
            upperLimit: (r['upper_tolerable_limit'] as num?)?.toDouble(),
            isCustomGoal: custom != null,
            coverageRatio: cov,
          ),
        );
      }
    } finally {
      defStmt.dispose();
    }

    final meanCov = items.isNotEmpty ? (sumCov / items.length) : 0.0;
    return (coveragePct: meanCov * 100.0, items: items);
  }

  static List<NutrientFoodContributor> topContributors(
    CommonDatabase db, {
    required String userId,
    required int nutrientId,
    required int windowDays,
    required DateTime referenceDate,
  }) {
    final start = referenceDate.subtract(Duration(days: windowDays - 1));
    final startStr =
        '${start.year.toString().padLeft(4, '0')}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr =
        '${referenceDate.year.toString().padLeft(4, '0')}-${referenceDate.month.toString().padLeft(2, '0')}-${referenceDate.day.toString().padLeft(2, '0')}';
    final stmt = db.prepare('''
      SELECT fl.food_name AS name,
             SUM((fl.gram_weight / 100.0) * fn.amount_per_100g) AS amt
      FROM food_logs fl
      INNER JOIN food_nutrients fn ON fl.food_id = fn.food_id
      WHERE fl.user_id = ? AND fl.date >= ? AND fl.date <= ? AND fn.nutrient_id = ?
      GROUP BY fl.food_id, fl.food_name
      ORDER BY amt DESC LIMIT 5;
    ''');
    try {
      return stmt
          .select([userId, startStr, endStr, nutrientId])
          .map((r) => NutrientFoodContributor(
                foodName: r['name'] as String,
                totalAmount: (r['amt'] as num?)?.toDouble() ?? 0.0,
              ))
          .toList();
    } finally {
      stmt.dispose();
    }
  }
}
