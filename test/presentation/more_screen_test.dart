import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/more_screen.dart';
import 'package:sique/presentation/screens/profile_targets_screen.dart';
import 'package:sique/presentation/screens/food_log_settings_screen.dart';
import 'package:sique/presentation/screens/expenditure_settings_screen.dart';
import 'package:sique/presentation/screens/data_export_screen.dart';
import 'package:sique/presentation/screens/about_screen.dart';
import 'package:sique/presentation/screens/account_profile_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() {
    db.close();
  });

  Widget buildTestableWidget(Widget child, {UserAccount? initialUser}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        if (initialUser != null)
          currentUserProvider.overrideWith((ref) => initialUser),
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

  group('MoreScreen Navigation & Content Tests', () {
    testWidgets('renders all 5 settings tiles with Obsidian cards and icons',
        (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildTestableWidget(const MoreScreen()));
      await tester.pumpAndSettle();

      expect(find.text('More'), findsOneWidget);
      expect(find.text('Profile & Targets'), findsOneWidget);
      expect(find.text('Food Log Settings'), findsOneWidget);
      expect(find.text('Expenditure & Weight Settings'), findsOneWidget);
      expect(find.text('Data Export & Diagnostics'), findsOneWidget);
      expect(find.text('About Sique'), findsOneWidget);
    });

    testWidgets(
        'Tapping Profile & Targets navigates to ProfileTargetsScreen with instant auto-save',
        (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildTestableWidget(const MoreScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile & Targets'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileTargetsScreen), findsOneWidget);
      expect(find.text('Physical Stats'), findsOneWidget);
      expect(find.text('Goal & Strategy'), findsOneWidget);
      expect(find.text('Daily Caloric Target'), findsOneWidget);

      // Verify changing Goal Type immediately triggers updateProfile
      await tester.tap(find.text('Muscle Gain'));
      await tester.pumpAndSettle();

      final updatedProfile = db.getUserProfile();
      expect(updatedProfile?.goalType, GoalType.muscleGain);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(MoreScreen), findsOneWidget);
    });

    testWidgets(
        'Tapping Food Log Settings navigates and auto-saves portion preferences',
        (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildTestableWidget(const MoreScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Food Log Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(FoodLogSettingsScreen), findsOneWidget);
      expect(find.text('Default Portion Unit'), findsOneWidget);
      expect(find.text('Default Cooking Oil Modifier'), findsOneWidget);
      expect(find.text('Show Empty Hourly Slots'), findsOneWidget);

      // Select Katori portion unit
      await tester.tap(find.text('Katori (Standard Bowl, 150ml)'));
      await tester.pumpAndSettle();

      // Verify persisted directly to database settings table
      expect(db.getSetting('default_portion_unit', ''),
          'Katori (Standard Bowl, 150ml)');

      // Select Extra Ghee modifier
      await tester
          .tap(find.text('Extra Ghee / Restaurant Style (2 tbsp, ~240 kcal)'));
      await tester.pumpAndSettle();

      expect(db.getSetting('default_oil_modifier', ''),
          'Extra Ghee / Restaurant Style (2 tbsp, ~240 kcal)');

      // Tap back
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(MoreScreen), findsOneWidget);
    });

    testWidgets(
        'Tapping Expenditure & Weight navigates to ExpenditureSettingsScreen',
        (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildTestableWidget(const MoreScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Expenditure & Weight Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(ExpenditureSettingsScreen), findsOneWidget);
      expect(find.text('Live Algorithmic State'), findsOneWidget);
      expect(find.text('Baseline Expenditure Prior'), findsOneWidget);
      expect(find.text('Adherence Neutrality Guarantee'), findsOneWidget);

      // Tap sensitivity mode
      await tester.tap(find.text('Conservative'));
      await tester.pumpAndSettle();

      expect(db.getSetting('expenditure_sensitivity', ''), 'Conservative');

      // Tap back
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(MoreScreen), findsOneWidget);
    });

    testWidgets(
        'Tapping Data Export navigates to DataExportScreen and tests preview',
        (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildTestableWidget(const MoreScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Data Export & Diagnostics'));
      await tester.pumpAndSettle();

      expect(find.byType(DataExportScreen), findsOneWidget);
      expect(find.text('Local Storage Diagnostics'), findsOneWidget);
      expect(find.text('Export Food Logs (JSON)'), findsOneWidget);
      expect(find.text('Export Scale Weights (CSV)'), findsOneWidget);

      // Open Food Logs preview dialog
      final previewButtons = find.widgetWithText(OutlinedButton, 'Preview');
      expect(previewButtons, findsNWidgets(2));
      await tester.tap(previewButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Food Logs Preview'), findsOneWidget);

      // Close preview dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Tap back
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(MoreScreen), findsOneWidget);
    });

    testWidgets('Tapping About navigates to AboutScreen and shows citations',
        (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildTestableWidget(const MoreScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('About Sique'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text('Sique'), findsOneWidget);
      expect(find.text('Indian Edition • Adherence-Neutral'), findsOneWidget);
      expect(find.text('Clean-Room Architecture'), findsOneWidget);
      expect(find.text('ICMR-NIN IFCT 2017 Database'), findsOneWidget);
      expect(find.text('Local Data Sovereignty'), findsOneWidget);

      // Tap back
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(MoreScreen), findsOneWidget);
    });

    testWidgets(
        'more_account_card renders at top and navigates to AccountProfileScreen',
        (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildTestableWidget(const MoreScreen()));
      await tester.pumpAndSettle();

      // Account card should be rendered
      expect(find.byKey(const Key('more_account_card')), findsOneWidget);
      expect(find.text('Guest Athlete'), findsOneWidget);
      expect(
        find.text('Sign in with Google to sync workouts & scale data'),
        findsOneWidget,
      );

      // Tap account card
      await tester.tap(find.byKey(const Key('more_account_card')));
      await tester.pumpAndSettle();

      // Should navigate to AccountProfileScreen
      expect(find.byType(AccountProfileScreen), findsOneWidget);
      expect(find.byKey(const Key('profile_back_btn')), findsOneWidget);

      // Pop back to MoreScreen
      await tester.tap(find.byKey(const Key('profile_back_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(MoreScreen), findsOneWidget);
    });

    testWidgets(
        'more_account_card correctly defaults unauthenticated user with non-empty displayName to Guest Athlete',
        (tester) async {
      configureViewport(tester);
      final now = DateTime.now();
      final unauthenticatedCustomNameUser = UserAccount(
        id: 'guest_custom',
        googleUserId: '',
        displayName: 'Local Runner',
        email: 'local@example.com',
        photoUrl: null,
        createdAt: now,
        updatedAt: now,
        isAuthenticated: false,
      );
      await tester.pumpWidget(
        buildTestableWidget(
          const MoreScreen(),
          initialUser: unauthenticatedCustomNameUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('more_account_card')), findsOneWidget);
      expect(find.text('Guest Athlete'), findsOneWidget);
      expect(find.text('Local Runner'), findsNothing);
      expect(
        find.text('Sign in with Google to sync workouts & scale data'),
        findsOneWidget,
      );
    });

    testWidgets('more_account_card renders user details when authenticated',
        (tester) async {
      configureViewport(tester);
      final now = DateTime.now();
      final authenticatedUser = UserAccount(
        id: 'google_123',
        googleUserId: 'sub_12345',
        displayName: 'Sarah Connor',
        email: 'sarah@example.com',
        photoUrl: 'https://example.com/avatar.jpg',
        createdAt: now,
        updatedAt: now,
        isAuthenticated: true,
        healthConnectEnabled: true,
      );
      await tester.pumpWidget(
        buildTestableWidget(
          const MoreScreen(),
          initialUser: authenticatedUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('more_account_card')), findsOneWidget);
      expect(find.text('Sarah Connor'), findsOneWidget);
      expect(find.text('sarah@example.com'), findsOneWidget);
      expect(find.text('SYNC ACTIVE'), findsOneWidget);
      expect(
        find.text('Sign in with Google to sync workouts & scale data'),
        findsNothing,
      );
    });
  });
}
