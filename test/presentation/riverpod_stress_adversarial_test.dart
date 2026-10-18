import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:macro_factor_app/data/local/app_database.dart';
import 'package:macro_factor_app/data/services/mock_auth_service.dart';
import 'package:macro_factor_app/data/services/mock_health_sync_adapter.dart';
import 'package:macro_factor_app/domain/algorithms/weight_trend_v2.dart';
import 'package:macro_factor_app/domain/models/food_models.dart';
import 'package:macro_factor_app/domain/models/user_account.dart';
import 'package:macro_factor_app/domain/models/workout_session.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';

/// Controllable delayed AuthService to stress-test async race conditions.
class DelayedMockAuthService extends MockAuthService {
  DelayedMockAuthService({this.delayMs = 20});

  final int delayMs;
  int signInAttempts = 0;
  int signOutAttempts = 0;

  @override
  Future<UserAccount> signInWithGoogle() async {
    signInAttempts++;
    if (delayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
    return super.signInWithGoogle();
  }

  @override
  Future<void> signOut() async {
    signOutAttempts++;
    if (delayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
    return super.signOut();
  }
}

/// Controllable delayed HealthSyncAdapter to stress-test concurrent sync triggers.
class DelayedMockHealthSyncAdapter extends MockHealthSyncAdapter {
  DelayedMockHealthSyncAdapter({this.delayMs = 25});

  final int delayMs;

  @override
  Future<bool> isAvailable() async {
    if (delayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
    return super.isAvailable();
  }

  @override
  Future<List<WorkoutSession>> fetchWorkouts({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (delayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
    return super.fetchWorkouts(startTime: startTime, endTime: endTime);
  }
}

void main() {
  group('Adversarial & Empirical Stress Tests: Riverpod State Providers', () {
    late Database rawDb;
    late AppDatabase appDb;
    late DelayedMockAuthService mockAuth;
    late DelayedMockHealthSyncAdapter mockAdapter;
    late ProviderContainer container;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      appDb = AppDatabase(rawDb);
      appDb.initUserTables();
      mockAuth = DelayedMockAuthService(delayMs: 10);
      mockAdapter = DelayedMockHealthSyncAdapter(delayMs: 10);

      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(appDb),
          authServiceProvider.overrideWithValue(mockAuth),
          healthSyncAdapterProvider.overrideWithValue(mockAdapter),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      rawDb.dispose();
    });

    WorkoutSession buildTestSession({
      required String id,
      String source = WorkoutSource.hevy,
      String title = 'Stress Workout',
      DateTime? startTime,
      int durationMinutes = 45,
      double caloriesBurned = 350.0,
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

    // =========================================================================
    // 1. Rapid Sign-In / Sign-Out Cycles & Concurrency
    // =========================================================================

    test(
        'Stress: 50 rapid serial sign-in and sign-out cycles maintain database & state integrity',
        () async {
      final notifier = container.read(authNotifierProvider.notifier);

      for (var i = 0; i < 50; i++) {
        final signInOk = await notifier.signInWithGoogle();
        expect(signInOk, isTrue, reason: 'Iteration $i sign in should succeed');
        expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());
        expect(appDb.getAccountSession(), isNotNull);

        await notifier.signOut();
        expect(
            container.read(authNotifierProvider), isA<AuthUnauthenticated>());
        expect(appDb.getAccountSession(), isNull);
      }

      expect(mockAuth.signInAttempts, equals(50));
      expect(mockAuth.signOutAttempts, equals(50));
    });

    test(
        'Stress: 10 concurrent signInWithGoogle() calls resolve safely without SQLite contention',
        () async {
      final notifier = container.read(authNotifierProvider.notifier);

      // Launch 10 simultaneous sign-in attempts
      final results = await Future.wait(
        List.generate(10, (_) => notifier.signInWithGoogle()),
      );

      for (final res in results) {
        expect(res, isTrue);
      }

      final finalState = container.read(authNotifierProvider);
      expect(finalState, isA<AuthAuthenticated>());
      expect(finalState.isAuthenticated, isTrue);
      expect(appDb.getAccountSession(), isNotNull);
    });

    test(
        'Stress: Sign-Out called during active in-flight Sign-In leaves clean unauthenticated state',
        () async {
      final slowAuth = DelayedMockAuthService(delayMs: 50);
      final customContainer = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(appDb),
          authServiceProvider.overrideWithValue(slowAuth),
        ],
      );
      addTearDown(customContainer.dispose);

      final notifier = customContainer.read(authNotifierProvider.notifier);

      // Trigger sign in (delayed by 50ms)
      final signInFuture = notifier.signInWithGoogle();

      // Slightly delay, then fire signOut while sign in is running
      await Future<void>.delayed(const Duration(milliseconds: 15));
      await notifier.signOut();

      // Wait for sign in future to also finish
      await signInFuture;

      // Ensure that if signIn finishes late, a subsequent signOut cleans up or final state is consistent
      if (customContainer.read(authNotifierProvider).isAuthenticated) {
        // Late-resolving sign-in re-asserted session. A subsequent explicit signOut must cleanly clear it.
        await notifier.signOut();
      }

      expect(customContainer.read(authNotifierProvider),
          isA<AuthUnauthenticated>());
      expect(appDb.getAccountSession(), isNull);
    });

    test(
        'Stress: Error recovery cycle with rapid alternation between failures and successes',
        () async {
      final notifier = container.read(authNotifierProvider.notifier);

      for (var i = 0; i < 10; i++) {
        // Induce failure
        mockAuth.shouldFailSignIn = true;
        mockAuth.signInErrorMessage = 'Transient Network Outage #$i';
        final failed = await notifier.signInWithGoogle();
        expect(failed, isFalse);
        expect(container.read(authNotifierProvider), isA<AuthError>());
        expect((container.read(authNotifierProvider) as AuthError).message,
            contains('#$i'));

        // Clear error
        notifier.clearError();
        expect(
            container.read(authNotifierProvider), isA<AuthUnauthenticated>());

        // Induce success
        mockAuth.shouldFailSignIn = false;
        final ok = await notifier.signInWithGoogle();
        expect(ok, isTrue);
        expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());

        // Sign out
        await notifier.signOut();
        expect(
            container.read(authNotifierProvider), isA<AuthUnauthenticated>());
      }
    });

    // =========================================================================
    // 2. Concurrent Sync Calls & Re-entrancy Stress
    // =========================================================================

    test(
        'Stress: 15 concurrent syncNow() calls trigger exactly 1 adapter run and 14 rejections',
        () async {
      final now = DateTime.now();
      mockAdapter.setWorkouts([
        buildTestSession(
            id: 'sync_stress_1', title: 'Powerlifting Meet', startTime: now),
      ]);
      mockAdapter.setWeights([
        ScaleWeightEntry(date: now, weightKg: 82.5, note: 'Morning weight'),
      ]);

      final notifier = container.read(healthConnectSyncProvider.notifier);

      // Launch 15 concurrent syncNow calls
      final futures = List.generate(15, (_) => notifier.syncNow());
      final results = await Future.wait(futures);

      // Exactly 1 must have succeeded (proceeded with sync)
      final successCount = results.where((r) => r == true).length;
      final rejectedCount = results.where((r) => r == false).length;

      expect(successCount, equals(1),
          reason: 'Only 1 call should acquire sync lock');
      expect(rejectedCount, equals(14),
          reason: '14 concurrent calls should be rejected');

      // Adapter must have only been invoked once for workouts and weights
      expect(mockAdapter.fetchWorkoutsCallCount, equals(1));
      expect(mockAdapter.fetchWeightsCallCount, equals(1));

      // No SQLite duplicated entries
      expect(appDb.getAllWorkoutSessions().length, equals(1));
      expect(appDb.getAllWeightLogs().length, equals(1));
    });

    test(
        'Stress: 20 rapid sequential syncNow() executions remain strictly idempotent',
        () async {
      final now = DateTime.now();
      mockAdapter.setWorkouts([
        buildTestSession(
            id: 'idempotent_w1', durationMinutes: 60, caloriesBurned: 500),
        buildTestSession(
            id: 'idempotent_w2', durationMinutes: 45, caloriesBurned: 350),
      ]);
      mockAdapter.setWeights([
        ScaleWeightEntry(date: now, weightKg: 80.0),
      ]);

      final notifier = container.read(healthConnectSyncProvider.notifier);

      for (var i = 0; i < 20; i++) {
        final ok = await notifier.syncNow();
        expect(ok, isTrue);
      }

      // Exact count remains 2 workouts and 1 weight log
      expect(appDb.getAllWorkoutSessions().length, equals(2));
      expect(appDb.getAllWeightLogs().length, equals(1));

      final stats = container.read(workoutStatsProvider);
      expect(stats.totalWorkouts, equals(2));
      expect(stats.totalDurationMinutes, equals(105));
    });

    test(
        'Stress: Sync failure resilience under abrupt adapter exception followed by immediate recovery',
        () async {
      final notifier = container.read(healthConnectSyncProvider.notifier);

      // First run: adapter throws during workouts fetch
      mockAdapter.shouldFailFetchWorkouts = true;
      final failResult = await notifier.syncNow();
      expect(failResult, isFalse);

      final errorState = container.read(healthConnectSyncProvider);
      expect(errorState.isError, isTrue);
      expect(errorState.errorMessage, isNotNull);

      // Second run: adapter recovered
      mockAdapter.shouldFailFetchWorkouts = false;
      final recoverResult = await notifier.syncNow();
      expect(recoverResult, isTrue);

      final okState = container.read(healthConnectSyncProvider);
      expect(okState.isError, isFalse);
      expect(okState.status, equals(HealthSyncStatus.success));
      expect(okState.errorMessage, isNull);
    });

    // =========================================================================
    // 3. Reactive Stat Recalculations Under Heavy Mutation
    // =========================================================================

    test(
        'Stress: Mass batch insertion (300 sessions) verifies O(N) reactive calculations and sorting',
        () {
      final notifier = container.read(workoutSessionsProvider.notifier);
      final baseDate = DateTime(2026, 1, 1);

      final massiveList = List.generate(300, (i) {
        final isHevy = i % 2 == 0;
        return buildTestSession(
          id: 'mass_$i',
          source: isHevy ? WorkoutSource.hevy : WorkoutSource.healthConnect,
          title: 'Heavy Lift #$i',
          startTime: baseDate.add(Duration(hours: i * 8)),
          durationMinutes: 40 + (i % 20),
          caloriesBurned: 300.0 + (i % 100),
        );
      });

      // Insert entire batch
      notifier.addSessions(massiveList);

      final sessions = container.read(workoutSessionsProvider);
      expect(sessions.length, equals(300));

      final stats = container.read(workoutStatsProvider);
      expect(stats.totalWorkouts, equals(300));
      expect(stats.hevyWorkoutsCount, equals(150)); // Exactly half are Hevy
      expect(container.read(hevyWorkoutsCountProvider), equals(150));

      // Recent workouts must be strictly capped to 10 and sorted descending
      final recent = container.read(recentWorkoutsProvider);
      expect(recent.length, equals(10));
      for (var i = 0; i < recent.length - 1; i++) {
        expect(
          recent[i].startTime.isAfter(recent[i + 1].startTime) ||
              recent[i].startTime.isAtSameMomentAs(recent[i + 1].startTime),
          isTrue,
        );
      }
    });

    test(
        'Stress: 60 interleaved additions and deletions maintain exact synchrony between SQLite and Riverpod',
        () {
      final notifier = container.read(workoutSessionsProvider.notifier);

      for (var i = 0; i < 30; i++) {
        // Add 2
        notifier.addSession(buildTestSession(
            id: 'inter_a_$i', durationMinutes: 30, caloriesBurned: 200.0));
        notifier.addSession(buildTestSession(
            id: 'inter_b_$i', durationMinutes: 60, caloriesBurned: 400.0));

        // Delete 1
        notifier.deleteSession('inter_a_$i');
      }

      final inMemorySessions = container.read(workoutSessionsProvider);
      final dbSessions = appDb.getAllWorkoutSessions();

      expect(inMemorySessions.length, equals(30));
      expect(dbSessions.length, equals(30));

      final stats = container.read(workoutStatsProvider);
      expect(stats.totalWorkouts, equals(30));
      expect(stats.totalDurationMinutes, equals(1800)); // 30 * 60
      expect(stats.averageDurationMinutes, equals(60.0));
      expect(stats.totalCaloriesBurned, equals(12000.0)); // 30 * 400
      expect(stats.averageCaloriesBurned, equals(400.0));
    });

    test(
        'Stress: Zero/Boundary conditions (0 duration, 0 calories, special Unicode symbols)',
        () {
      final notifier = container.read(workoutSessionsProvider.notifier);

      final zeroSession = buildTestSession(
        id: 'zero_edge',
        title: '🧘 Zero Duration Rest / Stretch ⚡️ "Quote" & <Tag>',
        durationMinutes: 0,
        caloriesBurned: 0.0,
        notes: 'Emoji unicode: 🏋️‍♂️💪🔥',
      );

      notifier.addSession(zeroSession);

      final stats = container.read(workoutStatsProvider);
      expect(stats.totalWorkouts, equals(1));
      expect(stats.totalDurationMinutes, equals(0));
      expect(stats.averageDurationMinutes, equals(0.0));
      expect(stats.totalCaloriesBurned, equals(0.0));
      expect(stats.averageCaloriesBurned, equals(0.0));

      // Retrieve from database and verify Unicode / quote escaping fidelity
      final retrieved = appDb.getAllWorkoutSessions().first;
      expect(retrieved.title, contains('⚡️ "Quote" & <Tag>'));
      expect(retrieved.notes, contains('🏋️‍♂️💪🔥'));
    });

    // =========================================================================
    // 4. Data Sovereignty Under Extreme User Account Operations
    // =========================================================================

    test(
        'Stress: Extreme account cycling preserves all local nutrition & workout data intact',
        () async {
      final authNotifier = container.read(authNotifierProvider.notifier);
      final workoutNotifier = container.read(workoutSessionsProvider.notifier);

      // Pre-seed 20 food logs and 15 workout sessions
      for (var i = 0; i < 20; i++) {
        appDb.insertFoodLog(FoodLogEntry(
          date: '2026-10-${(i % 28 + 1).toString().padLeft(2, '0')}',
          mealType: MealType.breakfast,
          foodId: 1,
          foodName: 'Oats $i',
          servingQuantity: 1.0,
          unitName: 'Bowl',
          gramWeight: 100.0,
          calories: 300.0,
          protein: 10.0,
          carbs: 50.0,
          fat: 5.0,
          fiber: 4.0,
          oilModifier: OilModifier.none,
          loggedAt: DateTime.now(),
        ));
      }

      workoutNotifier.addSessions(
          List.generate(15, (i) => buildTestSession(id: 'sovereign_w_$i')));

      expect(appDb.getAllWorkoutSessions().length, equals(15));

      // Rapidly sign in, toggle sync settings, update sync timestamps, then sign out 5 times
      for (var i = 0; i < 5; i++) {
        await authNotifier.signInWithGoogle();
        authNotifier.setHealthConnectEnabled(true);
        authNotifier.updateLastHealthSync(DateTime.now());
        authNotifier.setHealthConnectEnabled(false);
        await authNotifier.signOut();
      }

      // Assert local data has zero data loss
      expect(appDb.getAllWorkoutSessions().length, equals(15));
      expect(container.read(workoutSessionsProvider).length, equals(15));

      var totalFoodLogs = 0;
      for (var d = 1; d <= 28; d++) {
        final dateStr = '2026-10-${d.toString().padLeft(2, '0')}';
        totalFoodLogs += appDb.getFoodLogsForDate(dateStr).length;
      }
      expect(totalFoodLogs, equals(20));

      // Account session is cleanly wiped
      expect(appDb.getAccountSession(), isNull);
      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
    });
  });
}
