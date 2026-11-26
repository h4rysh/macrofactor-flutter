import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/data/repositories/firebase_auth_repository.dart';
import 'package:sique/domain/legal/legal_copy.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/about_screen.dart';
import 'package:sique/presentation/screens/onboarding/auth_gate_screen.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_01_health_connect.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_23_medical_disclaimer.dart';
import 'package:sique/presentation/screens/quick_actions_sheet.dart';
import 'package:sique/presentation/widgets/auth_legal_footer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() {
    db.close();
  });

  group('Legal Copy Single Source of Truth & Privacy Policy (AUD-01, AUD-03)',
      () {
    test('LegalCopy contains required FBE & SQLite sandboxing privacy copy',
        () {
      expect(LegalCopy.privacyPolicyTitle, equals('Privacy Policy'));
      expect(
        LegalCopy.privacyPolicyText,
        contains(
            'private SQLite database protected by Android application sandboxing'),
      );
      expect(
        LegalCopy.privacyPolicyText,
        contains('hardware-backed File-Based Encryption (FBE)'),
      );
      expect(LegalCopy.medicalDisclaimerTitle, equals('Medical Disclaimer'));
      expect(LegalCopy.termsTitle, equals('Terms of Service'));
    });

    testWidgets('AuthLegalFooter shows Privacy Policy dialog with FBE copy',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: AuthLegalFooter()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('auth_privacy_policy_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(LegalCopy.privacyPolicyTitle),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('hardware-backed File-Based Encryption (FBE)'),
        findsOneWidget,
      );

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Step 23 Medical Disclaimer binds to LegalCopy',
        (tester) async {
      tester.view.physicalSize = const Size(450, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool passed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Step23MedicalDisclaimer(onNext: () => passed = true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(LegalCopy.onboardingNoticeTitle), findsOneWidget);
      expect(find.text(LegalCopy.medicalDisclaimerTitle), findsOneWidget);
      expect(
          find.text(LegalCopy.onboardingDisclaimerAgreement), findsOneWidget);

      // Verify continue button blocked until checked
      await tester.tap(find.byKey(const Key('step_23_continue_btn')));
      await tester.pumpAndSettle();
      expect(passed, isFalse);

      await tester.tap(find.byKey(const Key('step_23_disclaimer_checkbox')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('step_23_continue_btn')));
      await tester.pumpAndSettle();
      expect(passed, isTrue);
    });
  });

  group('About Screen Metabolic Copy & Clean-Room Purge (AUD-02, AUD-08)', () {
    testWidgets(
        'AboutScreen renders Bayesian Adaptive Science instead of black-box reverse engineering',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Adaptive Nutrition Science'), findsOneWidget);
      expect(find.text('Clean-Room Architecture'), findsNothing);
      expect(find.textContaining('behavioral black-box reverse engineering'),
          findsNothing);
      expect(
        find.textContaining('real weight trends and food logs'),
        findsOneWidget,
      );
    });
  });

  group('Quick Actions Sheet Dead Tile Purge (AUD-04)', () {
    testWidgets('QuickActionsSheet omits dead Scan Barcode action tile',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuickActionsSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Search Food / Add to Plate'), findsOneWidget);
      expect(find.text('Scan Barcode'), findsNothing);
      expect(find.text('Log Scale Weight'), findsOneWidget);
    });
  });

  group('Sync Copy & Account Renaming (AUD-07, AUD-09)', () {
    testWidgets('Step01HealthConnect promises sync only on open',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(
              body: Step01HealthConnect(onNext: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Syncs automatically when you open Sique.'),
        findsOneWidget,
      );
      expect(find.textContaining('in the background'), findsNothing);
    });

    testWidgets(
        'AuthGateScreen renamed to Account & Device Data with honest sync copy',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const MaterialApp(
            home: AuthGateScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account & Device Data'), findsOneWidget);
      expect(find.text('Account & Cloud Sync'), findsNothing);
      expect(
        find.textContaining('Syncs automatically when you open Sique.'),
        findsOneWidget,
      );
    });
  });

  group('Streamlined Auth Enforcement (AUD-22)', () {
    test(
        'FirebaseAuthRepository reports unconfigured when Firebase not initialized',
        () {
      final repo = FirebaseAuthRepository(db: db, isConfigured: false);
      expect(repo.isConfigured, isFalse);
    });
  });
}
