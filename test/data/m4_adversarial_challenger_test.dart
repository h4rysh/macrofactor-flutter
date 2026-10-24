import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/workout_session.dart';
import 'package:sique/presentation/providers/workout_providers.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('Milestone 4 Challenger Adversarial & Stress Verification Suite', () {
    // =========================================================================
    // 1. Foreign Key Violation Rejection Across Multiple Scenarios
    // =========================================================================
    group('Foreign Key Referential Integrity Rejection', () {
      test(
          'Active foreign keys reject orphan insert, enforce RESTRICT and CASCADE',
          () {
        final rawDb = sqlite3.openInMemory();
        DatabaseMigrations.initializeAndMigrate(rawDb, isInMemory: true);

        // Ensure PRAGMA foreign_keys is 1
        final fkState = rawDb.select('PRAGMA foreign_keys;').first.values.first;
        expect(fkState, equals(1));

        // Create schema with both RESTRICT and CASCADE foreign key relationships
        rawDb.execute('''
          CREATE TABLE parent_dept (
            dept_id TEXT PRIMARY KEY,
            dept_name TEXT NOT NULL
          );
          CREATE TABLE child_employee (
            emp_id TEXT PRIMARY KEY,
            dept_id TEXT NOT NULL,
            emp_name TEXT NOT NULL,
            FOREIGN KEY (dept_id) REFERENCES parent_dept(dept_id) ON DELETE RESTRICT ON UPDATE CASCADE
          );
          CREATE TABLE child_badge (
            badge_id TEXT PRIMARY KEY,
            emp_id TEXT NOT NULL,
            FOREIGN KEY (emp_id) REFERENCES child_employee(emp_id) ON DELETE CASCADE
          );
        ''');

        rawDb.execute(
            "INSERT INTO parent_dept (dept_id, dept_name) VALUES ('eng', 'Engineering');");
        rawDb.execute(
            "INSERT INTO child_employee (emp_id, dept_id, emp_name) VALUES ('e1', 'eng', 'Alice');");
        rawDb.execute(
            "INSERT INTO child_badge (badge_id, emp_id) VALUES ('b1', 'e1');");

        // 1. Orphan child insertion must fail with SqliteException (FK violation)
        expect(
          () => rawDb.execute(
              "INSERT INTO child_employee (emp_id, dept_id, emp_name) VALUES ('e2', 'nonexistent_dept', 'Bob');"),
          throwsA(isA<SqliteException>()),
        );

        // 2. ON DELETE RESTRICT prevents deleting parent when children exist
        expect(
          () => rawDb.execute("DELETE FROM parent_dept WHERE dept_id = 'eng';"),
          throwsA(isA<SqliteException>()),
        );

        // 3. ON UPDATE CASCADE updates child foreign key
        rawDb.execute(
            "UPDATE parent_dept SET dept_id = 'rd' WHERE dept_id = 'eng';");
        final updatedEmpDept = rawDb
            .select("SELECT dept_id FROM child_employee WHERE emp_id = 'e1';")
            .first['dept_id'];
        expect(updatedEmpDept, equals('rd'));

        // 4. ON DELETE CASCADE on child_badge when child_employee is deleted
        rawDb.execute("DELETE FROM child_employee WHERE emp_id = 'e1';");
        final remainingBadges = rawDb
            .select('SELECT COUNT(*) as cnt FROM child_badge;')
            .first['cnt'];
        expect(remainingBadges, equals(0));

        // Now parent_dept can be deleted since child_employee is gone
        expect(
            () =>
                rawDb.execute("DELETE FROM parent_dept WHERE dept_id = 'rd';"),
            returnsNormally);

        rawDb.dispose();
      });
    });

    // =========================================================================
    // 2. Crash During Migration Step Verifying Rollback & Atomicity
    // =========================================================================
    group('Migration Step Crash & Rollback Atomicity', () {
      test(
          'Mid-step DDL crash completely rolls back added columns and preserves version',
          () {
        final rawDb = sqlite3.openInMemory();
        DatabaseMigrations.initializeAndMigrate(rawDb, isInMemory: true);

        final initialVersion =
            rawDb.select('PRAGMA user_version;').first.values.first as int;
        expect(initialVersion, equals(2));

        // Simulate failing step 3 that adds a column and then throws before commit
        expect(
          () => DatabaseMigrations.runStepForTest(rawDb, 3, (db) {
            db.execute(
                'ALTER TABLE user_profile ADD COLUMN experimental_metric REAL;');
            // Throw before user_version is bumped or committed
            throw StateError('Simulated crash during schema migration step 3');
          }),
          throwsA(isA<StateError>()),
        );

        // Verify user_version remained unchanged
        final versionAfterRollback =
            rawDb.select('PRAGMA user_version;').first.values.first as int;
        expect(versionAfterRollback, equals(2));

        // Verify experimental_metric was completely rolled back from table schema
        final tableInfo = rawDb.select("PRAGMA table_info('user_profile');");
        final columns = tableInfo.map((r) => r['name'] as String).toSet();
        expect(columns.contains('experimental_metric'), isFalse);

        // Verify database is back in autocommit mode
        expect(rawDb.autocommit, isTrue);

        rawDb.dispose();
      });

      test('Mid-step data migration failure rolls back all data modifications',
          () {
        final rawDb = sqlite3.openInMemory();
        DatabaseMigrations.initializeAndMigrate(rawDb, isInMemory: true);

        // Seed 1 row in app_settings
        rawDb.execute(
            "INSERT INTO app_settings (key, value) VALUES ('version_meta', '1.0');");

        expect(
          () => DatabaseMigrations.runStepForTest(rawDb, 3, (db) {
            db.execute(
                "INSERT INTO app_settings (key, value) VALUES ('step3_key', 'val3');");
            db.execute(
                "UPDATE app_settings SET value = '2.0' WHERE key = 'version_meta';");
            throw const SocketException(
                'Simulated crash during data migration');
          }),
          throwsA(isA<SocketException>()),
        );

        // Verify app_settings was restored to exact prior state
        final settingsRows = rawDb.select('SELECT * FROM app_settings;');
        expect(settingsRows.length, equals(1));
        expect(settingsRows.first['key'], equals('version_meta'));
        expect(settingsRows.first['value'], equals('1.0'));

        rawDb.dispose();
      });

      test(
          'Step that fails on first statement rolls back cleanly and allows subsequent retry',
          () {
        final rawDb = sqlite3.openInMemory();
        DatabaseMigrations.initializeAndMigrate(rawDb, isInMemory: true);

        var attempt = 0;
        void migrationStep(CommonDatabase db) {
          attempt++;
          if (attempt == 1) {
            db.execute('CREATE TABLE retry_table (id INT PRIMARY KEY);');
            throw Exception('Attempt 1 failed');
          } else {
            db.execute(
                'CREATE TABLE retry_table (id INT PRIMARY KEY, name TEXT);');
          }
        }

        // Attempt 1 fails
        expect(
          () => DatabaseMigrations.runStepForTest(rawDb, 3, migrationStep),
          throwsA(isA<Exception>()),
        );
        expect(
            rawDb.select('PRAGMA user_version;').first.values.first, equals(2));

        // Attempt 2 succeeds
        DatabaseMigrations.runStepForTest(rawDb, 3, migrationStep);
        expect(
            rawDb.select('PRAGMA user_version;').first.values.first, equals(3));

        // Verify table exists with columns from attempt 2
        final cols = rawDb
            .select("PRAGMA table_info('retry_table');")
            .map((r) => r['name'] as String)
            .toSet();
        expect(cols, containsAll(['id', 'name']));

        rawDb.dispose();
      });
    });

    // =========================================================================
    // 3. Downgrade Protection Under Extreme Higher Versions
    // =========================================================================
    group('Downgrade Protection Under Higher user_version', () {
      test(
          'Protects higher user_versions (3, 10, 999999) without touching schema or version',
          () {
        final versionsToTest = [3, 4, 10, 999999];

        for (final higherVer in versionsToTest) {
          final rawDb = sqlite3.openInMemory();
          rawDb.execute('PRAGMA user_version = $higherVer;');

          // Run initializeAndMigrate
          DatabaseMigrations.initializeAndMigrate(rawDb, isInMemory: true);

          // user_version must remain untouched
          final ver =
              rawDb.select('PRAGMA user_version;').first.values.first as int;
          expect(ver, equals(higherVer),
              reason: 'Version $higherVer was corrupted by migration runner');

          // Schema tables must NOT have been created since migration was skipped
          final tableCount = rawDb
              .select(
                  "SELECT COUNT(*) as cnt FROM sqlite_master WHERE type='table';")
              .first['cnt'];
          expect(tableCount, equals(0),
              reason:
                  'Tables should not be created when higher version exists');

          rawDb.dispose();
        }
      });

      test('Exact currentVersion (2) executes cleanly as idempotent no-op', () {
        final rawDb = sqlite3.openInMemory();
        DatabaseMigrations.initializeAndMigrate(rawDb, isInMemory: true);
        expect(
            rawDb.select('PRAGMA user_version;').first.values.first, equals(2));

        // Calling it again should be a complete no-op
        DatabaseMigrations.initializeAndMigrate(rawDb, isInMemory: true);
        expect(
            rawDb.select('PRAGMA user_version;').first.values.first, equals(2));

        rawDb.dispose();
      });
    });

    // =========================================================================
    // 4. Concurrent Connection Contention with Busy Timeout (5000ms)
    // =========================================================================
    group('Concurrent Multi-Connection File Contention with busy_timeout', () {
      test(
          'Multi-isolate concurrency: background isolate waits for lock and completes successfully',
          () async {
        final tempDir = Directory.systemTemp
            .createTempSync('sique_challenger_concurrency_');
        final dbFile = p.join(tempDir.path, 'concurrency_test.db');

        final conn1 = sqlite3.open(dbFile);

        try {
          DatabaseMigrations.initializeAndMigrate(conn1, isInMemory: false);
          expect(conn1.select('PRAGMA busy_timeout;').first.values.first,
              equals(5000));

          // Conn 1 begins an exclusive transaction and holds lock
          conn1.execute('BEGIN EXCLUSIVE TRANSACTION;');
          conn1.execute(
              "INSERT INTO app_settings (key, value) VALUES ('lock_holder', 'conn1');");

          // Launch background isolate to attempt write to the same DB file
          final isolateFuture = Isolate.run<bool>(() async {
            final bgConn = sqlite3.open(dbFile);
            try {
              DatabaseMigrations.initializeAndMigrate(bgConn,
                  isInMemory: false);
              // This write will block in SQLite's busy handler waiting for conn1 to commit
              bgConn.execute(
                  "INSERT INTO app_settings (key, value) VALUES ('lock_waiter', 'conn2');");
              return true;
            } finally {
              bgConn.dispose();
            }
          });

          // Hold the lock for 400ms while isolate is waiting
          await Future<void>.delayed(const Duration(milliseconds: 400));

          // Conn 1 commits and releases the exclusive lock
          conn1.execute('COMMIT;');

          // Background isolate should now finish and return true within busy_timeout
          final result =
              await isolateFuture.timeout(const Duration(seconds: 4));
          expect(result, isTrue);

          // Verify both rows exist
          final rows = conn1.select('SELECT * FROM app_settings ORDER BY key;');
          expect(rows.length, equals(2));
          expect(rows.first['key'], equals('lock_holder'));
          expect(rows.last['key'], equals('lock_waiter'));
        } finally {
          conn1.dispose();
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        }
      });
    });

    // =========================================================================
    // 5. Verification of Typed Exception Handlers Across Edge Cases
    // =========================================================================
    group('Typed Exception Handlers Validation', () {
      test(
          'AppDatabaseCoachingExtension handles malformed JSON and TypeErrors safely without crashing',
          () {
        final appDb = AppDatabase.inMemory();

        // 1. Corrupt invalid JSON string
        appDb.setSetting('active_coaching_program', '{"broken_json: true,');
        final brokenProgram = appDb.getCoachingProgram();
        expect(brokenProgram, isNull);

        // 2. Valid JSON but wrong data type (schema mismatch leading to TypeError)
        appDb.setSetting('active_coaching_program', '{"days": "not_a_list"}');
        final typeErrorProgram = appDb.getCoachingProgram();
        expect(typeErrorProgram, isNull);

        // 3. Valid JSON with number instead of string for ID
        appDb.setSetting(
            'active_coaching_program', '{"id": 12345, "days": []}');
        final invalidIdProgram = appDb.getCoachingProgram();
        expect(invalidIdProgram, isNull);

        appDb.close();
      });

      test(
          'WorkoutSessionsNotifier handles SqliteException gracefully without crashing state',
          () {
        final rawDb = sqlite3.openInMemory();
        final appDb = AppDatabase(rawDb, isInMemory: true);

        final notifier = WorkoutSessionsNotifier(appDb);

        // Preload some state
        notifier.state = [
          WorkoutSession(
            id: 'ws_mem_1',
            source: WorkoutSource.hevy,
            title: 'Memory Session',
            startTime: DateTime(2026, 10, 24, 10, 0),
            endTime: DateTime(2026, 10, 24, 11, 0),
            durationMinutes: 60,
            caloriesBurned: 300.0,
            createdAt: DateTime.now(),
          ),
        ];

        // Drop the underlying table to trigger an actual SqliteException on next query
        rawDb.execute('DROP TABLE workout_sessions;');

        // refresh() catches SqliteException and resets state to [] without throwing
        expect(() => notifier.refresh(), returnsNormally);
        expect(notifier.state, isEmpty);

        // getSessionsInRange() catches SqliteException and safely falls back to in-memory filter
        notifier.state = [
          WorkoutSession(
            id: 'ws_mem_2',
            source: WorkoutSource.hevy,
            title: 'Fallback Session',
            startTime: DateTime(2026, 10, 24, 12, 0),
            endTime: DateTime(2026, 10, 24, 13, 0),
            durationMinutes: 60,
            caloriesBurned: 350.0,
            createdAt: DateTime.now(),
          ),
        ];

        final inRange = notifier.getSessionsInRange(
          DateTime(2026, 10, 24, 0, 0),
          DateTime(2026, 10, 24, 23, 59),
        );
        expect(inRange.length, equals(1));
        expect(inRange.first.id, equals('ws_mem_2'));

        rawDb.dispose();
      });
    });
  });
}
