import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/data/services/mock_auth_service.dart';
import 'package:sique/data/services/mock_health_sync_adapter.dart';
import 'package:sique/domain/algorithms/weight_trend_v2.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/widgets/app_lifecycle_sync_observer.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Milestone 2 Adversarial Stress Suite: Health Connect Weight Sync', () {
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

    test(
        'Exact arithmetic mean verification with 2, 3, 5, 20, and 100 same-day readings',
        () async {
      final baseDate = DateTime(2026, 10, 18);
      final dateStr = DateFormat('yyyy-MM-dd').format(baseDate);

      // Scenario 1: 2 readings
      final twoWeights = [
        ScaleWeightEntry(
          date: DateTime(2026, 10, 18, 7, 0),
          weightKg: 72.0,
          note: 'Morning',
        ),
        ScaleWeightEntry(
          date: DateTime(2026, 10, 18, 19, 0),
          weightKg: 74.0,
          note: 'Evening',
        ),
      ];
      mockAdapter.setWeights(twoWeights);
      var ok =
          await container.read(healthConnectSyncProvider.notifier).syncNow();
      expect(ok, isTrue);

      var log = appDb.getWeightLogForDate(dateStr);
      expect(log, isNotNull);
      expect(log!.weightKg, equals(73.0));
      expect(log.note, equals('Morning, Evening'));

      // Scenario 2: 3 readings with fractional decimals
      final threeWeights = [
        ScaleWeightEntry(
          date: DateTime(2026, 10, 18, 6, 30),
          weightKg: 70.1,
          note: 'Scale A',
        ),
        ScaleWeightEntry(
          date: DateTime(2026, 10, 18, 12, 15),
          weightKg: 70.2,
          note: 'Scale A',
        ),
        ScaleWeightEntry(
          date: DateTime(2026, 10, 18, 21, 45),
          weightKg: 70.6,
          note: 'Scale B',
        ),
      ];
      mockAdapter.setWeights(threeWeights);
      ok = await container.read(healthConnectSyncProvider.notifier).syncNow();
      expect(ok, isTrue);

      log = appDb.getWeightLogForDate(dateStr);
      expect(log, isNotNull);
      // Arithmetic mean: (70.1 + 70.2 + 70.6) / 3 = 210.9 / 3 = 70.3
      expect((log!.weightKg - 70.3).abs(), lessThan(1e-9));
      // Note deduplication: 'Scale A' appears twice, should be deduplicated
      expect(log.note, equals('Scale A, Scale B'));

      // Scenario 3: 5 readings
      final fiveWeights = [
        ScaleWeightEntry(date: DateTime(2026, 10, 18, 6), weightKg: 80.0),
        ScaleWeightEntry(date: DateTime(2026, 10, 18, 9), weightKg: 81.0),
        ScaleWeightEntry(date: DateTime(2026, 10, 18, 13), weightKg: 82.0),
        ScaleWeightEntry(date: DateTime(2026, 10, 18, 17), weightKg: 83.0),
        ScaleWeightEntry(date: DateTime(2026, 10, 18, 22), weightKg: 84.0),
      ];
      mockAdapter.setWeights(fiveWeights);
      ok = await container.read(healthConnectSyncProvider.notifier).syncNow();
      expect(ok, isTrue);

      log = appDb.getWeightLogForDate(dateStr);
      expect(log!.weightKg, equals(82.0));

      // Scenario 4: 20 readings across the same calendar day
      final twentyWeights = List.generate(
        20,
        (i) => ScaleWeightEntry(
          date: DateTime(2026, 10, 18, 0, i * 2),
          weightKg: 75.0 + (i * 0.1),
          note: 'Test Scale',
        ),
      );
      final expectedTwentyMean =
          twentyWeights.map((e) => e.weightKg).reduce((a, b) => a + b) / 20;

      mockAdapter.setWeights(twentyWeights);
      ok = await container.read(healthConnectSyncProvider.notifier).syncNow();
      expect(ok, isTrue);

      log = appDb.getWeightLogForDate(dateStr);
      expect((log!.weightKg - expectedTwentyMean).abs(), lessThan(1e-9));

      // Scenario 5: High volume stress - 100 same-day readings
      final hundredWeights = List.generate(
        100,
        (i) => ScaleWeightEntry(
          date: DateTime(2026, 10, 18, i ~/ 5, (i % 5) * 10),
          weightKg: 65.0 + (i % 10) * 0.25,
          note: i % 2 == 0 ? 'Device Alpha' : 'Device Beta',
        ),
      );
      final expectedHundredMean =
          hundredWeights.map((e) => e.weightKg).reduce((a, b) => a + b) / 100;

      mockAdapter.setWeights(hundredWeights);
      ok = await container.read(healthConnectSyncProvider.notifier).syncNow();
      expect(ok, isTrue);

      log = appDb.getWeightLogForDate(dateStr);
      expect((log!.weightKg - expectedHundredMean).abs(), lessThan(1e-9));
      expect(log.note, equals('Device Alpha, Device Beta'));
    });

    test(
        'Midnight timezone boundaries (.toLocal() vs UTC) groups by local calendar date',
        () async {
      final utcReading1 = DateTime.utc(2026, 10, 18, 23, 50);
      final utcReading2 = DateTime.utc(2026, 10, 19, 0, 10);

      final localDateStr1 =
          DateFormat('yyyy-MM-dd').format(utcReading1.toLocal());
      final localDateStr2 =
          DateFormat('yyyy-MM-dd').format(utcReading2.toLocal());

      final entries = [
        ScaleWeightEntry(
          date: utcReading1,
          weightKg: 76.5,
          note: 'Near Midnight UTC 1',
        ),
        ScaleWeightEntry(
          date: utcReading2,
          weightKg: 77.5,
          note: 'Near Midnight UTC 2',
        ),
      ];

      mockAdapter.setWeights(entries);
      final ok =
          await container.read(healthConnectSyncProvider.notifier).syncNow();
      expect(ok, isTrue);

      if (localDateStr1 == localDateStr2) {
        final log = appDb.getWeightLogForDate(localDateStr1);
        expect(log, isNotNull);
        expect(log!.weightKg, equals(77.0));
      } else {
        final log1 = appDb.getWeightLogForDate(localDateStr1);
        expect(log1, isNotNull);
        expect(log1!.weightKg, equals(76.5));

        final log2 = appDb.getWeightLogForDate(localDateStr2);
        expect(log2, isNotNull);
        expect(log2!.weightKg, equals(77.5));
      }
    });

    test(
        'Manual weight entries are NEVER overwritten by Health Connect sync (repeated sync stress)',
        () async {
      const dateStr = '2026-10-18';

      // 1. User records a manual weight
      appDb.insertWeightLog(
        dateStr,
        71.8,
        'Manual morning check',
        source: 'manual',
      );

      final initialLog = appDb.getWeightLogForDate(dateStr);
      expect(initialLog, isNotNull);
      expect(initialLog!.weightKg, equals(71.8));
      expect(initialLog.note, equals('Manual morning check'));

      // 2. Health Connect attempts to sync a conflicting weight
      mockAdapter.setWeights([
        ScaleWeightEntry(
          date: DateTime.parse('$dateStr 07:15:00'),
          weightKg: 78.4,
          note: 'Health Connect Auto Weight',
        ),
      ]);

      final ok =
          await container.read(healthConnectSyncProvider.notifier).syncNow();
      expect(ok, isTrue);

      // Verify manual entry is preserved intact
      var preservedLog = appDb.getWeightLogForDate(dateStr);
      expect(preservedLog, isNotNull);
      expect(preservedLog!.weightKg, equals(71.8));
      expect(preservedLog.note, equals('Manual morning check'));

      // 3. Repeated adversarial sync cycles with various weights and multiple readings
      for (var round = 0; round < 10; round++) {
        mockAdapter.setWeights([
          ScaleWeightEntry(
            date: DateTime.parse('$dateStr 08:00:00'),
            weightKg: 60.0 + round * 2.0,
            note: 'Adversarial Round $round',
          ),
          ScaleWeightEntry(
            date: DateTime.parse('$dateStr 18:00:00'),
            weightKg: 90.0 - round * 1.5,
            note: 'Adversarial Round $round PM',
          ),
        ]);

        await container.read(healthConnectSyncProvider.notifier).syncNow();

        preservedLog = appDb.getWeightLogForDate(dateStr);
        expect(
          preservedLog!.weightKg,
          equals(71.8),
          reason: 'Manual weight must never be overwritten on round $round',
        );
        expect(preservedLog.note, equals('Manual morning check'));
      }
    });

    test(
        'Full lifecycle transition: Health Connect sync -> Manual overwrite -> Health Connect re-sync immunity',
        () async {
      const dateStr = '2026-10-18';

      // Phase 1: Health Connect syncs first
      mockAdapter.setWeights([
        ScaleWeightEntry(
          date: DateTime.parse('$dateStr 06:45:00'),
          weightKg: 74.5,
          note: 'Smart Scale Sync',
        ),
      ]);

      var ok =
          await container.read(healthConnectSyncProvider.notifier).syncNow();
      expect(ok, isTrue);

      var log = appDb.getWeightLogForDate(dateStr);
      expect(log, isNotNull);
      expect(log!.weightKg, equals(74.5));
      expect(log.note, equals('Smart Scale Sync'));

      // Phase 2: User manually overwrites via WeightLogsNotifier
      final weightNotifier = container.read(weightLogsProvider.notifier);
      weightNotifier.logWeight(dateStr, 73.8, 'Corrected by manual scale');

      log = appDb.getWeightLogForDate(dateStr);
      expect(log, isNotNull);
      expect(log!.weightKg, equals(73.8));
      expect(log.note, equals('Corrected by manual scale'));

      // Phase 3: Health Connect sync runs again with a new/different reading
      mockAdapter.setWeights([
        ScaleWeightEntry(
          date: DateTime.parse('$dateStr 20:00:00'),
          weightKg: 79.9,
          note: 'Late Health Connect Scale',
        ),
      ]);

      ok = await container.read(healthConnectSyncProvider.notifier).syncNow();
      expect(ok, isTrue);

      // Must remain the manual weight
      log = appDb.getWeightLogForDate(dateStr);
      expect(log, isNotNull);
      expect(
        log!.weightKg,
        equals(73.8),
        reason: 'Subsequent Health Connect sync must NOT overwrite manual log',
      );
      expect(log.note, equals('Corrected by manual scale'));
    });

    test(
        'Multi-day interleaved batch Health Connect payload correctly segregates averages per local date',
        () async {
      const day1 = '2026-10-18';
      const day2 = '2026-10-19';
      const day3 = '2026-10-20';

      // Day 3 already has a manual entry
      appDb.insertWeightLog(day3, 65.0, 'Pre-existing manual log',
          source: 'manual');

      // Interleaved readings across 3 days
      final mixedBatch = [
        ScaleWeightEntry(
            date: DateTime.parse('$day1 06:30:00'), weightKg: 70.0),
        ScaleWeightEntry(
            date: DateTime.parse('$day2 07:00:00'), weightKg: 68.0),
        ScaleWeightEntry(
            date: DateTime.parse('$day1 12:00:00'), weightKg: 71.0),
        ScaleWeightEntry(
            date: DateTime.parse('$day3 08:00:00'), weightKg: 82.0),
        ScaleWeightEntry(
            date: DateTime.parse('$day1 18:30:00'), weightKg: 72.0),
        ScaleWeightEntry(
            date: DateTime.parse('$day2 19:30:00'), weightKg: 70.0),
      ];

      mockAdapter.setWeights(mixedBatch);
      final ok =
          await container.read(healthConnectSyncProvider.notifier).syncNow();
      expect(ok, isTrue);

      // Day 1: average of 70, 71, 72 -> 71.0
      final log1 = appDb.getWeightLogForDate(day1);
      expect(log1, isNotNull);
      expect(log1!.weightKg, equals(71.0));

      // Day 2: average of 68, 70 -> 69.0
      final log2 = appDb.getWeightLogForDate(day2);
      expect(log2, isNotNull);
      expect(log2!.weightKg, equals(69.0));

      // Day 3: manual entry must be preserved despite HC sync containing 82.0!
      final log3 = appDb.getWeightLogForDate(day3);
      expect(log3, isNotNull);
      expect(log3!.weightKg, equals(65.0));
      expect(log3.note, equals('Pre-existing manual log'));
    });

    test('Empty and whitespace-only notes default to "Health Connect"',
        () async {
      const dateStr = '2026-10-18';
      final blankNotes = [
        ScaleWeightEntry(
          date: DateTime.parse('$dateStr 07:00:00'),
          weightKg: 74.0,
          note: null,
        ),
        ScaleWeightEntry(
          date: DateTime.parse('$dateStr 09:00:00'),
          weightKg: 75.0,
          note: '   \t  ',
        ),
      ];

      mockAdapter.setWeights(blankNotes);
      final ok =
          await container.read(healthConnectSyncProvider.notifier).syncNow();
      expect(ok, isTrue);

      final log = appDb.getWeightLogForDate(dateStr);
      expect(log, isNotNull);
      expect(log!.note, equals('Health Connect'));
    });
  });

  group('Milestone 2 Adversarial Stress Suite: Midnight Rollover Timer', () {
    late Database rawDb;
    late AppDatabase appDb;
    late MockHealthSyncAdapter mockAdapter;
    late MockAuthService mockAuth;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      appDb = AppDatabase(rawDb);
      appDb.initUserTables();
      mockAdapter = MockHealthSyncAdapter();
      mockAuth = MockAuthService();
    });

    tearDown(() {
      rawDb.dispose();
    });

    List<Override> createOverrides() {
      return [
        databaseProvider.overrideWithValue(appDb),
        healthSyncAdapterProvider.overrideWithValue(mockAdapter),
        authServiceProvider.overrideWithValue(mockAuth),
        currentUserProvider.overrideWithValue(UserAccount.guest),
      ];
    }

    testWidgets(
        'Rollover advances selectedDate when viewing today, preserves historical date',
        (tester) async {
      var simulatedTime = DateTime(2026, 10, 17, 23, 59, 50);
      final oct17Str = DateFormat('yyyy-MM-dd').format(simulatedTime);

      final container = ProviderContainer(overrides: createOverrides());
      addTearDown(container.dispose);

      // User starts by viewing today
      container.read(selectedDateProvider.notifier).state = oct17Str;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AppLifecycleSyncObserver(
              clock: () => simulatedTime,
              periodicCheckInterval: const Duration(seconds: 1),
              child: const Scaffold(body: SizedBox()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(selectedDateProvider), equals(oct17Str));

      // Advance clock past midnight
      simulatedTime = DateTime(2026, 10, 18, 0, 0, 10);
      final oct18Str = DateFormat('yyyy-MM-dd').format(simulatedTime);

      // Wait for timer check
      await tester.pump(const Duration(seconds: 2));

      // selectedDate should have rolled over to Oct 18
      expect(container.read(selectedDateProvider), equals(oct18Str));

      // Now user deliberately navigates back to historical date (Oct 10)
      const historicalDateStr = '2026-10-10';
      container.read(selectedDateProvider.notifier).state = historicalDateStr;

      // Another day rolls over past midnight into Oct 19
      simulatedTime = DateTime(2026, 10, 19, 0, 0, 10);

      // Wait for timer check
      await tester.pump(const Duration(seconds: 2));

      // Historical date MUST be preserved!
      expect(container.read(selectedDateProvider), equals(historicalDateStr));
    });

    testWidgets(
        'Rollover preserves future date view when user selected future date',
        (tester) async {
      var simulatedTime = DateTime(2026, 10, 17, 23, 59, 50);
      const futureDateStr = '2026-10-25';

      final container = ProviderContainer(overrides: createOverrides());
      addTearDown(container.dispose);

      // Set user selected date to future
      container.read(selectedDateProvider.notifier).state = futureDateStr;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AppLifecycleSyncObserver(
              clock: () => simulatedTime,
              periodicCheckInterval: const Duration(seconds: 1),
              child: const Scaffold(body: SizedBox()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(selectedDateProvider), equals(futureDateStr));

      // Time advances past midnight
      simulatedTime = DateTime(2026, 10, 18, 0, 0, 15);
      await tester.pump(const Duration(seconds: 2));

      // Future date must NOT be stomped
      expect(container.read(selectedDateProvider), equals(futureDateStr));
    });

    testWidgets(
        'Sequential multi-day rollovers in foreground update smoothly across 3 consecutive midnights',
        (tester) async {
      var simulatedTime = DateTime(2026, 10, 17, 23, 59, 50);
      final oct17Str = DateFormat('yyyy-MM-dd').format(simulatedTime);

      final container = ProviderContainer(overrides: createOverrides());
      addTearDown(container.dispose);

      container.read(selectedDateProvider.notifier).state = oct17Str;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AppLifecycleSyncObserver(
              clock: () => simulatedTime,
              periodicCheckInterval: const Duration(seconds: 1),
              child: const Scaffold(body: SizedBox()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(selectedDateProvider), equals('2026-10-17'));

      // Day 1 -> Day 2 rollover
      simulatedTime = DateTime(2026, 10, 18, 0, 0, 10);
      await tester.pump(const Duration(seconds: 2));
      expect(container.read(selectedDateProvider), equals('2026-10-18'));

      // Day 2 -> Day 3 rollover
      simulatedTime = DateTime(2026, 10, 19, 0, 0, 10);
      await tester.pump(const Duration(seconds: 2));
      expect(container.read(selectedDateProvider), equals('2026-10-19'));

      // Day 3 -> Day 4 rollover
      simulatedTime = DateTime(2026, 10, 20, 0, 0, 10);
      await tester.pump(const Duration(seconds: 2));
      expect(container.read(selectedDateProvider), equals('2026-10-20'));
    });

    testWidgets(
        'Multi-day pause-resume transition: advances if viewing today, preserves if viewing past',
        (tester) async {
      // Case 1: user viewing today
      var simulatedTime = DateTime(2026, 10, 17, 10, 0);

      final container = ProviderContainer(overrides: createOverrides());
      addTearDown(container.dispose);

      container.read(selectedDateProvider.notifier).state = '2026-10-17';

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AppLifecycleSyncObserver(
              clock: () => simulatedTime,
              child: const Scaffold(body: SizedBox()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // App paused on Oct 17
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // 4 days pass while app was in background
      simulatedTime = DateTime(2026, 10, 21, 8, 30);

      // App resumed on Oct 21
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Because user was viewing "today" (Oct 17 at pause time), it advances to Oct 21
      expect(container.read(selectedDateProvider), equals('2026-10-21'));

      // Case 2: user selects historical date Oct 14
      container.read(selectedDateProvider.notifier).state = '2026-10-14';

      // App paused
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // 3 more days pass (Oct 24)
      simulatedTime = DateTime(2026, 10, 24, 9, 0);

      // App resumed
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Historical date Oct 14 is preserved!
      expect(container.read(selectedDateProvider), equals('2026-10-14'));
    });

    testWidgets(
        'Rapid timer ticks (100 iterations) within the same day cause zero unwanted mutations',
        (tester) async {
      final simulatedTime = DateTime(2026, 10, 18, 14, 0);
      const testDate = '2026-10-18';

      final container = ProviderContainer(overrides: createOverrides());
      addTearDown(container.dispose);

      container.read(selectedDateProvider.notifier).state = testDate;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AppLifecycleSyncObserver(
              clock: () => simulatedTime,
              periodicCheckInterval: const Duration(milliseconds: 10),
              child: const Scaffold(body: SizedBox()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pump 100 fast ticks within the same calendar day
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }

      expect(container.read(selectedDateProvider), equals(testDate));
    });
  });
}
