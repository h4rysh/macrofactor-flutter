import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/services/mock_health_sync_adapter.dart';
import 'package:sique/domain/algorithms/weight_trend_v2.dart';
import 'package:sique/domain/models/workout_session.dart';

void main() {
  group('MockHealthSyncAdapter Test Suite', () {
    late MockHealthSyncAdapter adapter;

    setUp(() {
      adapter = MockHealthSyncAdapter();
    });

    test('isAvailable and hasPermissions return defaults and log telemetry',
        () async {
      expect(adapter.isAvailableCallCount, equals(0));
      expect(adapter.hasPermissionsCallCount, equals(0));

      expect(await adapter.isAvailable(), isTrue);
      expect(await adapter.hasPermissions(), isTrue);

      expect(adapter.isAvailableCallCount, equals(1));
      expect(adapter.hasPermissionsCallCount, equals(1));
    });

    test('requestPermissions updates hasPermissions state', () async {
      adapter.hasPermissionsResult = false;
      adapter.requestPermissionsResult = true;

      final granted = await adapter.requestPermissions();
      expect(granted, isTrue);
      expect(await adapter.hasPermissions(), isTrue);
      expect(adapter.requestPermissionsCallCount, equals(1));
    });

    test('fetchWorkouts filters sessions by time bounds', () async {
      final now = DateTime(2026, 10, 17, 12, 0);
      final customWorkouts = [
        WorkoutSession(
          id: 'w_inside',
          source: WorkoutSource.hevy,
          title: 'Morning Lift',
          startTime: now.subtract(const Duration(hours: 3)),
          endTime: now.subtract(const Duration(hours: 2)),
          durationMinutes: 60,
          caloriesBurned: 400.0,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        WorkoutSession(
          id: 'w_outside',
          source: WorkoutSource.hevy,
          title: 'Last Week Lift',
          startTime: now.subtract(const Duration(days: 8)),
          endTime: now.subtract(const Duration(days: 8, hours: -1)),
          durationMinutes: 60,
          caloriesBurned: 400.0,
          createdAt: now.subtract(const Duration(days: 8)),
        ),
      ];

      adapter.setWorkouts(customWorkouts);

      final start = now.subtract(const Duration(days: 1));
      final end = now;

      final results = await adapter.fetchWorkouts(
        startTime: start,
        endTime: end,
      );

      expect(adapter.fetchWorkoutsCallCount, equals(1));
      expect(adapter.lastFetchWorkoutsStartTime, equals(start));
      expect(adapter.lastFetchWorkoutsEndTime, equals(end));
      expect(results.length, equals(1));
      expect(results.first.id, equals('w_inside'));
    });

    test('fetchWorkouts throws Exception when shouldFailFetchWorkouts is true',
        () async {
      adapter.shouldFailFetchWorkouts = true;

      expect(
        () => adapter.fetchWorkouts(
          startTime: DateTime(2026, 1, 1),
          endTime: DateTime(2026, 1, 2),
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Health Connect service disconnected'),
          ),
        ),
      );
      expect(adapter.fetchWorkoutsCallCount, equals(1));
    });

    test('fetchWeights filters scale entries by time bounds', () async {
      final customWeights = [
        ScaleWeightEntry(
          date: DateTime(2026, 10, 16, 7, 0),
          weightKg: 75.2,
          note: 'Scale 1',
        ),
        ScaleWeightEntry(
          date: DateTime(2026, 10, 10, 7, 0),
          weightKg: 75.8,
          note: 'Scale 2',
        ),
      ];

      adapter.setWeights(customWeights);

      final start = DateTime(2026, 10, 15);
      final end = DateTime(2026, 10, 17, 23, 59);

      final results = await adapter.fetchWeights(
        startTime: start,
        endTime: end,
      );

      expect(adapter.fetchWeightsCallCount, equals(1));
      expect(adapter.lastFetchWeightsStartTime, equals(start));
      expect(adapter.lastFetchWeightsEndTime, equals(end));
      expect(results.length, equals(1));
      expect(results.first.weightKg, equals(75.2));
    });

    test('fetchWeights throws Exception when shouldFailFetchWeights is true',
        () async {
      adapter.shouldFailFetchWeights = true;

      expect(
        () => adapter.fetchWeights(
          startTime: DateTime(2026, 1, 1),
          endTime: DateTime(2026, 1, 2),
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Health Connect sensor read error'),
          ),
        ),
      );
      expect(adapter.fetchWeightsCallCount, equals(1));
    });

    test('reset clears telemetry and resets fault injection flags', () async {
      adapter.shouldFailFetchWorkouts = true;
      adapter.shouldFailFetchWeights = true;
      await adapter.isAvailable();
      await adapter.hasPermissions();

      adapter.reset();

      expect(adapter.isAvailableCallCount, equals(0));
      expect(adapter.hasPermissionsCallCount, equals(0));
      expect(adapter.fetchWorkoutsCallCount, equals(0));
      expect(adapter.fetchWeightsCallCount, equals(0));
      expect(adapter.shouldFailFetchWorkouts, isFalse);
      expect(adapter.shouldFailFetchWeights, isFalse);
      expect(adapter.lastFetchWorkoutsStartTime, isNull);
    });
  });
}
