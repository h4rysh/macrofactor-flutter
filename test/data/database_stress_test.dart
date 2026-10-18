import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:macro_factor_app/data/local/app_database.dart';
import 'package:macro_factor_app/domain/models/food_models.dart';
import 'package:macro_factor_app/domain/models/user_account.dart';
import 'package:macro_factor_app/domain/models/user_profile.dart';
import 'package:macro_factor_app/domain/models/workout_session.dart';

void main() {
  group('AppDatabase Adversarial Stress & Chaos Test Suite', () {
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

    WorkoutSession createSession({
      required String id,
      String source = WorkoutSource.hevy,
      String title = 'Workout Session',
      required DateTime startTime,
      DateTime? endTime,
      int durationMinutes = 60,
      double caloriesBurned = 350.0,
      String? notes,
      DateTime? createdAt,
    }) {
      return WorkoutSession(
        id: id,
        source: source,
        title: title,
        startTime: startTime,
        endTime: endTime ?? startTime.add(Duration(minutes: durationMinutes)),
        durationMinutes: durationMinutes,
        caloriesBurned: caloriesBurned,
        notes: notes,
        createdAt: createdAt ?? startTime,
      );
    }

    // =========================================================================
    // 1. Large Batches (500-Item Batches, Upsert Scalability & Memory)
    // =========================================================================
    test(
        'Batch 500 sessions executes atomically, preserves chronological order, and upserts cleanly',
        () {
      final baseDate = DateTime(2025, 1, 1, 8, 0);
      final batch500 = List.generate(500, (i) {
        return createSession(
          id: 'stress_batch_${i.toString().padLeft(4, '0')}',
          title: 'Training Session #$i',
          startTime: baseDate.add(Duration(hours: i * 6)),
          durationMinutes: 30 + (i % 60),
          caloriesBurned: 200.0 + (i * 1.5),
          notes: 'Notes for workout $i with metric details',
        );
      });

      final stopwatch = Stopwatch()..start();
      appDb.insertWorkoutSessions(batch500);
      stopwatch.stop();

      // Ensure high-performance execution (< 1500ms for 500 items in SQLite)
      expect(stopwatch.elapsedMilliseconds, lessThan(1500));

      final all = appDb.getAllWorkoutSessions();
      expect(all.length, equals(500));

      // Validate descending chronological ordering across the entire 500 items
      for (var i = 0; i < all.length - 1; i++) {
        expect(
          all[i].startTime.isAfter(all[i + 1].startTime) ||
              all[i].startTime.isAtSameMomentAs(all[i + 1].startTime),
          isTrue,
          reason: 'Ordering violation at index $i vs ${i + 1}',
        );
      }
      expect(all.first.id, equals('stress_batch_0499'));
      expect(all.last.id, equals('stress_batch_0000'));

      // Test 500-item bulk upsert: re-insert with modified calorie count (+100 kcal)
      final updatedBatch500 = List.generate(500, (i) {
        return createSession(
          id: 'stress_batch_${i.toString().padLeft(4, '0')}',
          title: 'Updated Session #$i',
          startTime: baseDate.add(Duration(hours: i * 6)),
          durationMinutes: 45,
          caloriesBurned: 300.0 + (i * 1.5),
          notes: 'Updated notes',
        );
      });

      appDb.insertWorkoutSessions(updatedBatch500);

      final reloaded = appDb.getAllWorkoutSessions();
      expect(reloaded.length, equals(500)); // Zero duplicate rows created
      expect(reloaded.first.title, equals('Updated Session #499'));
      expect(reloaded.first.caloriesBurned, equals(300.0 + (499 * 1.5)));
      expect(reloaded.last.title, equals('Updated Session #0'));
    });

    test(
        'Batch insertion handles duplicate IDs within the same batch payload via ON CONFLICT',
        () {
      final baseDate = DateTime(2026, 10, 1, 9, 0);
      final conflictingBatch = [
        createSession(
          id: 'dup_id_1',
          title: 'First Variant',
          startTime: baseDate,
          caloriesBurned: 100.0,
        ),
        createSession(
          id: 'unique_id_2',
          title: 'Unique Session',
          startTime: baseDate.add(const Duration(hours: 1)),
        ),
        createSession(
          id: 'dup_id_1',
          title: 'Overwriting Second Variant',
          startTime: baseDate,
          caloriesBurned: 450.0,
        ),
      ];

      expect(
          () => appDb.insertWorkoutSessions(conflictingBatch), returnsNormally);

      final all = appDb.getAllWorkoutSessions();
      expect(all.length, equals(2));
      final overwritten = all.firstWhere((s) => s.id == 'dup_id_1');
      expect(overwritten.title, equals('Overwriting Second Variant'));
      expect(overwritten.caloriesBurned, equals(450.0));
    });

    test(
        'Empty and single-element session batches execute safely without transaction fault',
        () {
      expect(() => appDb.insertWorkoutSessions([]), returnsNormally);
      expect(appDb.getAllWorkoutSessions(), isEmpty);

      final single = createSession(
        id: 'single_item',
        startTime: DateTime(2026, 10, 1),
      );
      appDb.insertWorkoutSessions([single]);
      expect(appDb.getAllWorkoutSessions().length, equals(1));
    });

    // =========================================================================
    // 2. Date Range Boundary Filtering
    // =========================================================================
    test(
        'Date range filtering precisely respects sub-second and boundary timestamps',
        () {
      final rangeStart = DateTime(2026, 10, 15, 10, 0, 0);
      final rangeEnd = DateTime(2026, 10, 15, 18, 0, 0);

      final sBefore = createSession(
        id: 'just_before',
        startTime: rangeStart.subtract(const Duration(milliseconds: 1)),
      );
      final sExactStart = createSession(
        id: 'exact_start',
        startTime: rangeStart,
      );
      final sMidpoint = createSession(
        id: 'mid_session',
        startTime: DateTime(2026, 10, 15, 14, 0, 0),
      );
      final sExactEnd = createSession(
        id: 'exact_end',
        startTime: rangeEnd,
      );
      final sAfter = createSession(
        id: 'just_after',
        startTime: rangeEnd.add(const Duration(milliseconds: 1)),
      );

      appDb.insertWorkoutSessions(
          [sBefore, sExactStart, sMidpoint, sExactEnd, sAfter]);

      final inRange = appDb.getWorkoutSessionsInRange(rangeStart, rangeEnd);
      final inRangeIds = inRange.map((s) => s.id).toSet();

      expect(inRangeIds.contains('exact_start'), isTrue);
      expect(inRangeIds.contains('mid_session'), isTrue);
      expect(inRangeIds.contains('exact_end'), isTrue);
      expect(inRangeIds.contains('just_before'), isFalse);
      expect(inRangeIds.contains('just_after'), isFalse);
      expect(inRange.length, equals(3));
    });

    test(
        'Date range filtering across Year, Month, Leap Year, and Epoch boundaries',
        () {
      final leapYearSession = createSession(
        id: 'leap_year_2028',
        startTime: DateTime(2028, 2, 29, 12, 0),
      );
      final yearEndSession = createSession(
        id: 'year_end_2026',
        startTime: DateTime(2026, 12, 31, 23, 59, 59),
      );
      final newYearSession = createSession(
        id: 'new_year_2027',
        startTime: DateTime(2027, 1, 1, 0, 0, 0),
      );
      final epochSession = createSession(
        id: 'epoch_1970',
        startTime: DateTime(1970, 1, 1, 0, 0, 0),
      );

      appDb.insertWorkoutSessions([
        leapYearSession,
        yearEndSession,
        newYearSession,
        epochSession,
      ]);

      // Leap day query
      final leapResults = appDb.getWorkoutSessionsInRange(
        DateTime(2028, 2, 29, 0, 0),
        DateTime(2028, 2, 29, 23, 59, 59),
      );
      expect(leapResults.length, equals(1));
      expect(leapResults.first.id, equals('leap_year_2028'));

      // New year rollover query
      final yearRollover = appDb.getWorkoutSessionsInRange(
        DateTime(2026, 12, 31, 12, 0),
        DateTime(2027, 1, 1, 12, 0),
      );
      expect(yearRollover.length, equals(2));
      expect(yearRollover.map((e) => e.id),
          containsAll(['year_end_2026', 'new_year_2027']));

      // Inverted boundary returns empty
      final inverted = appDb.getWorkoutSessionsInRange(
        DateTime(2027, 1, 1),
        DateTime(2026, 1, 1),
      );
      expect(inverted, isEmpty);
    });

    test(
        'Date range filtering across 365 daily sessions returns exact expected slice',
        () {
      final yearStart = DateTime(2026, 1, 1, 9, 0);
      final yearSessions = List.generate(365, (dayIndex) {
        return createSession(
          id: 'day_${dayIndex + 1}',
          startTime: yearStart.add(Duration(days: dayIndex)),
        );
      });
      appDb.insertWorkoutSessions(yearSessions);

      // Query Q1 only (Jan 1 to Mar 31 = 90 days in non-leap year)
      final q1Sessions = appDb.getWorkoutSessionsInRange(
        DateTime(2026, 1, 1, 0, 0),
        DateTime(2026, 3, 31, 23, 59, 59),
      );
      expect(q1Sessions.length, equals(90));
      expect(q1Sessions.first.id, equals('day_90'));
      expect(q1Sessions.last.id, equals('day_1'));
    });

    // =========================================================================
    // 3. Unicode, Emojis, and SQL Injection Security
    // =========================================================================
    test(
        'Guards against SQL injection in all WorkoutSession and UserAccount fields',
        () {
      const sqlInjectionId = "test'; DROP TABLE workout_sessions; --";
      const sqlInjectionTitle =
          "Leg Day'); DELETE FROM user_account_session; --";
      const sqlInjectionNotes = "'; UPDATE foods SET calories = 0; --";

      final maliciousSession = WorkoutSession(
        id: sqlInjectionId,
        source: "' OR '1'='1",
        title: sqlInjectionTitle,
        startTime: DateTime(2026, 10, 17, 14, 0),
        endTime: DateTime(2026, 10, 17, 15, 0),
        durationMinutes: 60,
        caloriesBurned: 400.0,
        notes: sqlInjectionNotes,
        createdAt: DateTime(2026, 10, 17, 15, 5),
      );

      expect(() => appDb.insertWorkoutSessions([maliciousSession]),
          returnsNormally);

      final loaded = appDb.getAllWorkoutSessions();
      expect(loaded.length, equals(1));
      expect(loaded.first.id, equals(sqlInjectionId));
      expect(loaded.first.title, equals(sqlInjectionTitle));
      expect(loaded.first.notes, equals(sqlInjectionNotes));

      // Verify that tables still exist and were not dropped or deleted
      expect(
          rawDb
              .select('SELECT COUNT(*) as c FROM workout_sessions;')
              .first['c'],
          equals(1));
      expect(
          rawDb
              .select('SELECT COUNT(*) as c FROM user_account_session;')
              .first['c'],
          equals(0));

      // Test SQL injection in UserAccount session
      final maliciousAccount = UserAccount(
        id: "active'; DROP TABLE user_profile; --",
        googleUserId: "g_id' OR 1=1; --",
        displayName: "Robert'); DROP TABLE food_logs;--",
        email: "hacker'--@evil.com",
        photoUrl: "https://evil.com/pic'; SELECT * FROM--",
        healthConnectEnabled: true,
        lastHealthSyncTime: DateTime(2026, 10, 17),
        createdAt: DateTime(2026, 10, 17),
        updatedAt: DateTime(2026, 10, 17),
      );

      expect(() => appDb.saveAccountSession(maliciousAccount), returnsNormally);

      final loadedAccount = appDb.getAccountSession();
      expect(loadedAccount, isNotNull);
      expect(loadedAccount!.displayName,
          equals("Robert'); DROP TABLE food_logs;--"));
      expect(loadedAccount.email, equals("hacker'--@evil.com"));

      // Clean delete by malicious ID
      expect(() => appDb.deleteWorkoutSession(sqlInjectionId), returnsNormally);
      expect(appDb.getAllWorkoutSessions(), isEmpty);
    });

    test(
        'Preserves multi-byte UTF-8, complex ZWJ emojis, RTL Arabic, and CJK text',
        () {
      final exoticSession = WorkoutSession(
        id: 'unicode_stress_01',
        source: WorkoutSource.hevy,
        title:
            '🏋️‍♀️ 筋力トレーニング (Squats) • 100% PR! • تمارین القوة والرشاقة 🏋🏿‍♂️',
        startTime: DateTime(2026, 10, 17, 17, 0),
        endTime: DateTime(2026, 10, 17, 18, 30),
        durationMinutes: 90,
        caloriesBurned: 650.5,
        notes:
            'Family: 👨‍👩‍👧‍👦 • Math: ∑(x_i) ≥ 500kg & <x> ≠ 0 • Quotes: "Double" \'Single\' `Backtick`',
        createdAt: DateTime(2026, 10, 17, 18, 35),
      );

      appDb.insertWorkoutSessions([exoticSession]);

      final all = appDb.getAllWorkoutSessions();
      expect(all.length, equals(1));
      final s = all.first;
      expect(
          s.title,
          equals(
              '🏋️‍♀️ 筋力トレーニング (Squats) • 100% PR! • تمارین القوة والرشاقة 🏋🏿‍♂️'));
      expect(s.notes, contains('👨‍👩‍👧‍👦'));
      expect(s.notes, contains('∑(x_i) ≥ 500kg'));
      expect(s.notes, contains('"Double" \'Single\' `Backtick`'));
    });

    // =========================================================================
    // 4. Data Sovereignty Upon Session Clear
    // =========================================================================
    test(
        'Data Sovereignty: Mass data preservation across repeated sign-in / sign-out cycles',
        () {
      // 1. Seed heavy baseline dataset: 100 food logs, 100 weight logs, 100 workouts
      final rand = Random(42);
      for (var i = 0; i < 100; i++) {
        final dateStr = DateTime(2026, 1, 1)
            .add(Duration(days: i))
            .toIso8601String()
            .substring(0, 10);
        appDb.insertFoodLog(FoodLogEntry(
          date: dateStr,
          mealType: MealType.values[i % MealType.values.length],
          foodId: 100 + i,
          foodName: 'Food Item #$i',
          servingQuantity: 1.0 + (i * 0.1),
          unitName: 'Serving',
          gramWeight: 100.0 + i,
          calories: 150.0 + (i * 2),
          protein: 10.0 + (i * 0.5),
          carbs: 20.0 + i,
          fat: 5.0 + (i * 0.2),
          fiber: 3.0,
          oilModifier: OilModifier.standard,
          loggedAt: DateTime(2026, 1, 1 + i, 8, 0),
        ));

        appDb.insertWeightLog(
          dateStr,
          75.0 + (rand.nextDouble() * 5),
          'Weigh-in #$i',
        );
      }

      final sessions = List.generate(100, (i) {
        return createSession(
          id: 'sovereign_workout_$i',
          startTime: DateTime(2026, 6, 1).add(Duration(days: i)),
          durationMinutes: 45 + (i % 30),
          caloriesBurned: 300.0 + i,
        );
      });
      appDb.insertWorkoutSessions(sessions);

      // Save User Profile and Settings
      appDb.saveUserProfile(const UserProfile(
        id: 'user_profile_primary',
        name: 'Sovereign Athlete',
        currentWeightKg: 78.5,
        targetWeightKg: 75.0,
        heightCm: 180.0,
        age: 28,
        isMale: true,
        goalType: GoalType.fatLoss,
        programMode: ProgramMode.collaborative,
        weeklyRateOfChangePct: -0.5,
        proteinPreference: ProteinPreference.high,
        calorieFloor: 1500.0,
        baselineExpenditureKcal: 2600.0,
      ));
      appDb.setSetting('app_theme', 'obsidian_dark');
      appDb.setSetting('haptics_enabled', 'true');

      // Verify pre-conditions
      expect(appDb.getAllFoodLogs().length, equals(100));
      expect(appDb.getAllWeightLogs().length, equals(100));
      expect(appDb.getAllWorkoutSessions().length, equals(100));
      expect(appDb.getUserProfile()!.name, equals('Sovereign Athlete'));
      expect(appDb.getSetting('app_theme', ''), equals('obsidian_dark'));

      // Cycle 1: Sign in User 1 -> Sign out
      appDb.saveAccountSession(UserAccount(
        id: 'active_session',
        googleUserId: 'google_user_001',
        displayName: 'User One',
        email: 'user1@macrofactor.test',
        healthConnectEnabled: true,
        createdAt: DateTime(2026, 10, 17),
        updatedAt: DateTime(2026, 10, 17),
      ));
      expect(appDb.getAccountSession(), isNotNull);

      // Clear session (sign out)
      appDb.clearAccountSession();

      // Assert session table is 100% empty, while all personal health records remain intact
      expect(appDb.getAccountSession(), isNull);
      expect(appDb.getAllFoodLogs().length, equals(100));
      expect(appDb.getAllWeightLogs().length, equals(100));
      expect(appDb.getAllWorkoutSessions().length, equals(100));
      expect(appDb.getUserProfile()!.name, equals('Sovereign Athlete'));
      expect(appDb.getSetting('app_theme', ''), equals('obsidian_dark'));

      // Cycle 2: Sign in User 2 -> Perform new logs -> Sign out again
      appDb.saveAccountSession(UserAccount(
        id: 'active_session',
        googleUserId: 'google_user_002',
        displayName: 'User Two',
        email: 'user2@macrofactor.test',
        healthConnectEnabled: false,
        createdAt: DateTime(2026, 10, 17),
        updatedAt: DateTime(2026, 10, 17),
      ));
      expect(appDb.getAccountSession()!.displayName, equals('User Two'));

      // Append 1 new workout while authenticated
      appDb.insertWorkoutSessions([
        createSession(
          id: 'workout_cycle_2',
          startTime: DateTime(2026, 10, 17, 20, 0),
        ),
      ]);
      expect(appDb.getAllWorkoutSessions().length, equals(101));

      // Sign out again
      appDb.clearAccountSession();
      expect(appDb.getAccountSession(), isNull);
      expect(appDb.getAllWorkoutSessions().length, equals(101));
      expect(appDb.getAllFoodLogs().length, equals(100));
    });

    // =========================================================================
    // 5. Concurrency & Interleaved Async Pipelines
    // =========================================================================
    test(
        'Simulates 20 concurrent interleaved async operations across DAOs without deadlock',
        () async {
      final futures = <Future<void>>[];

      for (var workerId = 0; workerId < 20; workerId++) {
        futures.add(Future(() async {
          // Worker writes a session
          final sess = createSession(
            id: 'concurrent_w_${workerId}_s1',
            title: 'Worker $workerId Session',
            startTime: DateTime(2026, 10, 1, workerId % 24, 0),
            durationMinutes: 30 + workerId,
            caloriesBurned: 200.0 + workerId,
          );
          appDb.insertWorkoutSessions([sess]);

          // Worker queries in-range
          final inRange = appDb.getWorkoutSessionsInRange(
            DateTime(2026, 10, 1, 0, 0),
            DateTime(2026, 10, 2, 0, 0),
          );
          expect(inRange, isNotEmpty);

          // Worker saves account session
          appDb.saveAccountSession(UserAccount(
            id: 'active_session',
            googleUserId: 'worker_user_$workerId',
            displayName: 'Worker $workerId',
            email: 'worker$workerId@test.com',
            healthConnectEnabled: workerId.isEven,
            createdAt: DateTime(2026, 10, 17),
            updatedAt: DateTime(2026, 10, 17),
          ));

          // Worker reads account session
          final currentSession = appDb.getAccountSession();
          expect(currentSession, isNotNull);

          // Worker updates setting
          appDb.setSetting('worker_last_key_$workerId', 'val_$workerId');
          expect(appDb.getSetting('worker_last_key_$workerId', ''),
              equals('val_$workerId'));
        }));
      }

      await Future.wait(futures);

      // Verify all 20 worker sessions exist in DB
      final allSessions = appDb.getAllWorkoutSessions();
      expect(allSessions.length, equals(20));

      final activeAccount = appDb.getAccountSession();
      expect(activeAccount, isNotNull);
      expect(activeAccount!.email, contains('@test.com'));
    });

    // =========================================================================
    // 6. Transaction Rollback & State Isolation on Mid-Batch Faults
    // =========================================================================
    test(
        'Transaction rollback atomicity: failed batch leaves database in exact prior state',
        () {
      // Pre-seed 2 valid sessions
      final s1 =
          createSession(id: 'pre_seed_1', startTime: DateTime(2026, 10, 1));
      final s2 =
          createSession(id: 'pre_seed_2', startTime: DateTime(2026, 10, 2));
      appDb.insertWorkoutSessions([s1, s2]);
      expect(appDb.getAllWorkoutSessions().length, equals(2));

      // Create an abort trigger in SQLite that rejects id 'abort_trigger'
      rawDb.execute('''
        CREATE TRIGGER fail_on_trigger BEFORE INSERT ON workout_sessions
        WHEN NEW.id = 'abort_trigger'
        BEGIN
          SELECT RAISE(ABORT, 'Simulated Transaction Fault');
        END;
      ''');

      final faultyBatch = [
        createSession(id: 'batch_valid_3', startTime: DateTime(2026, 10, 3)),
        createSession(id: 'abort_trigger', startTime: DateTime(2026, 10, 4)),
        createSession(id: 'batch_valid_5', startTime: DateTime(2026, 10, 5)),
      ];

      expect(
        () => appDb.insertWorkoutSessions(faultyBatch),
        throwsA(isA<SqliteException>()),
      );

      // Verify ROLLBACK occurred: 'batch_valid_3' must NOT be in DB, count must remain exactly 2
      final remaining = appDb.getAllWorkoutSessions();
      expect(remaining.length, equals(2));
      expect(remaining.map((s) => s.id),
          containsAll(['pre_seed_1', 'pre_seed_2']));
      expect(remaining.map((s) => s.id), isNot(contains('batch_valid_3')));

      // Drop trigger and verify subsequent transaction works normally without connection lockout
      rawDb.execute('DROP TRIGGER fail_on_trigger;');
      expect(
        () => appDb.insertWorkoutSessions([
          createSession(
              id: 'post_recovery_6', startTime: DateTime(2026, 10, 6)),
        ]),
        returnsNormally,
      );
      expect(appDb.getAllWorkoutSessions().length, equals(3));
    });

    // =========================================================================
    // 7. Timezone Offset & UTC Precision Invariants
    // =========================================================================
    test(
        'Date range filtering consistency across UTC and Local DateTime objects',
        () {
      final utcSession = createSession(
        id: 'utc_sess',
        startTime: DateTime.utc(2026, 10, 15, 12, 0, 0),
      );
      appDb.insertWorkoutSessions([utcSession]);

      // Query with matching UTC bounds
      final utcQuery = appDb.getWorkoutSessionsInRange(
        DateTime.utc(2026, 10, 15, 0, 0, 0),
        DateTime.utc(2026, 10, 15, 23, 59, 59),
      );
      expect(utcQuery.length, equals(1));
      expect(utcQuery.first.id, equals('utc_sess'));
    });
  });
}
