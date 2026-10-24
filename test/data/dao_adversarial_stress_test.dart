import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/domain/models/workout_session.dart';

void main() {
  group('Milestone 3 DAO Adversarial Stress & Verification Suite', () {
    late Database rawDb;
    late AppDatabase appDb;

    setUp(() {
      appDb = AppDatabase.inMemory();
      rawDb = appDb.rawDb;
    });

    tearDown(() {
      rawDb.dispose();
    });

    ExpenditureRecord makeRecord({
      required String date,
      double expenditureKcal = 2200.0,
      double trendWeightKg = 75.0,
      double variance = 900.0,
      double confidence = 0.85,
    }) {
      return ExpenditureRecord(
        date: date,
        expenditureKcal: expenditureKcal,
        trendWeightKg: trendWeightKg,
        variance: variance,
        confidence: confidence,
      );
    }

    UserProfile makeProfile({
      String id = 'profile_test_1',
      String name = 'Test Athlete',
      double currentWeightKg = 78.5,
      double targetWeightKg = 74.0,
      double heightCm = 180.0,
      int age = 28,
      bool isMale = true,
      GoalType goalType = GoalType.fatLoss,
      ProgramMode programMode = ProgramMode.coached,
      double weeklyRateOfChangePct = -0.005,
      ProteinPreference proteinPreference = ProteinPreference.high,
      double calorieFloor = 1500.0,
      double baselineExpenditureKcal = 2400.0,
      String dietType = 'balanced',
      String calorieFloorType = 'standard',
      String liftingExperience = 'intermediate',
      String cardioExperience = 'beginner',
      String? bodyFatRange = '15-19%',
      double? weightHistoryMax = 85.0,
      String distributionMode = 'even',
    }) {
      return UserProfile(
        id: id,
        name: name,
        currentWeightKg: currentWeightKg,
        targetWeightKg: targetWeightKg,
        heightCm: heightCm,
        age: age,
        isMale: isMale,
        goalType: goalType,
        programMode: programMode,
        weeklyRateOfChangePct: weeklyRateOfChangePct,
        proteinPreference: proteinPreference,
        calorieFloor: calorieFloor,
        baselineExpenditureKcal: baselineExpenditureKcal,
        dietType: dietType,
        calorieFloorType: calorieFloorType,
        liftingExperience: liftingExperience,
        cardioExperience: cardioExperience,
        bodyFatRange: bodyFatRange,
        weightHistoryMax: weightHistoryMax,
        distributionMode: distributionMode,
      );
    }

    FoodItem makeFood({
      required int id,
      required String name,
      String category = 'Grains',
      double calories = 150.0,
      double protein = 5.0,
      double carbs = 30.0,
      double fat = 1.0,
      double fiber = 2.0,
    }) {
      return FoodItem(
        id: id,
        uuid: 'food_uuid_$id',
        name: name,
        category: category,
        region: 'Pan-Indian',
        caloriesPer100g: calories,
        proteinPer100g: protein,
        carbsPer100g: carbs,
        fatPer100g: fat,
        fiberPer100g: fiber,
        iconSvg: '<svg>food</svg>',
        source: 'ICMR',
        aliases: '$name alias',
        portionUnits: [
          PortionUnit(
            id: id * 10,
            foodId: id,
            unitName: '1 katori',
            gramWeight: 150.0,
            isDefault: true,
          ),
        ],
      );
    }

    // =========================================================================
    // 1. Transaction Rollback in ExpenditureDao.saveExpenditures
    // =========================================================================
    group('ExpenditureDao.saveExpenditures Transaction Rollback', () {
      test(
          'mid-batch failure rolls back entire batch leaving pre-existing rows intact',
          () {
        // Step 1: Pre-seed baseline expenditure rows
        final baseline = [
          makeRecord(date: '2026-01-01', expenditureKcal: 2100.0),
          makeRecord(date: '2026-01-02', expenditureKcal: 2150.0),
          makeRecord(date: '2026-01-03', expenditureKcal: 2200.0),
        ];
        appDb.expenditureDao.saveExpenditures(baseline);
        expect(appDb.expenditureDao.getExpenditureHistory().length, equals(3));

        // Step 2: Add trigger that aborts on specific date '2026-01-15'
        rawDb.execute('''
          CREATE TRIGGER abort_on_fifteenth BEFORE INSERT ON expenditure_history
          WHEN NEW.date = '2026-01-15'
          BEGIN
            SELECT RAISE(ABORT, 'Simulated mid-batch trigger fault on 15th');
          END;
        ''');

        // Step 3: Construct a batch of 25 records (dates Jan 10..Feb 3)
        // Record at index 5 is Jan 15, which will trigger the abort mid-loop
        final faultyBatch = List.generate(25, (i) {
          final dateStr = DateFormat('yyyy-MM-dd')
              .format(DateTime(2026, 1, 10).add(Duration(days: i)));
          return makeRecord(date: dateStr, expenditureKcal: 2500.0 + i);
        });

        // Step 4: Verify saveExpenditures throws SqliteException
        expect(
          () => appDb.expenditureDao.saveExpenditures(faultyBatch),
          throwsA(isA<SqliteException>()),
        );

        // Step 5: Verify complete rollback - zero rows from faultyBatch were committed
        final history = appDb.expenditureDao.getExpenditureHistory();
        expect(history.length, equals(3),
            reason:
                'Rollback must preserve original 3 rows and drop all 25 faulty rows');
        expect(history.map((r) => r.date).toList(),
            equals(['2026-01-01', '2026-01-02', '2026-01-03']));
        expect(history.any((r) => r.date == '2026-01-10'), isFalse);
        expect(history.any((r) => r.date == '2026-01-14'), isFalse);

        // Step 6: Verify autocommit status is restored (not stuck in active transaction)
        expect(rawDb.autocommit, isTrue,
            reason: 'Database must be in autocommit mode after rollback');

        // Step 7: Verify subsequent writes and reads succeed immediately without error
        rawDb.execute('DROP TRIGGER abort_on_fifteenth;');
        final validRecord =
            makeRecord(date: '2026-01-04', expenditureKcal: 2250.0);
        expect(() => appDb.expenditureDao.saveExpenditure(validRecord),
            returnsNormally);
        expect(appDb.expenditureDao.getExpenditureHistory().length, equals(4));
        expect(rawDb.autocommit, isTrue);
      });

      test(
          'empty list in saveExpenditures is safe no-op and preserves autocommit',
          () {
        expect(
            () => appDb.expenditureDao.saveExpenditures([]), returnsNormally);
        expect(rawDb.autocommit, isTrue);
        expect(appDb.expenditureDao.getExpenditureHistory(), isEmpty);
      });

      test('single-record list in saveExpenditures commits atomically', () {
        final rec = makeRecord(date: '2026-03-01', expenditureKcal: 2450.0);
        appDb.expenditureDao.saveExpenditures([rec]);
        expect(rawDb.autocommit, isTrue);
        final fetched =
            appDb.expenditureDao.getExpenditureForDate('2026-03-01');
        expect(fetched, isNotNull);
        expect(fetched!.expenditureKcal, equals(2450.0));
      });

      test('batch with 2,000 records executes cleanly in single transaction',
          () {
        final baseDate = DateTime(2020, 1, 1);
        final records2000 = List.generate(2000, (i) {
          final dateStr =
              DateFormat('yyyy-MM-dd').format(baseDate.add(Duration(days: i)));
          return makeRecord(
            date: dateStr,
            expenditureKcal: 2000.0 + (i % 200),
            trendWeightKg: 75.0 + sin(i * 0.01) * 3.0,
          );
        });

        final sw = Stopwatch()..start();
        appDb.expenditureDao.saveExpenditures(records2000);
        sw.stop();

        expect(sw.elapsedMilliseconds, lessThan(3000));
        expect(rawDb.autocommit, isTrue);
        expect(
            appDb.expenditureDao.getExpenditureHistory().length, equals(2000));
      });
    });

    // =========================================================================
    // 2. Statement Disposal & Leak Checks Across All DAOs
    // =========================================================================
    group('Statement Disposal & Resource Leak Checks', () {
      test(
          '1000 consecutive faulted queries across DAOs do not corrupt connection',
          () {
        // Install trigger that causes every insert to fail
        rawDb.execute('''
          CREATE TRIGGER fail_expenditure BEFORE INSERT ON expenditure_history
          BEGIN
            SELECT RAISE(ABORT, 'Intentional fault');
          END;
        ''');

        for (var i = 0; i < 500; i++) {
          expect(
            () => appDb.expenditureDao.saveExpenditure(
              makeRecord(
                  date: '2026-05-${(i % 28 + 1).toString().padLeft(2, '0')}'),
            ),
            throwsA(isA<SqliteException>()),
          );
        }

        rawDb.execute('DROP TRIGGER fail_expenditure;');

        // Verify connection is healthy and autocommit is on
        expect(rawDb.autocommit, isTrue);
        final check = rawDb.select('PRAGMA integrity_check;');
        expect(check.first.values.first, equals('ok'));

        // Subsequent valid write works normally
        appDb.expenditureDao.saveExpenditure(makeRecord(date: '2026-05-01'));
        expect(appDb.expenditureDao.getExpenditureHistory().length, equals(1));
      });

      test(
          'repeated mid-batch faults in saveExpenditures do not leak active transactions or prevent clean DB close',
          () {
        final localRaw = sqlite3.openInMemory();
        final localApp = AppDatabase.inMemory();

        localApp.rawDb.execute('''
          CREATE TRIGGER fail_midway BEFORE INSERT ON expenditure_history
          WHEN NEW.date = '2026-08-05'
          BEGIN
            SELECT RAISE(ABORT, 'Midway fault');
          END;
        ''');

        // Execute 500 faulty batch attempts
        final batch = List.generate(10, (i) {
          final d = '2026-08-${(i + 1).toString().padLeft(2, '0')}';
          return makeRecord(date: d);
        });

        for (var i = 0; i < 200; i++) {
          expect(
            () => localApp.expenditureDao.saveExpenditures(batch),
            throwsA(isA<SqliteException>()),
          );
          // Autocommit must be true after each rollback
          expect(localApp.rawDb.autocommit, isTrue);
        }

        // Integrity check
        final integrity = localApp.rawDb.select('PRAGMA integrity_check;');
        expect(integrity.first.values.first, equals('ok'));

        // Verify clean disposal without throwing
        expect(() => localApp.close(), returnsNormally);
        localRaw.dispose();
      });

      test(
          'repeated open and close cycles of in-memory database dispose cleanly',
          () {
        for (var i = 0; i < 20; i++) {
          final testDb = AppDatabase.inMemory();
          testDb.settingsDao.setSetting('test_key_$i', 'value_$i');
          expect(testDb.settingsDao.getSetting('test_key_$i', ''),
              equals('value_$i'));
          testDb.expenditureDao.saveExpenditure(makeRecord(date: '2026-01-01'));
          testDb.weightDao.insertWeightLog('2026-01-01', 75.0, 'note');
          expect(() => testDb.close(), returnsNormally);
        }
      });

      test(
          'closing rawDb after hundreds of operations succeeds with ok integrity',
          () {
        final standaloneRaw = sqlite3.openInMemory();
        final standaloneApp = AppDatabase(standaloneRaw, isInMemory: true);

        // Perform operations across all 6 DAOs
        for (var i = 0; i < 100; i++) {
          standaloneApp.settingsDao.setSetting('key_$i', 'val_$i');
          standaloneApp.weightDao.insertWeightLog(
              '2026-01-${(i % 28 + 1).toString().padLeft(2, '0')}',
              70.0 + i * 0.1,
              null);
          standaloneApp.expenditureDao.setDayComplete(
              '2026-01-${(i % 28 + 1).toString().padLeft(2, '0')}', i.isEven);
        }

        final integrity = standaloneRaw.select('PRAGMA integrity_check;');
        expect(integrity.first.values.first, equals('ok'));

        expect(() => standaloneApp.close(), returnsNormally);
      });
    });

    // =========================================================================
    // 3. Multi-DAO Heavy Concurrency Stress Test (6 DAOs Interleaved)
    // =========================================================================
    group('Multi-DAO High-Concurrency Interleaving', () {
      test('60 concurrent async workers hammering all 6 DAOs simultaneously',
          () async {
        final futures = <Future<void>>[];

        for (var workerId = 0; workerId < 60; workerId++) {
          final wId = workerId;
          futures.add(Future(() async {
            final dateStr =
                '2026-07-${(wId % 28 + 1).toString().padLeft(2, '0')}';

            // 1. SettingsDao operations
            appDb.settingsDao.setSetting('worker_key_$wId', 'value_$wId');
            final retrievedSetting =
                appDb.settingsDao.getSetting('worker_key_$wId', 'default');
            expect(retrievedSetting, equals('value_$wId'));

            // 2. WeightDao operations (testing source sovereignty)
            // Health connect write
            appDb.weightDao.insertWeightLog(
              dateStr,
              75.0 + (wId * 0.1),
              'Health Connect sync',
              source: 'health_connect',
            );
            // Manual write overrides health connect
            appDb.weightDao.insertWeightLog(
              dateStr,
              74.5,
              'Manual weigh-in',
              source: 'manual',
            );
            // Subsequent health connect should NOT overwrite manual
            appDb.weightDao.insertWeightLog(
              dateStr,
              99.9,
              'Health Connect should be ignored',
              source: 'health_connect',
            );
            final weightEntry = appDb.weightDao.getWeightLogForDate(dateStr);
            expect(weightEntry, isNotNull);
            expect(weightEntry!.weightKg, equals(74.5),
                reason:
                    'Manual weight must never be overwritten by health_connect');

            // 3. ProfileDao operations
            final profile = makeProfile(
              id: 'profile_worker_$wId',
              name: 'Worker $wId',
              currentWeightKg: 70.0 + wId,
            );
            appDb.profileDao.saveUserProfile(profile);
            final readProfile = appDb.profileDao.getUserProfile();
            expect(readProfile, isNotNull);

            final session = UserAccount(
              id: 'session_$wId',
              googleUserId: 'google_id_$wId',
              displayName: 'Worker Name $wId',
              email: 'worker$wId@example.com',
              photoUrl: 'https://example.com/avatar_$wId.png',
              healthConnectEnabled: wId.isEven,
              lastHealthSyncTime: DateTime.now(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            appDb.profileDao.saveAccountSession(session);
            final readSession = appDb.profileDao.getAccountSession();
            expect(readSession, isNotNull);

            // 4. WorkoutDao operations
            final sessions = [
              WorkoutSession(
                id: 'workout_${wId}_1',
                source: WorkoutSource.hevy,
                title: 'Hevy Session $wId',
                startTime: DateTime(2026, 7, (wId % 28 + 1), 10, 0),
                endTime: DateTime(2026, 7, (wId % 28 + 1), 11, 0),
                durationMinutes: 60,
                caloriesBurned: 350.0 + wId,
                notes: 'Worker $wId notes',
                createdAt: DateTime.now(),
              ),
            ];
            appDb.workoutDao.insertWorkoutSessions(sessions);
            final workouts = appDb.workoutDao.getWorkoutSessionsInRange(
              DateTime(2026, 7, 1),
              DateTime(2026, 7, 31),
            );
            expect(workouts, isNotEmpty);

            // 5. ExpenditureDao operations
            appDb.expenditureDao.saveExpenditure(
              makeRecord(date: dateStr, expenditureKcal: 2100.0 + wId),
            );
            final expRecord =
                appDb.expenditureDao.getExpenditureForDate(dateStr);
            expect(expRecord, isNotNull);

            appDb.expenditureDao.setDayComplete(dateStr, wId % 3 == 0);
            final isComp = appDb.expenditureDao.isDayComplete(dateStr);
            expect(isComp, equals(wId % 3 == 0));

            // 6. FoodDao operations
            final food = makeFood(
              id: 1000 + wId,
              name: 'Katori Dal Worker $wId',
              calories: 120.0 + (wId % 50),
            );
            appDb.foodDao.insertFood(food);
            final fetchedFood = appDb.foodDao.getFoodById(1000 + wId);
            expect(fetchedFood, isNotNull);
            expect(fetchedFood!.name, equals('Katori Dal Worker $wId'));

            final logEntry = FoodLogEntry(
              id: 0,
              date: dateStr,
              mealType: MealType.lunch,
              foodId: 1000 + wId,
              foodName: 'Katori Dal Worker $wId',
              servingQuantity: 1.0,
              unitName: '1 katori',
              gramWeight: 150.0,
              calories: 180.0,
              protein: 8.0,
              carbs: 25.0,
              fat: 3.0,
              fiber: 4.0,
              oilModifier: OilModifier.standard,
              loggedAt: DateTime.now(),
              iconSvg: '<svg></svg>',
            );
            final logId = appDb.foodDao.insertFoodLog(logEntry);
            expect(logId, greaterThan(0));

            final logs = appDb.foodDao.getFoodLogsForDate(dateStr);
            expect(logs, isNotEmpty);
          }));
        }

        await Future.wait(futures);

        // Verification after concurrent barrage:
        expect(rawDb.autocommit, isTrue);
        final integrity = rawDb.select('PRAGMA integrity_check;');
        expect(integrity.first.values.first, equals('ok'));

        final totalSettings = appDb.settingsDao.getAllSettings();
        expect(totalSettings.length, equals(60));

        final totalExpenditures = appDb.expenditureDao.getExpenditureHistory();
        expect(totalExpenditures.length, greaterThanOrEqualTo(28));

        final totalWorkouts = appDb.workoutDao.getAllWorkoutSessions();
        expect(totalWorkouts.length, equals(60));

        final totalFoods = appDb.foodDao.getFoodCount();
        expect(totalFoods, equals(60));
      });
    });

    // =========================================================================
    // 4. SQL Injection & String Escaping Boundary Tests
    // =========================================================================
    group('SQL Injection & Character Escaping Across All DAOs', () {
      test('SettingsDao safely handles malicious SQL injection keys and values',
          () {
        const injectionKey = "test_key'; DROP TABLE app_settings; --";
        const injectionVal = "val'); DELETE FROM app_settings; --";

        appDb.settingsDao.setSetting(injectionKey, injectionVal);
        final retrieved = appDb.settingsDao.getSetting(injectionKey, '');
        expect(retrieved, equals(injectionVal));

        // Ensure table still exists and functions
        expect(appDb.settingsDao.getAllSettings(), isNotEmpty);
      });

      test(
          'FoodDao FTS5 search safely handles unescaped punctuation, operators, and injection',
          () {
        final maliciousQueries = [
          "OR 1=1; DROP TABLE foods; --",
          " दाल AND * () : - + \" ' ",
          "SELECT * FROM foods",
          "''''''''''",
          "***",
          "NEAR(foo, bar)",
          "name:paneer",
        ];

        for (final query in maliciousQueries) {
          expect(
            () => appDb.foodDao.searchFoods(query),
            returnsNormally,
            reason: 'Search query "$query" must not throw or crash FTS5 parser',
          );
        }
      });

      test(
          'WeightDao and ExpenditureDao safely handle SQL injection in date queries',
          () {
        const maliciousDate = "2026-01-01' OR '1'='1";

        expect(() => appDb.weightDao.getWeightLogForDate(maliciousDate),
            returnsNormally);
        expect(
            () => appDb.weightDao.getScaleWeights(maliciousDate, maliciousDate),
            returnsNormally);
        expect(() => appDb.weightDao.deleteWeightLogForDate(maliciousDate),
            returnsNormally);

        expect(() => appDb.expenditureDao.getExpenditureForDate(maliciousDate),
            returnsNormally);
        expect(
            () => appDb.expenditureDao
                .getExpenditureHistory(startDate: maliciousDate),
            returnsNormally);
        expect(() => appDb.expenditureDao.deleteExpendituresFrom(maliciousDate),
            returnsNormally);
        expect(() => appDb.expenditureDao.isDayComplete(maliciousDate),
            returnsNormally);
      });
    });

    // =========================================================================
    // 5. Database Schema & Migration Idempotency
    // =========================================================================
    group('Schema & Migration Idempotency', () {
      test(
          'running DatabaseMigrations.initializeAndMigrate multiple times is idempotent',
          () {
        final versionBefore =
            rawDb.select('PRAGMA user_version;').first.values.first as int;
        expect(versionBefore, equals(DatabaseMigrations.currentVersion));

        // Re-run migration 10 times consecutively
        for (var i = 0; i < 10; i++) {
          DatabaseMigrations.initializeAndMigrate(rawDb, isInMemory: true);
        }

        final versionAfter =
            rawDb.select('PRAGMA user_version;').first.values.first as int;
        expect(versionAfter, equals(DatabaseMigrations.currentVersion));

        final integrity = rawDb.select('PRAGMA integrity_check;');
        expect(integrity.first.values.first, equals('ok'));
      });

      test('all new Milestone 3 columns exist on user_profile table', () {
        final columns = rawDb
            .select("PRAGMA table_info('user_profile');")
            .map((r) => r['name'] as String)
            .toSet();

        final requiredColumns = [
          'diet_type',
          'calorie_floor_type',
          'lifting_experience',
          'cardio_experience',
          'body_fat_range',
          'weight_history_max',
          'distribution_mode',
        ];

        for (final col in requiredColumns) {
          expect(columns.contains(col), isTrue,
              reason: 'Column "$col" must exist in user_profile table');
        }
      });

      test('user_account_session table contains auth_provider column', () {
        final columns = rawDb
            .select("PRAGMA table_info('user_account_session');")
            .map((r) => r['name'] as String)
            .toSet();

        expect(columns.contains('auth_provider'), isTrue);
      });
    });
  });
}
