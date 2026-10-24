import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/data/services/mock_auth_service.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/auth/delete_account_dialog.dart';
import 'package:sique/presentation/screens/auth/email_auth_dialog.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';
import 'package:sique/presentation/widgets/auth_legal_footer.dart';
import 'package:sique/presentation/widgets/google_account_card.dart';

void main() {
  group('Milestone 5: Auth Data Wipe & Account Deletion Tests', () {
    late Database rawDb;
    late AppDatabase appDb;
    late MockAuthService mockAuth;

    setUp(() {
      SharedPreferences.setMockInitialValues({'dummy_user_key': 'saved_pref'});
      appDb = AppDatabase.inMemory();
      rawDb = appDb.rawDb;
      mockAuth = MockAuthService();
    });

    tearDown(() {
      appDb.close();
    });

    test(
        'ProfileDao.clearAllData() wipes user data, resets autoincrement sequence, and preserves catalog tables',
        () {
      // 1. Populate catalog tables
      rawDb.execute('''
        INSERT INTO foods (id, uuid, name, category, region, calories, protein, carbs, fat, fiber, icon_svg, source, aliases)
        VALUES (1, 'catalog_uuid_1', 'Catalog Oats', 'grain', 'Pan-Indian', 150.0, 5.0, 27.0, 3.0, 4.0, 'grain', 'ICMR-NIN', 'oats');
      ''');
      rawDb.execute('''
        INSERT INTO portion_units (id, food_id, unit_name, gram_weight, is_default)
        VALUES (1, 1, 'cup', 80.0, 1);
      ''');

      // 2. Populate user data tables
      rawDb.execute('''
        INSERT INTO food_logs (date, meal_type, food_id, food_name, serving_quantity, unit_name, gram_weight, calories, protein, carbs, fat, fiber, oil_modifier, logged_at, icon_svg)
        VALUES ('2026-10-24', 'breakfast', 1, 'Catalog Oats', 1.0, 'cup', 80.0, 150.0, 5.0, 27.0, 3.0, 4.0, 'none', '2026-10-24T08:00:00Z', 'food');
      ''');
      rawDb.execute('''
        INSERT INTO weight_logs (date, scale_weight, source, logged_at)
        VALUES ('2026-10-24', 75.5, 'manual', 1700000000);
      ''');
      rawDb.execute('''
        INSERT INTO day_completions (date, is_complete, updated_at)
        VALUES ('2026-10-24', 1, '2026-10-24T08:00:00Z');
      ''');
      rawDb.execute('''
        INSERT OR REPLACE INTO user_profile (id, name, current_weight, target_weight, height_cm, age, is_male, goal_type, program_mode, weekly_rate, protein_preference, calorie_floor, baseline_expenditure)
        VALUES ('default_profile', 'Test Athlete', 75.0, 70.0, 175.0, 25, 1, 'fatLoss', 'coached', 0.5, 'high', 1500.0, 2200.0);
      ''');

      // Verify sqlite_sequence has entries for autoincrement tables
      final initialSeq = rawDb.select(
          "SELECT name, seq FROM sqlite_sequence WHERE name IN ('food_logs', 'weight_logs');");
      expect(initialSeq.length, equals(2));

      // 3. Execute clearAllData()
      appDb.clearAllData();

      // 4. Verify catalog tables are completely preserved
      final remainingFoods =
          rawDb.select('SELECT id, name FROM foods WHERE id = ?;', [1]);
      expect(remainingFoods.length, equals(1));
      expect(remainingFoods.first['name'], equals('Catalog Oats'));

      final remainingPortions =
          rawDb.select('SELECT id FROM portion_units WHERE id = ?;', [1]);
      expect(remainingPortions.length, equals(1));

      // 5. Verify user data tables are wiped clean
      final remainingFoodLogs = rawDb.select('SELECT id FROM food_logs;');
      expect(remainingFoodLogs.isEmpty, isTrue);

      final remainingWeightLogs = rawDb.select('SELECT id FROM weight_logs;');
      expect(remainingWeightLogs.isEmpty, isTrue);

      final remainingDayCompletions =
          rawDb.select('SELECT date FROM day_completions;');
      expect(remainingDayCompletions.isEmpty, isTrue);

      final remainingProfiles = rawDb.select('SELECT id FROM user_profile;');
      expect(remainingProfiles.isEmpty, isTrue);

      // 6. Verify sqlite_sequence is reset for food_logs and weight_logs
      final resetSeq = rawDb.select(
          "SELECT name, seq FROM sqlite_sequence WHERE name IN ('food_logs', 'weight_logs');");
      expect(resetSeq.isEmpty, isTrue);
    });

    test(
        'AuthNotifier.deleteAccount() wipes local database, clears SharedPreferences, and resets state',
        () async {
      // Pre-condition: Set initial authenticated account
      final account = UserAccount.fromGoogle(
        googleUserId: 'athlete_to_delete',
        displayName: 'Delete Me',
        email: 'delete.me@sique.athletic',
      );
      appDb.saveAccountSession(account);

      // Populate user data
      rawDb.execute('''
        INSERT INTO weight_logs (date, scale_weight, source, logged_at)
        VALUES ('2026-10-24', 80.0, 'manual', 1700000000);
      ''');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('test_athlete_key', 'persisted_val');
      expect(prefs.getKeys().isNotEmpty, isTrue);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(appDb),
          authServiceProvider.overrideWithValue(mockAuth),
        ],
      );
      addTearDown(container.dispose);

      // Read initial state to ensure container initializes
      final initialAuthState = container.read(authNotifierProvider);
      expect(initialAuthState.isAuthenticated, isTrue);
      expect(initialAuthState.displayName, equals('Delete Me'));

      // Perform deletion
      final notifier = container.read(authNotifierProvider.notifier);
      final success = await notifier.deleteAccount();
      expect(success, isTrue);

      // Assert post-condition 1: State is unauthenticated guest
      final postAuthState = container.read(authNotifierProvider);
      expect(postAuthState.isAuthenticated, isFalse);
      expect(postAuthState.displayName, equals('Guest Athlete'));

      // Assert post-condition 2: SQLite account session removed
      expect(appDb.getAccountSession(), isNull);

      // Assert post-condition 3: User data tables wiped
      final weightLogs = rawDb.select('SELECT id FROM weight_logs;');
      expect(weightLogs.isEmpty, isTrue);

      // Assert post-condition 4: SharedPreferences cleared
      final postPrefs = await SharedPreferences.getInstance();
      expect(postPrefs.getKeys().isEmpty, isTrue);
    });

    testWidgets(
        'DeleteAccountDialog displays explicit permanent data wipe warning',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final emailUser = UserAccount(
        id: 'user_123',
        googleUserId: 'email_uid_123',
        authProvider: AuthProviderType.email,
        displayName: 'Athlete One',
        email: 'athlete@sique.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeleteAccountDialog(user: emailUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsOneWidget);
      expect(
        find.textContaining(
          'All local workout, nutrition, and weight data will be permanently wiped. This cannot be undone.',
        ),
        findsOneWidget,
      );
      expect(
          find.byKey(const Key('delete_account_confirm_btn')), findsOneWidget);
      expect(
          find.byKey(const Key('delete_account_cancel_btn')), findsOneWidget);
    });

    testWidgets(
        'GoogleAccountCard displays distinct auth provider badges for Guest, Google, and Email',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Guest Mode
      final guestContainer = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(appDb),
          authServiceProvider.overrideWithValue(mockAuth),
        ],
      );
      addTearDown(guestContainer.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: guestContainer,
          child: const MaterialApp(
            home: Scaffold(
              body: GoogleAccountCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final guestBadgeFinder =
          find.byKey(const Key('profile_auth_provider_badge'));
      expect(guestBadgeFinder, findsOneWidget);
      expect(find.text('Guest Mode'), findsOneWidget);

      final AppleBadge guestBadge = tester.widget(guestBadgeFinder);
      expect(guestBadge.color, equals(AppTheme.warning));

      // 2. Google Account Mode
      final googleUser = UserAccount.fromGoogle(
        googleUserId: 'g_user_1',
        displayName: 'Google Athlete',
        email: 'athlete@gmail.com',
      );
      appDb.saveAccountSession(googleUser);

      final googleContainer = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(appDb),
          authServiceProvider.overrideWithValue(mockAuth),
        ],
      );
      addTearDown(googleContainer.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: googleContainer,
          child: const MaterialApp(
            home: Scaffold(
              body: GoogleAccountCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final googleBadgeFinder =
          find.byKey(const Key('profile_auth_provider_badge'));
      expect(googleBadgeFinder, findsOneWidget);
      expect(find.text('Google Account'), findsOneWidget);

      final AppleBadge googleBadge = tester.widget(googleBadgeFinder);
      expect(googleBadge.color, equals(AppTheme.activeBlue));

      // 3. Email Account Mode
      rawDb.execute('DELETE FROM user_account_session;');
      final emailUser = UserAccount(
        id: 'active_session',
        googleUserId: 'email_uid_456',
        authProvider: AuthProviderType.email,
        displayName: 'Email Athlete',
        email: 'athlete@sique.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      appDb.saveAccountSession(emailUser);

      final emailContainer = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(appDb),
          authServiceProvider.overrideWithValue(mockAuth),
        ],
      );
      addTearDown(emailContainer.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: emailContainer,
          child: const MaterialApp(
            home: Scaffold(
              body: GoogleAccountCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final emailBadgeFinder =
          find.byKey(const Key('profile_auth_provider_badge'));
      expect(emailBadgeFinder, findsOneWidget);
      expect(find.text('Email Account'), findsOneWidget);

      final AppleBadge emailBadge = tester.widget(emailBadgeFinder);
      expect(emailBadge.color, equals(AppTheme.success));
    });

    testWidgets(
        'EmailAuthDialog performs regex email validation and password confirmation in SignUp mode',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(appDb),
          authServiceProvider.overrideWithValue(mockAuth),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: EmailAuthDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test Invalid Email in SignIn mode
      final emailInput = find.byKey(const Key('auth_email_input'));
      final passwordInput = find.byKey(const Key('auth_password_input'));
      final submitBtn = find.byKey(const Key('auth_submit_btn'));

      await tester.enterText(emailInput, 'invalid-email-address');
      await tester.enterText(passwordInput, 'secret123');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Invalid email address'), findsOneWidget);

      // Switch to SignUp mode
      final switchToSignUpBtn =
          find.byKey(const Key('auth_switch_to_signup_btn'));
      await tester.tap(switchToSignUpBtn);
      await tester.pumpAndSettle();

      // Verify Confirm Password input is present in SignUp mode
      final confirmPasswordInput =
          find.byKey(const Key('auth_confirm_password_input'));
      expect(confirmPasswordInput, findsOneWidget);

      // Enter valid email but mismatched passwords
      await tester.enterText(emailInput, 'athlete@sique.com');
      await tester.enterText(passwordInput, 'password123');
      await tester.enterText(confirmPasswordInput, 'different_password');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);

      // Enter matching passwords
      await tester.enterText(confirmPasswordInput, 'password123');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Form validation succeeds and submission triggered
      expect(find.text('Passwords do not match'), findsNothing);
      expect(find.text('Invalid email address'), findsNothing);
    });

    testWidgets(
        'AuthLegalFooter opens Privacy Policy and Medical Disclaimer modals',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AuthLegalFooter(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final privacyBtn = find.byKey(const Key('auth_privacy_policy_btn'));
      final disclaimerBtn =
          find.byKey(const Key('auth_medical_disclaimer_btn'));

      expect(privacyBtn, findsOneWidget);
      expect(disclaimerBtn, findsOneWidget);

      // Tap Privacy Policy button
      await tester.tap(privacyBtn);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Privacy Policy'),
        ),
        findsOneWidget,
      );
      expect(find.text('Close'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Tap Medical Disclaimer button
      await tester.tap(disclaimerBtn);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Medical Disclaimer'),
        ),
        findsOneWidget,
      );
      expect(find.text('Understood'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
