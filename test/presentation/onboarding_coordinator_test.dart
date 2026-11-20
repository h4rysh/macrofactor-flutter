import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/main.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/onboarding/auth_gate_screen.dart';
import 'package:sique/presentation/screens/onboarding/onboarding_flow_screen.dart';
import 'package:sique/presentation/screens/onboarding/welcome_screen.dart';
import 'package:sique/presentation/screens/scaffold_with_nav_bar.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() {
    db.close();
  });

  testWidgets(
      'First launch (onboarding not completed) renders WelcomeScreen with Adherence-Neutral intro',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const SiqueApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify WelcomeScreen is displayed
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('SIQUE'), findsOneWidget);
    expect(find.text('Smarter Nutrition.\nZero Guilt.'), findsOneWidget);
    expect(find.text('Configure My Strategy'), findsOneWidget);
    expect(find.text('Already have an account? Sign In'), findsOneWidget);
  });

  testWidgets(
      'Completed onboarding boots directly into ScaffoldWithNavBar dashboard',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    db.setSetting('onboarding_completed', 'true');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const SiqueApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Dashboard / Main Scaffold is loaded
    expect(find.byType(ScaffoldWithNavBar), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
  });

  testWidgets(
      'Partially completed onboarding resumes at saved step after restart',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    db.setSetting('onboarding_completed', 'false');
    db.setSetting('onboarding_step', '4');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const SiqueApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify OnboardingFlowScreen opened at step index 4 (Step 5 of 24)
    expect(find.byType(OnboardingFlowScreen), findsOneWidget);
    expect(find.text('Step 5 of 24'), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
  });

  testWidgets(
      'Tapping "Configure My Strategy" on WelcomeScreen navigates to AuthGateScreen, proceeding enters OnboardingFlowScreen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const SiqueApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Configure My Strategy
    await tester.tap(find.text('Configure My Strategy'));
    await tester.pumpAndSettle();

    // Verify AuthGateScreen is displayed
    expect(find.byType(AuthGateScreen), findsOneWidget);
    expect(find.text('Account & Device Data'), findsOneWidget);

    // Tap Continue as Guest
    await tester.tap(find.byKey(const Key('auth_gate_guest_btn')));
    await tester.pumpAndSettle();

    // Verify OnboardingFlowScreen is open at step 1
    expect(find.byType(OnboardingFlowScreen), findsOneWidget);
    expect(find.text('Step 1 of 24'), findsOneWidget);
  });

  testWidgets(
      'Tapping "Already have an account? Sign In" navigates to AuthGateScreen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const SiqueApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Sign In link
    await tester.tap(find.text('Already have an account? Sign In'));
    await tester.pumpAndSettle();

    // Verify AuthGateScreen is open
    expect(find.byType(AuthGateScreen), findsOneWidget);
    expect(find.text('Account & Device Data'), findsOneWidget);
  });
}
