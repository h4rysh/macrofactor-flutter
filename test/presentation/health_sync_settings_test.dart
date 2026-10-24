import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/algorithms/weight_trend_v2.dart';
import 'package:sique/domain/models/workout_session.dart';
import 'package:sique/domain/services/health_sync_adapter.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/health_sync_settings_screen.dart';

class FakeHealthSyncAdapter implements HealthSyncAdapter {
  FakeHealthSyncAdapter({
    this.available = true,
    this.permissions = true,
  });

  bool available;
  bool permissions;
  bool requestPermissionsCalled = false;
  bool fetchWorkoutsCalled = false;
  bool fetchWeightsCalled = false;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> hasPermissions() async => permissions;

  @override
  Future<bool> requestPermissions() async {
    requestPermissionsCalled = true;
    permissions = true;
    return true;
  }

  @override
  Future<List<WorkoutSession>> fetchWorkouts({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    fetchWorkoutsCalled = true;
    return [];
  }

  @override
  Future<List<ScaleWeightEntry>> fetchWeights({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    fetchWeightsCalled = true;
    return [];
  }
}

void main() {
  late AppDatabase db;
  late FakeHealthSyncAdapter syncAdapter;

  setUp(() {
    db = AppDatabase.inMemory();
    syncAdapter = FakeHealthSyncAdapter();
  });

  tearDown(() {
    db.close();
  });

  Widget buildTestableWidget({FakeHealthSyncAdapter? adapter}) {
    final effectiveAdapter = adapter ?? syncAdapter;
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        healthSyncAdapterProvider.overrideWithValue(effectiveAdapter),
      ],
      child: const MaterialApp(
        home: HealthSyncSettingsScreen(),
      ),
    );
  }

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('HealthSyncSettingsScreen Widget Tests', () {
    testWidgets('renders all cards, titles, channels, and privacy notice',
        (tester) async {
      configureViewport(tester);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Screen title and back button
      expect(find.text('Health Connect Sync'), findsOneWidget);
      expect(find.byKey(const Key('health_sync_back_btn')), findsOneWidget);

      // Status card
      expect(find.byKey(const Key('health_sync_status_card')), findsOneWidget);
      expect(find.text('Google Health Connect'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);

      // Manual sync action card
      expect(find.byKey(const Key('health_sync_manual_card')), findsOneWidget);
      expect(find.text('Synchronization'), findsOneWidget);
      expect(find.byKey(const Key('health_sync_trigger_btn')), findsOneWidget);
      expect(find.text('Sync Now (30 Days)'), findsOneWidget);

      // Supported channels
      expect(find.text('Supported Channels'), findsOneWidget);
      expect(find.text('Workouts & Exercises'), findsOneWidget);
      expect(find.text('Scale Body Weight'), findsOneWidget);

      // Privacy card
      expect(find.textContaining('100% Local Privacy'), findsOneWidget);
    });

    testWidgets('tapping health_sync_trigger_btn triggers manual sync',
        (tester) async {
      configureViewport(tester);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(syncAdapter.fetchWorkoutsCalled, isFalse);

      await tester.tap(find.byKey(const Key('health_sync_trigger_btn')));
      await tester.pumpAndSettle();

      expect(syncAdapter.fetchWorkoutsCalled, isTrue);
      expect(syncAdapter.fetchWeightsCalled, isTrue);
    });

    testWidgets('renders permission prompt when permission is missing',
        (tester) async {
      configureViewport(tester);

      final unpermittedAdapter = FakeHealthSyncAdapter(
        available: true,
        permissions: false,
      );

      await tester.pumpWidget(buildTestableWidget(adapter: unpermittedAdapter));
      await tester.pumpAndSettle();

      expect(find.text('Action Required'), findsOneWidget);
      expect(find.text('Grant Read Permissions'), findsOneWidget);

      await tester.tap(find.text('Grant Read Permissions'));
      await tester.pumpAndSettle();

      expect(unpermittedAdapter.requestPermissionsCalled, isTrue);
    });

    testWidgets('tapping back button navigates back', (tester) async {
      configureViewport(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            healthSyncAdapterProvider.overrideWithValue(syncAdapter),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HealthSyncSettingsScreen(),
                      ),
                    );
                  },
                  child: const Text('Go to Sync'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open screen
      await tester.tap(find.text('Go to Sync'));
      await tester.pumpAndSettle();
      expect(find.byType(HealthSyncSettingsScreen), findsOneWidget);

      // Tap back button
      await tester.tap(find.byKey(const Key('health_sync_back_btn')));
      await tester.pumpAndSettle();

      // Back to caller
      expect(find.byType(HealthSyncSettingsScreen), findsNothing);
      expect(find.text('Go to Sync'), findsOneWidget);
    });
  });
}
