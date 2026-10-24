import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/algorithms/weight_trend_v2.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/models/workout_session.dart';
import 'package:sique/domain/services/health_sync_adapter.dart';
import 'package:sique/presentation/providers/auth_providers.dart';
import 'package:sique/presentation/providers/health_sync_providers.dart';
import 'package:sique/presentation/widgets/app_lifecycle_sync_observer.dart';

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

/// Test StateNotifier to observe and control sync behavior in widget tests.
class TestHealthSyncNotifier extends HealthSyncNotifier {
  TestHealthSyncNotifier({
    AppDatabase? db,
    HealthSyncAdapter? adapter,
    HealthSyncState? initialState,
    this.shouldThrow = false,
    this.syncSuccess = true,
    this.clock,
  }) : super(
          db: db ?? AppDatabase(sqlite3.openInMemory()),
          adapter: adapter ?? _FakeHealthSyncAdapter(),
        ) {
    if (initialState != null) {
      state = initialState;
    }
  }

  int syncCallCount = 0;
  bool shouldThrow;
  bool syncSuccess;
  final DateTime Function()? clock;

  @override
  Future<void> checkAvailabilityAndPermissions() async {}

  @override
  Future<bool> syncNow({int trailingDays = 30}) async {
    syncCallCount++;
    if (shouldThrow) {
      throw Exception('Uncaught native health connect fault');
    }
    state = state.copyWith(
      status: syncSuccess ? HealthSyncStatus.success : HealthSyncStatus.error,
      lastSyncedAt: clock != null ? clock!() : DateTime.now(),
    );
    return syncSuccess;
  }

  @override
  Future<bool> requestPermissions() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLifecycleSyncObserver Launch Auto-Sync', () {
    testWidgets(
        'triggers background sync on launch when healthConnectEnabled is true',
        (tester) async {
      final syncNotifier = TestHealthSyncNotifier();
      final triggeredReasons = <String>[];

      final enabledUser = UserAccount.fromGoogle(
        id: 'user_1',
        googleUserId: 'g_1',
        displayName: 'Test User',
        email: 'test@example.com',
        healthConnectEnabled: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(enabledUser),
            healthConnectSyncProvider.overrideWith((ref) => syncNotifier),
          ],
          child: MaterialApp(
            home: AppLifecycleSyncObserver(
              onSyncTriggered: (reason) => triggeredReasons.add(reason),
              child: const Scaffold(body: Text('Dashboard View')),
            ),
          ),
        ),
      );

      // Settle the post-frame callback
      await tester.pumpAndSettle();

      expect(find.text('Dashboard View'), findsOneWidget);
      expect(syncNotifier.syncCallCount, equals(1));
      expect(triggeredReasons, equals(['launch']));
    });

    testWidgets(
        'does NOT trigger background sync on launch when healthConnectEnabled is false',
        (tester) async {
      final syncNotifier = TestHealthSyncNotifier();
      final triggeredReasons = <String>[];

      final guestUser = UserAccount.guest; // healthConnectEnabled is false

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(guestUser),
            healthConnectSyncProvider.overrideWith((ref) => syncNotifier),
          ],
          child: MaterialApp(
            home: AppLifecycleSyncObserver(
              onSyncTriggered: (reason) => triggeredReasons.add(reason),
              child: const Scaffold(body: Text('Guest Screen')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Guest Screen'), findsOneWidget);
      expect(syncNotifier.syncCallCount, equals(0));
      expect(triggeredReasons, isEmpty);
    });

    testWidgets(
        'does NOT trigger sync on launch when sync is already in progress',
        (tester) async {
      final syncNotifier = TestHealthSyncNotifier(
        initialState: const HealthSyncState(
          status: HealthSyncStatus.syncing,
        ),
      );
      final triggeredReasons = <String>[];

      final enabledUser = UserAccount.fromGoogle(
        id: 'user_1',
        googleUserId: 'g_1',
        displayName: 'Test User',
        email: 'test@example.com',
        healthConnectEnabled: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(enabledUser),
            healthConnectSyncProvider.overrideWith((ref) => syncNotifier),
          ],
          child: MaterialApp(
            home: AppLifecycleSyncObserver(
              onSyncTriggered: (reason) => triggeredReasons.add(reason),
              child: const Scaffold(body: Text('Active View')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(syncNotifier.syncCallCount, equals(0));
      expect(triggeredReasons, isEmpty);
    });
  });

  group('AppLifecycleSyncObserver Resume & Throttling', () {
    testWidgets(
        'triggers sync on AppLifecycleState.resumed when throttle interval has elapsed',
        (tester) async {
      var simulatedNow = DateTime(2026, 10, 17, 8, 0, 0);
      final syncNotifier = TestHealthSyncNotifier(clock: () => simulatedNow);
      final triggeredReasons = <String>[];

      final enabledUser = UserAccount.fromGoogle(
        id: 'user_1',
        googleUserId: 'g_1',
        displayName: 'Test User',
        email: 'test@example.com',
        healthConnectEnabled: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(enabledUser),
            healthConnectSyncProvider.overrideWith((ref) => syncNotifier),
          ],
          child: MaterialApp(
            home: AppLifecycleSyncObserver(
              clock: () => simulatedNow,
              throttleDuration: const Duration(minutes: 5),
              onSyncTriggered: (reason) => triggeredReasons.add(reason),
              child: const Scaffold(body: Text('Main Feed')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(syncNotifier.syncCallCount, equals(1));
      expect(triggeredReasons, equals(['launch']));

      // Simulate advancing time past the 5-minute throttle duration
      simulatedNow = simulatedNow.add(const Duration(minutes: 6));

      // Simulate app resuming from background
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(syncNotifier.syncCallCount, equals(2));
      expect(triggeredReasons, equals(['launch', 'resume']));
    });

    testWidgets(
        'throttles and suppresses sync on AppLifecycleState.resumed when within 5 minutes',
        (tester) async {
      var simulatedNow = DateTime(2026, 10, 17, 8, 0, 0);
      final syncNotifier = TestHealthSyncNotifier(clock: () => simulatedNow);
      final triggeredReasons = <String>[];

      final enabledUser = UserAccount.fromGoogle(
        id: 'user_1',
        googleUserId: 'g_1',
        displayName: 'Test User',
        email: 'test@example.com',
        healthConnectEnabled: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(enabledUser),
            healthConnectSyncProvider.overrideWith((ref) => syncNotifier),
          ],
          child: MaterialApp(
            home: AppLifecycleSyncObserver(
              clock: () => simulatedNow,
              throttleDuration: const Duration(minutes: 5),
              onSyncTriggered: (reason) => triggeredReasons.add(reason),
              child: const Scaffold(body: Text('Main Feed')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(syncNotifier.syncCallCount, equals(1));
      expect(triggeredReasons, equals(['launch']));

      // Advance time by only 2 minutes (inside the 5 minute throttle window)
      simulatedNow = simulatedNow.add(const Duration(minutes: 2));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Should be throttled — no additional sync dispatch
      expect(syncNotifier.syncCallCount, equals(1));
      expect(triggeredReasons, equals(['launch']));
    });

    testWidgets(
        'ignores non-resumed lifecycle transitions (paused, inactive, detached)',
        (tester) async {
      final syncNotifier = TestHealthSyncNotifier();
      final triggeredReasons = <String>[];

      var simulatedNow = DateTime(2026, 10, 17, 8, 0, 0);

      final enabledUser = UserAccount.fromGoogle(
        id: 'user_1',
        googleUserId: 'g_1',
        displayName: 'Test User',
        email: 'test@example.com',
        healthConnectEnabled: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(enabledUser),
            healthConnectSyncProvider.overrideWith((ref) => syncNotifier),
          ],
          child: MaterialApp(
            home: AppLifecycleSyncObserver(
              clock: () => simulatedNow,
              throttleDuration: const Duration(minutes: 5),
              onSyncTriggered: (reason) => triggeredReasons.add(reason),
              child: const Scaffold(body: Text('Main Feed')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(syncNotifier.syncCallCount, equals(1));

      simulatedNow = simulatedNow.add(const Duration(hours: 1));

      // Inactive
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();

      // Paused
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      // Detached
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
      await tester.pumpAndSettle();

      expect(syncNotifier.syncCallCount, equals(1));
      expect(triggeredReasons, equals(['launch']));
    });
  });

  group('AppLifecycleSyncObserver Error Absorption', () {
    testWidgets(
        'quietly absorbs exceptions during sync without interrupting user interface',
        (tester) async {
      final failingSyncNotifier = TestHealthSyncNotifier(shouldThrow: true);

      final enabledUser = UserAccount.fromGoogle(
        id: 'user_1',
        googleUserId: 'g_1',
        displayName: 'Test User',
        email: 'test@example.com',
        healthConnectEnabled: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(enabledUser),
            healthConnectSyncProvider
                .overrideWith((ref) => failingSyncNotifier),
          ],
          child: const MaterialApp(
            home: AppLifecycleSyncObserver(
              child: Scaffold(
                body: Center(
                  child: Text('Resilient UI'),
                ),
              ),
            ),
          ),
        ),
      );

      // Should complete without uncaught exceptions
      await tester.pumpAndSettle();

      expect(find.text('Resilient UI'), findsOneWidget);
      expect(failingSyncNotifier.syncCallCount, equals(1));
    });
  });
}
