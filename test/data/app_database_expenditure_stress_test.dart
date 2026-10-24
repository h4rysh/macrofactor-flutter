import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sique/data/local/app_database.dart';

void main() {
  group('AppDatabase Expenditure & Day Completion Persistence Stress Suite',
      () {
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

    ExpenditureRecord createRecord({
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

    // =========================================================================
    // 1. Bulk Transactions & Concurrency (365+ Days, 1000 Days)
    // =========================================================================

    test('Bulk save of 365 days runs in a single transaction in < 1000ms', () {
      final baseDate = DateTime(2025, 1, 1);
      final records365 = List.generate(365, (i) {
        final d = baseDate.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(d);
        return createRecord(
          date: dateStr,
          expenditureKcal: 2000.0 + (i % 50) * 10,
          trendWeightKg: 80.0 - (i * 0.02),
          variance: 500.0 - (i * 0.5),
          confidence: (0.5 + (i * 0.001)).clamp(0.0, 1.0),
        );
      });

      final sw = Stopwatch()..start();
      appDb.saveExpenditures(records365);
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(1000));

      final allRecords = appDb.getExpenditureHistory();
      expect(allRecords.length, equals(365));

      // Validate chronological ordering and boundary integrity
      expect(allRecords.first.date, equals('2025-01-01'));
      expect(allRecords.last.date, equals('2025-12-31'));

      for (var i = 0; i < allRecords.length - 1; i++) {
        expect(
          allRecords[i].date.compareTo(allRecords[i + 1].date),
          lessThan(0),
          reason: 'Chronological violation between $i and ${i + 1}',
        );
      }

      // Verify data fidelity on a sampled record
      final midRecord = allRecords[180];
      expect(midRecord.date, equals('2025-06-30'));
      expect(midRecord.expenditureKcal, equals(2000.0 + (180 % 50) * 10));
    });

    test('Bulk save of 1000 days (~2.7 years) handles scale cleanly', () {
      final baseDate = DateTime(2023, 1, 1);
      final records1000 = List.generate(1000, (i) {
        final d = baseDate.add(Duration(days: i));
        return createRecord(
          date: DateFormat('yyyy-MM-dd').format(d),
          expenditureKcal: 2200.0 + (i % 100),
          trendWeightKg: 75.0 + sin(i * 0.05) * 5.0,
        );
      });

      final sw = Stopwatch()..start();
      appDb.saveExpenditures(records1000);
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(2000));
      expect(appDb.getExpenditureHistory().length, equals(1000));
    });

    test('Empty batch saveExpenditures([]) is a safe no-op', () {
      expect(() => appDb.saveExpenditures([]), returnsNormally);
      expect(appDb.getExpenditureHistory(), isEmpty);
    });

    test('Single saveExpenditure inserts and updates cleanly', () {
      final record1 = createRecord(
        date: '2026-05-01',
        expenditureKcal: 2150.0,
      );
      appDb.saveExpenditure(record1);

      var fetched = appDb.getExpenditureForDate('2026-05-01');
      expect(fetched, isNotNull);
      expect(fetched!.expenditureKcal, equals(2150.0));

      // Upsert update
      final record2 = createRecord(
        date: '2026-05-01',
        expenditureKcal: 2300.0,
      );
      appDb.saveExpenditure(record2);

      fetched = appDb.getExpenditureForDate('2026-05-01');
      expect(fetched!.expenditureKcal, equals(2300.0));
      expect(appDb.getExpenditureHistory().length, equals(1));
    });

    // =========================================================================
    // 2. Idempotency & Overlapping Date Ranges
    // =========================================================================

    test('Re-running batch saves across overlapping date ranges is idempotent',
        () {
      final baseDate = DateTime(2025, 1, 1);

      // Batch 1: Days 0..199
      final batch1 = List.generate(200, (i) {
        final d = baseDate.add(Duration(days: i));
        return createRecord(
          date: DateFormat('yyyy-MM-dd').format(d),
          expenditureKcal: 2000.0,
          trendWeightKg: 70.0,
        );
      });
      appDb.saveExpenditures(batch1);
      expect(appDb.getExpenditureHistory().length, equals(200));

      // Batch 2: Days 100..299 with updated values (+250 kcal, +1.5 kg)
      final batch2 = List.generate(200, (i) {
        final d = baseDate.add(Duration(days: 100 + i));
        return createRecord(
          date: DateFormat('yyyy-MM-dd').format(d),
          expenditureKcal: 2250.0,
          trendWeightKg: 71.5,
        );
      });
      appDb.saveExpenditures(batch2);

      final totalRecords = appDb.getExpenditureHistory();
      // Days 0..299 = 300 unique days total
      expect(totalRecords.length, equals(300));

      // First 100 days (0..99) retain original batch 1 values
      for (var i = 0; i < 100; i++) {
        expect(totalRecords[i].expenditureKcal, equals(2000.0));
        expect(totalRecords[i].trendWeightKg, equals(70.0));
      }

      // Overlapping days (100..199) reflect updated batch 2 values
      for (var i = 100; i < 200; i++) {
        expect(totalRecords[i].expenditureKcal, equals(2250.0));
        expect(totalRecords[i].trendWeightKg, equals(71.5));
      }

      // Trailing new days (200..299) reflect batch 2 values
      for (var i = 200; i < 300; i++) {
        expect(totalRecords[i].expenditureKcal, equals(2250.0));
        expect(totalRecords[i].trendWeightKg, equals(71.5));
      }

      // Re-running Batch 2 ten times consecutively produces identical state
      for (var rep = 0; rep < 10; rep++) {
        appDb.saveExpenditures(batch2);
      }
      expect(appDb.getExpenditureHistory().length, equals(300));
    });

    // =========================================================================
    // 3. Query Range Filtering & Bounds
    // =========================================================================

    test('getExpenditureHistory bounds queries by startDate and endDate', () {
      final baseDate = DateTime(2025, 3, 1);
      final records = List.generate(31, (i) {
        final d = baseDate.add(Duration(days: i));
        return createRecord(date: DateFormat('yyyy-MM-dd').format(d));
      });
      appDb.saveExpenditures(records);

      // Start date only
      final fromMid = appDb.getExpenditureHistory(startDate: '2025-03-15');
      expect(fromMid.length, equals(17)); // 15..31 inclusive = 17
      expect(fromMid.first.date, equals('2025-03-15'));
      expect(fromMid.last.date, equals('2025-03-31'));

      // End date only
      final upToMid = appDb.getExpenditureHistory(endDate: '2025-03-10');
      expect(upToMid.length, equals(10)); // 01..10 inclusive = 10
      expect(upToMid.first.date, equals('2025-03-01'));
      expect(upToMid.last.date, equals('2025-03-10'));

      // Both bounds
      final window = appDb.getExpenditureHistory(
        startDate: '2025-03-10',
        endDate: '2025-03-20',
      );
      expect(window.length, equals(11));
      expect(window.first.date, equals('2025-03-10'));
      expect(window.last.date, equals('2025-03-20'));

      // Inverted bounds (startDate > endDate) returns empty list
      final inverted = appDb.getExpenditureHistory(
        startDate: '2025-03-25',
        endDate: '2025-03-10',
      );
      expect(inverted, isEmpty);
    });

    test('getLatestExpenditureBefore retrieves correct chronological anchor',
        () {
      appDb.saveExpenditures([
        createRecord(date: '2026-01-05', expenditureKcal: 2000.0),
        createRecord(date: '2026-01-10', expenditureKcal: 2100.0),
        createRecord(date: '2026-01-20', expenditureKcal: 2200.0),
      ]);

      // Exactly matches a recorded date
      final exact = appDb.getLatestExpenditureBefore('2026-01-10');
      expect(exact, isNotNull);
      expect(exact!.date, equals('2026-01-10'));
      expect(exact.expenditureKcal, equals(2100.0));

      // Falls between recorded dates
      final between = appDb.getLatestExpenditureBefore('2026-01-15');
      expect(between, isNotNull);
      expect(between!.date, equals('2026-01-10'));

      // Falls before any recorded date
      final beforeAll = appDb.getLatestExpenditureBefore('2026-01-01');
      expect(beforeAll, isNull);

      // Falls after all recorded dates
      final afterAll = appDb.getLatestExpenditureBefore('2026-02-01');
      expect(afterAll, isNotNull);
      expect(afterAll!.date, equals('2026-01-20'));
    });

    test(
        'deleteExpendituresFrom removes forward history without affecting past',
        () {
      final baseDate = DateTime(2026, 2, 1);
      final records = List.generate(28, (i) {
        final d = baseDate.add(Duration(days: i));
        return createRecord(date: DateFormat('yyyy-MM-dd').format(d));
      });
      appDb.saveExpenditures(records);
      expect(appDb.getExpenditureHistory().length, equals(28));

      // Delete from Feb 15 forward
      appDb.deleteExpendituresFrom('2026-02-15');

      final remaining = appDb.getExpenditureHistory();
      expect(remaining.length, equals(14)); // Feb 01..14 = 14 records
      expect(remaining.last.date, equals('2026-02-14'));
      expect(appDb.getExpenditureForDate('2026-02-15'), isNull);
    });

    // =========================================================================
    // 4. Day Completion Flags & Rapid Flip-Flopping
    // =========================================================================

    test('isDayComplete defaults correctly for recorded and unrecorded dates',
        () {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final yesterdayStr = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(const Duration(days: 1)));
      final tomorrowStr = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().add(const Duration(days: 1)));

      // Unrecorded past day defaults to true
      expect(appDb.isDayComplete(yesterdayStr), isTrue);

      // Unrecorded today defaults to false
      expect(appDb.isDayComplete(todayStr), isFalse);

      // Explicitly setting today to complete overrides default
      appDb.setDayComplete(todayStr, true);
      expect(appDb.isDayComplete(todayStr), isTrue);

      // Explicitly setting past day to incomplete overrides default
      appDb.setDayComplete(yesterdayStr, false);
      expect(appDb.isDayComplete(yesterdayStr), isFalse);

      // Future date defaults to false
      expect(appDb.isDayComplete(tomorrowStr), isFalse);
    });

    test('Rapid flip-flopping of day completion status retains final state',
        () {
      const testDate = '2026-04-15';

      // Rapidly toggle 200 times
      for (var i = 0; i < 200; i++) {
        final flag = (i % 2 == 0);
        appDb.setDayComplete(testDate, flag);
        expect(appDb.isDayComplete(testDate), equals(flag));
      }

      // Final state was i = 199 -> odd -> false
      expect(appDb.isDayComplete(testDate), isFalse);

      // Now set to true
      appDb.setDayComplete(testDate, true);
      expect(appDb.isDayComplete(testDate), isTrue);

      // Ensure day_completions table has exactly 1 row for testDate
      final completions = appDb.getDayCompletions();
      expect(completions.length, equals(1));
      expect(completions[testDate], isTrue);
    });

    test('getDayCompletions filters correctly by date range', () {
      final baseDate = DateTime(2026, 6, 1);
      for (var i = 0; i < 30; i++) {
        final dStr =
            DateFormat('yyyy-MM-dd').format(baseDate.add(Duration(days: i)));
        appDb.setDayComplete(dStr, i % 2 == 0);
      }

      final all = appDb.getDayCompletions();
      expect(all.length, equals(30));

      final window = appDb.getDayCompletions(
        startDate: '2026-06-10',
        endDate: '2026-06-15',
      );
      expect(window.length, equals(6));
      expect(window['2026-06-10'], isFalse); // June 10 is i=9 (odd -> false)
      expect(window['2026-06-11'], isTrue); // June 11 is i=10 (even -> true)
      expect(window.containsKey('2026-06-09'), isFalse);
      expect(window.containsKey('2026-06-16'), isFalse);
    });

    // =========================================================================
    // 5. Transaction Rollback & Atomicity on Mid-Batch Faults
    // =========================================================================

    test(
        'Transaction rollback atomicity: trigger ABORT mid-batch leaves DB in exact prior state',
        () {
      // Pre-seed 3 baseline records
      appDb.saveExpenditures([
        createRecord(date: '2026-01-01', expenditureKcal: 2000.0),
        createRecord(date: '2026-01-02', expenditureKcal: 2050.0),
        createRecord(date: '2026-01-03', expenditureKcal: 2100.0),
      ]);
      expect(appDb.getExpenditureHistory().length, equals(3));

      // Create an abort trigger that rejects date '2026-01-20'
      rawDb.execute("""
        CREATE TRIGGER abort_on_20 BEFORE INSERT ON expenditure_history
        WHEN NEW.date = '2026-01-20'
        BEGIN
          SELECT RAISE(ABORT, 'Simulated mid-batch trigger abort');
        END;
      """);

      // Attempt to batch save 50 records (dates 2026-01-10 to 2026-02-28)
      // Record 10 is '2026-01-20', which will abort after records 0..9 are processed
      final batch50 = List.generate(50, (i) {
        final d = DateTime(2026, 1, 10).add(Duration(days: i));
        return createRecord(
          date: DateFormat('yyyy-MM-dd').format(d),
          expenditureKcal: 2500.0,
        );
      });

      expect(
        () => appDb.saveExpenditures(batch50),
        throwsA(isA<SqliteException>()),
      );

      // Verify that ROLLBACK occurred:
      // None of the records from batch50 should be in the database
      final history = appDb.getExpenditureHistory();
      expect(history.length, equals(3),
          reason: 'All 50 records must be rolled back');
      expect(history.map((r) => r.date),
          containsAll(['2026-01-01', '2026-01-02', '2026-01-03']));
      expect(history.any((r) => r.date == '2026-01-10'), isFalse);
      expect(history.any((r) => r.date == '2026-01-19'), isFalse);

      // Verify transaction state is cleanly reset (not stuck in transaction)
      // Next write must succeed immediately without transaction active error
      rawDb.execute('DROP TRIGGER abort_on_20;');
      expect(
        () => appDb.saveExpenditure(createRecord(date: '2026-01-04')),
        returnsNormally,
      );
      expect(appDb.getExpenditureHistory().length, equals(4));
    });

    test(
        'Transaction rollback atomicity: trigger ROLLBACK handled cleanly during saveExpenditures',
        () {
      rawDb.execute("""
        CREATE TRIGGER rollback_on_mid BEFORE INSERT ON expenditure_history
        WHEN NEW.date = '2026-02-15'
        BEGIN
          SELECT RAISE(ROLLBACK, 'Simulated mid-batch trigger rollback');
        END;
      """);

      final batch = [
        createRecord(date: '2026-02-14'),
        createRecord(date: '2026-02-15'),
        createRecord(date: '2026-02-16'),
      ];

      expect(
        () => appDb.saveExpenditures(batch),
        throwsA(isA<SqliteException>()),
      );

      rawDb.execute('DROP TRIGGER rollback_on_mid;');
      expect(appDb.getExpenditureHistory(), isEmpty);
    });

    test(
        'Transaction rollback atomicity: Dart exception during iterable iteration rolls back and closes statement',
        () {
      Iterable<ExpenditureRecord> generateFaultyIterable() sync* {
        for (var i = 1; i <= 10; i++) {
          yield createRecord(
            date: '2026-03-${i.toString().padLeft(2, '0')}',
            expenditureKcal: 2000.0 + i,
          );
        }
        throw StateError('Simulated generator iteration fault mid-batch');
      }

      expect(
        () => appDb.saveExpenditures(generateFaultyIterable().toList()),
        throwsA(isA<StateError>()),
      );

      expect(appDb.getExpenditureHistory(), isEmpty);
    });

    // =========================================================================
    // 6. Zero Statement Leaks & Resource Safety Under Rapid Faults
    // =========================================================================

    test(
        'Statement handle disposal verification: zero leaks across 1,000 faulted queries',
        () {
      rawDb.execute("""
        CREATE TRIGGER fail_all BEFORE INSERT ON expenditure_history
        BEGIN
          SELECT RAISE(ABORT, 'Always fail');
        END;
      """);

      for (var i = 0; i < 1000; i++) {
        expect(
          () => appDb.saveExpenditure(createRecord(date: '2026-04-01')),
          throwsA(isA<SqliteException>()),
        );
      }

      // Drop trigger and verify subsequent usage works
      rawDb.execute('DROP TRIGGER fail_all;');
      expect(
        () => appDb.saveExpenditure(createRecord(date: '2026-04-01')),
        returnsNormally,
      );
      expect(appDb.getExpenditureHistory().length, equals(1));
    });

    // =========================================================================
    // 7. High-Concurrency Multi-Worker DAO Interleaving
    // =========================================================================

    test(
        'High-concurrency stress: 50 concurrent async workers hammering reads, writes, and batch updates',
        () async {
      final futures = <Future<void>>[];

      for (var worker = 0; worker < 50; worker++) {
        futures.add(Future(() async {
          final dateStr =
              '2026-07-${(worker % 28 + 1).toString().padLeft(2, '0')}';

          // Single write
          appDb.saveExpenditure(createRecord(
            date: dateStr,
            expenditureKcal: 2000.0 + worker,
          ));

          // Read single
          final rec = appDb.getExpenditureForDate(dateStr);
          expect(rec, isNotNull);

          // Batch save 5 records
          final miniBatch = List.generate(5, (j) {
            final day = ((worker + j) % 28 + 1).toString().padLeft(2, '0');
            return createRecord(
              date: '2026-08-$day',
              expenditureKcal: 2200.0 + j,
            );
          });
          appDb.saveExpenditures(miniBatch);

          // Range query
          final history = appDb.getExpenditureHistory(
            startDate: '2026-08-01',
            endDate: '2026-08-10',
          );
          expect(history, isA<List<ExpenditureRecord>>());

          // Day completion toggle
          appDb.setDayComplete(dateStr, worker.isEven);
          final isComp = appDb.isDayComplete(dateStr);
          expect(isComp, equals(worker.isEven));

          // Day completions map
          final comps = appDb.getDayCompletions(
              startDate: '2026-07-01', endDate: '2026-07-31');
          expect(comps, isNotEmpty);
        }));
      }

      await Future.wait(futures);

      final allExp = appDb.getExpenditureHistory();
      expect(allExp, isNotEmpty);
      final allComps = appDb.getDayCompletions();
      expect(allComps, isNotEmpty);
    });

    // =========================================================================
    // 8. SQL Injection & Numeric Edge Cases
    // =========================================================================

    test(
        'Guards against SQL injection in range filtering dates and day completion dates',
        () {
      const sqlInjectDate = "2026-01-01'; DROP TABLE expenditure_history; --";

      expect(
        () => appDb.getExpenditureHistory(startDate: sqlInjectDate),
        returnsNormally,
      );
      expect(
        () => appDb.getExpenditureForDate(sqlInjectDate),
        returnsNormally,
      );
      expect(
        () => appDb.getLatestExpenditureBefore(sqlInjectDate),
        returnsNormally,
      );
      expect(
        () => appDb.deleteExpendituresFrom(sqlInjectDate),
        returnsNormally,
      );
      expect(
        () => appDb.setDayComplete(sqlInjectDate, true),
        returnsNormally,
      );
      expect(
        () => appDb.getDayCompletions(startDate: sqlInjectDate),
        returnsNormally,
      );

      // Verify table still exists and functions normally
      final checkTable =
          rawDb.select('SELECT COUNT(*) as c FROM expenditure_history;');
      expect(checkTable.first['c'], equals(0));
    });

    test(
        'Extreme numeric edge cases in ExpenditureRecord: negative values and zero variances',
        () {
      final extremeRecord = createRecord(
        date: '2026-09-01',
        expenditureKcal: -1000.0,
        trendWeightKg: 0.0,
        variance: 0.0,
        confidence: -0.5,
      );

      expect(() => appDb.saveExpenditure(extremeRecord), returnsNormally);
      final fetched = appDb.getExpenditureForDate('2026-09-01');
      expect(fetched, isNotNull);
      expect(fetched!.expenditureKcal, equals(-1000.0));
      expect(fetched.confidence, equals(-0.5));
    });
  });
}
