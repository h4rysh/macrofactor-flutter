import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/repositories/auth_repository.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/account_profile_screen.dart';
import 'package:sique/presentation/screens/onboarding/auth_gate_screen.dart';
import 'package:sique/presentation/screens/onboarding/onboarding_flow_screen.dart';
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
        'Google Sign-In creates authenticated session and saves to SQLite',
        (tester) async {
      await tester.pumpWidget(createTestWidget(child: const AuthGateScreen()));
      await tester.pumpAndSettle();

      // Tap Continue with Google
      await tester.tap(find.byKey(const Key('auth_gate_google_btn')));
      await tester.pumpAndSettle();

      // Verify user session in SQLite
      final session = db.getAccountSession();
      expect(session, isNotNull);
      expect(session!.email, equals('athlete@gmail.com'));
      expect(session.displayName, equals('Google Athlete'));
      expect(session.authProvider, equals(AuthProviderType.google));
    });

    testWidgets(
        'Delete Account clears Google account session without password prompt',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeAuthRepository();
      final googleUser = await repo.signInWithGoogle();

      await tester.pumpWidget(createTestWidget(
        child: const AccountProfileScreen(),
        authRepo: repo,
        initialUser: googleUser,
      ));
      await tester.pumpAndSettle();

      // Tap Delete Account
      await tester.tap(find.byKey(const Key('profile_delete_account_btn')));
      await tester.pumpAndSettle();

      // Confirm deletion directly (streamlined Google + Guest auth has no password input)
      expect(
          find.byKey(const Key('delete_account_confirm_btn')), findsOneWidget);
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

      // Guest navigation still functional -> enters OnboardingFlowScreen
      expect(find.byKey(const Key('auth_gate_guest_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('auth_gate_guest_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingFlowScreen), findsOneWidget);
    });
  });
}
