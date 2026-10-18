import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macro_factor_app/data/local/app_database.dart';
import 'package:macro_factor_app/main.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';
import 'package:macro_factor_app/presentation/screens/onboarding/auth_gate_screen.dart';
import 'package:macro_factor_app/presentation/screens/onboarding/strategy_setup_wizard.dart';
import 'package:macro_factor_app/presentation/screens/onboarding/welcome_screen.dart';
import 'package:macro_factor_app/presentation/screens/scaffold_with_nav_bar.dart';

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
        child: const MacroFactorApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify WelcomeScreen is displayed
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('MACROFACTOR'), findsOneWidget);
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
        child: const MacroFactorApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Dashboard / Main Scaffold is loaded
    expect(find.byType(ScaffoldWithNavBar), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
  });

  testWidgets(
      'Tapping "Configure My Strategy" on WelcomeScreen navigates to StrategySetupWizard',
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
        child: const MacroFactorApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Configure My Strategy
    await tester.tap(find.text('Configure My Strategy'));
    await tester.pumpAndSettle();

    // Verify StrategySetupWizard is open
    expect(find.byType(StrategySetupWizard), findsOneWidget);
    expect(find.text('Step 1 of 6'), findsOneWidget);
    expect(find.text('Tell us about yourself'), findsOneWidget);
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
        child: const MacroFactorApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Sign In link
    await tester.tap(find.text('Already have an account? Sign In'));
    await tester.pumpAndSettle();

    // Verify AuthGateScreen is open
    expect(find.byType(AuthGateScreen), findsOneWidget);
    expect(find.text('Account & Cloud Sync'), findsOneWidget);
  });
}
