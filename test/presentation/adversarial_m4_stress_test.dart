import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/auth/change_password_dialog.dart';
import 'package:sique/presentation/screens/auth/delete_account_dialog.dart';
import 'package:sique/presentation/screens/auth/email_auth_dialog.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_03_dob.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_04_height.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_05_weight.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_13_tdee_reveal.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_15_target_weight.dart';
import 'package:sique/presentation/screens/weight_log_modal.dart';
import 'package:sique/presentation/widgets/sique_empty_state.dart';
import 'package:sique/presentation/widgets/sique_error_state.dart';

import '../mocks/fake_auth_repository.dart';

void main() {
  group('Adversarial M4 Stress Suite: Form Ergonomics, State Widgets & Hygiene',
      () {
    late AppDatabase db;
    late FakeAuthRepository fakeAuth;

    setUp(() {
      db = AppDatabase.inMemory();
      fakeAuth = FakeAuthRepository();
    });

    tearDown(() {
      db.close();
    });

    Widget wrap(Widget child, {List<Override> overrides = const []}) {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authRepositoryProvider.overrideWithValue(fakeAuth),
          ...overrides,
        ],
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets(
        'Adversarial: WeightLogModal rejects non-numeric input strings and handles invalid chars',
        (tester) async {
      await tester.pumpWidget(wrap(const WeightLogModal()));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));
      final weightField = textFields.first;

      // 1. Enter pure malicious characters, emojis, and symbols
      await tester.enterText(weightField, 'abc!@#\$-xyz🥑');
      await tester.pumpAndSettle();

      // Controller should completely reject non-numeric characters and remain empty
      final TextField widget1 = tester.widget(weightField);
      final text1 = widget1.controller?.text ?? '';
      expect(text1, isEmpty);

      // Save button must be disabled when weight is empty
      final saveBtn1 =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(saveBtn1.onPressed, isNull);

      // 2. Enter valid decimal followed by malicious trailing symbols, emojis, negative signs
      await tester.enterText(weightField, '72.5abc!@#\$-xyz🥑');
      await tester.pumpAndSettle();

      final TextField widget2 = tester.widget(weightField);
      final text2 = widget2.controller?.text ?? '';
      expect(text2, equals('72.5'));
      expect(text2.contains('abc'), isFalse);
      expect(text2.contains('!@#\$'), isFalse);
      expect(text2.contains('xyz'), isFalse);
      expect(text2.contains('🥑'), isFalse);
      expect(text2.contains('-'), isFalse);
      expect(double.tryParse(text2), equals(72.5));

      // Save button must be enabled when weight is a valid positive number
      final saveBtn2 =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(saveBtn2.onPressed, isNotNull);

      // 3. Prevent multiple decimal points (e.g. 72.5.8)
      await tester.enterText(weightField, '72.5.8.9');
      await tester.pumpAndSettle();
      final TextField widget3 = tester.widget(weightField);
      final text3 = widget3.controller?.text ?? '';
      expect(text3, equals('72.5'));
    });

    testWidgets(
        'Adversarial: Step04Height cm rejects non-digits and negative numbers',
        (tester) async {
      await tester.pumpWidget(wrap(Step04Height(
        initialHeightCm: 175.0,
        onNext: (_) {},
      )));
      await tester.pumpAndSettle();

      final heightFinder = find.byKey(const Key('step_04_height_input'));
      expect(heightFinder, findsOneWidget);

      // 1. Malicious characters
      await tester.enterText(heightFinder, 'bad-cm!🥑');
      await tester.pumpAndSettle();

      final TextField widget1 = tester.widget(
          find.descendant(of: heightFinder, matching: find.byType(TextField)));
      final text1 = widget1.controller?.text ?? '';
      expect(text1, isEmpty);

      // 2. Valid digits with trailing garbage
      await tester.enterText(heightFinder, '182.5bad-cm!🥑');
      await tester.pumpAndSettle();

      final TextField widget2 = tester.widget(
          find.descendant(of: heightFinder, matching: find.byType(TextField)));
      final text2 = widget2.controller?.text ?? '';
      expect(text2, equals('182.5'));
      expect(text2.contains('bad'), isFalse);
      expect(text2.contains('cm'), isFalse);
      expect(text2.contains('!'), isFalse);
      expect(text2.contains('-'), isFalse);
      expect(double.tryParse(text2), equals(182.5));
    });

    testWidgets(
        'Adversarial: Step05Weight rejects invalid text and formatters filter input',
        (tester) async {
      await tester.pumpWidget(wrap(Step05Weight(
        initialWeightKg: 75.0,
        onNext: (_) {},
      )));
      await tester.pumpAndSettle();

      final weightFinder = find.byKey(const Key('step_05_weight_input'));
      expect(weightFinder, findsOneWidget);

      // 1. Malicious string
      await tester.enterText(weightFinder, 'weight#kg🥑');
      await tester.pumpAndSettle();

      final TextField widget1 = tester.widget(
          find.descendant(of: weightFinder, matching: find.byType(TextField)));
      final text1 = widget1.controller?.text ?? '';
      expect(text1, isEmpty);

      // 2. Valid decimal with trailing garbage
      await tester.enterText(weightFinder, '84.2weight#kg🥑');
      await tester.pumpAndSettle();

      final TextField widget2 = tester.widget(
          find.descendant(of: weightFinder, matching: find.byType(TextField)));
      final text2 = widget2.controller?.text ?? '';
      expect(text2, equals('84.2'));
      expect(text2.contains('weight'), isFalse);
      expect(text2.contains('kg'), isFalse);
      expect(text2.contains('#'), isFalse);
      expect(double.tryParse(text2), equals(84.2));
    });

    testWidgets('Adversarial: Step03Dob digitsOnly enforces pure integer age',
        (tester) async {
      await tester.pumpWidget(wrap(Step03Dob(
        initialAge: 25,
        onNext: (_) {},
      )));
      await tester.pumpAndSettle();

      final ageFinder = find.byKey(const Key('step_03_age_input'));
      expect(ageFinder, findsOneWidget);

      await tester.enterText(ageFinder, 'age:29.5yrs!');
      await tester.pumpAndSettle();

      final TextField widget = tester.widget(
          find.descendant(of: ageFinder, matching: find.byType(TextField)));
      final text = widget.controller?.text ?? '';
      expect(
          text, equals('295')); // digitsOnly retains only pure integer digits
    });

    testWidgets(
        'Adversarial: Step13TdeeReveal override input filters non-digits',
        (tester) async {
      await tester.pumpWidget(wrap(Step13TdeeReveal(
        weightKg: 80.0,
        heightCm: 180.0,
        age: 28,
        isMale: true,
        activityLevel: 'moderate',
        exerciseFrequency: '3-5 days/week',
        onNext: (_) {},
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('step_13_override_toggle')));
      await tester.pumpAndSettle();

      final tdeeFinder = find.byKey(const Key('step_13_override_input'));
      expect(tdeeFinder, findsOneWidget);

      await tester.enterText(tdeeFinder, 'kcal:2450.7!');
      await tester.pumpAndSettle();

      final TextField widget = tester.widget(
          find.descendant(of: tdeeFinder, matching: find.byType(TextField)));
      final text = widget.controller?.text ?? '';
      expect(text, equals('24507')); // digitsOnly
    });

    testWidgets('Adversarial: Step15TargetWeight filters alphanumeric garbage',
        (tester) async {
      await tester.pumpWidget(wrap(Step15TargetWeight(
        goalType: GoalType.fatLoss,
        currentWeightKg: 75.0,
        heightCm: 175.0,
        initialTargetWeightKg: 70.0,
        onNext: (_) {},
      )));
      await tester.pumpAndSettle();

      final targetFinder = find.byKey(const Key('step_15_target_weight_input'));
      expect(targetFinder, findsOneWidget);

      // 1. Pure malicious string
      await tester.enterText(targetFinder, 'target:lbs!🥑');
      await tester.pumpAndSettle();

      final TextField widget1 = tester.widget(
          find.descendant(of: targetFinder, matching: find.byType(TextField)));
      final text1 = widget1.controller?.text ?? '';
      expect(text1, isEmpty);

      // 2. Valid decimal with trailing garbage
      await tester.enterText(targetFinder, '68.5target:lbs!🥑');
      await tester.pumpAndSettle();

      final TextField widget2 = tester.widget(
          find.descendant(of: targetFinder, matching: find.byType(TextField)));
      final text2 = widget2.controller?.text ?? '';
      expect(text2, equals('68.5'));
      expect(text2.contains('target'), isFalse);
      expect(text2.contains('lbs'), isFalse);
      expect(text2.contains('🥑'), isFalse);
      expect(double.tryParse(text2), equals(68.5));
    });

    testWidgets(
        'Adversarial: Auth forms AutofillGroup hierarchy and hint isolation',
        (tester) async {
      // 1. EmailAuthDialog
      await tester.pumpWidget(wrap(const EmailAuthDialog()));
      await tester.pumpAndSettle();

      final emailGroup = find.byType(AutofillGroup);
      expect(emailGroup, findsOneWidget);

      final emailInput = find.byKey(const Key('auth_email_input'));
      final passInput = find.byKey(const Key('auth_password_input'));

      expect(find.descendant(of: emailGroup, matching: emailInput),
          findsOneWidget);
      expect(
          find.descendant(of: emailGroup, matching: passInput), findsOneWidget);

      final emailField = tester.widget<TextField>(
          find.descendant(of: emailInput, matching: find.byType(TextField)));
      final passField = tester.widget<TextField>(
          find.descendant(of: passInput, matching: find.byType(TextField)));

      expect(emailField.autofillHints, equals([AutofillHints.email]));
      expect(passField.autofillHints, equals([AutofillHints.password]));
      expect(passField.keyboardType, equals(TextInputType.visiblePassword));

      // 2. ChangePasswordDialog
      await tester.pumpWidget(wrap(const ChangePasswordDialog()));
      await tester.pumpAndSettle();

      expect(find.byType(AutofillGroup), findsOneWidget);
      final curPass = find.byKey(const Key('change_password_current_input'));
      final newPass = find.byKey(const Key('change_password_new_input'));
      final confPass = find.byKey(const Key('change_password_confirm_input'));

      expect(
          tester
              .widget<TextField>(find.descendant(
                  of: curPass, matching: find.byType(TextField)))
              .autofillHints,
          equals([AutofillHints.password]));
      expect(
          tester
              .widget<TextField>(find.descendant(
                  of: newPass, matching: find.byType(TextField)))
              .autofillHints,
          equals([AutofillHints.newPassword]));
      expect(
          tester
              .widget<TextField>(find.descendant(
                  of: confPass, matching: find.byType(TextField)))
              .autofillHints,
          equals([AutofillHints.newPassword]));

      // 3. DeleteAccountDialog
      final testUser = UserAccount(
        id: 'u1',
        googleUserId: 'g1',
        displayName: 'Test User',
        authProvider: AuthProviderType.email,
        email: 'user@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await tester.pumpWidget(wrap(DeleteAccountDialog(user: testUser)));
      await tester.pumpAndSettle();

      final delGroup = find.byType(AutofillGroup);
      expect(delGroup, findsOneWidget);
      final delPass = find.byKey(const Key('delete_account_password_input'));
      expect(
          tester
              .widget<TextField>(find.descendant(
                  of: delPass, matching: find.byType(TextField)))
              .autofillHints,
          equals([AutofillHints.password]));
    });

    testWidgets(
        'Adversarial: SiqueEmptyState and SiqueErrorState edge-cases and retry callbacks',
        (tester) async {
      var retryCalls = 0;

      // Empty State with long message
      await tester.pumpWidget(wrap(
        const SiqueEmptyState(
          icon: Icons.search_off_rounded,
          title: 'Extreme Title Length For Empty State Testing',
          message:
              'Very long descriptive body explaining why there are no results to stress wrap boundaries in small dialogs.',
          actionLabel: 'Click Me',
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Extreme Title Length For Empty State Testing'),
          findsOneWidget);
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);

      // Error State full-page with callback
      await tester.pumpWidget(wrap(
        SiqueErrorState(
          title: 'Network Timeout 504',
          message: 'Unable to reach backend database services.',
          onRetry: () => retryCalls++,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Network Timeout 504'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      await tester.pump();
      expect(retryCalls, 1);

      // Error State inline banner
      await tester.pumpWidget(wrap(
        SiqueErrorState(
          isInline: true,
          message: 'Inline transient synchronization failed.',
          onRetry: () => retryCalls++,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Inline transient synchronization failed.'),
          findsOneWidget);
      final refreshBtn = find.byIcon(Icons.refresh_rounded);
      expect(refreshBtn, findsOneWidget);
      await tester.tap(refreshBtn);
      await tester.pump();
      expect(retryCalls, 2);
    });

    testWidgets(
        'Adversarial: Empty input validation guards in EmailAuthDialog and ChangePasswordDialog',
        (tester) async {
      // 1. EmailAuthDialog empty submission
      await tester.pumpWidget(wrap(const EmailAuthDialog()));
      await tester.pumpAndSettle();

      final signInBtn = find.byKey(const Key('auth_submit_btn'));
      expect(signInBtn, findsOneWidget);
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);

      // 2. ChangePasswordDialog empty submission
      await tester.pumpWidget(wrap(const ChangePasswordDialog()));
      await tester.pumpAndSettle();

      final changeBtn = find.byKey(const Key('change_password_submit_btn'));
      expect(changeBtn, findsOneWidget);
      await tester.tap(changeBtn);
      await tester.pumpAndSettle();

      expect(find.text('Current password is required'), findsOneWidget);
      expect(find.text('New password is required'), findsOneWidget);
    });

    testWidgets(
        'Adversarial: Zero and extreme numeric value guards in WeightLogModal',
        (tester) async {
      await tester.pumpWidget(wrap(const WeightLogModal()));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      final weightField = textFields.first;

      // Enter 0 - button must remain disabled
      await tester.enterText(weightField, '0');
      await tester.pumpAndSettle();
      var saveBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(saveBtn.onPressed, isNull);

      // Enter 0.0 - button must remain disabled
      await tester.enterText(weightField, '0.0');
      await tester.pumpAndSettle();
      saveBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(saveBtn.onPressed, isNull);

      // Enter extreme large positive weight - no crash, button enabled
      await tester.enterText(weightField, '99999.9');
      await tester.pumpAndSettle();
      saveBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(saveBtn.onPressed, isNotNull);
    });
  });
}
