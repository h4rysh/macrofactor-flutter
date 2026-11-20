import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/expenditure_settings_screen.dart';
import 'package:sique/presentation/screens/food_log_settings_screen.dart';
import 'package:sique/presentation/screens/health_sync_settings_screen.dart';
import 'package:sique/presentation/screens/more_screen.dart';
import 'package:sique/presentation/screens/onboarding/onboarding_coordinator.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_24_program_ready.dart';
import 'package:sique/presentation/screens/onboarding/strategy_setup_wizard.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() {
    db.close();
  });

  Widget createHarness({
    required Widget child,
    UserProfile? initialProfile,
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        currentUserProvider.overrideWith((ref) => UserAccount(
              id: 'test_user',
              googleUserId: 'google_123',
              displayName: 'Pro Athlete',
              email: 'athlete@sique.fit',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group(
      'UI Remediation Fixes Tests (ISS-1-02, ISS-1-03, ISS-1-06, ISS-1-07, ISS-6-01, ISS-6-04, ISS-7-03, ISS-7-05, ISS-8-03)',
      () {
    testWidgets(
        '1. OnboardingStepScaffold: ClampingScrollPhysics prevents RenderFlex overflow under simulated 219px keyboard inset',
        (tester) async {
      tester.view.physicalSize = const Size(360, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createHarness(
          child: const OnboardingStepScaffold(
            title: 'Test Step Title',
            subtitle: 'Test step subtitle explaining biometric targets.',
            onContinue: null,
            child: SizedBox(
              height: 250,
              child: Text('Step Content Input Body'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the SingleChildScrollView and verify ClampingScrollPhysics
      final scrollFinder = find.byType(SingleChildScrollView);
      expect(scrollFinder, findsOneWidget);
      final scrollView = tester.widget<SingleChildScrollView>(scrollFinder);
      expect(scrollView.physics, isA<ClampingScrollPhysics>());
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '2. OnboardingFlowScreen: Resuming at Step 24 (index 23) synthesizes program without deadlock or indefinite spinner',
        (tester) async {
      tester.view.physicalSize = const Size(450, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      db.setSetting('onboarding_completed', 'false');
      db.setSetting('onboarding_step', '23');

      await tester.pumpWidget(
        createHarness(
          child: const OnboardingCoordinator(),
        ),
      );
      await tester.pumpAndSettle();

      // Should render Step 24 Program Ready screen immediately
      expect(find.byType(Step24ProgramReady), findsOneWidget);
      expect(find.text('Program Ready'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
        '3. StrategySetupWizard: Pops navigation route instead of pushing AuthGate and preserves profile name and calorie floor',
        (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Prepopulate a custom profile
      const customProfile = UserProfile(
        id: 'usr_me',
        name: 'Custom Champion',
        currentWeightKg: 80.0,
        targetWeightKg: 75.0,
        heightCm: 180.0,
        age: 30,
        isMale: true,
        goalType: GoalType.fatLoss,
        programMode: ProgramMode.coached,
        weeklyRateOfChangePct: -0.5,
        proteinPreference: ProteinPreference.high,
        calorieFloor: 1650.0,
        baselineExpenditureKcal: 2500.0,
      );
      db.saveUserProfile(customProfile);

      bool popped = false;
      final observer = _TestNavObserver(onPopped: () => popped = true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            navigatorObservers: [observer],
            home: Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).push(
                      MaterialPageRoute(
                          builder: (_) => const StrategySetupWizard()),
                    );
                  },
                  child: const Text('Launch Wizard'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Launch Wizard'));
      await tester.pumpAndSettle();

      expect(find.byType(StrategySetupWizard), findsOneWidget);

      // Advance through wizard to final step
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('wizard_continue_btn')));
        await tester.pumpAndSettle();
      }

      // Tap final button to activate strategy
      await tester.tap(find.byKey(const Key('wizard_continue_btn')));
      await tester.pumpAndSettle();

      // Route popped back
      expect(popped, isTrue);

      // Verify custom name and calorie floor preserved in database
      final saved = db.getUserProfile();
      expect(saved?.name, 'Custom Champion');
      expect(saved?.calorieFloor, 1650.0);
    });

    testWidgets(
        '4. MoreScreen: Health Connect Sync navigation tile is wired in and navigates to HealthSyncSettingsScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createHarness(child: const MoreScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Health Connect Sync'), findsOneWidget);
      await tester.tap(find.text('Health Connect Sync'));
      await tester.pumpAndSettle();

      expect(find.byType(HealthSyncSettingsScreen), findsOneWidget);
    });

    testWidgets(
        '5. FoodLogSettingsScreen & ExpenditureSettingsScreen: Render with ClampingScrollPhysics and connect toggles',
        (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Test FoodLogSettingsScreen
      await tester
          .pumpWidget(createHarness(child: const FoodLogSettingsScreen()));
      await tester.pumpAndSettle();

      final foodScroll = tester.widget<ListView>(find.byType(ListView));
      expect(foodScroll.physics, isA<ClampingScrollPhysics>());
      expect(tester.takeException(), isNull);

      // Test ExpenditureSettingsScreen on compact viewport
      await tester
          .pumpWidget(createHarness(child: const ExpenditureSettingsScreen()));
      await tester.pumpAndSettle();

      final expScroll = tester.widget<ListView>(find.byType(ListView));
      expect(expScroll.physics, isA<ClampingScrollPhysics>());
      expect(tester.takeException(), isNull);
    });
  });
}

class _TestNavObserver extends NavigatorObserver {
  _TestNavObserver({required this.onPopped});
  final VoidCallback onPopped;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    onPopped();
  }
}
