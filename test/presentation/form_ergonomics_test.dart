import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/auth/delete_account_dialog.dart';
import 'package:sique/presentation/screens/food_search_screen.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_03_dob.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_04_height.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_05_weight.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_06_weight_history.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_13_tdee_reveal.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_15_target_weight.dart';
import 'package:sique/presentation/screens/weight_log_modal.dart';

import '../mocks/fake_auth_repository.dart';

void main() {
  group('Form Ergonomics & Autofill/Keyboard Configuration Tests', () {
    late AppDatabase db;
    late FakeAuthRepository fakeAuth;

    setUp(() {
      db = AppDatabase.inMemory();
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
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    TextField getField(WidgetTester tester, Finder finder) {
      final widget = tester.widget(finder);
      if (widget is TextField) return widget;
      return tester.widget<TextField>(
        find.descendant(of: finder, matching: find.byType(TextField)),
      );
    }

    testWidgets(
        'DeleteAccountDialog: displays confirmation and action buttons cleanly',
        (tester) async {
      final testUser = UserAccount(
        id: 'u1',
        googleUserId: 'g1',
        displayName: 'Test User',
        authProvider: AuthProviderType.google,
        email: 'user@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(
        DeleteAccountDialog(user: testUser),
      ));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('delete_account_confirm_btn')), findsOneWidget);
      expect(
          find.byKey(const Key('delete_account_cancel_btn')), findsOneWidget);
    });

    testWidgets(
        'FoodSearchScreen: search input has TextInputAction.search and text keyboard',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const FoodSearchScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final searchFieldFinder = find.byType(TextField);
      expect(searchFieldFinder, findsOneWidget);
      final searchField = tester.widget<TextField>(searchFieldFinder);
      expect(searchField.keyboardType, equals(TextInputType.text));
      expect(searchField.textInputAction, equals(TextInputAction.search));
    });

    testWidgets(
        'WeightLogModal: weight field has decimal keyboard and next action; note has done action',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const WeightLogModal()));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      final weightField = tester.widget<TextField>(textFields.first);
      expect(weightField.keyboardType,
          equals(const TextInputType.numberWithOptions(decimal: true)));
      expect(weightField.textInputAction, equals(TextInputAction.next));

      final noteField = tester.widget<TextField>(textFields.last);
      expect(noteField.keyboardType, equals(TextInputType.text));
      expect(noteField.textInputAction, equals(TextInputAction.done));
    });

    testWidgets(
        'Onboarding Step Numeric Inputs: enforce decimal/integer keyboards, actions, and formatters',
        (tester) async {
      // Step 3: DOB age input
      await tester.pumpWidget(createTestWidget(Step03Dob(
        initialAge: 25,
        onNext: (_) {},
      )));
      await tester.pumpAndSettle();

      final ageFinder = find.byKey(const Key('step_03_age_input'));
      expect(ageFinder, findsOneWidget);
      final ageField = getField(tester, ageFinder);
      expect(ageField.keyboardType, equals(TextInputType.number));
      expect(ageField.textInputAction, equals(TextInputAction.done));

      // Step 4: Metric height input
      await tester.pumpWidget(createTestWidget(Step04Height(
        initialHeightCm: 175.0,
        onNext: (_) {},
      )));
      await tester.pumpAndSettle();

      final heightFinder = find.byKey(const Key('step_04_height_input'));
      expect(heightFinder, findsOneWidget);
      final heightField = getField(tester, heightFinder);
      expect(heightField.keyboardType,
          equals(const TextInputType.numberWithOptions(decimal: true)));
      expect(heightField.textInputAction, equals(TextInputAction.done));

      // Step 5: Weight input
      await tester.pumpWidget(createTestWidget(Step05Weight(
        initialWeightKg: 75.0,
        onNext: (_) {},
      )));
      await tester.pumpAndSettle();

      final weightFinder = find.byKey(const Key('step_05_weight_input'));
      expect(weightFinder, findsOneWidget);
      final stepWeightField = getField(tester, weightFinder);
      expect(stepWeightField.keyboardType,
          equals(const TextInputType.numberWithOptions(decimal: true)));
      expect(stepWeightField.textInputAction, equals(TextInputAction.done));

      // Step 6: Max weight input
      await tester.pumpWidget(createTestWidget(Step06WeightHistory(
        currentWeightKg: 75.0,
        initialMaxWeightKg: 85.0,
        onNext: (_) {},
      )));
      await tester.pumpAndSettle();

      final maxWeightFinder = find.byKey(const Key('step_06_max_weight_input'));
      expect(maxWeightFinder, findsOneWidget);
      final maxWeightField = getField(tester, maxWeightFinder);
      expect(maxWeightField.keyboardType,
          equals(const TextInputType.numberWithOptions(decimal: true)));
      expect(maxWeightField.textInputAction, equals(TextInputAction.done));

      // Step 13: TDEE Override input
      await tester.pumpWidget(createTestWidget(Step13TdeeReveal(
        weightKg: 80.0,
        heightCm: 180.0,
        age: 28,
        isMale: true,
        activityLevel: 'moderate',
        exerciseFrequency: '3-5 days/week',
        onNext: (_) {},
      )));
      await tester.pumpAndSettle();

      // Tap override toggle to reveal override input
      final toggleFinder = find.byKey(const Key('step_13_override_toggle'));
      expect(toggleFinder, findsOneWidget);
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      final tdeeFinder = find.byKey(const Key('step_13_override_input'));
      expect(tdeeFinder, findsOneWidget);
      final tdeeField = getField(tester, tdeeFinder);
      expect(tdeeField.keyboardType, equals(TextInputType.number));
      expect(tdeeField.textInputAction, equals(TextInputAction.done));

      // Step 15: Target weight input
      await tester.pumpWidget(createTestWidget(Step15TargetWeight(
        goalType: GoalType.fatLoss,
        currentWeightKg: 75.0,
        heightCm: 175.0,
        initialTargetWeightKg: 70.0,
        onNext: (_) {},
      )));
      await tester.pumpAndSettle();

      final targetWeightFinder =
          find.byKey(const Key('step_15_target_weight_input'));
      expect(targetWeightFinder, findsOneWidget);
      final targetWeightField = getField(tester, targetWeightFinder);
      expect(targetWeightField.keyboardType,
          equals(const TextInputType.numberWithOptions(decimal: true)));
      expect(targetWeightField.textInputAction, equals(TextInputAction.done));
    });
  });
}
