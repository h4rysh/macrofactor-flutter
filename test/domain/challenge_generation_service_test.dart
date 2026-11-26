import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/dao/challenges_dao.dart';
import 'package:sique/domain/algorithms/challenge_generation_service.dart';
import 'package:sique/domain/models/weekly_challenge_model.dart';

void main() {
  group('ChallengeGenerationService - Deficit-Mined Habit Generation', () {
    final now = DateTime.now();

    test('Generates protein and fiber challenges when both show deficits', () {
      const metrics = MinedDeficitMetrics(
        totalLoggedDays: 7,
        proteinHitDays: 2, // deficit (< 5)
        avgFiberG: 14.5, // deficit (< 22.0)
        produceDays: 5,
        weighInDays: 6,
        avgHydrationMl: 2600,
      );

      final challenges = ChallengeGenerationService.generateWeeklyChallenges(
        metrics: metrics,
        weekStart: now,
        proteinTargetG: 160.0,
      );

      expect(challenges.length, 2);
      expect(challenges[0].type, ChallengeType.proteinAnchor);
      expect(challenges[0].title, contains('160g'));
      expect(challenges[1].type, ChallengeType.fiberBuilder);
    });

    test(
        'Generates produce and hydration challenges when protein and fiber are optimal',
        () {
      const metrics = MinedDeficitMetrics(
        totalLoggedDays: 7,
        proteinHitDays: 6,
        avgFiberG: 28.0,
        produceDays: 1, // deficit (< 4)
        weighInDays: 7,
        avgHydrationMl: 1400, // deficit (< 2000)
      );

      final challenges = ChallengeGenerationService.generateWeeklyChallenges(
        metrics: metrics,
        weekStart: now,
      );

      expect(challenges.length, 2);
      expect(challenges[0].type, ChallengeType.produceBooster);
      expect(challenges[1].type, ChallengeType.hydrationHero);
    });

    test(
        'Fallback: Returns 2 mastery challenges when user meets all deficit thresholds',
        () {
      const metrics = MinedDeficitMetrics(
        totalLoggedDays: 7,
        proteinHitDays: 7,
        avgFiberG: 32.0,
        produceDays: 7,
        weighInDays: 7,
        avgHydrationMl: 3000,
      );

      final challenges = ChallengeGenerationService.generateWeeklyChallenges(
        metrics: metrics,
        weekStart: now,
      );

      expect(challenges.length, 2);
      expect(challenges[0].type, ChallengeType.proteinAnchor);
      expect(challenges[1].type, ChallengeType.produceBooster);
    });
  });
}
