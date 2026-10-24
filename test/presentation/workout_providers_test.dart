import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/workout_session.dart';
import 'package:sique/presentation/providers/app_providers.dart';

void main() {
  group('Workout Riverpod Providers Reactive Logic Tests', () {
    late Database rawDb;
    late AppDatabase appDb;
    late ProviderContainer container;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      appDb = AppDatabase(rawDb);
      appDb.initUserTables();

      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(appDb),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      rawDb.dispose();
    });

    WorkoutSession createSession({
      required String id,
      String source = WorkoutSource.hevy,
      String title = 'Leg Day',
      DateTime? startTime,
      int durationMinutes = 60,
      double caloriesBurned = 400.0,
      String? notes,
    }) {
      final start = startTime ?? DateTime.now();
      return WorkoutSession(
        id: id,
        source: source,
        title: title,
        startTime: start,
        endTime: start.add(Duration(minutes: durationMinutes)),
        durationMinutes: durationMinutes,
        caloriesBurned: caloriesBurned,
        notes: notes,
        createdAt: start,
      );
    }

    test('Fresh install starts with empty sessions and empty stats', () {
      final sessions = container.read(workoutSessionsProvider);
      expect(sessions, isEmpty);

      final stats = container.read(workoutStatsProvider);
      expect(stats.totalWorkouts, equals(0));
      expect(stats.hevyWorkoutsCount, equals(0));
      expect(stats.totalDurationMinutes, equals(0));
      expect(stats.averageDurationMinutes, equals(0.0));
      expect(stats.totalCaloriesBurned, equals(0.0));
      expect(stats.weeklyFrequency, equals(0.0));
      expect(stats.recentWorkouts, isEmpty);
      expect(container.read(hevyWorkoutsCountProvider), equals(0));
      expect(container.read(recentWorkoutsProvider), isEmpty);
    });

    test('Loads pre-existing SQLite workout sessions upon startup', () {
      appDb.insertWorkoutSessions([
        createSession(id: 'pre_1', title: 'Session A', durationMinutes: 50),
        createSession(id: 'pre_2', title: 'Session B', durationMinutes: 70),
      ]);

      final preContainer = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(appDb)],
      );
      addTearDown(preContainer.dispose);

      final sessions = preContainer.read(workoutSessionsProvider);
      expect(sessions.length, equals(2));

      final stats = preContainer.read(workoutStatsProvider);
      expect(stats.totalWorkouts, equals(2));
      expect(stats.totalDurationMinutes, equals(120));
      expect(stats.averageDurationMinutes, equals(60.0));
    });

    test(
        'addSession persists to SQLite and reactively updates derived workoutStatsProvider',
        () {
      final notifier = container.read(workoutSessionsProvider.notifier);

      final hevyWorkout = createSession(
        id: 'w_hevy_1',
        source: WorkoutSource.hevy,
        title: 'Upper Body Blast',
        durationMinutes: 60,
        caloriesBurned: 450.0,
      );

      notifier.addSession(hevyWorkout);

      final sessions = container.read(workoutSessionsProvider);
      expect(sessions.length, equals(1));
      expect(sessions.first.id, equals('w_hevy_1'));

      final stats = container.read(workoutStatsProvider);
      expect(stats.totalWorkouts, equals(1));
      expect(stats.hevyWorkoutsCount, equals(1));
      expect(stats.totalDurationMinutes, equals(60));
      expect(stats.averageDurationMinutes, equals(60.0));
      expect(stats.totalCaloriesBurned, equals(450.0));
      expect(stats.averageCaloriesBurned, equals(450.0));
      expect(container.read(hevyWorkoutsCountProvider), equals(1));
      expect(container.read(recentWorkoutsProvider).length, equals(1));
    });

    test(
        'Adding Health Connect workout updates totalWorkouts but NOT hevyWorkoutsCount',
        () {
      final notifier = container.read(workoutSessionsProvider.notifier);

      notifier.addSession(createSession(
        id: 'w_hc_run',
        source: WorkoutSource.healthConnect,
        title: 'Outdoor Running',
        durationMinutes: 40,
        caloriesBurned: 350.0,
      ));

      final stats = container.read(workoutStatsProvider);
      expect(stats.totalWorkouts, equals(1));
      expect(stats.hevyWorkoutsCount, equals(0)); // Non-Hevy
      expect(stats.totalDurationMinutes, equals(40));
      expect(container.read(hevyWorkoutsCountProvider), equals(0));
    });

    test(
        'deleteSession removes session and reactively recalculates stats downwards',
        () {
      final notifier = container.read(workoutSessionsProvider.notifier);

      final s1 = createSession(
          id: 'del_s1', durationMinutes: 60, caloriesBurned: 400.0);
      final s2 = createSession(
          id: 'del_s2', durationMinutes: 30, caloriesBurned: 200.0);
      notifier.addSessions([s1, s2]);

      expect(container.read(workoutStatsProvider).totalWorkouts, equals(2));
      expect(container.read(workoutStatsProvider).totalDurationMinutes,
          equals(90));

      notifier.deleteSession('del_s1');

      final updatedSessions = container.read(workoutSessionsProvider);
      expect(updatedSessions.length, equals(1));
      expect(updatedSessions.first.id, equals('del_s2'));

      final updatedStats = container.read(workoutStatsProvider);
      expect(updatedStats.totalWorkouts, equals(1));
      expect(updatedStats.totalDurationMinutes, equals(30));
      expect(updatedStats.averageDurationMinutes, equals(30.0));
      expect(updatedStats.totalCaloriesBurned, equals(200.0));
    });

    test(
        'recentWorkoutsProvider caps at 10 sessions and sorts descending by start time',
        () {
      final notifier = container.read(workoutSessionsProvider.notifier);

      final sessions = List.generate(15, (i) {
        return createSession(
          id: 'recent_$i',
          title: 'Session #$i',
          startTime: DateTime(2026, 10, 1).add(Duration(days: i)),
        );
      });

      notifier.addSessions(sessions);

      final recent = container.read(recentWorkoutsProvider);
      expect(recent.length, equals(10)); // Capped at 10
      expect(recent.first.id, equals('recent_14')); // Newest first
      expect(recent.last.id, equals('recent_5'));
    });

    test('getSessionsInRange returns sessions within custom window', () {
      final notifier = container.read(workoutSessionsProvider.notifier);

      notifier.addSessions([
        createSession(id: 'in_1', startTime: DateTime(2026, 10, 5)),
        createSession(id: 'in_2', startTime: DateTime(2026, 10, 10)),
        createSession(id: 'in_3', startTime: DateTime(2026, 10, 15)),
      ]);

      final inRange = notifier.getSessionsInRange(
        DateTime(2026, 10, 8),
        DateTime(2026, 10, 12),
      );

      expect(inRange.length, equals(1));
      expect(inRange.first.id, equals('in_2'));
    });
  });
}
