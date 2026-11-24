import 'package:sique/data/local/dao/challenges_dao.dart';
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
        description: 'Hit your daily protein target of ${targetP}g on at least 5 days this week.',
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
        targetMetric: 'days_hit',
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
        description: 'Eat 2+ servings of whole fruits or green vegetables on 5 days this week.',
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
        description: 'Step on the scale upon waking 5 mornings this week for clean trend estimation.',
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

    // Return exactly the top 2 highest-priority habit challenges
    return candidates.take(2).toList();
  }
}
