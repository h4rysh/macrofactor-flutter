import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/account_profile_screen.dart';
import 'package:sique/presentation/screens/dashboard_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() {
    db.close();
  });

  Widget buildTestableWidget({
    required Widget child,
    UserAccount? currentUser,
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        if (currentUser != null)
          currentUserProvider.overrideWith((ref) => currentUser),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('Dashboard Profile Avatar Tests', () {
    testWidgets(
        'renders dashboard_profile_avatar_btn in header action row and navigates to AccountProfileScreen',
        (tester) async {
      configureViewport(tester);

      await tester.pumpWidget(
        buildTestableWidget(child: const DashboardScreen()),
      );
      await tester.pumpAndSettle();

      // Verify dashboard header
      expect(find.text('Dashboard'), findsOneWidget);

      // Verify avatar button is present in the action row
      final avatarFinder =
          find.byKey(const Key('dashboard_profile_avatar_btn'));
      expect(avatarFinder, findsOneWidget);

      // Tap profile avatar
      await tester.tap(avatarFinder);
      await tester.pumpAndSettle();

      // Should navigate to AccountProfileScreen
      expect(find.byType(AccountProfileScreen), findsOneWidget);
      expect(find.byKey(const Key('profile_back_btn')), findsOneWidget);

      // Tap back button
      await tester.tap(find.byKey(const Key('profile_back_btn')));
      await tester.pumpAndSettle();

      // Back on Dashboard
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('renders signed-in user initials on Dashboard profile avatar',
        (tester) async {
      configureViewport(tester);

      final user = UserAccount.fromGoogle(
        googleUserId: 'google_123',
        email: 'john.doe@example.com',
        displayName: 'John Doe',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const DashboardScreen(),
          currentUser: user,
        ),
      );
      await tester.pumpAndSettle();

      final avatarFinder =
          find.byKey(const Key('dashboard_profile_avatar_btn'));
      expect(avatarFinder, findsOneWidget);

      // Verify initial "J" is shown
      expect(find.text('J'), findsOneWidget);
    });
  });
}
