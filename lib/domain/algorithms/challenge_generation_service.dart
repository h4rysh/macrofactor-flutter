import 'dart:math' as math;

import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/weekly_challenge_model.dart';

/// Generates tailored behavioral habit challenges based on SQLite deficit mining.
class ChallengeGenerationService {
  const ChallengeGenerationService._();

  /// Evaluates mined deficit metrics and generates exactly 2 high-impact weekly habits.
  static List<WeeklyChallengeModel> generateWeeklyChallenges({
    required MinedDeficitMetrics metrics,
    required DateTime weekStart,
    String userId = 'default_user',
    double? proteinTargetG,
  }) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final now = DateTime.now();
    final candidates = <WeeklyChallengeModel>[];

    final targetP = (proteinTargetG ?? 150.0).round();

    // 1. Deficit Heuristic: Protein consistency
    if (metrics.proteinHitDays < 5) {
      candidates.add(WeeklyChallengeModel(
        id: 'chk_${userId}_protein_${weekStart.millisecondsSinceEpoch}',
        userId: userId,
        type: ChallengeType.proteinAnchor,
        title: 'Protein Anchor (${targetP}g/day)',
        description:
            'Hit your daily protein target of ${targetP}g on at least 5 days this week.',
        targetMetric: 'days_hit',
        targetValue: 5.0,
        currentValue: 0.0,
        unit: 'days',
        status: ChallengeStatus.active,
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        createdAt: now,
      ));
    }

    // 2. Deficit Heuristic: Fiber & Satiety
    if (metrics.avgFiberG < 22.0) {
      candidates.add(WeeklyChallengeModel(
        id: 'chk_${userId}_fiber_${weekStart.millisecondsSinceEpoch}',
        userId: userId,
        type: ChallengeType.fiberBuilder,
        title: 'Fiber & Satiety Builder',
        description: 'Reach at least 25g of dietary fiber on 4 days this week.',
        targetMetric: 'fiber:25',
        targetValue: 4.0,
        currentValue: 0.0,
        unit: 'days',
        status: ChallengeStatus.active,
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        createdAt: now,
      ));
    }

    // 3. Deficit Heuristic: Fresh produce
    if (metrics.produceDays < 4) {
      candidates.add(WeeklyChallengeModel(
        id: 'chk_${userId}_produce_${weekStart.millisecondsSinceEpoch}',
        userId: userId,
        type: ChallengeType.produceBooster,
        title: 'Daily Produce Booster',
        description:
            'Eat 2+ servings of whole fruits or green vegetables on 5 days this week.',
        targetMetric: 'days_hit',
        targetValue: 5.0,
        currentValue: 0.0,
        unit: 'days',
        status: ChallengeStatus.active,
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        createdAt: now,
      ));
    }

    // 4. Deficit Heuristic: Weigh-In Cadence
    if (metrics.weighInDays < 5) {
      candidates.add(WeeklyChallengeModel(
        id: 'chk_${userId}_scale_${weekStart.millisecondsSinceEpoch}',
        userId: userId,
        type: ChallengeType.scaleCadence,
        title: 'Morning Weigh-In Cadence',
        description:
            'Step on the scale upon waking 5 mornings this week for clean trend estimation.',
        targetMetric: 'days_hit',
        targetValue: 5.0,
        currentValue: 0.0,
        unit: 'days',
        status: ChallengeStatus.active,
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        createdAt: now,
      ));
    }

    // 5. Deficit Heuristic: Hydration baseline
    if (metrics.avgHydrationMl < 2000) {
      candidates.add(WeeklyChallengeModel(
        id: 'chk_${userId}_water_${weekStart.millisecondsSinceEpoch}',
        userId: userId,
        type: ChallengeType.hydrationHero,
        title: 'Hydration Foundation (2.5L)',
        description: 'Drink at least 2,500ml of water on 5 days this week.',
        targetMetric: 'hydration:2500',
        targetValue: 5.0,
        currentValue: 0.0,
        unit: 'days',
        status: ChallengeStatus.active,
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        createdAt: now,
      ));
    }

    // Fallback: If user is performing exceptionally well across all habits, maintain protein and produce anchors
    if (candidates.isEmpty) {
      candidates.add(WeeklyChallengeModel(
        id: 'chk_${userId}_protein_${weekStart.millisecondsSinceEpoch}',
        userId: userId,
        type: ChallengeType.proteinAnchor,
        title: 'Protein Master (${targetP}g/day)',
        description: 'Hit your daily protein target on 6 days this week.',
        targetMetric: 'days_hit',
        targetValue: 6.0,
        currentValue: 0.0,
        unit: 'days',
        status: ChallengeStatus.active,
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        createdAt: now,
      ));
      candidates.add(WeeklyChallengeModel(
        id: 'chk_${userId}_produce_${weekStart.millisecondsSinceEpoch}',
        userId: userId,
        type: ChallengeType.produceBooster,
        title: 'Super Produce Intake',
        description: 'Log fruits or fresh greens on 6 days this week.',
        targetMetric: 'days_hit',
        targetValue: 6.0,
        currentValue: 0.0,
        unit: 'days',
        status: ChallengeStatus.active,
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        createdAt: now,
      ));
    } else if (candidates.length == 1) {
      candidates.add(WeeklyChallengeModel(
        id: 'chk_${userId}_water_${weekStart.millisecondsSinceEpoch}',
        userId: userId,
        type: ChallengeType.hydrationHero,
        title: 'Daily Hydration Habit',
        description: 'Drink at least 2,500ml of water on 5 days this week.',
        targetMetric: 'hydration:2500',
        targetValue: 5.0,
        currentValue: 0.0,
        unit: 'days',
        status: ChallengeStatus.active,
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        createdAt: now,
      ));
    }

    // Return exactly the top 2 highest-priority habit challenges
    return candidates.take(2).toList();
  }

  /// Generates up to 3 scored adaptive weekly challenges using V2 6-table deficit mining,
  /// SDT adaptive staircase calibration (65-80% attainability), and minimum logging gating.
  static List<WeeklyChallengeModel> generateAdaptiveChallengesV2({
    required MinedDeficitMetricsV2 metrics,
    required DateTime weekStart,
    String userId = 'default_user',
    double proteinTargetG = 150.0,
    int plannedWorkoutDays = 3,
    int limit = 3,
  }) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final now = DateTime.now();
    final scored = <({double score, WeeklyChallengeModel challenge})>[];

    double roundTo25(double v) => (v / 25.0).round() * 25.0;
    final safeProteinTarget = (proteinTargetG.isFinite && proteinTargetG > 0)
        ? proteinTargetG
        : 150.0;

    // Gate: if < 3 logged days, prioritize Scale Cadence & Hydration first
    if (metrics.totalLoggedDays >= 3) {
      // 1. Cumulative Weekly Protein Volume (forgiving: 1 low day won't fail)
      if (metrics.avgDailyProteinG < 0.85 * safeProteinTarget) {
        final rawGoal = roundTo25(7.0 * metrics.avgDailyProteinG * 1.15);
        final weeklyTarget = rawGoal
            .clamp(0.60 * 7.0 * safeProteinTarget, 7.0 * safeProteinTarget)
            .clamp(250.0, 2000.0);
        final severity = (1.0 -
                (metrics.avgDailyProteinG / math.max(safeProteinTarget, 60.0)))
            .clamp(0.1, 1.0);
        scored.add((
          score: 100.0 * severity + 20.0,
          challenge: WeeklyChallengeModel(
            id: 'chk_${userId}_protvol_${weekStart.millisecondsSinceEpoch}',
            userId: userId,
            type: ChallengeType.proteinVolume,
            title: 'Hit ${weeklyTarget.round()}g+ Total Protein',
            description:
                'Last week averaged ${metrics.avgDailyProteinG.round()}g/day vs ${safeProteinTarget.round()}g goal. Cumulative weekly target.',
            targetMetric: 'total_protein_g',
            targetValue: weeklyTarget,
            unit: 'g',
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            createdAt: now,
          ),
        ));
      }

      // 2. Coverage-Gated Micronutrient Fix
      if (metrics.worstNutrientId != null &&
          metrics.worstNutrientName != null &&
          metrics.worstNutrientRda != null &&
          (metrics.worstNutrientDeficitRatio ?? 0.0) > 0.25) {
        final threshold = (metrics.worstNutrientRda! * 0.80);
        final pct =
            (100.0 * (1.0 - metrics.worstNutrientDeficitRatio!)).round();
        scored.add((
          score: 85.0 * metrics.worstNutrientDeficitRatio! + 15.0,
          challenge: WeeklyChallengeModel(
            id: 'chk_${userId}_micro_${metrics.worstNutrientId}_${weekStart.millisecondsSinceEpoch}',
            userId: userId,
            type: ChallengeType.micronutrientFix,
            title: 'Close ${metrics.worstNutrientName} Gap',
            description:
                '${metrics.worstNutrientName} averaged $pct% RDA last week. Hit ${threshold.toStringAsFixed(0)}${metrics.worstNutrientUnit ?? ''} on 4 days.',
            targetMetric:
                'micro:${metrics.worstNutrientId}:${threshold.toStringAsFixed(2)}',
            targetValue: 4.0,
            unit: 'days',
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            createdAt: now,
          ),
        ));
      }

      // 3. Adaptive Fiber Staircase
      if (metrics.avgFiberG < 25.0) {
        final stepTarget = (metrics.avgFiberG + 4.0).clamp(18.0, 30.0).round();
        scored.add((
          score: (25.0 - metrics.avgFiberG) * 3.0,
          challenge: WeeklyChallengeModel(
            id: 'chk_${userId}_fiber_${weekStart.millisecondsSinceEpoch}',
            userId: userId,
            type: ChallengeType.fiberBuilder,
            title: 'Reach ${stepTarget}g+ Fiber (4d)',
            description:
                'Last week averaged ${metrics.avgFiberG.toStringAsFixed(1)}g fiber. Step up on 4 days.',
            targetMetric: 'fiber:$stepTarget',
            targetValue: 4.0,
            unit: 'days',
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            createdAt: now,
          ),
        ));
      }

      // 4. Produce Diversity
      if (metrics.produceDays < 5) {
        final targetDays = math.min(6, metrics.produceDays + 2);
        scored.add((
          score: (5 - metrics.produceDays) * 14.0,
          challenge: WeeklyChallengeModel(
            id: 'chk_${userId}_produce_${weekStart.millisecondsSinceEpoch}',
            userId: userId,
            type: ChallengeType.produceBooster,
            title: 'Produce on $targetDays Days',
            description:
                'Logged produce on ${metrics.produceDays}/7 days last week. Add 1+ fruit, palak, or sabzi daily.',
            targetMetric: 'days_hit',
            targetValue: targetDays.toDouble(),
            unit: 'days',
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            createdAt: now,
          ),
        ));
      }

      // 5. Late-Night Snack Tamer
      if (metrics.lateNightSnackDays >= 2) {
        scored.add((
          score: metrics.lateNightSnackDays * 15.0,
          challenge: WeeklyChallengeModel(
            id: 'chk_${userId}_nightcap_${weekStart.millisecondsSinceEpoch}',
            userId: userId,
            type: ChallengeType.nightCapTamer,
            title: 'Kitchen Closed After 9 PM',
            description:
                'Late-night snacks appeared on ${metrics.lateNightSnackDays} days last week. Keep 5 nights clear.',
            targetMetric: 'days_hit',
            targetValue: 5.0,
            unit: 'nights',
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            createdAt: now,
          ),
        ));
      }
    }

    // 6. Scale Cadence
    if (metrics.weighInDays < 5) {
      final target = math.min(6, metrics.weighInDays + 2).clamp(3, 6);
      scored.add((
        score: (5 - metrics.weighInDays) * 16.0 + 10.0,
        challenge: WeeklyChallengeModel(
          id: 'chk_${userId}_scale_${weekStart.millisecondsSinceEpoch}',
          userId: userId,
          type: ChallengeType.scaleCadence,
          title: '$target Morning Weigh-Ins',
          description:
              'Logged ${metrics.weighInDays}/7 weigh-ins last week. More data tightens Kalman TDEE.',
          targetMetric: 'days_hit',
          targetValue: target.toDouble(),
          unit: 'days',
          weekStartDate: weekStart,
          weekEndDate: weekEnd,
          createdAt: now,
        ),
      ));
    }

    // 7. Weight-Scaled Hydration
    if (metrics.avgHydrationMl < (metrics.adaptiveWaterTargetMl * 0.80)) {
      scored.add((
        score: 52.0,
        challenge: WeeklyChallengeModel(
          id: 'chk_${userId}_water_${weekStart.millisecondsSinceEpoch}',
          userId: userId,
          type: ChallengeType.hydrationHero,
          title:
              'Hydrate ${(metrics.adaptiveWaterTargetMl / 1000.0).toStringAsFixed(1)}L+ (5d)',
          description:
              'Last week averaged ${metrics.avgHydrationMl}ml/day. Hit target on 5 days.',
          targetMetric: 'hydration:${metrics.adaptiveWaterTargetMl}',
          targetValue: 5.0,
          unit: 'days',
          weekStartDate: weekStart,
          weekEndDate: weekEnd,
          createdAt: now,
        ),
      ));
    }

    // 8. Training Consistency
    if (metrics.workoutDays < plannedWorkoutDays) {
      final targetW =
          math.min(plannedWorkoutDays, metrics.workoutDays + 1).clamp(2, 6);
      scored.add((
        score: (plannedWorkoutDays - metrics.workoutDays) * 18.0,
        challenge: WeeklyChallengeModel(
          id: 'chk_${userId}_workout_${weekStart.millisecondsSinceEpoch}',
          userId: userId,
          type: ChallengeType.trainingConsistency,
          title: '$targetW Workouts (>=20 min)',
          description:
              'Completed ${metrics.workoutDays} sessions last week. Hit $targetW to keep expenditure drift positive.',
          targetMetric: 'days_hit',
          targetValue: targetW.toDouble(),
          unit: 'sessions',
          weekStartDate: weekStart,
          weekEndDate: weekEnd,
          createdAt: now,
        ),
      ));
    }

    // 9. Recomp Waist Check-In
    if (metrics.daysSinceLastMeasurement >= 14) {
      scored.add((
        score: 48.0,
        challenge: WeeklyChallengeModel(
          id: 'chk_${userId}_recomp_${weekStart.millisecondsSinceEpoch}',
          userId: userId,
          type: ChallengeType.recompMeasure,
          title: 'Log a 30-Sec Waist Check-In',
          description:
              'No waist log in ${metrics.daysSinceLastMeasurement}+ days. Keeps Silent Recomp radar accurate.',
          targetMetric: 'measurements_hit',
          targetValue: 1.0,
          unit: 'log',
          weekStartDate: weekStart,
          weekEndDate: weekEnd,
          createdAt: now,
        ),
      ));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).map((e) => e.challenge).toList();
  }

  /// Queries local SQLite foods to suggest Top 3 actionable foods that fix a challenge.
  static List<({String name, String badge})> suggestFixingFoods(
    AppDatabase db,
    WeeklyChallengeModel challenge,
  ) {
    final String sql;
    final List<Object?> args;
    switch (challenge.type) {
      case ChallengeType.proteinAnchor:
      case ChallengeType.proteinVolume:
        sql = '''
          SELECT name, printf('%.0fg P / 100g', protein_per_100g) AS badge
          FROM foods WHERE protein_per_100g >= 12
          ORDER BY protein_per_100g DESC LIMIT 3;
        ''';
        args = const [];
        break;
      case ChallengeType.fiberBuilder:
        sql = '''
          SELECT name, printf('%.1fg Fiber', fiber_per_100g) AS badge
          FROM foods WHERE fiber_per_100g >= 4
          ORDER BY fiber_per_100g DESC LIMIT 3;
        ''';
        args = const [];
        break;
      case ChallengeType.micronutrientFix:
        final parts = challenge.targetMetric.split(':');
        final nid = parts.length >= 2 ? (int.tryParse(parts[1]) ?? 1) : 1;
        sql = '''
          SELECT f.name AS name,
                 printf('%.1f %s/100g', fn.amount_per_100g, nd.unit) AS badge
          FROM food_nutrients fn
          INNER JOIN foods f ON f.id = fn.food_id
          INNER JOIN nutrient_definitions nd ON nd.id = fn.nutrient_id
          WHERE fn.nutrient_id = ?
          ORDER BY fn.amount_per_100g DESC LIMIT 3;
        ''';
        args = [nid];
        break;
      case ChallengeType.produceBooster:
        sql = '''
          SELECT name, 'Fresh Produce' AS badge
          FROM foods
          WHERE LOWER(name) LIKE '%palak%' OR LOWER(name) LIKE '%spinach%'
             OR LOWER(name) LIKE '%guava%' OR LOWER(name) LIKE '%apple%'
             OR LOWER(name) LIKE '%broccoli%'
          LIMIT 3;
        ''';
        args = const [];
        break;
      default:
        return const [];
    }

    final stmt = db.rawDb.prepare(sql);
    try {
      return stmt
          .select(args)
          .map((r) => (
                name: (r['name'] as String?) ?? '',
                badge: (r['badge'] as String?) ?? '',
              ))
          .where((e) => e.name.isNotEmpty)
          .toList();
    } finally {
      stmt.dispose();
    }
  }
}
