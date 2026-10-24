import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/workout_session.dart';

void main() {
  group('AppDatabase Workout Sessions DAO Tests', () {
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

    WorkoutSession createTestSession({
      required String id,
      String source = WorkoutSource.hevy,
      String title = 'Upper Body A',
      DateTime? startTime,
      DateTime? endTime,
      int durationMinutes = 60,
      double caloriesBurned = 350.0,
      String? notes = 'Chest & Triceps focus',
      DateTime? createdAt,
    }) {
      final start = startTime ?? DateTime(2026, 10, 15, 10, 0);
      final end = endTime ?? start.add(Duration(minutes: durationMinutes));
      return WorkoutSession(
        id: id,
        source: source,
        title: title,
        startTime: start,
        endTime: end,
        durationMinutes: durationMinutes,
        caloriesBurned: caloriesBurned,
        notes: notes,
        createdAt: createdAt ?? start,
      );
    }

    test('Initial state returns empty workout sessions list', () {
      final sessions = appDb.getAllWorkoutSessions();
      expect(sessions, isEmpty);
    });

    test('Inserts single workout session and retrieves with all fields intact',
        () {
      final start = DateTime(2026, 10, 16, 9, 30);
      final end = DateTime(2026, 10, 16, 10, 45);
      final created = DateTime(2026, 10, 16, 10, 50);

      final session = WorkoutSession(
        id: 'hevy_sess_001',
        source: WorkoutSource.hevy,
        title: 'Push Day Hypertrophy',
        startTime: start,
        endTime: end,
        durationMinutes: 75,
        caloriesBurned: 420.5,
        notes: 'Incline DB Press 36kg 3x8, Lateral raises',
        createdAt: created,
      );

      appDb.insertWorkoutSessions([session]);

      final all = appDb.getAllWorkoutSessions();
      expect(all.length, equals(1));

      final retrieved = all.first;
      expect(retrieved.id, equals('hevy_sess_001'));
      expect(retrieved.source, equals(WorkoutSource.hevy));
      expect(retrieved.title, equals('Push Day Hypertrophy'));
      expect(retrieved.startTime, equals(start));
      expect(retrieved.endTime, equals(end));
      expect(retrieved.durationMinutes, equals(75));
      expect(retrieved.caloriesBurned, equals(420.5));
      expect(
          retrieved.notes, equals('Incline DB Press 36kg 3x8, Lateral raises'));
      expect(retrieved.isHevy, isTrue);
      expect(retrieved.isHealthConnect, isFalse);
    });

    test(
        'getAllWorkoutSessions returns records sorted chronologically descending',
        () {
      final s1 = createTestSession(
        id: 'w_older',
        startTime: DateTime(2026, 10, 10, 8, 0),
        title: 'Old Session',
      );
      final s2 = createTestSession(
        id: 'w_newest',
        startTime: DateTime(2026, 10, 17, 8, 0),
        title: 'Newest Session',
      );
      final s3 = createTestSession(
        id: 'w_middle',
        startTime: DateTime(2026, 10, 14, 8, 0),
        title: 'Middle Session',
      );

      appDb.insertWorkoutSessions([s1, s2, s3]);

      final all = appDb.getAllWorkoutSessions();
      expect(all.length, equals(3));
      expect(all[0].id, equals('w_newest'));
      expect(all[1].id, equals('w_middle'));
      expect(all[2].id, equals('w_older'));
    });

    test(
        'insertWorkoutSessions upserts idempotently without duplicates on re-sync',
        () {
      final initial = createTestSession(
        id: 'hevy_sync_repeat',
        title: 'Initial Workout Title',
        durationMinutes: 45,
        caloriesBurned: 250.0,
        notes: 'Initial notes',
      );

      appDb.insertWorkoutSessions([initial]);
      expect(appDb.getAllWorkoutSessions().length, equals(1));

      // Re-sync with modified calories, duration, and title
      final updated = createTestSession(
        id: 'hevy_sync_repeat',
        title: 'Updated Workout Title',
        durationMinutes: 60,
        caloriesBurned: 380.0,
        notes: 'Updated notes after sync completion',
      );

      appDb.insertWorkoutSessions([updated]);

      final all = appDb.getAllWorkoutSessions();
      expect(all.length, equals(1)); // Still 1 record
      expect(all.first.title, equals('Updated Workout Title'));
      expect(all.first.durationMinutes, equals(60));
      expect(all.first.caloriesBurned, equals(380.0));
      expect(all.first.notes, equals('Updated notes after sync completion'));
    });

    test('deleteWorkoutSession removes targeted session cleanly', () {
      final s1 = createTestSession(id: 'del_1');
      final s2 = createTestSession(id: 'keep_2');
      appDb.insertWorkoutSessions([s1, s2]);

      expect(appDb.getAllWorkoutSessions().length, equals(2));

      appDb.deleteWorkoutSession('del_1');

      final remaining = appDb.getAllWorkoutSessions();
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('keep_2'));
    });

    test('deleteWorkoutSession handles non-existent ID gracefully', () {
      final s = createTestSession(id: 'keep_1');
      appDb.insertWorkoutSessions([s]);

      expect(
          () => appDb.deleteWorkoutSession('non_existent_id'), returnsNormally);
      expect(appDb.getAllWorkoutSessions().length, equals(1));
    });

    test(
        'getWorkoutSessionsInRange filters within boundary timestamps inclusive',
        () {
      final s1 = createTestSession(
        id: 'before_range',
        startTime: DateTime(2026, 10, 1, 10, 0),
      );
      final s2 = createTestSession(
        id: 'at_start_bound',
        startTime: DateTime(2026, 10, 10, 0, 0),
      );
      final s3 = createTestSession(
        id: 'inside_range',
        startTime: DateTime(2026, 10, 12, 14, 0),
      );
      final s4 = createTestSession(
        id: 'at_end_bound',
        startTime: DateTime(2026, 10, 15, 23, 59, 59),
      );
      final s5 = createTestSession(
        id: 'after_range',
        startTime: DateTime(2026, 10, 16, 0, 0),
      );

      appDb.insertWorkoutSessions([s1, s2, s3, s4, s5]);

      final rangeResults = appDb.getWorkoutSessionsInRange(
        DateTime(2026, 10, 10, 0, 0),
        DateTime(2026, 10, 15, 23, 59, 59),
      );

      final ids = rangeResults.map((e) => e.id).toList();
      expect(ids.length, equals(3));
      expect(
          ids, containsAll(['at_start_bound', 'inside_range', 'at_end_bound']));
      expect(ids, isNot(contains('before_range')));
      expect(ids, isNot(contains('after_range')));
    });

    test('getWorkoutSessionsInRange with inverted dates returns empty list',
        () {
      final s =
          createTestSession(id: 's_test', startTime: DateTime(2026, 10, 12));
      appDb.insertWorkoutSessions([s]);

      final results = appDb.getWorkoutSessionsInRange(
        DateTime(2026, 10, 15),
        DateTime(2026, 10, 10),
      );
      expect(results, isEmpty);
    });

    test('Handles nullable notes and zero duration/calories edge cases', () {
      final edgeSession = WorkoutSession(
        id: 'edge_null_notes',
        source: WorkoutSource.manual,
        title: 'Zero Calorie Mobility Drill',
        startTime: DateTime(2026, 10, 15, 7, 0),
        endTime: DateTime(2026, 10, 15, 7, 0),
        durationMinutes: 0,
        caloriesBurned: 0.0,
        notes: null,
        createdAt: DateTime(2026, 10, 15, 7, 1),
      );

      appDb.insertWorkoutSessions([edgeSession]);

      final loaded = appDb.getAllWorkoutSessions().first;
      expect(loaded.notes, isNull);
      expect(loaded.durationMinutes, equals(0));
      expect(loaded.caloriesBurned, equals(0.0));
    });

    test(
        'Handles unicode, emoji, and special characters in workout title and notes',
        () {
      final unicodeSession = WorkoutSession(
        id: 'unicode_001',
        source: WorkoutSource.hevy,
        title: 'Heavy Deadlifts 🏋️‍♂️ & Core व्यायाम',
        startTime: DateTime(2026, 10, 15, 18, 0),
        endTime: DateTime(2026, 10, 15, 19, 15),
        durationMinutes: 75,
        caloriesBurned: 520.0,
        notes:
            'PR 180kg x 3! 🔥 Feeling unstoppable. "Quotes" & symbols: 100% & <fast>',
        createdAt: DateTime(2026, 10, 15, 19, 20),
      );

      appDb.insertWorkoutSessions([unicodeSession]);

      final loaded = appDb.getAllWorkoutSessions().first;
      expect(loaded.title, equals('Heavy Deadlifts 🏋️‍♂️ & Core व्यायाम'));
      expect(loaded.notes, contains('PR 180kg x 3! 🔥'));
      expect(loaded.notes, contains('"Quotes" & symbols: 100% & <fast>'));
    });

    test('Batch insertion of 50 sessions executes atomically and accurately',
        () {
      final batch = List.generate(50, (index) {
        return createTestSession(
          id: 'batch_sess_$index',
          title: 'Workout #$index',
          startTime: DateTime(2026, 9, 1).add(Duration(days: index, hours: 8)),
          durationMinutes: 45 + (index % 30),
          caloriesBurned: 250.0 + (index * 5.0),
        );
      });

      appDb.insertWorkoutSessions(batch);

      final all = appDb.getAllWorkoutSessions();
      expect(all.length, equals(50));
      // First is newest (index 49)
      expect(all.first.id, equals('batch_sess_49'));
      // Last is oldest (index 0)
      expect(all.last.id, equals('batch_sess_0'));
    });

    test('In-memory SQLite isolation: independent instances do not leak data',
        () {
      final db2 = AppDatabase(sqlite3.openInMemory());
      db2.initUserTables();

      final s = createTestSession(id: 'iso_db1');
      appDb.insertWorkoutSessions([s]);

      expect(appDb.getAllWorkoutSessions().length, equals(1));
      expect(db2.getAllWorkoutSessions(), isEmpty);

      db2.close();
    });
  });
}
