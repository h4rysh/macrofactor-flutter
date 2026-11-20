import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/data/services/mock_auth_service.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/auth/delete_account_dialog.dart';
import 'package:sique/presentation/screens/more_screen.dart';

void main() {
  group('MoreScreen Safety, Legal & Data Deletion Tests', () {
    late AppDatabase db;
    late MockAuthService mockAuth;

    setUp(() {
      db = AppDatabase.inMemory();
      mockAuth = MockAuthService();
    });

    tearDown(() {
      db.close();
    });

    Widget buildTestWidget({UserAccount? user}) {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWithValue(mockAuth),
          if (user != null) currentUserProvider.overrideWith((ref) => user),
        ],
        child: const MaterialApp(
          home: MoreScreen(),
        ),
      );
    }

    testWidgets(
        'renders ICMR-NIN IFCT attribution and legal disclaimer/privacy triggers',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('ICMR-NIN IFCT 2017'),
        findsOneWidget,
      );

      final disclaimerBtn =
          find.byKey(const Key('more_medical_disclaimer_btn'));
      expect(disclaimerBtn, findsOneWidget);
      await tester.tap(disclaimerBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Important Health & Safety Notice:'),
          findsOneWidget);
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();

      final privacyBtn = find.byKey(const Key('more_privacy_policy_btn'));
      expect(privacyBtn, findsOneWidget);
      await tester.tap(privacyBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'tapping Delete All My Data tile opens DeleteAccountDialog and clears data upon confirmation',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Insert some sample user data to verify wiping
      final rawDb = db.rawDb;
      rawDb.execute('''
        INSERT INTO weight_logs (date, scale_weight, source, logged_at)
        VALUES ('2026-10-25', 76.2, 'manual', 1700000000);
      ''');
      expect(db.getAllWeightLogs().length, equals(1));

      final testUser = UserAccount(
        id: 'test_user_id',
        googleUserId: 'google_sub_123',
        displayName: 'Aarav Patel',
        email: 'aarav@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAuthenticated: true,
        authProvider: AuthProviderType.google,
      );

      await tester.pumpWidget(buildTestWidget(user: testUser));
      await tester.pumpAndSettle();

      final deleteTile = find.byKey(const Key('more_delete_data_tile'));
      expect(deleteTile, findsOneWidget);

      await tester.tap(deleteTile);
      await tester.pumpAndSettle();

      expect(find.byType(DeleteAccountDialog), findsOneWidget);
      expect(find.text('Permanently Delete'), findsOneWidget);

      // Confirm permanent deletion
      await tester.tap(find.byKey(const Key('delete_account_confirm_btn')));
      await tester.pumpAndSettle();

      // Check dialog closed
      expect(find.byType(DeleteAccountDialog), findsNothing);

      // Verify that local database logs were purged
      expect(db.getAllWeightLogs(), isEmpty);
    });
  });
}
