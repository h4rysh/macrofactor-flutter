import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macro_factor_app/data/local/app_database.dart';
import 'package:macro_factor_app/domain/algorithms/weight_trend_v2.dart';
import 'package:macro_factor_app/domain/models/food_models.dart';
import 'package:macro_factor_app/domain/models/user_account.dart';
import 'package:macro_factor_app/domain/models/workout_session.dart';
import 'package:macro_factor_app/domain/services/auth_service.dart';
import 'package:macro_factor_app/domain/services/health_sync_adapter.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';
import 'package:macro_factor_app/presentation/screens/about_screen.dart';
import 'package:macro_factor_app/presentation/screens/account_profile_screen.dart';
import 'package:macro_factor_app/presentation/screens/dashboard_screen.dart';
import 'package:macro_factor_app/presentation/screens/data_export_screen.dart';
import 'package:macro_factor_app/presentation/screens/expenditure_settings_screen.dart';
import 'package:macro_factor_app/presentation/screens/food_log_settings_screen.dart';
import 'package:macro_factor_app/presentation/screens/more_screen.dart';
import 'package:macro_factor_app/presentation/screens/profile_targets_screen.dart';
import 'package:macro_factor_app/presentation/screens/scaffold_with_nav_bar.dart';

class ControllableAuthService implements AuthService {
  ControllableAuthService({this.currentUser});

  UserAccount? currentUser;
  bool shouldFailSignIn = false;
  int signInCalls = 0;
  int signOutCalls = 0;

  @override
  Future<UserAccount?> getCurrentUser() async => currentUser;

  @override
  Future<UserAccount?> signInSilently() async => currentUser;

  @override
  Future<UserAccount> signInWithGoogle() async {
    signInCalls++;
    if (shouldFailSignIn) {
      throw Exception('OAuth Network Unavailable');
    }
    final user = UserAccount.fromGoogle(
      googleUserId: 'g_stress_999',
      displayName: 'Adversarial Athlete',
      email: 'adv@athlete.com',
      healthConnectEnabled: true,
    );
    currentUser = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    currentUser = null;
  }
}

class ControllableHealthSyncAdapter implements HealthSyncAdapter {
  ControllableHealthSyncAdapter({
    this.isAvailableValue = true,
    this.hasPermissionsValue = true,
  });

  bool isAvailableValue;
  bool hasPermissionsValue;
  bool shouldThrowOnFetch = false;
  int fetchWorkoutsCalls = 0;
  int fetchWeightsCalls = 0;
  Completer<void>? inFlightCompleter;

  @override
  Future<bool> isAvailable() async => isAvailableValue;

  @override
  Future<bool> hasPermissions() async => hasPermissionsValue;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<List<WorkoutSession>> fetchWorkouts({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    fetchWorkoutsCalls++;
    if (shouldThrowOnFetch) {
      throw Exception('Health Connect connection failed');
    }
    if (inFlightCompleter != null) {
      await inFlightCompleter!.future;
    }
    return [
      WorkoutSession(
        id: 'stress_workout_1',
        source: 'hevy',
        title: 'Heavy Bench & Incline',
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().subtract(const Duration(hours: 1)),
        durationMinutes: 60,
        caloriesBurned: 350.0,
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<ScaleWeightEntry>> fetchWeights({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    fetchWeightsCalls++;
    if (shouldThrowOnFetch) {
      throw Exception('Health Connect connection failed');
    }
    if (inFlightCompleter != null) {
      await inFlightCompleter!.future;
    }
    return [
      ScaleWeightEntry(
        date: DateTime.now(),
        weightKg: 77.8,
        note: 'Health Connect',
      ),
    ];
  }
}

void main() {
  late AppDatabase db;
  late ControllableAuthService authService;
  late ControllableHealthSyncAdapter syncAdapter;

  setUp(() {
    db = AppDatabase.inMemory();
    authService = ControllableAuthService();
    syncAdapter = ControllableHealthSyncAdapter();
  });

  tearDown(() {
    db.close();
  });

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget buildTestHarness({
    required Widget child,
    UserAccount? initialUser,
  }) {
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
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Group 1: Navigation Push & Pop Stress Cycles', () {
    testWidgets(
      'Dashboard -> AccountProfileScreen -> Pop back across 5 continuous rapid cycles',
      (tester) async {
        configureViewport(tester);

        await tester.pumpWidget(
          buildTestHarness(child: const DashboardScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);

        // Run 5 continuous push-pop cycles
        for (var i = 1; i <= 5; i++) {
          final avatarBtn =
              find.byKey(const Key('dashboard_profile_avatar_btn'));
          expect(avatarBtn, findsOneWidget);

          // Push
          await tester.tap(avatarBtn);
          await tester.pumpAndSettle();

          expect(find.byType(AccountProfileScreen), findsOneWidget);
          expect(find.byKey(const Key('profile_back_btn')), findsOneWidget);

          // Pop
          await tester.tap(find.byKey(const Key('profile_back_btn')));
          await tester.pumpAndSettle();

          expect(find.byType(DashboardScreen), findsOneWidget);
          expect(find.byType(AccountProfileScreen), findsNothing);
        }
      },
    );

    testWidgets(
      'MoreScreen -> AccountProfileScreen -> Pop back across 5 continuous rapid cycles',
      (tester) async {
        configureViewport(tester);

        await tester.pumpWidget(
          buildTestHarness(child: const MoreScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MoreScreen), findsOneWidget);

        for (var i = 1; i <= 5; i++) {
          final moreAccountCard = find.byKey(const Key('more_account_card'));
          expect(moreAccountCard, findsOneWidget);

          // Push
          await tester.tap(moreAccountCard);
          await tester.pumpAndSettle();

          expect(find.byType(AccountProfileScreen), findsOneWidget);
          expect(find.byKey(const Key('profile_back_btn')), findsOneWidget);

          // Pop
          await tester.tap(find.byKey(const Key('profile_back_btn')));
          await tester.pumpAndSettle();

          expect(find.byType(MoreScreen), findsOneWidget);
          expect(find.byType(AccountProfileScreen), findsNothing);
        }
      },
    );

    testWidgets(
      'Multi-tab root scaffold navigation stress with interleaved profile visits',
      (tester) async {
        configureViewport(tester);

        await tester.pumpWidget(
          buildTestHarness(child: const ScaffoldWithNavBar()),
        );
        await tester.pumpAndSettle();

        // Starts on Food Log (index 1) by default
        expect(find.text('Food Log'), findsWidgets);

        // Switch to Dashboard (Tab index 0)
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();

        // 1. Visit Profile from Dashboard
        await tester.tap(find.byKey(const Key('dashboard_profile_avatar_btn')));
        await tester.pumpAndSettle();
        expect(find.byType(AccountProfileScreen), findsOneWidget);

        // Pop back to Dashboard
        await tester.tap(find.byKey(const Key('profile_back_btn')));
        await tester.pumpAndSettle();
        expect(find.byType(AccountProfileScreen), findsNothing);

        // 2. Switch to More Tab (Tab index 3)
        await tester.tap(find.text('More'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('more_account_card')), findsOneWidget);

        // Visit Profile from More Screen
        await tester.tap(find.byKey(const Key('more_account_card')));
        await tester.pumpAndSettle();
        expect(find.byType(AccountProfileScreen), findsOneWidget);

        // Pop back to More Screen
        await tester.tap(find.byKey(const Key('profile_back_btn')));
        await tester.pumpAndSettle();
        expect(find.byType(AccountProfileScreen), findsNothing);

        // 3. Switch between tabs rapidly without crashes
        await tester.tap(find.text('Food Log'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Strategy'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();

        // Final Profile visit to verify intact navigation stack
        await tester.tap(find.byKey(const Key('dashboard_profile_avatar_btn')));
        await tester.pumpAndSettle();
        expect(find.byType(AccountProfileScreen), findsOneWidget);
        await tester.tap(find.byKey(const Key('profile_back_btn')));
        await tester.pumpAndSettle();
        expect(find.byType(DashboardScreen), findsOneWidget);
      },
    );
  });

  group('Group 2: Live Auth State Transitions & Data Sovereignty Stress', () {
    testWidgets(
      'Guest -> Authenticated -> Sign out dialog Cancel -> Confirm Sign out -> Guest with 100% data sovereignty',
      (tester) async {
        configureViewport(tester);

        // 1. Pre-seed database with local food logs, workouts, and weight logs
        db.insertFoodLog(
          FoodLogEntry(
            date: '2026-10-18',
            mealType: MealType.lunch,
            foodId: 101,
            foodName: 'Paneer Butter Masala',
            servingQuantity: 1.0,
            unitName: 'Katori',
            gramWeight: 150.0,
            calories: 320.0,
            protein: 14.0,
            carbs: 10.0,
            fat: 24.0,
            fiber: 3.0,
            oilModifier: OilModifier.standard,
            loggedAt: DateTime.now(),
          ),
        );

        db.insertWorkoutSessions([
          WorkoutSession(
            id: 'local_pre_seed_session',
            source: 'hevy',
            title: 'Full Body Hypertrophy',
            startTime: DateTime.now().subtract(const Duration(hours: 3)),
            endTime: DateTime.now().subtract(const Duration(hours: 2)),
            durationMinutes: 60,
            caloriesBurned: 420.0,
            createdAt: DateTime.now(),
          ),
        ]);

        db.insertWeightLog('2026-10-18', 75.5, 'Pre-auth baseline weight');

        // Verify pre-conditions in DB
        expect(db.getFoodLogsForDate('2026-10-18'), hasLength(1));
        expect(db.getAllWorkoutSessions(), hasLength(1));
        expect(db.getAllWeightLogs(), hasLength(1));

        // 2. Mount AccountProfileScreen in Guest Mode
        await tester.pumpWidget(
          buildTestHarness(child: const AccountProfileScreen()),
        );
        await tester.pumpAndSettle();

        // Guest mode assertions
        expect(find.text('Guest Athlete'), findsOneWidget);
        expect(find.text('Guest Mode'), findsOneWidget);
        expect(find.byKey(const Key('profile_sign_in_btn')), findsOneWidget);
        expect(find.byKey(const Key('profile_sign_out_btn')), findsNothing);

        // 3. Trigger Google Sign-In
        await tester.tap(find.byKey(const Key('profile_sign_in_btn')));
        await tester.pumpAndSettle();

        // Live UI transition assertions
        expect(authService.signInCalls, 1);
        expect(find.text('Adversarial Athlete'), findsOneWidget);
        expect(find.text('adv@athlete.com'), findsOneWidget);
        expect(find.text('Connected'), findsOneWidget);
        expect(find.byKey(const Key('profile_sign_out_btn')), findsOneWidget);
        expect(find.byKey(const Key('profile_sign_in_btn')), findsNothing);

        // 4. Test Sign Out Dialog - Cancel first
        await tester.tap(find.byKey(const Key('profile_sign_out_btn')));
        await tester.pumpAndSettle();

        expect(find.text('Sign Out'), findsWidgets);
        expect(
          find.text(
            'Are you sure you want to sign out? All your local workout logs and nutrition data will remain intact.',
          ),
          findsOneWidget,
        );

        // Tap Cancel
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();

        // User should still be authenticated
        expect(find.text('Adversarial Athlete'), findsOneWidget);
        expect(authService.signOutCalls, 0);

        // 5. Test Sign Out Dialog - Confirm Sign Out
        await tester.tap(find.byKey(const Key('profile_sign_out_btn')));
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.widgetWithText(TextButton, 'Sign Out'),
          ),
        );
        await tester.pumpAndSettle();

        // UI transitions back to Guest Mode
        expect(authService.signOutCalls, 1);
        expect(find.text('Guest Athlete'), findsOneWidget);
        expect(find.text('Guest Mode'), findsOneWidget);
        expect(find.byKey(const Key('profile_sign_in_btn')), findsOneWidget);
        expect(find.byKey(const Key('profile_sign_out_btn')), findsNothing);

        // 6. RIGOROUS DATA SOVEREIGNTY ASSERTION: All pre-seeded data remains intact
        final retainedFoodLogs = db.getFoodLogsForDate('2026-10-18');
        expect(retainedFoodLogs, hasLength(1));
        expect(retainedFoodLogs.first.foodName, 'Paneer Butter Masala');

        final retainedWorkouts = db.getAllWorkoutSessions();
        expect(retainedWorkouts, hasLength(1));
        expect(retainedWorkouts.first.title, 'Full Body Hypertrophy');

        final retainedWeights = db.getAllWeightLogs();
        expect(retainedWeights, hasLength(1));
        expect(retainedWeights.first.weightKg, 75.5);

        // Account session table must be cleared
        expect(db.getAccountSession(), isNull);
      },
    );

    testWidgets(
      'Google Sign-In failure handles error state gracefully without crashing UI',
      (tester) async {
        configureViewport(tester);

        authService.shouldFailSignIn = true;

        await tester.pumpWidget(
          buildTestHarness(child: const AccountProfileScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('profile_sign_in_btn')), findsOneWidget);

        await tester.tap(find.byKey(const Key('profile_sign_in_btn')));
        await tester.pumpAndSettle();

        // Should still be in a stable state with guest fallback, no red screen
        expect(find.byType(AccountProfileScreen), findsOneWidget);
        expect(authService.signInCalls, 1);
        expect(find.byKey(const Key('profile_sign_in_btn')), findsOneWidget);
      },
    );
  });

  group(
      'Group 3: Health Connect Manual Sync Rapid Double-Tap & Concurrency Stress',
      () {
    testWidgets(
      'Rapid multiple taps on Key("profile_sync_now_btn") are guarded by in-flight lock',
      (tester) async {
        configureViewport(tester);

        final completer = Completer<void>();
        syncAdapter.inFlightCompleter = completer;

        await tester.pumpWidget(
          buildTestHarness(child: const AccountProfileScreen()),
        );
        await tester.pumpAndSettle();

        final syncBtn = find.byKey(const Key('profile_sync_now_btn'));

        // Scroll until visible
        await tester.scrollUntilVisible(
          syncBtn,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        // 1. First tap initiates sync
        await tester.tap(syncBtn);
        await tester.pump(); // Pump frame to render syncing state

        // Verify spinning indicator and synchronizing text
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Synchronizing Health Data...'), findsOneWidget);

        // 2. Rapid double/triple taps while sync is in-flight
        await tester.tap(syncBtn, warnIfMissed: false);
        await tester.pump();
        await tester.tap(syncBtn, warnIfMissed: false);
        await tester.pump();

        // Verify adapter was invoked only once so far
        expect(syncAdapter.fetchWorkoutsCalls, 1);

        // 3. Complete the in-flight operation
        completer.complete();
        await tester.pumpAndSettle();

        // Spinner is gone, status is updated
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(syncAdapter.fetchWorkoutsCalls, 1);
        expect(find.byKey(const Key('profile_last_sync_text')), findsOneWidget);
        expect(find.text('Just now'), findsOneWidget);
      },
    );

    testWidgets(
      'Rapid multiple taps on Key("settings_sync_now_btn") in FoodLogSettingsScreen are guarded',
      (tester) async {
        configureViewport(tester);

        final completer = Completer<void>();
        syncAdapter.inFlightCompleter = completer;

        await tester.pumpWidget(
          buildTestHarness(child: const FoodLogSettingsScreen()),
        );
        await tester.pumpAndSettle();

        final settingsSyncBtn = find.byKey(const Key('settings_sync_now_btn'));

        // Scroll until visible
        await tester.scrollUntilVisible(
          settingsSyncBtn,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        // 1. First tap triggers sync
        await tester.tap(settingsSyncBtn);
        await tester.pump();

        // Spinner is visible and label says "Syncing..."
        expect(find.byType(CircularProgressIndicator), findsWidgets);
        expect(find.text('Syncing...'), findsOneWidget);

        // 2. Rapid repeated taps while in-flight
        await tester.tap(settingsSyncBtn, warnIfMissed: false);
        await tester.pump();
        await tester.tap(settingsSyncBtn, warnIfMissed: false);
        await tester.pump();

        // Adapter must only have been called once
        expect(syncAdapter.fetchWorkoutsCalls, 1);

        // 3. Complete in-flight future
        completer.complete();
        await tester.pumpAndSettle();

        // Returned to normal state
        expect(find.text('Sync Now'), findsOneWidget);
        expect(syncAdapter.fetchWorkoutsCalls, 1);
        expect(find.text('Last synced: Just now'), findsOneWidget);
      },
    );

    testWidgets(
      'Manual sync error handling recovers button state and presents error cleanly',
      (tester) async {
        configureViewport(tester);

        syncAdapter.shouldThrowOnFetch = true;

        await tester.pumpWidget(
          buildTestHarness(child: const AccountProfileScreen()),
        );
        await tester.pumpAndSettle();

        final syncBtn = find.byKey(const Key('profile_sync_now_btn'));

        await tester.scrollUntilVisible(
          syncBtn,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(syncBtn);
        await tester.pumpAndSettle();

        // Verifies no uncaught widget error; spinner dismissed
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(syncAdapter.fetchWorkoutsCalls, 1);

        // Button should still be rendered and recoverable
        expect(syncBtn, findsOneWidget);
      },
    );
  });

  group('Group 4: MoreScreen 5 Settings Tiles Stability Under ALL Auth States',
      () {
    testWidgets(
      'All 5 settings tiles maintain tap targets and navigate under Guest State',
      (tester) async {
        configureViewport(tester);

        await tester.pumpWidget(
          buildTestHarness(child: const MoreScreen()),
        );
        await tester.pumpAndSettle();

        // 1. Profile & Targets
        await tester.tap(find.text('Profile & Targets'));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileTargetsScreen), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(MoreScreen), findsOneWidget);

        // 2. Food Log Settings
        await tester.tap(find.text('Food Log Settings'));
        await tester.pumpAndSettle();
        expect(find.byType(FoodLogSettingsScreen), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(MoreScreen), findsOneWidget);

        // 3. Expenditure & Weight Settings
        await tester.tap(find.text('Expenditure & Weight Settings'));
        await tester.pumpAndSettle();
        expect(find.byType(ExpenditureSettingsScreen), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(MoreScreen), findsOneWidget);

        // 4. Data Export & Diagnostics
        await tester.tap(find.text('Data Export & Diagnostics'));
        await tester.pumpAndSettle();
        expect(find.byType(DataExportScreen), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(MoreScreen), findsOneWidget);

        // 5. About Screen
        await tester.tap(find.text('About MacroFactor (Indian Edition)'));
        await tester.pumpAndSettle();
        expect(find.byType(AboutScreen), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(MoreScreen), findsOneWidget);
      },
    );

    testWidgets(
      'All 5 settings tiles maintain tap targets and navigate under Authenticated State',
      (tester) async {
        configureViewport(tester);

        final authedUser = UserAccount.fromGoogle(
          googleUserId: 'g_authed_user_555',
          displayName: 'Priya Sharma',
          email: 'priya.sharma@example.com',
          healthConnectEnabled: true,
        );

        await tester.pumpWidget(
          buildTestHarness(
            child: const MoreScreen(),
            initialUser: authedUser,
          ),
        );
        await tester.pumpAndSettle();

        // Verify account card displays authenticated user name
        expect(find.text('Priya Sharma'), findsOneWidget);
        expect(find.text('priya.sharma@example.com'), findsOneWidget);

        // 1. Profile & Targets
        await tester.tap(find.text('Profile & Targets'));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileTargetsScreen), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(MoreScreen), findsOneWidget);

        // 2. Food Log Settings
        await tester.tap(find.text('Food Log Settings'));
        await tester.pumpAndSettle();
        expect(find.byType(FoodLogSettingsScreen), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(MoreScreen), findsOneWidget);

        // 3. Expenditure & Weight Settings
        await tester.tap(find.text('Expenditure & Weight Settings'));
        await tester.pumpAndSettle();
        expect(find.byType(ExpenditureSettingsScreen), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(MoreScreen), findsOneWidget);

        // 4. Data Export & Diagnostics
        await tester.tap(find.text('Data Export & Diagnostics'));
        await tester.pumpAndSettle();
        expect(find.byType(DataExportScreen), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(MoreScreen), findsOneWidget);

        // 5. About Screen
        await tester.tap(find.text('About MacroFactor (Indian Edition)'));
        await tester.pumpAndSettle();
        expect(find.byType(AboutScreen), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(MoreScreen), findsOneWidget);
      },
    );
  });
}
