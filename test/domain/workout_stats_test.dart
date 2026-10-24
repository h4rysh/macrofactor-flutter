import 'package:flutter_test/flutter_test.dart';
import 'package:sique/domain/models/workout_session.dart';
import 'package:sique/domain/models/workout_stats.dart';

void main() {
  group('WorkoutStats Domain Model & Calculation Tests', () {
    test('WorkoutStats.empty produces clean zero-initialized metrics', () {
      const stats = WorkoutStats.empty;

      expect(stats.totalWorkouts, equals(0));
      expect(stats.hevyWorkoutsCount, equals(0));
      expect(stats.totalDurationMinutes, equals(0));
      expect(stats.averageDurationMinutes, equals(0.0));
      expect(stats.totalCaloriesBurned, equals(0.0));
      expect(stats.averageCaloriesBurned, equals(0.0));
      expect(stats.weeklyFrequency, equals(0.0));
      expect(stats.workoutsThisWeek, equals(0));
      expect(stats.activeDaysThisWeek, isEmpty);
      expect(stats.recentWorkouts, isEmpty);
      expect(stats.formattedWeeklyFrequency, equals('0.0'));
      expect(stats.roundedAverageDurationMinutes, equals(0));
      expect(stats.roundedAverageCaloriesBurned, equals(0));
    });

    test('WorkoutStats.fromSessions with empty list returns empty sentinel',
        () {
      final stats = WorkoutStats.fromSessions(const []);
      expect(stats, equals(WorkoutStats.empty));
    });

    test(
        'WorkoutStats.fromSessions aggregates metrics and partitions calendar week',
        () {
      // Reference date: Thursday 2026-10-15
      // Current week: Monday 2026-10-12 to Sunday 2026-10-18
      final refDate = DateTime(2026, 10, 15, 12, 0);

      final sessions = [
        // Monday of current week (weekday 1)
        WorkoutSession(
          id: 'w1',
          source: WorkoutSource.hevy,
          title: 'Upper A',
          startTime: DateTime(2026, 10, 12, 9, 0),
          endTime: DateTime(2026, 10, 12, 10, 0),
          durationMinutes: 60,
          caloriesBurned: 400.0,
          createdAt: DateTime(2026, 10, 12, 10, 5),
        ),
        // Wednesday of current week (weekday 3)
        WorkoutSession(
          id: 'w2',
          source: WorkoutSource.hevy,
          title: 'Lower A',
          startTime: DateTime(2026, 10, 14, 9, 0),
          endTime: DateTime(2026, 10, 14, 9, 45),
          durationMinutes: 45,
          caloriesBurned: 350.0,
          createdAt: DateTime(2026, 10, 14, 9, 50),
        ),
        // Thursday of current week (weekday 4)
        WorkoutSession(
          id: 'w3',
          source: WorkoutSource.healthConnect,
          title: 'Morning Run',
          startTime: DateTime(2026, 10, 15, 7, 0),
          endTime: DateTime(2026, 10, 15, 7, 30),
          durationMinutes: 30,
          caloriesBurned: 250.0,
          createdAt: DateTime(2026, 10, 15, 7, 35),
        ),
        // Last week: Friday 2026-10-09 (within past 28 days)
        WorkoutSession(
          id: 'w4',
          source: WorkoutSource.hevy,
          title: 'Push Day',
          startTime: DateTime(2026, 10, 9, 10, 0),
          endTime: DateTime(2026, 10, 9, 11, 0),
          durationMinutes: 60,
          caloriesBurned: 420.0,
          createdAt: DateTime(2026, 10, 9, 11, 5),
        ),
        // 2 weeks ago: Friday 2026-10-02 (within past 28 days)
        WorkoutSession(
          id: 'w5',
          source: WorkoutSource.manual,
          title: 'Swim',
          startTime: DateTime(2026, 10, 2, 8, 0),
          endTime: DateTime(2026, 10, 2, 8, 45),
          durationMinutes: 45,
          caloriesBurned: 380.0,
          createdAt: DateTime(2026, 10, 2, 8, 50),
        ),
        // 40 days ago: Outside past 28 days
        WorkoutSession(
          id: 'w6',
          source: WorkoutSource.hevy,
          title: 'Old Session',
          startTime: DateTime(2026, 9, 1, 10, 0),
          endTime: DateTime(2026, 9, 1, 11, 0),
          durationMinutes: 60,
          caloriesBurned: 400.0,
          createdAt: DateTime(2026, 9, 1, 11, 5),
        ),
      ];

      final stats = WorkoutStats.fromSessions(
        sessions,
        referenceDate: refDate,
        recentLimit: 3,
      );

      expect(stats.totalWorkouts, equals(6));
      expect(stats.hevyWorkoutsCount, equals(4)); // w1, w2, w4, w6
      expect(stats.totalDurationMinutes, equals(300));
      expect(stats.averageDurationMinutes, equals(50.0));
      expect(stats.totalCaloriesBurned, equals(2200.0));
      expect(stats.averageCaloriesBurned, closeTo(366.67, 0.01));

      // 5 sessions within past 28 days / 4 = 1.25 weekly freq
      expect(stats.weeklyFrequency, equals(1.25));
      expect(stats.formattedWeeklyFrequency, equals('1.3'));

      // 3 workouts this week (w1, w2, w3)
      expect(stats.workoutsThisWeek, equals(3));
      expect(stats.activeDaysThisWeek, equals({1, 3, 4}));

      // recentLimit = 3, sorted descending
      expect(stats.recentWorkouts.length, equals(3));
      expect(stats.recentWorkouts[0].id, equals('w3'));
      expect(stats.recentWorkouts[1].id, equals('w2'));
      expect(stats.recentWorkouts[2].id, equals('w1'));
    });

    test('copyWith and value equality verify state semantics', () {
      const s1 = WorkoutStats(
        totalWorkouts: 5,
        hevyWorkoutsCount: 3,
        totalDurationMinutes: 250,
        averageDurationMinutes: 50.0,
        totalCaloriesBurned: 1500.0,
        averageCaloriesBurned: 300.0,
        weeklyFrequency: 3.5,
        workoutsThisWeek: 3,
        activeDaysThisWeek: {1, 3, 5},
        recentWorkouts: [],
      );

      final s2 = s1.copyWith(workoutsThisWeek: 4);
      expect(s2.workoutsThisWeek, equals(4));
      expect(s2.totalWorkouts, equals(5));

      const s3 = WorkoutStats(
        totalWorkouts: 5,
        hevyWorkoutsCount: 3,
        totalDurationMinutes: 250,
        averageDurationMinutes: 50.0,
        totalCaloriesBurned: 1500.0,
        averageCaloriesBurned: 300.0,
        weeklyFrequency: 3.5,
        workoutsThisWeek: 3,
        activeDaysThisWeek: {1, 3, 5},
        recentWorkouts: [],
      );

      expect(s1, equals(s3));
      expect(s1.hashCode, equals(s3.hashCode));
      expect(s1.toString(), contains('WorkoutStats(total: 5'));
    });
  });
}
