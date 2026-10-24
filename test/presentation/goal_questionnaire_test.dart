import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/main.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
    db.setSetting('onboarding_completed', 'true');
  });

  tearDown(() {
    db.close();
  });

  Widget createSubject({Widget? child}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: child ?? const SiqueApp(),
    );
  }

  group('Apple Tactile Card & Bouncy Micro-interactions', () {
    testWidgets('AppleBouncy animates and triggers callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppleBouncy(
              onTap: () => tapped = true,
              child: const Text('Bouncy Button'),
            ),
          ),
        ),
      );

      expect(find.text('Bouncy Button'), findsOneWidget);
      await tester.tap(find.text('Bouncy Button'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('AppleGlassCard and AppleBadge render correctly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppleGlassCard(
              child: AppleBadge(
                label: 'FEATURED',
                color: Colors.blue,
                icon: Icons.star,
              ),
            ),
          ),
        ),
      );

      expect(find.text('FEATURED'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('Goal Questionnaire Sheet Flow & Dynamic Branching', () {
    testWidgets(
        'Dashboard banner opens Goal Questionnaire Sheet and displays step 1',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(450, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Navigate to Dashboard tab
      await tester.tap(find.text('Dashboard').first);
      await tester.pumpAndSettle();

      // Tap the top adaptive setup banner
      expect(find.byKey(const Key('dashboard_goal_banner')), findsOneWidget);
      await tester.tap(find.byKey(const Key('dashboard_goal_banner')));
      await tester.pumpAndSettle();

      // Questionnaire sheet should be displayed
      expect(find.text('GOAL SELECTION'), findsOneWidget);
      expect(find.text('What is your primary goal?'), findsOneWidget);
      expect(find.text('Fat Loss'), findsOneWidget);
      expect(find.text('Maintenance & Recomposition'), findsOneWidget);
      expect(find.text('Muscle Gain (Hypertrophy)'), findsOneWidget);
    });

    testWidgets('Dynamic Branching: Step 1 Rate options adapt to selected goal',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(450, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Open from Dashboard button
      await tester.tap(find.text('Dashboard').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dashboard_goal_setup_btn')));
      await tester.pumpAndSettle();

      // Case A: Fat Loss
      await tester.tap(find.text('Fat Loss'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('questionnaire_next_btn')));
      await tester.pumpAndSettle();

      expect(find.text('RATE OF CHANGE'), findsOneWidget);
      expect(
          find.text('Select your desired pace of fat loss:'), findsOneWidget);
      expect(find.text('Conservative Loss'), findsOneWidget);
      expect(find.text('Recommended Standard'), findsOneWidget);
      expect(find.text('Aggressive Deficit'), findsOneWidget);

      // Back to Step 0
      await tester.tap(find.byKey(const Key('questionnaire_back_btn')));
      await tester.pumpAndSettle();

      // Case B: Muscle Gain
      await tester.tap(find.text('Muscle Gain (Hypertrophy)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('questionnaire_next_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Lean Bulk (Conservative)'), findsOneWidget);
      expect(find.text('Standard Muscle Gain'), findsOneWidget);
      expect(find.text('Hypertrophy Surplus'), findsOneWidget);

      // Back to Step 0
      await tester.tap(find.byKey(const Key('questionnaire_back_btn')));
      await tester.pumpAndSettle();

      // Case C: Maintenance & Recomposition
      await tester.tap(find.text('Maintenance & Recomposition'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('questionnaire_next_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Caloric Equilibrium / Recomp'), findsOneWidget);
    });

    testWidgets(
        'Completing 6-step questionnaire saves profile & Indian diet settings',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(450, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Open Questionnaire
      await tester.tap(find.text('Dashboard').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dashboard_goal_banner')));
      await tester.pumpAndSettle();

      // Step 0: Goal -> Fat Loss
      await tester.tap(find.text('Fat Loss'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('questionnaire_next_btn')));
      await tester.pumpAndSettle();

      // Step 1: Rate of Change -> Recommended Standard (-0.75%)
      await tester.tap(find.text('Recommended Standard'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('questionnaire_next_btn')));
      await tester.pumpAndSettle();

      // Step 2: Activity -> Moderately Active
      expect(find.text('PHYSICAL ACTIVITY & TDEE'), findsOneWidget);
      await tester.tap(find.text('Moderately Active'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('questionnaire_next_btn')));
      await tester.pumpAndSettle();

      // Step 3: Indian Nutrition & Dietary Habits
      expect(find.text('INDIAN NUTRITION & DIET'), findsOneWidget);
      // Select Eggetarian
      await tester.tap(find.text('Eggetarian'));
      await tester.pumpAndSettle();
      // Select Roti dominant
      await tester.tap(find.text('Roti dominant'));
      await tester.pumpAndSettle();
      // Select Light spray
      await tester.tap(find.text('Light spray (~0.5 tbsp)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('questionnaire_next_btn')));
      await tester.pumpAndSettle();

      // Step 4: Protein Strategy -> High Protein (2.0 g/kg)
      expect(find.text('PROTEIN STRATEGY'), findsOneWidget);
      await tester.tap(find.text('High Protein (Recommended)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('questionnaire_next_btn')));
      await tester.pumpAndSettle();

      // Step 5: Target Preview & Activation
      expect(find.text('TARGET PREVIEW & CONFIRMATION'), findsOneWidget);
      expect(find.text('ADHERENCE-NEUTRAL GUARANTEE'), findsOneWidget);
      expect(find.text('Activate Custom Program'), findsOneWidget);

      // Confirm and activate program
      await tester.tap(find.text('Activate Custom Program'));
      await tester.pumpAndSettle();

      // Modal sheet should be closed
      expect(find.text('TARGET PREVIEW & CONFIRMATION'), findsNothing);

      // Verify app settings saved in SQLite
      final dietSetting = db.getSetting('dietary_preference', '');
      final stapleSetting = db.getSetting('staple_preference', '');
      final oilSetting = db.getSetting('default_oil_modifier', '');

      expect(dietSetting, 'eggetarian');
      expect(stapleSetting, 'roti');
      expect(oilSetting, 'light');

      // Verify user profile saved in SQLite
      final profile = db.getUserProfile();
      expect(profile, isNotNull);
      expect(profile!.goalType, GoalType.fatLoss);
      expect(profile.weeklyRateOfChangePct, -0.75);
    });

    testWidgets(
        'Stress Test: Rapid double tap on Activate Custom Program is guarded',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(450, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dashboard').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dashboard_goal_banner')));
      await tester.pumpAndSettle();

      // Advance to step 5
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('questionnaire_next_btn')));
        await tester.pumpAndSettle();
      }

      expect(find.text('Activate Custom Program'), findsOneWidget);

      // Rapid double tap without pumpAndSettle
      await tester.tap(find.text('Activate Custom Program'));
      await tester.tap(
        find.text('Activate Custom Program'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // Dashboard should still be rendered and not popped out
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('ENERGY EXPENDITURE'), findsOneWidget);
    });

    testWidgets(
        'Intermediate Auto-Save: Navigating from Step 0 to Step 1 persists choice even if sheet is dismissed early',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(450, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dashboard').first);
      await tester.pumpAndSettle();

      // Open questionnaire
      await tester.tap(find.byKey(const Key('dashboard_goal_banner')));
      await tester.pumpAndSettle();

      // Select Muscle Gain
      await tester.tap(find.text('Muscle Gain (Hypertrophy)'));
      await tester.pumpAndSettle();

      // Tap Next to advance to Step 1 (triggers _autoSaveCurrentState())
      await tester.tap(find.byKey(const Key('questionnaire_next_btn')));
      await tester.pumpAndSettle();

      expect(find.text('RATE OF CHANGE'), findsOneWidget);

      // Now close/dismiss the sheet before finishing remaining steps
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Verify the sheet is closed and dashboard is visible
      expect(find.text('Dashboard'), findsWidgets);

      // Verify database has updated profile with GoalType.muscleGain
      final profile = db.getUserProfile();
      expect(profile, isNotNull);
      expect(profile!.goalType, equals(GoalType.muscleGain));
    });
  });
}
