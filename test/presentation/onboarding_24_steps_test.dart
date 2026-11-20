import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/onboarding/onboarding_flow_screen.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_03_dob.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_04_height.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_05_weight.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_13_tdee_reveal.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_15_target_weight.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_21_distribution_mode.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_23_medical_disclaimer.dart';
import 'package:sqlite3/sqlite3.dart';
import '../mocks/fake_auth_repository.dart';

void main() {
  group('24-Step Honest Onboarding Flow & Guardrail Tests', () {
    late Database rawDb;
    late AppDatabase db;
    late FakeAuthRepository fakeAuth;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      db = AppDatabase(rawDb);
      db.initUserTables();
      fakeAuth = FakeAuthRepository();
    });

    tearDown(() {
      db.close();
    });

    Widget createTestWidget(Widget child) {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authRepositoryProvider.overrideWithValue(fakeAuth),
        ],
        child: MaterialApp(home: child),
      );
    }

    testWidgets(
        '1. Step 3 Age Lock: blocks progression when age < 18 with guardrail banner',
        (tester) async {
      tester.view.physicalSize = const Size(450, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int? submittedAge;

      await tester.pumpWidget(createTestWidget(
        Step03Dob(
          initialAge: 17,
          onNext: (age) => submittedAge = age,
        ),
      ));
      await tester.pumpAndSettle();

      // Guardrail banner must be visible
      expect(find.byKey(const Key('step_03_age_guardrail_banner')),
          findsOneWidget);
      expect(find.textContaining('adults 18 and older'), findsOneWidget);

      // Continue button must be disabled (tapping does nothing)
      await tester.tap(find.byKey(const Key('step_03_continue_btn')));
      await tester.pumpAndSettle();
      expect(submittedAge, isNull);

      // Increment age to 18
      await tester.tap(find.byKey(const Key('step_03_increment_btn')));
      await tester.pumpAndSettle();

      // Banner dismissed and continue enabled
      expect(
          find.byKey(const Key('step_03_age_guardrail_banner')), findsNothing);
      await tester.tap(find.byKey(const Key('step_03_continue_btn')));
      await tester.pumpAndSettle();

      expect(submittedAge, equals(18));
    });

    testWidgets(
        '2. Step 15 BMI Guardrail: blocks progression when target BMI < 18.5 for fat loss',
        (tester) async {
      tester.view.physicalSize = const Size(450, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      double? submittedTarget;

      // 45 kg at 175 cm => BMI = 45 / (1.75^2) = 14.7 (< 18.5)
      await tester.pumpWidget(createTestWidget(
        Step15TargetWeight(
          goalType: GoalType.fatLoss,
          currentWeightKg: 75.0,
          heightCm: 175.0,
          initialTargetWeightKg: 45.0,
          onNext: (w) => submittedTarget = w,
        ),
      ));
      await tester.pumpAndSettle();

      // Guardrail banner must be displayed
      expect(find.byKey(const Key('step_15_bmi_guardrail_banner')),
          findsOneWidget);
      expect(find.textContaining('clinical underweight range (< 18.5)'),
          findsOneWidget);

      // Continue button is disabled
      await tester.tap(find.byKey(const Key('step_15_continue_btn')));
      await tester.pumpAndSettle();
      expect(submittedTarget, isNull);

      // Change target weight to safe 65 kg (BMI ~ 21.2)
      await tester.enterText(
          find.byKey(const Key('step_15_target_weight_input')), '65.0');
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('step_15_bmi_guardrail_banner')), findsNothing);
      await tester.tap(find.byKey(const Key('step_15_continue_btn')));
      await tester.pumpAndSettle();

      expect(submittedTarget, equals(65.0));
    });

    testWidgets('3. Step 4 Height & Step 5 Weight Unit Toggles work seamlessly',
        (tester) async {
      tester.view.physicalSize = const Size(450, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      double? submittedHeight;
      await tester.pumpWidget(createTestWidget(
        Step04Height(
          initialHeightCm: 180.0,
          onNext: (h) => submittedHeight = h,
        ),
      ));
      await tester.pumpAndSettle();

      // Default cm chip
      expect(find.byKey(const Key('step_04_unit_toggle_cm')), findsOneWidget);

      // Switch to Imperial (ft/in)
      await tester.tap(find.byKey(const Key('step_04_unit_toggle_ft')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('step_04_feet_input')), findsOneWidget);
      expect(find.byKey(const Key('step_04_inches_input')), findsOneWidget);

      await tester.tap(find.byKey(const Key('step_04_continue_btn')));
      await tester.pumpAndSettle();
      expect(submittedHeight, isNotNull);

      // Weight Unit Toggle (kg vs lb, slider + numeric)
      double? submittedWeight;
      await tester.pumpWidget(createTestWidget(
        Step05Weight(
          initialWeightKg: 80.0,
          onNext: (w) => submittedWeight = w,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('step_05_weight_slider')), findsOneWidget);
      expect(find.byKey(const Key('step_05_weight_input')), findsOneWidget);

      // Switch to lbs
      await tester.tap(find.byKey(const Key('step_05_unit_toggle_lb')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('step_05_continue_btn')));
      await tester.pumpAndSettle();
      expect(submittedWeight, closeTo(80.0, 0.5));
    });

    testWidgets('4. Resume after restart: restores persisted onboarding_step',
        (tester) async {
      tester.view.physicalSize = const Size(450, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Simulate earlier progress saved at step 3 (0-indexed => step 4)
      db.setSetting('onboarding_step', '3');

      await tester.pumpWidget(createTestWidget(const OnboardingFlowScreen()));
      await tester.pumpAndSettle();

      // Renders Step 4 of 7 directly
      expect(find.text('Step 4 of 7'), findsOneWidget);
      expect(find.textContaining('Activity & Training'), findsOneWidget);
    });

    testWidgets(
        '5. TDEE override typed in Step 13 reaches profile baselineExpenditureKcal',
        (tester) async {
      tester.view.physicalSize = const Size(450, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      double? submittedTdee;

      await tester.pumpWidget(createTestWidget(
        Step13TdeeReveal(
          weightKg: 75.0,
          heightCm: 175.0,
          age: 28,
          isMale: true,
          activityLevel: 'moderate',
          exerciseFrequency: '1-3',
          onNext: (tdee) => submittedTdee = tdee,
        ),
      ));
      await tester.pumpAndSettle();

      // Calculation card is expandable
      await tester.tap(find.byKey(const Key('step_13_calculation_expandable')));
      await tester.pumpAndSettle();
      expect(
          find.textContaining('Resting BMR (Mifflin-St Jeor)'), findsOneWidget);

      // Enable manual override switch
      await tester.tap(find.byKey(const Key('step_13_override_toggle')));
      await tester.pumpAndSettle();

      // Enter known override calories
      await tester.enterText(
          find.byKey(const Key('step_13_override_input')), '2750');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('step_13_continue_btn')));
      await tester.pumpAndSettle();

      expect(submittedTdee, equals(2750.0));
    });

    testWidgets(
        '6. Step 23 Medical Disclaimer: blocks continue button until checked',
        (tester) async {
      tester.view.physicalSize = const Size(450, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool continued = false;

      await tester.pumpWidget(createTestWidget(
        Step23MedicalDisclaimer(
          onNext: () => continued = true,
        ),
      ));
      await tester.pumpAndSettle();

      // Continue is disabled
      await tester.tap(find.byKey(const Key('step_23_continue_btn')));
      await tester.pumpAndSettle();
      expect(continued, isFalse);

      // Tap acknowledgment checkbox
      await tester.tap(find.byKey(const Key('step_23_disclaimer_checkbox')));
      await tester.pumpAndSettle();

      // Continue is now enabled
      await tester.tap(find.byKey(const Key('step_23_continue_btn')));
      await tester.pumpAndSettle();
      expect(continued, isTrue);
    });

    testWidgets(
        '7. Step 21 Distribution Mode toggles Even vs Shifted Workout Days',
        (tester) async {
      tester.view.physicalSize = const Size(450, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? submittedMode;
      Set<int>? submittedDays;

      await tester.pumpWidget(createTestWidget(
        Step21DistributionMode(
          initialMode: 'even',
          initialWorkoutDays: const {1, 3, 5},
          onNext: (mode, days) {
            submittedMode = mode;
            submittedDays = days;
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Even Allocation'), findsOneWidget);

      // Tap Shifted Workout Days
      await tester.tap(find.byKey(const Key('step_21_shifted_tile')));
      await tester.pumpAndSettle();

      expect(find.text('Select Your Training Days:'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);

      await tester.tap(find.byKey(const Key('step_21_continue_btn')));
      await tester.pumpAndSettle();

      expect(submittedMode, equals('shifted'));
      expect(submittedDays, containsAll([1, 3, 5]));
    });
  });
}
