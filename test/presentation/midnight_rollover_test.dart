import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:macro_factor_app/domain/models/user_account.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';
import 'package:macro_factor_app/presentation/providers/auth_providers.dart';
import 'package:macro_factor_app/presentation/providers/health_sync_providers.dart';
import 'package:macro_factor_app/presentation/widgets/app_lifecycle_sync_observer.dart';

import 'package:sqlite3/sqlite3.dart';
import 'package:macro_factor_app/data/local/app_database.dart';
import 'package:macro_factor_app/domain/algorithms/weight_trend_v2.dart';
import 'package:macro_factor_app/domain/models/workout_session.dart';
import 'package:macro_factor_app/domain/services/health_sync_adapter.dart';

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
  Future<void> triggerSync({String? triggerReason}) async {}
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
  });
}
