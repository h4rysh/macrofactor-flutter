import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/widgets/app_lifecycle_sync_observer.dart';

import 'package:sqlite3/sqlite3.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/algorithms/weight_trend_v2.dart';
import 'package:sique/domain/models/workout_session.dart';
import 'package:sique/domain/services/health_sync_adapter.dart';

class _FakeHealthSyncAdapter implements HealthSyncAdapter {
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<bool> hasPermissions() async => true;
  @override
  Future<bool> requestPermissions() async => true;
  @override
  Future<List<WorkoutSession>> fetchWorkouts({
    required DateTime startTime,
    required DateTime endTime,
  }) async =>
      [];
  @override
  Future<List<ScaleWeightEntry>> fetchWeights({
    required DateTime startTime,
    required DateTime endTime,
  }) async =>
      [];
}

class _FakeHealthSyncNotifier extends HealthSyncNotifier {
  _FakeHealthSyncNotifier()
      : super(
          db: AppDatabase(sqlite3.openInMemory()),
          adapter: _FakeHealthSyncAdapter(),
        );

  @override
  Future<void> checkAvailabilityAndPermissions() async {}

  @override
  Future<bool> syncNow({int trailingDays = 30}) async => true;
}

void main() {
  group('Issue 8 Regression: Midnight Date Rollover on App Resume', () {
    testWidgets(
        'AppLifecycleSyncObserver rolls over selectedDate if midnight passed',
        (tester) async {
      var simulatedTime = DateTime(2026, 10, 17, 23, 50); // Yesterday night
      final yesterdayStr = DateFormat('yyyy-MM-dd').format(simulatedTime);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(UserAccount.guest),
          healthConnectSyncProvider
              .overrideWith((ref) => _FakeHealthSyncNotifier()),
        ],
      );
      addTearDown(container.dispose);

      // Explicitly set selectedDate to yesterday
      container.read(selectedDateProvider.notifier).state = yesterdayStr;
      expect(container.read(selectedDateProvider), equals(yesterdayStr));

      // Mount the observer in the widget tree with simulated clock
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

      // Ensure still yesterday before midnight
      expect(container.read(selectedDateProvider), equals(yesterdayStr));

      // Advance clock past midnight into today
      simulatedTime = DateTime(2026, 10, 18, 7, 30);
      final todayStr = DateFormat('yyyy-MM-dd').format(simulatedTime);

      // Simulate app resuming on the new day
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // selectedDateProvider should now have rolled over to todayStr!
      expect(container.read(selectedDateProvider), equals(todayStr));
    });

    testWidgets(
        'AppLifecycleSyncObserver does NOT advance selectedDate if user was viewing a historical date',
        (tester) async {
      var simulatedTime = DateTime(2026, 10, 17, 23, 50); // Today is Oct 17
      const historicalDate = '2026-10-10'; // User navigated back to Oct 10

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(UserAccount.guest),
          healthConnectSyncProvider
              .overrideWith((ref) => _FakeHealthSyncNotifier()),
        ],
      );
      addTearDown(container.dispose);

      // Explicitly set selectedDate to historical past date
      container.read(selectedDateProvider.notifier).state = historicalDate;
      expect(container.read(selectedDateProvider), equals(historicalDate));

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

      // Advance clock past midnight into Oct 18
      simulatedTime = DateTime(2026, 10, 18, 07, 30);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Selected date should still be historical date, not stomped!
      expect(container.read(selectedDateProvider), equals(historicalDate));
    });

    testWidgets(
        'AppLifecycleSyncObserver rolls over selectedDate via periodic foreground timer',
        (tester) async {
      var simulatedTime = DateTime(2026, 10, 17, 23, 59, 30);
      final oct17Str = DateFormat('yyyy-MM-dd').format(simulatedTime);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(UserAccount.guest),
          healthConnectSyncProvider
              .overrideWith((ref) => _FakeHealthSyncNotifier()),
        ],
      );
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

      // Now clock ticks past midnight, app remains in foreground
      simulatedTime = DateTime(2026, 10, 18, 00, 00, 05);
      final oct18Str = DateFormat('yyyy-MM-dd').format(simulatedTime);

      // Fast forward the timer by 2 seconds
      await tester.pump(const Duration(seconds: 2));

      expect(container.read(selectedDateProvider), equals(oct18Str));
    });
  });
}
