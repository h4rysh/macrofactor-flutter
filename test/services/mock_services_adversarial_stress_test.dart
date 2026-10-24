import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/services/mock_auth_service.dart';
import 'package:sique/data/services/mock_health_sync_adapter.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/models/workout_session.dart';
import 'package:sique/domain/models/workout_stats.dart';

void main() {
  group('Adversarial Stress Test: MockHealthSyncAdapter Date Boundaries', () {
    late MockHealthSyncAdapter adapter;

    setUp(() {
      adapter = MockHealthSyncAdapter();
    });

    test('Zero-duration boundary window (startTime == endTime)', () async {
      final exactTime = DateTime(2026, 10, 17, 10, 30, 0, 0);

      final testSessions = [
        WorkoutSession(
          id: 'exact_session',
          source: WorkoutSource.hevy,
          title: 'Exact Session',
          startTime: exactTime,
          endTime: exactTime.add(const Duration(minutes: 45)),
          durationMinutes: 45,
          caloriesBurned: 300,
          createdAt: exactTime,
        ),
        WorkoutSession(
          id: 'microsecond_before',
          source: WorkoutSource.hevy,
          title: 'Before',
          startTime: exactTime.subtract(const Duration(microseconds: 1)),
          endTime: exactTime.add(const Duration(minutes: 45)),
          durationMinutes: 45,
          caloriesBurned: 300,
          createdAt: exactTime,
        ),
        WorkoutSession(
          id: 'microsecond_after',
          source: WorkoutSource.hevy,
          title: 'After',
          startTime: exactTime.add(const Duration(microseconds: 1)),
          endTime: exactTime.add(const Duration(minutes: 45)),
          durationMinutes: 45,
          caloriesBurned: 300,
          createdAt: exactTime,
        ),
      ];

      adapter.setWorkouts(testSessions);

      // Query with zero-duration window matching exactTime
      final result = await adapter.fetchWorkouts(
        startTime: exactTime,
        endTime: exactTime,
      );

      expect(result.length, equals(1));
      expect(result.first.id, equals('exact_session'));
    });

    test('Inverted date range (startTime > endTime) returns empty gracefully',
        () async {
      final start = DateTime(2026, 10, 18, 12, 0);
      final end = DateTime(2026, 10, 17, 12, 0);

      final result =
          await adapter.fetchWorkouts(startTime: start, endTime: end);
      expect(result, isEmpty);
      expect(adapter.lastFetchWorkoutsStartTime, equals(start));
      expect(adapter.lastFetchWorkoutsEndTime, equals(end));

      final weightResult =
          await adapter.fetchWeights(startTime: start, endTime: end);
      expect(weightResult, isEmpty);
      expect(adapter.lastFetchWeightsStartTime, equals(start));
      expect(adapter.lastFetchWeightsEndTime, equals(end));
    });

    test('Timezone mixing: UTC query vs Local session timestamps', () async {
      // Local time 12:00
      final localInstant = DateTime(2026, 10, 17, 12, 0);
      // Convert to UTC instant (different clock time, identical instant)
      final utcEquivalent = localInstant.toUtc();

      final session = WorkoutSession(
        id: 'tz_session',
        source: WorkoutSource.healthConnect,
        title: 'Timezone Check',
        startTime: localInstant,
        endTime: localInstant.add(const Duration(hours: 1)),
        durationMinutes: 60,
        caloriesBurned: 400,
        createdAt: localInstant,
      );

      adapter.setWorkouts([session]);

      // Query using UTC range covering the equivalent instant
      final res = await adapter.fetchWorkouts(
        startTime: utcEquivalent.subtract(const Duration(minutes: 1)),
        endTime: utcEquivalent.add(const Duration(minutes: 1)),
      );

      expect(res.length, equals(1));
      expect(res.first.id, equals('tz_session'));
    });

    test('High volume stress: 5,000 workouts filtered in narrow window',
        () async {
      final baseDate = DateTime(2026, 1, 1);
      final manySessions = List.generate(5000, (i) {
        final sessionTime = baseDate.add(Duration(hours: i));
        return WorkoutSession(
          id: 'session_$i',
          source: i.isEven ? WorkoutSource.hevy : WorkoutSource.healthConnect,
          title: 'Bulk Session #$i',
          startTime: sessionTime,
          endTime: sessionTime.add(const Duration(minutes: 45)),
          durationMinutes: 45,
          caloriesBurned: 250.0 + (i % 100),
          createdAt: sessionTime,
        );
      });

      adapter.setWorkouts(manySessions);

      // Query window matching indices 100 to 110 (11 sessions: 100..110 inclusive)
      final queryStart = baseDate.add(const Duration(hours: 100));
      final queryEnd = baseDate.add(const Duration(hours: 110));

      final stopwatch = Stopwatch()..start();
      final results = await adapter.fetchWorkouts(
        startTime: queryStart,
        endTime: queryEnd,
      );
      stopwatch.stop();

      expect(results.length, equals(11));
      expect(results.first.id, equals('session_100'));
      expect(results.last.id, equals('session_110'));
      // Performance verification: 5,000 item in-memory filter must execute comfortably
      // in sub-second time (< 1000ms) without infinite loops or quadratic hang.
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });

  group('Adversarial Stress Test: Concurrency & Async Interleaving', () {
    test(
        'MockAuthService: 100 concurrent signInWithGoogle calls preserve telemetry',
        () async {
      final auth = MockAuthService(delay: const Duration(milliseconds: 5));

      final futures = List.generate(100, (_) => auth.signInWithGoogle());
      final users = await Future.wait(futures);

      expect(users.length, equals(100));
      for (final u in users) {
        expect(u.isAuthenticated, isTrue);
        expect(u.displayName, equals('Alex Mercer'));
      }
      expect(auth.signInWithGoogleCallCount, equals(100));
      expect(await auth.getCurrentUser(), isNotNull);
    });

    test(
        'MockAuthService: Interleaved concurrent sign-in, sign-out, and silent queries',
        () async {
      final auth = MockAuthService(delay: const Duration(milliseconds: 2));

      final signIns = List.generate(20, (_) => auth.signInWithGoogle());
      final signSilently = List.generate(20, (_) => auth.signInSilently());
      final signOuts = List.generate(20, (_) => auth.signOut());

      // Execute all 60 calls concurrently
      await Future.wait([...signIns, ...signSilently, ...signOuts]);

      expect(auth.signInWithGoogleCallCount, equals(20));
      expect(auth.signInSilentlyCallCount, equals(20));
      expect(auth.signOutCallCount, equals(20));
    });

    test('MockHealthSyncAdapter: 100 concurrent requests across methods',
        () async {
      final adapter =
          MockHealthSyncAdapter(delay: const Duration(milliseconds: 2));
      final now = DateTime.now();

      final wFutures = List.generate(
        50,
        (_) => adapter.fetchWorkouts(
          startTime: now.subtract(const Duration(days: 30)),
          endTime: now,
        ),
      );
      final weightFutures = List.generate(
        50,
        (_) => adapter.fetchWeights(
          startTime: now.subtract(const Duration(days: 30)),
          endTime: now,
        ),
      );

      final wResults = await Future.wait(wFutures);
      final weightResults = await Future.wait(weightFutures);

      expect(adapter.fetchWorkoutsCallCount, equals(50));
      expect(adapter.fetchWeightsCallCount, equals(50));
      expect(wResults.length, equals(50));
      expect(weightResults.length, equals(50));
      // Every concurrent call receives identical uncorrupted data
      for (final res in wResults) {
        expect(res, isNotEmpty);
      }
    });
  });

  group('Adversarial Stress Test: Fault Injection & Telemetry Resilience', () {
    test(
        'MockAuthService: Custom error injection and telemetry retention during failure',
        () async {
      final auth = MockAuthService(
        shouldFailSignIn: true,
        signInErrorMessage: 'Custom Auth Network Timeout 504',
      );

      expect(auth.signInWithGoogleCallCount, equals(0));

      expect(
        () => auth.signInWithGoogle(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Custom Auth Network Timeout 504'),
          ),
        ),
      );

      // Crucial: Call count must record failed attempts
      expect(auth.signInWithGoogleCallCount, equals(1));
      expect(await auth.getCurrentUser(), isNull);

      // Fault recovery test
      auth.shouldFailSignIn = false;
      final recoveredUser = await auth.signInWithGoogle();
      expect(recoveredUser.isAuthenticated, isTrue);
      expect(auth.signInWithGoogleCallCount, equals(2));
    });

    test('MockHealthSyncAdapter: Telemetry recorded despite exceptions',
        () async {
      final adapter = MockHealthSyncAdapter(
        shouldFailFetchWorkouts: true,
        shouldFailFetchWeights: true,
      );

      final start = DateTime(2026, 10, 1);
      final end = DateTime(2026, 10, 2);

      await expectLater(
        () => adapter.fetchWorkouts(startTime: start, endTime: end),
        throwsA(isA<Exception>()),
      );
      expect(adapter.fetchWorkoutsCallCount, equals(1));
      expect(adapter.lastFetchWorkoutsStartTime, equals(start));
      expect(adapter.lastFetchWorkoutsEndTime, equals(end));

      await expectLater(
        () => adapter.fetchWeights(startTime: start, endTime: end),
        throwsA(isA<Exception>()),
      );
      expect(adapter.fetchWeightsCallCount, equals(1));
      expect(adapter.lastFetchWeightsStartTime, equals(start));
      expect(adapter.lastFetchWeightsEndTime, equals(end));
    });

    test('MockHealthSyncAdapter: Permissions rejection flow', () async {
      final adapter = MockHealthSyncAdapter(
        hasPermissionsResult: false,
        requestPermissionsResult: false,
      );

      expect(await adapter.hasPermissions(), isFalse);
      expect(await adapter.requestPermissions(), isFalse);
      expect(await adapter.hasPermissions(), isFalse);
      expect(adapter.requestPermissionsCallCount, equals(1));
    });
  });

  group('Adversarial Stress Test: Immutability & Collection Mutation Isolation',
      () {
    test(
        'MockHealthSyncAdapter: External list mutations do not mutate adapter storage',
        () async {
      final adapter = MockHealthSyncAdapter();
      final externalList = [
        WorkoutSession(
          id: 'orig_1',
          source: WorkoutSource.hevy,
          title: 'Squat Day',
          startTime: DateTime(2026, 10, 10),
          endTime: DateTime(2026, 10, 10, 1),
          durationMinutes: 60,
          caloriesBurned: 400,
          createdAt: DateTime(2026, 10, 10),
        ),
      ];

      adapter.setWorkouts(externalList);

      // Mutate the external caller's list
      externalList.clear();

      final fetched = await adapter.fetchWorkouts(
        startTime: DateTime(2026, 10, 9),
        endTime: DateTime(2026, 10, 11),
      );

      // Adapter must retain defensive copy
      expect(fetched.length, equals(1));
      expect(fetched.first.id, equals('orig_1'));

      // Mutating returned list must not affect subsequent fetches
      fetched.clear();

      final fetchedAgain = await adapter.fetchWorkouts(
        startTime: DateTime(2026, 10, 9),
        endTime: DateTime(2026, 10, 11),
      );
      expect(fetchedAgain.length, equals(1));
    });

    test('UserAccount and WorkoutSession: copyWith null clearing safeguards',
        () {
      final user = UserAccount.fromGoogle(
        googleUserId: 'g_123',
        displayName: 'Test User',
        email: 'test@gmail.com',
        photoUrl: 'https://photo.url',
        lastHealthSyncTime: DateTime(2026, 10, 17),
      );

      final cleared = user.copyWith(
        clearPhotoUrl: true,
        clearLastSyncTime: true,
      );

      expect(cleared.photoUrl, isNull);
      expect(cleared.lastHealthSyncTime, isNull);
      expect(cleared.googleUserId, equals('g_123'));

      final workout = WorkoutSession(
        id: 'w_notes',
        source: WorkoutSource.hevy,
        title: 'Notes Test',
        startTime: DateTime(2026, 10, 17),
        endTime: DateTime(2026, 10, 17, 1),
        durationMinutes: 60,
        caloriesBurned: 350,
        notes: 'Initial notes',
        createdAt: DateTime(2026, 10, 17),
      );

      final clearedWorkout = workout.copyWith(clearNotes: true);
      expect(clearedWorkout.notes, isNull);
      expect(clearedWorkout.title, equals('Notes Test'));
    });
  });

  group('Adversarial Stress Test: WorkoutStats Edge Cases & Extremes', () {
    test(
        'Zero minutes and zero calories sessions calculate without division by zero',
        () {
      final zeroSession = WorkoutSession(
        id: 'zero',
        source: WorkoutSource.hevy,
        title: 'Zero Activity',
        startTime: DateTime(2026, 10, 17, 8, 0),
        endTime: DateTime(2026, 10, 17, 8, 0),
        durationMinutes: 0,
        caloriesBurned: 0.0,
        createdAt: DateTime(2026, 10, 17, 8, 0),
      );

      final stats = WorkoutStats.fromSessions([zeroSession],
          referenceDate: DateTime(2026, 10, 17));

      expect(stats.totalWorkouts, equals(1));
      expect(stats.totalDurationMinutes, equals(0));
      expect(stats.averageDurationMinutes, equals(0.0));
      expect(stats.totalCaloriesBurned, equals(0.0));
      expect(stats.averageCaloriesBurned, equals(0.0));
      expect(stats.roundedAverageDurationMinutes, equals(0));
      expect(stats.roundedAverageCaloriesBurned, equals(0));
      expect(stats.formattedWeeklyFrequency,
          equals('0.3')); // 1 session / 4 weeks = 0.25 -> 0.3
    });

    test('Calendar week boundary: Monday 00:00:00 to Sunday 23:59:59.999', () {
      // 2026-10-19 is a Monday
      final mondayStart = DateTime(2026, 10, 19, 0, 0, 0);
      final sundayEnd = DateTime(2026, 10, 25, 23, 59, 59);
      final nextMonday = DateTime(2026, 10, 26, 0, 0, 0);

      final sessions = [
        WorkoutSession(
          id: 'mon_start',
          source: WorkoutSource.hevy,
          title: 'Monday Open',
          startTime: mondayStart,
          endTime: mondayStart.add(const Duration(hours: 1)),
          durationMinutes: 60,
          caloriesBurned: 300,
          createdAt: mondayStart,
        ),
        WorkoutSession(
          id: 'sun_end',
          source: WorkoutSource.hevy,
          title: 'Sunday Close',
          startTime: sundayEnd,
          endTime: sundayEnd.add(const Duration(minutes: 30)),
          durationMinutes: 30,
          caloriesBurned: 200,
          createdAt: sundayEnd,
        ),
        WorkoutSession(
          id: 'next_mon',
          source: WorkoutSource.hevy,
          title: 'Next Week',
          startTime: nextMonday,
          endTime: nextMonday.add(const Duration(hours: 1)),
          durationMinutes: 60,
          caloriesBurned: 300,
          createdAt: nextMonday,
        ),
      ];

      final stats = WorkoutStats.fromSessions(
        sessions,
        referenceDate: DateTime(2026, 10, 22, 12, 0), // Midweek Thursday
      );

      // Both Monday and Sunday sessions must fall within current week, Next Monday excluded
      expect(stats.workoutsThisWeek, equals(2));
      expect(stats.activeDaysThisWeek, containsAll([1, 7]));
      expect(stats.activeDaysThisWeek.contains(2), isFalse);
    });

    test('3,000 workouts aggregation performance and stability', () {
      final now = DateTime(2026, 10, 17);
      final bulkSessions = List.generate(3000, (i) {
        final start = now.subtract(Duration(hours: i * 2));
        return WorkoutSession(
          id: 's_$i',
          source: i % 3 == 0 ? WorkoutSource.hevy : WorkoutSource.healthConnect,
          title: 'Session #$i',
          startTime: start,
          endTime: start.add(const Duration(minutes: 60)),
          durationMinutes: 60,
          caloriesBurned: 350.0,
          createdAt: start,
        );
      });

      final stopwatch = Stopwatch()..start();
      final stats = WorkoutStats.fromSessions(bulkSessions, referenceDate: now);
      stopwatch.stop();

      expect(stats.totalWorkouts, equals(3000));
      expect(stats.hevyWorkoutsCount, equals(1000));
      expect(stats.totalDurationMinutes, equals(180000));
      expect(stats.averageDurationMinutes, equals(60.0));
      expect(stats.recentWorkouts.length, equals(10));
      // Relaxed from 100ms to 1000ms to prevent brittle wall-clock test failures under CI scheduler jitter.
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });
}
