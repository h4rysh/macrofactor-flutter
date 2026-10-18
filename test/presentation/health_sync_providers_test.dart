import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:macro_factor_app/data/local/app_database.dart';
import 'package:macro_factor_app/data/services/mock_auth_service.dart';
import 'package:macro_factor_app/data/services/mock_health_sync_adapter.dart';
import 'package:macro_factor_app/domain/algorithms/weight_trend_v2.dart';
import 'package:macro_factor_app/domain/models/workout_session.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';

void main() {
  group('Health Connect Sync Riverpod Provider Tests', () {
    late Database rawDb;
    late AppDatabase appDb;
    late MockHealthSyncAdapter mockAdapter;
    late MockAuthService mockAuth;
    late ProviderContainer container;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      appDb = AppDatabase(rawDb);
      appDb.initUserTables();
      mockAdapter = MockHealthSyncAdapter();
      mockAuth = MockAuthService();

      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(appDb),
          healthSyncAdapterProvider.overrideWithValue(mockAdapter),
          authServiceProvider.overrideWithValue(mockAuth),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      rawDb.dispose();
    });

    test('Initial state initializes with idle status and clean counters', () {
      final state = container.read(healthConnectSyncProvider);
      expect(state.status, equals(HealthSyncStatus.idle));
      expect(state.syncedWorkoutsCount, equals(0));
      expect(state.syncedWeightsCount, equals(0));
      expect(state.errorMessage, isNull);
      expect(state.isSyncing, isFalse);
    });

    test(
        'syncNow executes full successful cycle and propagates to downstream providers',
        () async {
      final now = DateTime.now();
      final customWorkouts = [
        WorkoutSession(
          id: 'hevy_synced_01',
          source: WorkoutSource.hevy,
          title: 'Chest & Back Hypertrophy',
          startTime: now.subtract(const Duration(days: 1, hours: 2)),
          endTime: now.subtract(const Duration(days: 1, hours: 1)),
          durationMinutes: 60,
          caloriesBurned: 420.0,
          notes: 'Hevy workout import',
          createdAt: now.subtract(const Duration(days: 1, hours: 1)),
        ),
      ];

      final customWeights = [
        ScaleWeightEntry(
          date: DateTime(now.year, now.month, now.day - 1),
          weightKg: 75.2,
          note: 'Smart Scale Import',
        ),
      ];

      mockAdapter.setWorkouts(customWorkouts);
      mockAdapter.setWeights(customWeights);

      final notifier = container.read(healthConnectSyncProvider.notifier);

      final result = await notifier.syncNow();
      expect(result, isTrue);

      final syncState = container.read(healthConnectSyncProvider);
      expect(syncState.status, equals(HealthSyncStatus.success));
      expect(syncState.syncedWorkoutsCount, equals(1));
      expect(syncState.syncedWeightsCount, equals(1));
      expect(syncState.lastSyncedAt, isNotNull);
      expect(syncState.errorMessage, isNull);

      // Verify adapter telemetry
      expect(mockAdapter.isAvailableCallCount, greaterThanOrEqualTo(1));
      expect(mockAdapter.fetchWorkoutsCallCount, equals(1));
      expect(mockAdapter.fetchWeightsCallCount, equals(1));

      // Verify SQLite persistence
      final dbWorkouts = appDb.getAllWorkoutSessions();
      expect(dbWorkouts.length, equals(1));
      expect(dbWorkouts.first.id, equals('hevy_synced_01'));

      final dbWeights = appDb.getAllWeightLogs();
      expect(dbWeights.length, equals(1));
      expect(dbWeights.first.weightKg, equals(75.2));

      // Verify downstream Riverpod providers reactively updated
      final workoutSessions = container.read(workoutSessionsProvider);
      expect(workoutSessions.length, equals(1));
      expect(workoutSessions.first.title, equals('Chest & Back Hypertrophy'));

      final workoutStats = container.read(workoutStatsProvider);
      expect(workoutStats.totalWorkouts, equals(1));
      expect(workoutStats.hevyWorkoutsCount, equals(1));
      expect(workoutStats.totalDurationMinutes, equals(60));

      final weightLogs = container.read(weightLogsProvider);
      expect(weightLogs.length, equals(1));
      expect(weightLogs.first.weightKg, equals(75.2));
    });

    test(
        'syncNow halts gracefully when Health Connect is not available on device',
        () async {
      mockAdapter.isAvailableResult = false;

      final notifier = container.read(healthConnectSyncProvider.notifier);
      final result = await notifier.syncNow();

      expect(result, isFalse);

      final state = container.read(healthConnectSyncProvider);
      expect(state.status, equals(HealthSyncStatus.error));
      expect(state.isAvailable, isFalse);
      expect(state.errorMessage, contains('not available on this device'));
      expect(mockAdapter.fetchWorkoutsCallCount, equals(0));
      expect(mockAdapter.fetchWeightsCallCount, equals(0));
    });

    test(
        'syncNow requests permissions if ungranted and halts if denied by user',
        () async {
      mockAdapter.hasPermissionsResult = false;
      mockAdapter.requestPermissionsResult = false; // User denies

      final notifier = container.read(healthConnectSyncProvider.notifier);
      final result = await notifier.syncNow();

      expect(result, isFalse);

      final state = container.read(healthConnectSyncProvider);
      expect(state.status, equals(HealthSyncStatus.error));
      expect(state.hasPermissions, isFalse);
      expect(state.errorMessage, contains('permissions not granted'));
      expect(mockAdapter.requestPermissionsCallCount, equals(1));
      expect(mockAdapter.fetchWorkoutsCallCount, equals(0));
    });

    test(
        'syncNow proceeds when permissions are successfully requested and granted',
        () async {
      mockAdapter.hasPermissionsResult = false;
      mockAdapter.requestPermissionsResult = true; // User grants on prompt

      final notifier = container.read(healthConnectSyncProvider.notifier);
      final result = await notifier.syncNow();

      expect(result, isTrue);

      final state = container.read(healthConnectSyncProvider);
      expect(state.status, equals(HealthSyncStatus.success));
      expect(state.hasPermissions, isTrue);
      expect(mockAdapter.requestPermissionsCallCount, equals(1));
      expect(mockAdapter.fetchWorkoutsCallCount, equals(1));
    });

    test('syncNow catches workout fetch errors and preserves existing state',
        () async {
      mockAdapter.shouldFailFetchWorkouts = true;

      final notifier = container.read(healthConnectSyncProvider.notifier);
      final result = await notifier.syncNow();

      expect(result, isFalse);

      final state = container.read(healthConnectSyncProvider);
      expect(state.status, equals(HealthSyncStatus.error));
      expect(
          state.errorMessage, contains('Health Connect service disconnected'));

      // Database remains clean and uncorrupted
      expect(appDb.getAllWorkoutSessions(), isEmpty);
    });

    test(
        'syncNow is idempotent: consecutive syncs do not duplicate SQLite entries',
        () async {
      final notifier = container.read(healthConnectSyncProvider.notifier);

      // First sync
      await notifier.syncNow();
      final count1 = appDb.getAllWorkoutSessions().length;
      expect(count1, greaterThan(0));

      // Second consecutive sync with identical adapter data
      await notifier.syncNow();
      final count2 = appDb.getAllWorkoutSessions().length;
      expect(count2, equals(count1)); // Exactly the same count, no duplicates
    });

    test('clearError resets error state back to idle', () async {
      mockAdapter.isAvailableResult = false;
      final notifier = container.read(healthConnectSyncProvider.notifier);
      await notifier.syncNow();

      expect(container.read(healthConnectSyncProvider).isError, isTrue);

      notifier.clearError();
      final state = container.read(healthConnectSyncProvider);
      expect(state.isError, isFalse);
      expect(state.status, equals(HealthSyncStatus.idle));
      expect(state.errorMessage, isNull);
    });
  });
}
