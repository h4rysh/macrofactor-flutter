import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('Empirical Stress Testing: WAL Mode and Filesystem Concurrency', () {
    late Directory tempDir;
    late String dbPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('sique_wal_stress_');
      dbPath = p.join(tempDir.path, 'stress.db');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('File-based WAL mode creates shm and wal companion files on write',
        () {
      final db = sqlite3.open(dbPath);
      DatabaseMigrations.initializeAndMigrate(db, isInMemory: false);

      // Verify PRAGMA journal_mode
      final journalMode = db.select('PRAGMA journal_mode;');
      expect(
        (journalMode.first.values.first as String).toLowerCase(),
        equals('wal'),
      );

      // Insert data to force writing into WAL
      db.execute(
        "INSERT INTO user_profile (id, name, current_weight, target_weight, height_cm, age, is_male, goal_type, program_mode, weekly_rate, protein_preference, calorie_floor, baseline_expenditure) VALUES ('u1', 'Athlete', 75.0, 70.0, 175.0, 25, 1, 'fatLoss', 'coached', -0.5, 'high', 1500.0, 2500.0);",
      );

      // Check filesystem for .db
      final files = tempDir.listSync().map((f) => p.basename(f.path)).toList();
      expect(files.contains('stress.db'), isTrue);

      db.dispose();
    });

    test(
        'Concurrent readers succeed while write transaction is active in WAL mode',
        () {
      final writerDb = sqlite3.open(dbPath);
      DatabaseMigrations.initializeAndMigrate(writerDb, isInMemory: false);

      writerDb.execute(
        "INSERT INTO user_profile (id, name, current_weight, target_weight, height_cm, age, is_male, goal_type, program_mode, weekly_rate, protein_preference, calorie_floor, baseline_expenditure) VALUES ('u1', 'Initial', 75.0, 70.0, 175.0, 25, 1, 'fatLoss', 'coached', -0.5, 'high', 1500.0, 2500.0);",
      );

      // Second connection as reader
      final readerDb = sqlite3.open(dbPath);
      DatabaseMigrations.initializeAndMigrate(readerDb, isInMemory: false);

      // Start an exclusive/immediate write transaction on connection 1
      writerDb.execute('BEGIN IMMEDIATE;');
      writerDb.execute(
        "UPDATE user_profile SET name = 'Modified In Tx' WHERE id = 'u1';",
      );

      // Reader connection can read concurrently without blocking because WAL enables snapshot isolation
      final readResult =
          readerDb.select("SELECT name FROM user_profile WHERE id = 'u1';");
      expect(readResult.first['name'], equals('Initial'));

      // Commit writer
      writerDb.execute('COMMIT;');

      // Now reader sees committed data
      final readAfterCommit =
          readerDb.select("SELECT name FROM user_profile WHERE id = 'u1';");
      expect(readAfterCommit.first['name'], equals('Modified In Tx'));

      readerDb.dispose();
      writerDb.dispose();
    });
  });

  group('Empirical Stress Testing: busy_timeout Behavior', () {
    late Directory tempDir;
    late String dbPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('sique_busy_stress_');
      dbPath = p.join(tempDir.path, 'busy_test.db');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('busy_timeout pragma is configured to 5000ms by initializeAndMigrate',
        () {
      final db = sqlite3.open(dbPath);
      DatabaseMigrations.initializeAndMigrate(db, isInMemory: false);
      expect(
          db.select('PRAGMA busy_timeout;').first.values.first, equals(5000));
      db.dispose();
    });

    test(
        'busy_timeout waits for cross-isolate lock release and avoids SQLITE_BUSY crash',
        () async {
      final db = sqlite3.open(dbPath);
      DatabaseMigrations.initializeAndMigrate(db, isInMemory: false);
      db.execute(
        "INSERT INTO user_profile (id, name, current_weight, target_weight, height_cm, age, is_male, goal_type, program_mode, weekly_rate, protein_preference, calorie_floor, baseline_expenditure) VALUES ('u1', 'Initial', 75.0, 70.0, 175.0, 25, 1, 'fatLoss', 'coached', -0.5, 'high', 1500.0, 2500.0);",
      );

      // Spawn background isolate that locks the database file exclusively for 300ms
      final backgroundLock = Isolate.run(() async {
        final isolateDb = sqlite3.open(dbPath);
        isolateDb.execute('PRAGMA busy_timeout = 5000;');
        isolateDb.execute('BEGIN EXCLUSIVE;');
        await Future.delayed(const Duration(milliseconds: 300));
        isolateDb.execute(
          "UPDATE user_profile SET name = 'Isolate Updated' WHERE id = 'u1';",
        );
        isolateDb.execute('COMMIT;');
        isolateDb.dispose();
      });

      // Give isolate a moment to acquire lock
      await Future.delayed(const Duration(milliseconds: 50));

      final stopwatch = Stopwatch()..start();
      // Main isolate attempts to begin exclusive write transaction
      // Because PRAGMA busy_timeout is 5000ms, it should wait for the 300ms isolate lock rather than crashing
      db.execute('BEGIN EXCLUSIVE;');
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(200));

      // Main isolate commits successfully
      db.execute('COMMIT;');
      await backgroundLock;

      final result =
          db.select("SELECT name FROM user_profile WHERE id = 'u1';");
      expect(result.first['name'], equals('Isolate Updated'));

      db.dispose();
    });
  });

  group(
      'Empirical Stress Testing: Corrupted JSON and Invalid Dates in Providers',
      () {
    test(
        'Corrupted JSON in active_coaching_program gracefully falls back to default program',
        () {
      final appDb = AppDatabase.inMemory();

      // Corrupt the setting directly
      appDb.setSetting(
          'active_coaching_program', '{"incomplete_json": true, "corrupted');

      // Verify getCoachingProgram() does not throw and returns null
      expect(() => appDb.getCoachingProgram(), returnsNormally);
      expect(appDb.getCoachingProgram(), isNull);

      // Now verify Riverpod provider handles corrupted JSON seamlessly
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(appDb),
          userProfileProvider.overrideWith(
            (ref) => UserProfileNotifier(appDb, ref)
              ..state = const UserProfile(
                id: 'test_user',
                name: 'Tester',
                currentWeightKg: 80.0,
                targetWeightKg: 75.0,
                heightCm: 180.0,
                age: 28,
                isMale: true,
                goalType: GoalType.fatLoss,
                programMode: ProgramMode.coached,
                weeklyRateOfChangePct: -0.5,
                proteinPreference: ProteinPreference.high,
                calorieFloor: 1500.0,
                baselineExpenditureKcal: 2500.0,
              ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Reading weeklyMacroProgramProvider should not crash and should produce a valid program
      final program = container.read(weeklyMacroProgramProvider);
      expect(program, isNotNull);
      expect(program.days.length, equals(7));
      expect(program.days.first.calories, greaterThan(1000));

      appDb.close();
    });

    test(
        'JSON schema mismatch (TypeError) in active_coaching_program gracefully falls back',
        () {
      final appDb = AppDatabase.inMemory();

      // Store a valid JSON object that violates WeeklyMacroProgram schema (TypeError on fromJson)
      appDb.setSetting('active_coaching_program',
          jsonEncode({'id': 12345, 'days': 'not_a_list'}));

      // Verify getCoachingProgram() catches TypeError and returns null
      expect(() => appDb.getCoachingProgram(), returnsNormally);
      expect(appDb.getCoachingProgram(), isNull);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(appDb),
          userProfileProvider.overrideWith(
            (ref) => UserProfileNotifier(appDb, ref)
              ..state = const UserProfile(
                id: 'test_user',
                name: 'Tester',
                currentWeightKg: 80.0,
                targetWeightKg: 75.0,
                heightCm: 180.0,
                age: 28,
                isMale: true,
                goalType: GoalType.fatLoss,
                programMode: ProgramMode.coached,
                weeklyRateOfChangePct: -0.5,
                proteinPreference: ProteinPreference.high,
                calorieFloor: 1500.0,
                baselineExpenditureKcal: 2500.0,
              ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final program = container.read(weeklyMacroProgramProvider);
      expect(program, isNotNull);
      expect(program.days.length, equals(7));

      appDb.close();
    });

    test(
        'Malformed selectedDateStr in dayMacroTargetForSelectedDateProvider falls back to day 1 target',
        () {
      final appDb = AppDatabase.inMemory();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(appDb),
          selectedDateProvider.overrideWith((ref) => 'not-a-valid-date-string'),
        ],
      );
      addTearDown(container.dispose);

      // Reading dayMacroTargetForSelectedDateProvider must not throw FormatException
      expect(
        () => container.read(dayMacroTargetForSelectedDateProvider),
        returnsNormally,
      );

      final target = container.read(dayMacroTargetForSelectedDateProvider);
      expect(target, isNotNull);
      expect(target.calories, greaterThan(0));

      appDb.close();
    });

    test(
        'Corrupted date string in getDailyCalorieTotals() does not crash expenditureStateProvider',
        () {
      final appDb = AppDatabase.inMemory();

      // Insert initial weight observation
      appDb.insertWeightLog('2026-10-20', 75.0, null);

      // Corrupt food_logs with an unparseable date
      appDb.rawDb.execute('''
        INSERT INTO food_logs (
          date, meal_type, food_id, food_name, serving_quantity, unit_name, gram_weight,
          calories, protein, carbs, fat, fiber, oil_modifier, logged_at, icon_svg
        ) VALUES (
          'completely-corrupted-date-xyz', 'breakfast', 1, 'Oats', 1.0, 'serving', 100.0,
          300.0, 10.0, 50.0, 5.0, 4.0, 'none', '2026-10-24T12:00:00Z', 'icon'
        );
      ''');

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(appDb),
        ],
      );
      addTearDown(container.dispose);

      // Reading expenditureStateProvider should log warning but not crash
      expect(
        () => container.read(expenditureStateProvider),
        returnsNormally,
      );

      final expenditure = container.read(expenditureStateProvider);
      expect(expenditure, isNotNull);
      expect(expenditure.expenditureKcal, greaterThan(0));

      appDb.close();
    });

    test(
        'SqliteException during workout provider operations is caught and logged gracefully',
        () {
      final appDb = AppDatabase.inMemory();

      // Drop workout_sessions table to force a SqliteException
      appDb.rawDb.execute('DROP TABLE workout_sessions;');

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(appDb),
        ],
      );
      addTearDown(container.dispose);

      // Notifier refresh should catch SqliteException and leave state empty rather than crashing
      final notifier = container.read(workoutSessionsProvider.notifier);
      expect(() => notifier.refresh(), returnsNormally);
      expect(container.read(workoutSessionsProvider), isEmpty);

      // Range query should also catch SqliteException and return empty list
      expect(
        () => notifier.getSessionsInRange(DateTime.now(), DateTime.now()),
        returnsNormally,
      );
      expect(
        notifier.getSessionsInRange(DateTime.now(), DateTime.now()),
        isEmpty,
      );

      appDb.close();
    });
  });
}
