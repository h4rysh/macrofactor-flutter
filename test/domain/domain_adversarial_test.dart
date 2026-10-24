import 'package:flutter_test/flutter_test.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/models/workout_session.dart';
import 'package:sique/domain/models/workout_stats.dart';

void main() {
  group('Adversarial Boundary Dates & Calendar Edge Cases', () {
    test('handles leap day (Feb 29) reference date and weekday partitioning',
        () {
      // 2024 is a leap year. Feb 29, 2024 is a Thursday (weekday 4).
      // Week range: Monday 2024-02-26 to Sunday 2024-03-03.
      final leapDay = DateTime(2024, 2, 29, 14, 30);

      final sessions = [
        // Monday Feb 26 (weekday 1)
        WorkoutSession(
          id: 's_leap_1',
          source: WorkoutSource.hevy,
          title: 'Monday Squats',
          startTime: DateTime(2024, 2, 26, 8, 0),
          endTime: DateTime(2024, 2, 26, 9, 0),
          durationMinutes: 60,
          caloriesBurned: 400.0,
          createdAt: DateTime(2024, 2, 26, 9, 5),
        ),
        // Leap Day: Thursday Feb 29 (weekday 4)
        WorkoutSession(
          id: 's_leap_2',
          source: WorkoutSource.hevy,
          title: 'Leap Day Bench',
          startTime: DateTime(2024, 2, 29, 12, 0),
          endTime: DateTime(2024, 2, 29, 13, 0),
          durationMinutes: 60,
          caloriesBurned: 450.0,
          createdAt: DateTime(2024, 2, 29, 13, 5),
        ),
        // Sunday March 3 (weekday 7)
        WorkoutSession(
          id: 's_leap_3',
          source: WorkoutSource.healthConnect,
          title: 'Sunday Trail Run',
          startTime: DateTime(2024, 3, 3, 18, 0),
          endTime: DateTime(2024, 3, 3, 18, 45),
          durationMinutes: 45,
          caloriesBurned: 380.0,
          createdAt: DateTime(2024, 3, 3, 18, 50),
        ),
        // Previous week: Sunday Feb 25 (outside current week)
        WorkoutSession(
          id: 's_leap_4',
          source: WorkoutSource.hevy,
          title: 'Previous Sunday',
          startTime: DateTime(2024, 2, 25, 10, 0),
          endTime: DateTime(2024, 2, 25, 11, 0),
          durationMinutes: 60,
          caloriesBurned: 410.0,
          createdAt: DateTime(2024, 2, 25, 11, 5),
        ),
      ];

      final stats = WorkoutStats.fromSessions(sessions, referenceDate: leapDay);

      expect(stats.totalWorkouts, equals(4));
      expect(stats.workoutsThisWeek, equals(3));
      expect(stats.activeDaysThisWeek, equals({1, 4, 7}));
      expect(stats.totalDurationMinutes, equals(225));
      expect(stats.totalCaloriesBurned, equals(1640.0));
    });

    test('handles trailing 28-day window across leap year February', () {
      // Reference date: March 1, 2024 (day after leap day).
      // Trailing 28 days = March 1 minus 28 days = Feb 2, 2024.
      final refDate = DateTime(2024, 3, 1, 12, 0);

      final sessions = [
        // Within 28 days: Feb 2, 2024 at 13:00 (after 12:00)
        WorkoutSession(
          id: 's_w28_1',
          source: WorkoutSource.hevy,
          title: 'Inside Window',
          startTime: DateTime(2024, 2, 2, 13, 0),
          endTime: DateTime(2024, 2, 2, 14, 0),
          durationMinutes: 60,
          caloriesBurned: 400.0,
          createdAt: DateTime(2024, 2, 2, 14, 5),
        ),
        // Outside 28 days: Feb 2, 2024 at 11:00 (before 12:00)
        WorkoutSession(
          id: 's_w28_2',
          source: WorkoutSource.hevy,
          title: 'Outside Window',
          startTime: DateTime(2024, 2, 2, 11, 0),
          endTime: DateTime(2024, 2, 2, 12, 0),
          durationMinutes: 60,
          caloriesBurned: 400.0,
          createdAt: DateTime(2024, 2, 2, 12, 5),
        ),
      ];

      final stats = WorkoutStats.fromSessions(sessions, referenceDate: refDate);
      expect(stats.totalWorkouts, equals(2));
      // Only s_w28_1 is after refDate - 28 days
      expect(stats.weeklyFrequency, equals(1 / 4.0)); // 0.25
      expect(stats.formattedWeeklyFrequency, equals('0.3'));
    });

    test('handles year-boundary crossing week (Dec 31 to Jan 1)', () {
      // 2026-01-01 is a Thursday (weekday 4).
      // Week starts Monday 2025-12-29 and ends Sunday 2026-01-04.
      final newYearsDay = DateTime(2026, 1, 1, 10, 0);

      final sessions = [
        // Monday Dec 29, 2025 (weekday 1)
        WorkoutSession(
          id: 's_yr_1',
          source: WorkoutSource.hevy,
          title: 'End of Year Lift',
          startTime: DateTime(2025, 12, 29, 9, 0),
          endTime: DateTime(2025, 12, 29, 10, 0),
          durationMinutes: 60,
          caloriesBurned: 500.0,
          createdAt: DateTime(2025, 12, 29, 10, 5),
        ),
        // Thursday Jan 1, 2026 (weekday 4)
        WorkoutSession(
          id: 's_yr_2',
          source: WorkoutSource.hevy,
          title: 'New Year Workout',
          startTime: DateTime(2026, 1, 1, 11, 0),
          endTime: DateTime(2026, 1, 1, 12, 0),
          durationMinutes: 60,
          caloriesBurned: 450.0,
          createdAt: DateTime(2026, 1, 1, 12, 5),
        ),
        // Sunday Jan 4, 2026 (weekday 7)
        WorkoutSession(
          id: 's_yr_3',
          source: WorkoutSource.healthConnect,
          title: 'First Sunday Run',
          startTime: DateTime(2026, 1, 4, 15, 0),
          endTime: DateTime(2026, 1, 4, 15, 40),
          durationMinutes: 40,
          caloriesBurned: 320.0,
          createdAt: DateTime(2026, 1, 4, 15, 45),
        ),
      ];

      final stats =
          WorkoutStats.fromSessions(sessions, referenceDate: newYearsDay);

      expect(stats.totalWorkouts, equals(3));
      expect(stats.workoutsThisWeek, equals(3));
      expect(stats.activeDaysThisWeek, equals({1, 4, 7}));
    });

    test('exact microsecond boundary at week start and week end', () {
      // Reference date: Wednesday 2026-10-14
      // Monday is 2026-10-12 00:00:00.000
      // Sunday is 2026-10-18 23:59:59.999999
      final refDate = DateTime(2026, 10, 14, 12, 0);

      final exactStartOfWeek = DateTime(2026, 10, 12, 0, 0, 0, 0, 0);
      final oneMicroBeforeStart =
          exactStartOfWeek.subtract(const Duration(microseconds: 1));
      final exactEndOfWeek = DateTime(2026, 10, 18, 23, 59, 59, 0, 999);
      final oneMicroAfterEnd = DateTime(2026, 10, 19, 0, 0, 0, 0, 0);

      final sessions = [
        WorkoutSession(
          id: 's_start_exact',
          source: WorkoutSource.hevy,
          title: 'Exact Start',
          startTime: exactStartOfWeek,
          endTime: exactStartOfWeek.add(const Duration(minutes: 30)),
          durationMinutes: 30,
          caloriesBurned: 200.0,
          createdAt: exactStartOfWeek,
        ),
        WorkoutSession(
          id: 's_before_start',
          source: WorkoutSource.hevy,
          title: 'Before Start',
          startTime: oneMicroBeforeStart,
          endTime: oneMicroBeforeStart.add(const Duration(minutes: 30)),
          durationMinutes: 30,
          caloriesBurned: 200.0,
          createdAt: oneMicroBeforeStart,
        ),
        WorkoutSession(
          id: 's_end_exact',
          source: WorkoutSource.hevy,
          title: 'Exact End',
          startTime: exactEndOfWeek,
          endTime: exactEndOfWeek.add(const Duration(minutes: 30)),
          durationMinutes: 30,
          caloriesBurned: 200.0,
          createdAt: exactEndOfWeek,
        ),
        WorkoutSession(
          id: 's_after_end',
          source: WorkoutSource.hevy,
          title: 'After End',
          startTime: oneMicroAfterEnd,
          endTime: oneMicroAfterEnd.add(const Duration(minutes: 30)),
          durationMinutes: 30,
          caloriesBurned: 200.0,
          createdAt: oneMicroAfterEnd,
        ),
      ];

      final stats = WorkoutStats.fromSessions(sessions, referenceDate: refDate);

      // Only s_start_exact and s_end_exact should fall inside the current week
      expect(stats.workoutsThisWeek, equals(2));
      expect(stats.activeDaysThisWeek, equals({1, 7}));
    });
  });

  group('Adversarial Negative and Zero Values', () {
    test('zero values in WorkoutSession and WorkoutStats', () {
      final zeroSession = WorkoutSession(
        id: 's_zero',
        source: WorkoutSource.manual,
        title: 'Zero Workout',
        startTime: DateTime(2026, 10, 15, 10, 0),
        endTime: DateTime(2026, 10, 15, 10, 0),
        durationMinutes: 0,
        caloriesBurned: 0.0,
        createdAt: DateTime(2026, 10, 15, 10, 0),
      );

      expect(zeroSession.durationMinutes, equals(0));
      expect(zeroSession.caloriesBurned, equals(0.0));
      expect(zeroSession.duration, equals(Duration.zero));
      expect(zeroSession.formattedDuration, equals('0m'));

      final stats = WorkoutStats.fromSessions([zeroSession],
          referenceDate: DateTime(2026, 10, 15));
      expect(stats.totalWorkouts, equals(1));
      expect(stats.totalDurationMinutes, equals(0));
      expect(stats.averageDurationMinutes, equals(0.0));
      expect(stats.totalCaloriesBurned, equals(0.0));
      expect(stats.averageCaloriesBurned, equals(0.0));
      expect(stats.roundedAverageDurationMinutes, equals(0));
      expect(stats.roundedAverageCaloriesBurned, equals(0));
    });

    test('behavior of negative durationMinutes in formattedDuration', () {
      // Testing robustness: what happens if a corrupted session has negative duration
      final negSession = WorkoutSession(
        id: 's_neg',
        source: WorkoutSource.manual,
        title: 'Negative Duration',
        startTime: DateTime(2026, 10, 15, 10, 0),
        endTime: DateTime(2026, 10, 15, 9, 45), // 15 mins before start
        durationMinutes: -15,
        caloriesBurned: -100.0,
        createdAt: DateTime(2026, 10, 15, 10, 0),
      );

      expect(negSession.duration.isNegative, isTrue);
      // In Dart: -15 ~/ 60 = 0, and -15 % 60 = 45 due to Euclidean modulo
      // Verify formattedDuration does not throw an unhandled exception
      expect(negSession.formattedDuration, isA<String>());
    });

    test('aggregates negative values in WorkoutStats without throwing', () {
      final negSession = WorkoutSession(
        id: 's_neg',
        source: WorkoutSource.hevy,
        title: 'Corrupted Session',
        startTime: DateTime(2026, 10, 15, 10, 0),
        endTime: DateTime(2026, 10, 15, 9, 30),
        durationMinutes: -30,
        caloriesBurned: -150.0,
        createdAt: DateTime(2026, 10, 15, 10, 0),
      );

      final stats = WorkoutStats.fromSessions([negSession],
          referenceDate: DateTime(2026, 10, 15));
      expect(stats.totalDurationMinutes, equals(-30));
      expect(stats.totalCaloriesBurned, equals(-150.0));
      expect(stats.averageDurationMinutes, equals(-30.0));
      expect(stats.averageCaloriesBurned, equals(-150.0));
      expect(stats.roundedAverageDurationMinutes, equals(-30));
      expect(stats.roundedAverageCaloriesBurned, equals(-150));
    });
  });

  group('Adversarial Empty Lists and Deduplication', () {
    test('WorkoutStats.fromSessions with empty list returns WorkoutStats.empty',
        () {
      final stats = WorkoutStats.fromSessions(const []);
      expect(
          identical(stats, WorkoutStats.empty) || stats == WorkoutStats.empty,
          isTrue);
      expect(stats.totalWorkouts, equals(0));
      expect(stats.recentWorkouts, isEmpty);
      expect(stats.activeDaysThisWeek, isEmpty);
    });

    test(
        'deduplicates activeDaysThisWeek when multiple workouts occur on the same day',
        () {
      final refDate = DateTime(2026, 10, 14, 20, 0); // Wednesday

      final sessions = [
        // Two sessions on Wednesday morning and evening
        WorkoutSession(
          id: 's_wed_1',
          source: WorkoutSource.hevy,
          title: 'Morning Chest',
          startTime: DateTime(2026, 10, 14, 7, 0),
          endTime: DateTime(2026, 10, 14, 8, 0),
          durationMinutes: 60,
          caloriesBurned: 400.0,
          createdAt: DateTime(2026, 10, 14, 8, 5),
        ),
        WorkoutSession(
          id: 's_wed_2',
          source: WorkoutSource.healthConnect,
          title: 'Evening Run',
          startTime: DateTime(2026, 10, 14, 18, 0),
          endTime: DateTime(2026, 10, 14, 18, 45),
          durationMinutes: 45,
          caloriesBurned: 350.0,
          createdAt: DateTime(2026, 10, 14, 18, 50),
        ),
      ];

      final stats = WorkoutStats.fromSessions(sessions, referenceDate: refDate);
      expect(stats.workoutsThisWeek, equals(2));
      // Weekday 3 (Wednesday) should appear only once
      expect(stats.activeDaysThisWeek, equals({3}));
      expect(stats.activeDaysThisWeek.length, equals(1));
    });

    test('handles recentLimit variations (0, greater than total, negative)',
        () {
      final refDate = DateTime(2026, 10, 15, 12, 0);
      final sessions = List.generate(
        5,
        (i) => WorkoutSession(
          id: 'session_$i',
          source: WorkoutSource.hevy,
          title: 'Workout $i',
          startTime: DateTime(2026, 10, 10 + i, 9, 0),
          endTime: DateTime(2026, 10, 10 + i, 10, 0),
          durationMinutes: 60,
          caloriesBurned: 400.0,
          createdAt: DateTime(2026, 10, 10 + i, 10, 5),
        ),
      );

      // recentLimit = 0
      final statsZeroLimit = WorkoutStats.fromSessions(
        sessions,
        referenceDate: refDate,
        recentLimit: 0,
      );
      expect(statsZeroLimit.recentWorkouts, isEmpty);

      // recentLimit greater than session count
      final statsLargeLimit = WorkoutStats.fromSessions(
        sessions,
        referenceDate: refDate,
        recentLimit: 100,
      );
      expect(statsLargeLimit.recentWorkouts.length, equals(5));

      // recentLimit < 0 throws ArgumentError in List.take()
      expect(
        () => WorkoutStats.fromSessions(sessions,
            referenceDate: refDate, recentLimit: -1),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Adversarial String Ingestion, Unicode and SQL Injection Characters',
      () {
    test(
        'UserAccount and WorkoutSession preserve unicode, emojis, and special SQL characters',
        () {
      final complexUser = UserAccount(
        id: "usr_'; DROP TABLE user_account_session; --",
        googleUserId: 'gid_🚀🏋️',
        displayName: 'Athleté José & René — "The Beast"',
        email: 'athlete+special\'test"@fitness.io',
        photoUrl:
            'https://cdn.example.com/avatars/user?name=test&filter=true#anchor',
        healthConnectEnabled: true,
        lastHealthSyncTime: DateTime(2026, 10, 17, 12, 0),
        createdAt: DateTime(2026, 10, 1, 8, 0),
        updatedAt: DateTime(2026, 10, 17, 12, 0),
        isAuthenticated: true,
      );

      final userMap = complexUser.toMap();
      final restoredUser = UserAccount.fromMap(userMap);
      expect(restoredUser.id, equals(complexUser.id));
      expect(restoredUser.googleUserId, equals(complexUser.googleUserId));
      expect(restoredUser.displayName, equals(complexUser.displayName));
      expect(restoredUser.email, equals(complexUser.email));
      expect(restoredUser.photoUrl, equals(complexUser.photoUrl));

      final complexSession = WorkoutSession(
        id: "sess_'; DELETE FROM workout_sessions; --",
        source: 'hevy',
        title: '🔥 PR Bench: 140kg x 5 @ RPE 9.5 🏋️‍♂️',
        startTime: DateTime(2026, 10, 17, 9, 0),
        endTime: DateTime(2026, 10, 17, 10, 15),
        durationMinutes: 75,
        caloriesBurned: 520.75,
        notes:
            "Line 1: Warmup\nLine 2: 5x5 'Heavy'\r\nLine 3: Cool-down & stretching\tDone!",
        createdAt: DateTime(2026, 10, 17, 10, 20),
      );

      final sessionMap = complexSession.toMap();
      final restoredSession = WorkoutSession.fromMap(sessionMap);
      expect(restoredSession.id, equals(complexSession.id));
      expect(restoredSession.title, equals(complexSession.title));
      expect(restoredSession.notes, equals(complexSession.notes));
      expect(restoredSession, equals(complexSession));
    });
  });

  group('Adversarial fromMap Error Handling and Type Safety', () {
    test(
        'UserAccount.fromMap handles corrupted/unexpected types and invalid dates',
        () {
      final corruptedMap = {
        'id': 'corrupted_1',
        'google_user_id': '',
        'display_name': 'Fallback Name',
        'email': 'fallback@test.com',
        'photo_url': null,
        'health_connect_enabled': 0,
        'last_health_sync_time': 'invalid-not-a-date-iso-string',
        'created_at': 'corrupted-timestamp',
        'updated_at': 'another-bad-date',
      };

      final account = UserAccount.fromMap(corruptedMap);
      expect(account.id, equals('corrupted_1'));
      expect(account.lastHealthSyncTime, isNull);
      expect(account.createdAt, isA<DateTime>());
      expect(account.updatedAt, isA<DateTime>());
      expect(account.isAuthenticated, isFalse);
    });

    test('WorkoutSession.fromMap handles missing optional attributes cleanly',
        () {
      final minimalSessionMap = {
        'id': 'min_session_1',
        'source': null,
        'title': null,
        'start_time': '2026-10-15T08:00:00.000',
        'end_time': '2026-10-15T09:00:00.000',
        'duration_minutes': null,
        'calories_burned': null,
        'notes': null,
        'created_at': null,
      };

      final session = WorkoutSession.fromMap(minimalSessionMap);
      expect(session.id, equals('min_session_1'));
      expect(session.source,
          equals(WorkoutSource.healthConnect)); // fallback default
      expect(session.title, equals('Workout')); // fallback default
      expect(session.durationMinutes, equals(0));
      expect(session.caloriesBurned, equals(0.0));
      expect(session.notes, isNull);
      expect(session.createdAt, isA<DateTime>());
    });

    test(
        'WorkoutSession.fromMap throws FormatException when start_time or end_time is invalid',
        () {
      final badDateMap = {
        'id': 'bad_session_1',
        'start_time': 'not-a-valid-iso-date',
        'end_time': '2026-10-15T09:00:00.000',
      };

      expect(() => WorkoutSession.fromMap(badDateMap),
          throwsA(isA<FormatException>()));
    });
  });

  group('Adversarial Value Equality and Identity Contracts', () {
    test('Set and Map hashing semantics preserve contract', () {
      final s1 = WorkoutSession(
        id: 's_hash_1',
        source: WorkoutSource.hevy,
        title: 'Workout',
        startTime: DateTime(2026, 10, 15, 10, 0),
        endTime: DateTime(2026, 10, 15, 11, 0),
        durationMinutes: 60,
        caloriesBurned: 400.0,
        createdAt: DateTime(2026, 10, 15, 11, 5),
      );

      final s2 = WorkoutSession(
        id: 's_hash_1',
        source: WorkoutSource.hevy,
        title: 'Workout',
        startTime: DateTime(2026, 10, 15, 10, 0),
        endTime: DateTime(2026, 10, 15, 11, 0),
        durationMinutes: 60,
        caloriesBurned: 400.0,
        createdAt: DateTime(2026, 10, 15, 11, 5),
      );

      final set = <WorkoutSession>{s1};
      expect(set.contains(s2), isTrue);

      final map = <WorkoutSession, String>{s1: 'found'};
      expect(map[s2], equals('found'));
    });
  });
}
