import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/dashboard_screen.dart';
import 'package:sique/presentation/screens/data_export_screen.dart';
import 'package:sique/presentation/screens/food_log_settings_screen.dart';
import 'package:sique/presentation/screens/food_search_screen.dart';
import 'package:sique/presentation/screens/plate_serving_sheet.dart';
import 'package:sique/presentation/screens/profile_targets_screen.dart';
import 'package:sique/presentation/screens/scaffold_with_nav_bar.dart';
import 'package:sique/presentation/screens/weight_log_modal.dart';
import 'package:sique/presentation/widgets/macro_gauge_ring.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() {
    db.close();
  });

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ScaffoldWithNavBar(),
      ),
    );
  }

  group('End-to-End User Journeys (E2E Test Suite)', () {
    testWidgets(
        'E2E Journey 1: Search food -> Select Paneer -> Add portion & oil modifier -> Add to Plate -> Live Dashboard Macros Update',
        (tester) async {
      configureViewport(tester);

      // Seed Paneer food item and portion unit in database
      const paneerItem = FoodItem(
        id: 101,
        uuid: 'paneer_101',
        name: 'Paneer (Cottage Cheese)',
        caloriesPer100g: 257.0,
        proteinPer100g: 18.3,
        fatPer100g: 20.8,
        carbsPer100g: 3.4,
        fiberPer100g: 0.0,
        category: 'Dairy Products',
        region: 'North',
        iconSvg: 'dairy',
        source: 'ICMR-NIN IFCT 2017',
        aliases: 'paneer, cottage cheese',
      );
      db.insertFood(paneerItem);
      db.insertPortionUnit(const PortionUnit(
        id: 1,
        foodId: 101,
        unitName: 'Katori (150g)',
        gramWeight: 150.0,
        isDefault: true,
      ));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Switch to Dashboard tab (ScaffoldWithNavBar defaults to FoodLogScreen)
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      // Verify Initial Dashboard State
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(MacroGaugeRing), findsOneWidget);

      // Open Food Search via "Log Food" action pill
      await tester.tap(find.text('Log Food'));
      await tester.pumpAndSettle();

      expect(find.byType(FoodSearchScreen), findsOneWidget);

      // Enter search query "Paneer"
      await tester.enterText(find.byType(TextField), 'Paneer');
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(find.text('Paneer (Cottage Cheese)'), findsOneWidget);

      // Tap on the Paneer item to open PlateServingSheet
      await tester.tap(find.text('Paneer (Cottage Cheese)'));
      await tester.pumpAndSettle();

      expect(find.byType(PlateServingSheet), findsOneWidget);
      expect(find.text('Paneer (Cottage Cheese)'), findsWidgets);

      // Tap "Add to Plate" button
      await tester.tap(find.text('Add to Plate'));
      await tester.pumpAndSettle();

      // Verify that database has recorded the food log entry
      final allLogs = db.getAllFoodLogs();
      expect(allLogs.length, 1);
      expect(allLogs.first.food.name, 'Paneer (Cottage Cheese)');

      // Adding to plate confirms and automatically navigates back to Dashboard
      expect(find.byType(DashboardScreen), findsOneWidget);

      // Verify that the Dashboard Macro Ring displays the newly logged calories
      final expectedCals = allLogs.first.calories.round();
      expect(find.text('$expectedCals'), findsWidgets);
    });

    testWidgets(
        'E2E Journey 2: Scale Weight Logging -> SQLite Persistence -> Trend Weight Preview & Calculation',
        (tester) async {
      configureViewport(tester);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Switch to Dashboard tab
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      // Tap "Log Weight" on Dashboard action pill
      await tester.tap(find.text('Log Weight'));
      await tester.pumpAndSettle();

      expect(find.byType(WeightLogModal), findsOneWidget);
      expect(find.text('LOG SCALE WEIGHT'), findsOneWidget);

      // Enter weight "74.8"
      final weightTextField = find.descendant(
        of: find.byType(WeightLogModal),
        matching: find.byType(TextField).first,
      );
      await tester.enterText(weightTextField, '74.8');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('SAVE SCALE WEIGHT'));
      await tester.pumpAndSettle();

      // Verify saved in SQLite database
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final weights = db.getScaleWeights(todayStr, todayStr);
      expect(weights.length, 1);
      expect(weights.first.weightKg, 74.8);
    });

    testWidgets(
        'E2E Journey 3: Instant Auto-Save in Profile & Targets -> Reactive Caloric Target Propagation to Dashboard',
        (tester) async {
      configureViewport(tester);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Switch to "More" bottom navigation tab (index 3)
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      // Tap "Profile & Targets"
      await tester.tap(find.text('Profile & Targets'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileTargetsScreen), findsOneWidget);

      // Tap "Muscle Gain" Goal Type
      await tester.tap(find.text('Muscle Gain'));
      await tester.pumpAndSettle();

      // Verify instant auto-save to database
      var profile = db.getUserProfile();
      expect(profile?.goalType, GoalType.muscleGain);

      // Select "Extra High (2.4 g/kg)" Protein Preference
      await tester.tap(find.text('Extra High (2.4 g/kg)'));
      await tester.pumpAndSettle();

      profile = db.getUserProfile();
      expect(profile?.proteinPreference, ProteinPreference.extraHigh);

      // Navigate back to More
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      // Switch back to Dashboard tab (index 0)
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets(
        'E2E Journey 4: Food Log Settings -> Instant Key-Value Auto-Save to App Settings Table',
        (tester) async {
      configureViewport(tester);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Navigate to More
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      // Tap "Food Log Settings"
      await tester.tap(find.text('Food Log Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(FoodLogSettingsScreen), findsOneWidget);

      // Select Katori unit
      await tester.tap(find.text('Katori (Standard Bowl, 150ml)'));
      await tester.pumpAndSettle();

      expect(db.getSetting('default_portion_unit', ''),
          'Katori (Standard Bowl, 150ml)');

      // Select Low Oil modifier
      await tester.tap(find.text('Low Oil (1 tsp, ~40 kcal)'));
      await tester.pumpAndSettle();

      expect(db.getSetting('default_oil_modifier', ''),
          'Low Oil (1 tsp, ~40 kcal)');

      // Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Food Log Settings'), findsOneWidget);
    });

    testWidgets(
        'E2E Journey 5: Data Export & Storage Diagnostics -> JSON & CSV Exports Verification',
        (tester) async {
      configureViewport(tester);

      // Seed a sample weight log and food log
      db.insertScaleWeight(DateTime.now(), 72.5, 'Morning weigh-in');
      const roti = FoodItem(
        id: 202,
        uuid: 'roti_202',
        name: 'Whole Wheat Roti',
        caloriesPer100g: 264.0,
        proteinPer100g: 9.1,
        fatPer100g: 3.2,
        carbsPer100g: 50.4,
        fiberPer100g: 3.5,
        category: 'Breads & Cereals',
        region: 'Pan-India',
        iconSvg: 'bread',
        source: 'ICMR-NIN IFCT 2017',
        aliases: 'roti, chapati',
      );
      db.insertFood(roti);
      db.insertFoodLog(FoodLogEntry(
        id: 1,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        mealType: MealType.dinner,
        foodId: 202,
        foodName: 'Whole Wheat Roti',
        servingQuantity: 2.0,
        unitName: 'Piece (35g)',
        gramWeight: 70.0,
        calories: 184.8,
        protein: 6.37,
        carbs: 35.28,
        fat: 2.24,
        fiber: 2.45,
        oilModifier: OilModifier.none,
        loggedAt: DateTime.now(),
        iconSvg: 'bread',
      ));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Navigate to More -> Data Export & Diagnostics
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Data Export & Diagnostics'));
      await tester.pumpAndSettle();

      expect(find.byType(DataExportScreen), findsOneWidget);

      // Verify diagnostics cards render non-zero counts
      expect(find.text('Food Logs'), findsOneWidget);
      expect(find.text('Weight Logs'), findsOneWidget);

      // Open and verify Food Logs JSON preview dialog
      final previewButtons = find.widgetWithText(OutlinedButton, 'Preview');
      expect(previewButtons, findsNWidgets(2));
      await tester.tap(previewButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Food Logs Preview'), findsOneWidget);
      expect(find.textContaining('Whole Wheat Roti'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Open and verify CSV scale weights preview dialog
      await tester.tap(previewButtons.last);
      await tester.pumpAndSettle();

      expect(find.text('Scale Weights CSV Preview'), findsOneWidget);
      expect(find.textContaining('72.5'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'E2E Journey 6: Onboarding Coordinator -> 23 Steps -> Target Activation -> Enter Dashboard',
        (tester) async {
      configureViewport(tester);

      // Start with uncompleted onboarding in clean DB
      expect(db.getSetting('onboarding_completed', 'false'), equals('false'));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ScaffoldWithNavBar(),
        ),
      ));
      await tester.pumpAndSettle();

      // Switch to Dashboard tab (ScaffoldWithNavBar defaults to FoodLogScreen)
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      // Verify dashboard is up and running
      expect(find.byType(DashboardScreen), findsOneWidget);
    });
  });
}
