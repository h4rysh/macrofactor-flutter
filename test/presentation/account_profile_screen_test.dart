import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/algorithms/weight_trend_v2.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/models/workout_session.dart';
import 'package:sique/domain/services/auth_service.dart';
import 'package:sique/domain/services/health_sync_adapter.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/account_profile_screen.dart';
import 'package:sique/presentation/widgets/google_account_card.dart';
import 'package:sique/presentation/widgets/health_connect_sync_card.dart';
import 'package:sique/presentation/widgets/physical_stats_summary_card.dart';
import 'package:sique/presentation/widgets/recent_workout_card.dart';
import 'package:sique/presentation/widgets/workout_consistency_tracker.dart';
import 'package:sique/presentation/widgets/workout_stats_hero_grid.dart';

class FakeAuthService implements AuthService {
  FakeAuthService({this.currentUser});

  UserAccount? currentUser;
  bool signInCalled = false;
  bool signOutCalled = false;

  @override
  Future<UserAccount?> getCurrentUser() async => currentUser;

  @override
  Future<UserAccount?> signInSilently() async => currentUser;

  @override
  Future<UserAccount> signInWithGoogle() async {
    signInCalled = true;
    return currentUser ??
        UserAccount.fromGoogle(
          googleUserId: 'g_123',
          displayName: 'Test Athlete',
          email: 'test@example.com',
        );
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    currentUser = null;
  }
}

class FakeHealthSyncAdapter implements HealthSyncAdapter {
  bool fetchWorkoutsCalled = false;

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
  }) async {
    fetchWorkoutsCalled = true;
    return [];
  }

  @override
  Future<List<ScaleWeightEntry>> fetchWeights({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    return [];
  }
}

void main() {
  late AppDatabase db;
  late FakeAuthService authService;
  late FakeHealthSyncAdapter syncAdapter;

  setUp(() {
    db = AppDatabase.inMemory();
    authService = FakeAuthService();
    syncAdapter = FakeHealthSyncAdapter();
  });

  tearDown(() {
    db.close();
  });

  Widget buildTestableWidget({UserAccount? initialUser}) {
    if (initialUser != null) {
      db.saveAccountSession(initialUser);
      authService.currentUser = initialUser;
    }

    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        authServiceProvider.overrideWithValue(authService),
        healthSyncAdapterProvider.overrideWithValue(syncAdapter),
      ],
      child: const MaterialApp(
        home: AccountProfileScreen(),
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

  group('AccountProfileScreen Widget Tests', () {
    testWidgets(
        'renders all 6 modular cards in guest mode and handles back button',
        (tester) async {
      configureViewport(tester);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // App bar and back button
      expect(find.text('Account & Profile'), findsOneWidget);
      expect(find.byKey(const Key('profile_back_btn')), findsOneWidget);

      // Verify all 6 modular cards exist
      expect(find.byType(GoogleAccountCard), findsOneWidget);
      expect(find.byType(WorkoutStatsHeroGrid), findsOneWidget);
      expect(find.byType(WorkoutConsistencyTracker), findsOneWidget);
      expect(find.byType(RecentWorkoutsFeed), findsOneWidget);
      expect(find.byType(PhysicalStatsSummaryCard), findsOneWidget);
      expect(find.byType(HealthConnectSyncCard), findsOneWidget);

      // Guest mode card contents
      expect(find.byKey(const Key('profile_sign_in_btn')), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Guest Athlete'), findsOneWidget);

      // Hero stats
      expect(find.byKey(const Key('hero_stat_total_workouts')), findsOneWidget);
      expect(find.byKey(const Key('hero_stat_training_time')), findsOneWidget);
      expect(find.byKey(const Key('hero_stat_avg_duration')), findsOneWidget);
      expect(
          find.byKey(const Key('hero_stat_active_calories')), findsOneWidget);

      // Consistency & Recent
      expect(find.text('Weekly Consistency'), findsOneWidget);
      expect(find.text('Recent Workouts'), findsOneWidget);

      // Physical stats
      expect(find.text('Physical Stats & Targets'), findsOneWidget);

      // Health Connect Card
      expect(find.byKey(const Key('profile_sync_now_btn')), findsOneWidget);
      expect(find.byKey(const Key('profile_last_sync_text')), findsOneWidget);
    });

    testWidgets('renders authenticated state and handles Sign Out action',
        (tester) async {
      configureViewport(tester);

      final authedUser = UserAccount.fromGoogle(
        googleUserId: 'google_789',
        displayName: 'Dev Sharma',
        email: 'dev.sharma@example.com',
        healthConnectEnabled: true,
      );

      await tester.pumpWidget(buildTestableWidget(initialUser: authedUser));
      await tester.pumpAndSettle();

      // Display name and email
      expect(find.text('Dev Sharma'), findsOneWidget);
      expect(find.text('dev.sharma@example.com'), findsOneWidget);

      // Sign out button should be visible
      expect(find.byKey(const Key('profile_sign_out_btn')), findsOneWidget);

      // Tap Sign Out button
      await tester.tap(find.byKey(const Key('profile_sign_out_btn')));
      await tester.pumpAndSettle();

      // Confirm sign out in dialog
      await tester.tap(find.widgetWithText(TextButton, 'Sign Out'));
      await tester.pumpAndSettle();

      expect(authService.signOutCalled, isTrue);
    });

    testWidgets(
        'tapping sync now button in HealthConnectSyncCard triggers sync',
        (tester) async {
      configureViewport(tester);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Scroll to HealthConnectSyncCard
      await tester.scrollUntilVisible(
        find.byKey(const Key('profile_sync_now_btn')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profile_sync_now_btn')));
      await tester.pumpAndSettle();

      expect(syncAdapter.fetchWorkoutsCalled, isTrue);
    });

    testWidgets(
        'tapping Continue with Demo Athlete Profile button logs in as Demo Athlete',
        (tester) async {
      configureViewport(tester);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Guest athlete initially visible
      expect(find.text('Guest Athlete'), findsOneWidget);
      expect(find.byKey(const Key('profile_demo_sign_in_btn')), findsOneWidget);

      // Tap Demo Athlete button
      await tester.tap(find.byKey(const Key('profile_demo_sign_in_btn')));
      await tester.pumpAndSettle();

      // Should now be signed in with Demo Athlete profile
      expect(find.text('Athlete (Demo)'), findsOneWidget);
      expect(find.text('athlete.demo@sique.local'), findsOneWidget);
      expect(find.byKey(const Key('profile_sign_out_btn')), findsOneWidget);
    });
  });
}
