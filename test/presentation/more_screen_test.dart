import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macro_factor_app/data/local/app_database.dart';
import 'package:macro_factor_app/domain/models/user_profile.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';
import 'package:macro_factor_app/presentation/screens/more_screen.dart';
import 'package:macro_factor_app/presentation/screens/profile_targets_screen.dart';
import 'package:macro_factor_app/presentation/screens/food_log_settings_screen.dart';
import 'package:macro_factor_app/presentation/screens/expenditure_settings_screen.dart';
import 'package:macro_factor_app/presentation/screens/data_export_screen.dart';
import 'package:macro_factor_app/presentation/screens/about_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() {
    db.close();
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
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
      expect(find.text('About MacroFactor (Indian Edition)'), findsOneWidget);
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

      await tester.tap(find.text('About MacroFactor (Indian Edition)'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text('MacroFactor'), findsOneWidget);
      expect(find.text('Indian Edition • Adherence-Neutral'), findsOneWidget);
      expect(find.text('Clean-Room Architecture'), findsOneWidget);
      expect(find.text('ICMR-NIN IFCT 2017 Database'), findsOneWidget);
      expect(find.text('Local Data Sovereignty'), findsOneWidget);

      // Tap back
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(MoreScreen), findsOneWidget);
    });
  });
}
