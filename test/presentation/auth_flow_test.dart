import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/repositories/auth_repository.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/account_profile_screen.dart';
import 'package:sique/presentation/screens/onboarding/auth_gate_screen.dart';
import 'package:sqlite3/sqlite3.dart';
import '../mocks/fake_auth_repository.dart';

void main() {
  group('Provider-Aware Authentication & Flow Verification Tests', () {
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

    Widget createTestWidget({
      required Widget child,
      AuthRepository? authRepo,
      UserAccount? initialUser,
    }) {
      if (initialUser != null) {
        db.saveAccountSession(initialUser);
      }
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authRepositoryProvider.overrideWithValue(authRepo ?? fakeAuth),
        ],
        child: MaterialApp(home: child),
      );
    }

    testWidgets(
        'Email/Password Sign-Up creates account and saves session to SQLite',
        (tester) async {
      await tester.pumpWidget(createTestWidget(child: const AuthGateScreen()));
      await tester.pumpAndSettle();

      // Tap Continue with Email
      await tester.tap(find.byKey(const Key('auth_gate_email_btn')));
      await tester.pumpAndSettle();

      // Switch to Sign Up
      await tester.tap(find.byKey(const Key('auth_switch_to_signup_btn')));
      await tester.pumpAndSettle();

      // Fill form
      await tester.enterText(
          find.byKey(const Key('auth_name_input')), 'Kavita Athlete');
      await tester.enterText(
          find.byKey(const Key('auth_email_input')), 'kavita@sique.test');
      await tester.enterText(
          find.byKey(const Key('auth_password_input')), 'securepass123');
      if (find
          .byKey(const Key('auth_confirm_password_input'))
          .evaluate()
          .isNotEmpty) {
        await tester.enterText(
            find.byKey(const Key('auth_confirm_password_input')),
            'securepass123');
      }
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.byKey(const Key('auth_submit_btn')));
      await tester.pumpAndSettle();

      // Verify user session in SQLite
      final session = db.getAccountSession();
      expect(session, isNotNull);
      expect(session!.email, equals('kavita@sique.test'));
      expect(session.displayName, equals('Kavita Athlete'));
      expect(session.authProvider, equals(AuthProviderType.email));
    });

    testWidgets('Change Password button is visible for Email accounts',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final emailUser = UserAccount(
        id: 'usr_email_1',
        googleUserId: 'email_1',
        displayName: 'Email User',
        email: 'user@sique.test',
        authProvider: AuthProviderType.email,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAuthenticated: true,
      );

      final emailRepo = FakeAuthRepository(initialUser: emailUser);
      await tester.pumpWidget(createTestWidget(
        child: const AccountProfileScreen(),
        authRepo: emailRepo,
        initialUser: emailUser,
      ));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('profile_change_password_btn')), findsOneWidget);
    });

    testWidgets('Change Password button is hidden for Google accounts',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final googleUser = UserAccount(
        id: 'usr_google_1',
        googleUserId: 'google_1',
        displayName: 'Google User',
        email: 'google@sique.test',
        authProvider: AuthProviderType.google,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAuthenticated: true,
      );

      final googleRepo = FakeAuthRepository(initialUser: googleUser);
      await tester.pumpWidget(createTestWidget(
        child: const AccountProfileScreen(),
        authRepo: googleRepo,
        initialUser: googleUser,
      ));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('profile_change_password_btn')), findsNothing);
    });

    testWidgets(
        'Provider-aware Delete Account prompts for password on Email account',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeAuthRepository();
      final signedUpUser = await repo.signUpWithEmailAndPassword(
        email: 'del@sique.test',
        password: 'password123',
        displayName: 'Delete Test User',
      );

      await tester.pumpWidget(createTestWidget(
        child: const AccountProfileScreen(),
        authRepo: repo,
        initialUser: signedUpUser,
      ));
      await tester.pumpAndSettle();

      // Tap Delete Account
      await tester.tap(find.byKey(const Key('profile_delete_account_btn')));
      await tester.pumpAndSettle();

      // Password input field must be present for Email account deletion
      expect(find.byKey(const Key('delete_account_password_input')),
          findsOneWidget);

      // Enter password and confirm deletion
      await tester.enterText(
          find.byKey(const Key('delete_account_password_input')),
          'password123');
      await tester.tap(find.byKey(const Key('delete_account_confirm_btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // User session should be wiped from SQLite
      expect(db.getAccountSession(), isNull);
    });

    testWidgets(
        'Firebase unconfigured state displays clear notice without crashing or blocking guest navigation',
        (tester) async {
      final unconfiguredRepo = FakeAuthRepository(isConfigured: false);

      await tester.pumpWidget(createTestWidget(
        child: const AuthGateScreen(),
        authRepo: unconfiguredRepo,
      ));
      await tester.pumpAndSettle();

      // Banner should be visible
      expect(find.byKey(const Key('auth_gate_unconfigured_banner')),
          findsOneWidget);
      expect(find.text('Sign-in unavailable: Firebase not configured'),
          findsOneWidget);

      // Guest navigation still functional
      expect(find.byKey(const Key('auth_gate_guest_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('auth_gate_guest_btn')));
      await tester.pumpAndSettle();

      expect(db.getSetting('onboarding_completed', 'false'), equals('true'));
    });
  });
}
