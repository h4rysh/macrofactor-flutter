import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/onboarding/onboarding_flow_screen.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_04_age.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_10_pacing.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_15_distribution_mode.dart';
import 'package:sqlite3/sqlite3.dart';
import '../mocks/fake_auth_repository.dart';

void main() {
  group('23-Step Modular Onboarding Flow & Guardrail Tests', () {
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

    testWidgets('Step 4 Age Guardrail blocks progression when age < 18',
        (tester) async {
      int? submittedAge;

      await tester.pumpWidget(createTestWidget(
        Step04Age(
          initialAge: 17,
          onNext: (age) => submittedAge = age,
        ),
      ));
      await tester.pumpAndSettle();

      // Guardrail banner must be visible
      expect(find.byKey(const Key('step_04_age_guardrail_banner')),
          findsOneWidget);
      expect(find.textContaining('adults 18 and older'), findsOneWidget);

      // Continue button must be disabled
      await tester.tap(find.byKey(const Key('step_04_continue_btn')));
      await tester.pumpAndSettle();
      expect(submittedAge, isNull);

      // Increment age to 18
      await tester.tap(find.byKey(const Key('step_04_increment_btn')));
      await tester.pumpAndSettle();

      // Guardrail banner dismissed, continue enabled
      expect(
          find.byKey(const Key('step_04_age_guardrail_banner')), findsNothing);
      await tester.tap(find.byKey(const Key('step_04_continue_btn')));
      await tester.pumpAndSettle();

      expect(submittedAge, equals(18));
    });

    testWidgets('Step 10 Pacing Guardrail triggers warning when BMI < 18.5',
        (tester) async {
      double? submittedRate;

      // 45 kg at 175 cm => BMI = 45 / (1.75^2) = 14.7 (< 18.5)
      await tester.pumpWidget(createTestWidget(
        Step10Pacing(
          goalType: GoalType.fatLoss,
          currentWeightKg: 45.0,
          heightCm: 175.0,
          initialRatePct: -0.50,
          onNext: (rate) => submittedRate = rate,
        ),
      ));
      await tester.pumpAndSettle();

      // Guardrail banner must be displayed
      expect(find.byKey(const Key('step_10_bmi_guardrail_banner')),
          findsOneWidget);
      expect(find.textContaining('underweight range (< 18.5)'), findsOneWidget);

      // Aggressive deficit (-0.5%) is restricted for underweight
      await tester.tap(find.byKey(const Key('step_10_continue_btn')));
      await tester.pumpAndSettle();
      expect(submittedRate, isNull);
    });

    testWidgets(
        'Step 15 Distribution Mode toggles Even vs Shifted Workout Days',
        (tester) async {
      String? submittedMode;
      Set<int>? submittedDays;

      await tester.pumpWidget(createTestWidget(
        Step15DistributionMode(
          initialMode: 'even',
          initialWorkoutDays: const {1, 3, 5},
          onNext: (mode, days) {
            submittedMode = mode;
            submittedDays = days;
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Even mode is initially selected
      expect(find.text('Even Allocation'), findsOneWidget);

      // Tap Shifted Workout Days
      await tester.tap(find.byKey(const Key('step_15_shifted_tile')));
      await tester.pumpAndSettle();

      // Day chips should appear (Mon, Wed, Fri selected by default)
      expect(find.text('Select Your Training Days:'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);

      // Continue
      await tester.tap(find.byKey(const Key('step_15_continue_btn')));
      await tester.pumpAndSettle();

      expect(submittedMode, equals('shifted'));
      expect(submittedDays, containsAll([1, 3, 5]));
    });

    testWidgets('OnboardingFlowScreen initializes and renders Step 1 Welcome',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const OnboardingFlowScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 23'), findsOneWidget);
      expect(find.text('Welcome to Sique'), findsOneWidget);
      expect(find.byKey(const Key('step_01_continue_btn')), findsOneWidget);

      // Tap Get Started -> advances to Step 2
      await tester.tap(find.byKey(const Key('step_01_continue_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 23'), findsOneWidget);
      expect(find.text('What should we call you?'), findsOneWidget);
    });
  });
}
