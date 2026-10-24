import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('Database Migrations and Profile Column Schema Evolution', () {
    test(
        'Fresh database migration ladder upgrades user_version to 2 with WAL and foreign keys',
        () {
      final rawDb = sqlite3.openInMemory();
      DatabaseMigrations.initializeAndMigrate(rawDb, isInMemory: true);

      // Verify user_version is 2
      final versionResult = rawDb.select('PRAGMA user_version;');
      expect(versionResult.first.values.first, equals(2));

      // Verify foreign_keys enabled
      final fkResult = rawDb.select('PRAGMA foreign_keys;');
      expect(fkResult.first.values.first, equals(1));

      // Verify all 7 new columns exist in user_profile
      final tableInfo = rawDb.select("PRAGMA table_info('user_profile');");
      final columnNames = tableInfo.map((r) => r['name'] as String).toSet();

      expect(columnNames.contains('diet_type'), isTrue);
      expect(columnNames.contains('calorie_floor_type'), isTrue);
      expect(columnNames.contains('lifting_experience'), isTrue);
      expect(columnNames.contains('cardio_experience'), isTrue);
      expect(columnNames.contains('body_fat_range'), isTrue);
      expect(columnNames.contains('weight_history_max'), isTrue);
      expect(columnNames.contains('distribution_mode'), isTrue);

      rawDb.dispose();
    });

    test(
        'Upgrading v1 database with existing profile preserves existing data and adds new columns',
        () {
      final rawDb = sqlite3.openInMemory();

      // Create v1 schema manually without new columns
      rawDb.execute('''
        CREATE TABLE user_profile (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          current_weight REAL NOT NULL,
          target_weight REAL NOT NULL,
          height_cm REAL NOT NULL,
          age INTEGER NOT NULL,
          is_male INTEGER NOT NULL,
          goal_type TEXT NOT NULL,
          program_mode TEXT NOT NULL,
          weekly_rate REAL NOT NULL,
          protein_preference TEXT NOT NULL,
          calorie_floor REAL NOT NULL,
          baseline_expenditure REAL NOT NULL,
          custom_calories REAL,
          custom_protein REAL,
          custom_carbs REAL,
          custom_fat REAL
        );
        PRAGMA user_version = 1;
      ''');

      // Insert pre-existing v1 profile record
      rawDb.execute('''
        INSERT INTO user_profile (
          id, name, current_weight, target_weight, height_cm, age, is_male,
          goal_type, program_mode, weekly_rate, protein_preference,
          calorie_floor, baseline_expenditure
        ) VALUES (
          'user_legacy', 'Legacy User', 80.0, 75.0, 180.0, 30, 1,
          'fatLoss', 'coached', -0.5, 'high', 1400.0, 2400.0
        );
      ''');

      // Run migration
      DatabaseMigrations.initializeAndMigrate(rawDb, isInMemory: true);

      // Verify version upgraded to 2
      final versionResult = rawDb.select('PRAGMA user_version;');
      expect(versionResult.first.values.first, equals(2));

      final appDb = AppDatabase(rawDb, isInMemory: true);
      final profile = appDb.getUserProfile();

      expect(profile, isNotNull);
      expect(profile!.id, equals('user_legacy'));
      expect(profile.name, equals('Legacy User'));
      expect(profile.currentWeightKg, equals(80.0));
      // Verify new columns defaulted safely
      expect(profile.dietType, equals('standard'));
      expect(profile.calorieFloorType, equals('standard'));
      expect(profile.liftingExperience, equals('beginner'));
      expect(profile.cardioExperience, equals('beginner'));
      expect(profile.bodyFatRange, isNull);
      expect(profile.weightHistoryMax, isNull);
      expect(profile.distributionMode, equals('even'));

      appDb.close();
    });

    test(
        'Saving and retrieving UserProfile preserves all new profile attributes',
        () {
      final appDb = AppDatabase.inMemory();

      const advancedProfile = UserProfile(
        id: 'user_advanced',
        name: 'Sique Athlete',
        currentWeightKg: 82.5,
        targetWeightKg: 78.0,
        heightCm: 182.0,
        age: 26,
        isMale: true,
        goalType: GoalType.fatLoss,
        programMode: ProgramMode.coached,
        weeklyRateOfChangePct: -0.6,
        proteinPreference: ProteinPreference.extraHigh,
        calorieFloor: 1500.0,
        baselineExpenditureKcal: 2650.0,
        dietType: 'vegan',
        calorieFloorType: 'dynamic',
        liftingExperience: 'advanced',
        cardioExperience: 'intermediate',
        bodyFatRange: '12-15%',
        weightHistoryMax: 95.0,
        distributionMode: 'shiftedWorkout',
      );

      appDb.saveUserProfile(advancedProfile);

      final retrieved = appDb.getUserProfile();
      expect(retrieved, isNotNull);
      expect(retrieved!.dietType, equals('vegan'));
      expect(retrieved.calorieFloorType, equals('dynamic'));
      expect(retrieved.liftingExperience, equals('advanced'));
      expect(retrieved.cardioExperience, equals('intermediate'));
      expect(retrieved.bodyFatRange, equals('12-15%'));
      expect(retrieved.weightHistoryMax, equals(95.0));
      expect(retrieved.distributionMode, equals('shiftedWorkout'));

      appDb.close();
    });

    test(
        'Foreign keys pragma actively enforces referential integrity constraints',
        () {
      final rawDb = sqlite3.openInMemory();
      DatabaseMigrations.initializeAndMigrate(rawDb, isInMemory: true);

      // Verify PRAGMA foreign_keys is 1
      final fkPragma = rawDb.select('PRAGMA foreign_keys;');
      expect(fkPragma.first.values.first, equals(1));

      // Create test tables with foreign key relationship
      rawDb.execute('''
        CREATE TABLE fk_parent (
          id TEXT PRIMARY KEY,
          label TEXT NOT NULL
        );
        CREATE TABLE fk_child (
          id TEXT PRIMARY KEY,
          parent_id TEXT NOT NULL,
          FOREIGN KEY (parent_id) REFERENCES fk_parent(id) ON DELETE CASCADE
        );
      ''');

      rawDb.execute(
          "INSERT INTO fk_parent (id, label) VALUES ('p1', 'Parent 1');");

      // Valid insert should succeed
      rawDb
          .execute("INSERT INTO fk_child (id, parent_id) VALUES ('c1', 'p1');");
      final childCount =
          rawDb.select('SELECT COUNT(*) as cnt FROM fk_child;').first['cnt'];
      expect(childCount, equals(1));

      // Invalid insert referencing non-existent parent must throw SqliteException
      expect(
        () => rawDb.execute(
            "INSERT INTO fk_child (id, parent_id) VALUES ('c2', 'nonexistent');"),
        throwsA(isA<SqliteException>()),
      );

      // CASCADE delete: deleting parent deletes child
      rawDb.execute("DELETE FROM fk_parent WHERE id = 'p1';");
      final remainingChildren =
          rawDb.select('SELECT COUNT(*) as cnt FROM fk_child;').first['cnt'];
      expect(remainingChildren, equals(0));

      rawDb.dispose();
    });

    test('DatabaseMigrations configures busy_timeout to 5000ms', () {
      final rawDb = sqlite3.openInMemory();
      DatabaseMigrations.initializeAndMigrate(rawDb, isInMemory: true);

      final result = rawDb.select('PRAGMA busy_timeout;');
      expect(result.first.values.first, equals(5000));

      rawDb.dispose();
    });

    test(
        'File-based database configures journal_mode=WAL and synchronous=NORMAL',
        () {
      final tempDir = Directory.systemTemp.createTempSync('sique_test_wal_');
      final dbPath = p.join(tempDir.path, 'wal_test.db');
      final fileDb = sqlite3.open(dbPath);

      try {
        DatabaseMigrations.initializeAndMigrate(fileDb, isInMemory: false);

        final journalMode = fileDb.select('PRAGMA journal_mode;');
        expect(
          (journalMode.first.values.first as String).toLowerCase(),
          equals('wal'),
        );

        final synchronous = fileDb.select('PRAGMA synchronous;');
        // SQLite synchronous NORMAL corresponds to value 1
        expect(synchronous.first.values.first, equals(1));
      } finally {
        fileDb.dispose();
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    test('Failed migration rolls back changes and preserves prior user_version',
        () {
      final rawDb = sqlite3.openInMemory();
      DatabaseMigrations.initializeAndMigrate(rawDb, isInMemory: true);

      // Current user_version is 2
      final initialVersion =
          rawDb.select('PRAGMA user_version;').first.values.first;
      expect(initialVersion, equals(2));

      // Attempt a failing migration step to version 3
      expect(
        () => DatabaseMigrations.runStepForTest(rawDb, 3, (db) {
          db.execute('CREATE TABLE step3_rollback_table (id INT);');
          throw Exception('Simulated migration crash');
        }),
        throwsA(isA<Exception>()),
      );

      // Verify user_version remained 2
      final postFailureVersion =
          rawDb.select('PRAGMA user_version;').first.values.first;
      expect(postFailureVersion, equals(2));

      // Verify step3_rollback_table was rolled back and does not exist
      final checkTable = rawDb.select(
        "SELECT count(*) as cnt FROM sqlite_master WHERE type='table' AND name='step3_rollback_table';",
      );
      expect(checkTable.first['cnt'], equals(0));

      rawDb.dispose();
    });

    test('Isolated step-by-step v0 -> v1 -> v2 migration ladder', () {
      final rawDb = sqlite3.openInMemory();

      // Starts at v0
      final v0 = rawDb.select('PRAGMA user_version;').first.values.first;
      expect(v0, equals(0));

      // Verify user_profile table does not exist initially
      final initialTables = rawDb.select(
        "SELECT count(*) as cnt FROM sqlite_master WHERE type='table' AND name='user_profile';",
      );
      expect(initialTables.first['cnt'], equals(0));

      // Apply Step 1
      DatabaseMigrations.applyStepForTest(rawDb, 1);
      final v1 = rawDb.select('PRAGMA user_version;').first.values.first;
      expect(v1, equals(1));

      // Verify user_profile table exists under v1
      final tableInfoV1 = rawDb.select("PRAGMA table_info('user_profile');");
      expect(tableInfoV1, isNotEmpty);

      // Apply Step 2
      DatabaseMigrations.applyStepForTest(rawDb, 2);
      final v2 = rawDb.select('PRAGMA user_version;').first.values.first;
      expect(v2, equals(2));

      // Verify diet_type column exists in user_profile
      final tableInfoV2 = rawDb.select("PRAGMA table_info('user_profile');");
      final colsV2 = tableInfoV2.map((r) => r['name'] as String).toSet();
      expect(colsV2.contains('diet_type'), isTrue);

      rawDb.dispose();
    });

    test('Higher user_version is protected from downgrade overwrite', () {
      final rawDb = sqlite3.openInMemory();
      rawDb.execute('PRAGMA user_version = 5;');

      DatabaseMigrations.initializeAndMigrate(rawDb, isInMemory: true);

      final versionResult = rawDb.select('PRAGMA user_version;');
      expect(versionResult.first.values.first, equals(5));

      rawDb.dispose();
    });
  });
}
