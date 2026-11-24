import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/body_measurement_entry.dart';
import 'package:sique/domain/models/lifestyle_models.dart';
import 'package:sique/domain/models/weekly_challenge_model.dart';

void main() {
  group('Lifestyle DAOs Integration Tests', () {
    late Database rawDb;
    late AppDatabase appDb;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      appDb = AppDatabase(rawDb);
      appDb.initUserTables();
    });

    tearDown(() {
      rawDb.dispose();
    });

    group('BodyMeasurementsDao', () {
      test('Upserts, retrieves, and deletes body measurements', () {
        final now = DateTime.now();
        final entry = BodyMeasurementEntry(
          id: 'bm_test_1',
          userId: 'test_user',
          date: now,
          waistCm: 84.5,
          neckCm: 39.0,
          hipsCm: 98.0,
          chestCm: 102.0,
          bodyFatPct: 20.2,
          loggedAt: now,
        );

        appDb.bodyMeasurementsDao.upsertMeasurement(entry);

        final retrieved = appDb.bodyMeasurementsDao.getMeasurementForDate(now, userId: 'test_user');
        expect(retrieved, isNotNull);
        expect(retrieved!.waistCm, 84.5);
        expect(retrieved.neckCm, 39.0);
        expect(retrieved.hipsCm, 98.0);
        expect(retrieved.bodyFatPct, 20.2);

        final recents = appDb.bodyMeasurementsDao.getRecentMeasurements(limit: 10, userId: 'test_user');
        expect(recents.length, 1);
        expect(recents.first.id, 'bm_test_1');

        appDb.bodyMeasurementsDao.deleteMeasurement('bm_test_1', userId: 'test_user');
        final afterDelete = appDb.bodyMeasurementsDao.getRecentMeasurements(limit: 10, userId: 'test_user');
        expect(afterDelete, isEmpty);
      });
    });

    group('ChallengesDao', () {
      test('Upserts challenge, records daily progress, and updates status', () {
        final now = DateTime.now();
        final challenge = WeeklyChallengeModel(
          id: 'chk_test_1',
          userId: 'test_user',
          type: ChallengeType.proteinAnchor,
          title: 'Protein Anchor',
          description: 'Hit 150g protein on 5 days',
          targetMetric: 'days_hit',
          targetValue: 5.0,
          currentValue: 0.0,
          unit: 'days',
          status: ChallengeStatus.active,
          weekStartDate: now,
          weekEndDate: now.add(const Duration(days: 7)),
          createdAt: now,
        );

        appDb.challengesDao.upsertChallenge(challenge);

        final active = appDb.challengesDao.getActiveChallenges(userId: 'test_user');
        expect(active.length, 1);
        expect(active.first.title, 'Protein Anchor');

        // Update progress
        appDb.challengesDao.updateChallengeProgress(
          'chk_test_1',
          3.0,
          userId: 'test_user',
        );

        final updated = appDb.challengesDao.getActiveChallenges(userId: 'test_user').first;
        expect(updated.currentValue, 3.0);
        expect(updated.progressFraction, 0.60);

        // Record daily progress
        appDb.challengesDao.recordDailyProgress('chk_test_1', '2026-11-24', 155.0, true);

        // Complete challenge
        appDb.challengesDao.updateChallengeStatus(
          'chk_test_1',
          ChallengeStatus.completed,
          completedAt: DateTime.now(),
          userId: 'test_user',
        );

        final activeAfter = appDb.challengesDao.getActiveChallenges(userId: 'test_user');
        expect(activeAfter, isEmpty);

        final history = appDb.challengesDao.getChallengeHistory(userId: 'test_user');
        expect(history.length, 1);
        expect(history.first.status, ChallengeStatus.completed);
      });

      test('mineDeficitMetrics runs query without error on empty or populated logs', () {
        final metrics = appDb.challengesDao.mineDeficitMetrics(
          proteinTargetG: 140.0,
          userId: 'test_user',
        );

        expect(metrics, isNotNull);
        expect(metrics.proteinHitDays, 0);
        expect(metrics.avgHydrationMl, 0);
        expect(metrics.weighInDays, 0);
      });
    });

    group('WaterDao', () {
      test('Logs water intake, aggregates daily total, and resets day', () {
        final now = DateTime.now();

        appDb.waterDao.logWater(500, date: now, userId: 'test_user');
        appDb.waterDao.logWater(750, date: now, userId: 'test_user');

        final total = appDb.waterDao.getDailyWaterMl(now, userId: 'test_user');
        expect(total, 1250);

        final entries = appDb.waterDao.getWaterEntriesForDate(now, userId: 'test_user');
        expect(entries.length, 2);

        appDb.waterDao.clearDayWater(now, userId: 'test_user');
        final totalAfter = appDb.waterDao.getDailyWaterMl(now, userId: 'test_user');
        expect(totalAfter, 0);
      });
    });

    group('FastingDao', () {
      test('Starts, inspects, and ends an intermittent fasting session', () {
        final start = DateTime.now().subtract(const Duration(hours: 14));
        final targetEnd = start.add(const Duration(hours: 16));

        final session = FastingSession(
          id: 'fast_test_1',
          userId: 'test_user',
          protocol: FastingProtocol.f16_8,
          startTime: start,
          targetEndTime: targetEnd,
          state: 'active',
        );

        appDb.fastingDao.startFast(session);

        final active = appDb.fastingDao.getActiveFast(userId: 'test_user');
        expect(active, isNotNull);
        expect(active!.id, 'fast_test_1');
        expect(active.protocol, FastingProtocol.f16_8);

        appDb.fastingDao.endFast('fast_test_1', completed: true, userId: 'test_user');

        final activeAfter = appDb.fastingDao.getActiveFast(userId: 'test_user');
        expect(activeAfter, isNull);

        final recents = appDb.fastingDao.getRecentFasts(limit: 5, userId: 'test_user');
        expect(recents.length, 1);
        expect(recents.first.state, 'completed');
        expect(recents.first.actualEndTime, isNotNull);
      });
    });
  });
}
