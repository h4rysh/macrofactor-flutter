import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/food_log_screen.dart';
import 'package:sique/presentation/screens/scaffold_with_nav_bar.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Empirical Challenger: Food Deletion Undo & State Integrity', () {
    late Database rawDb;
    late AppDatabase db;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      db = AppDatabase(rawDb);
      db.initUserTables();
      db.setSetting('onboarding_completed', 'true');
    });

    tearDown(() {
      rawDb.dispose();
    });

    test(
        'Adversarial ID Preservation: Interleaved inserts and out-of-order restoration maintain exact IDs and timestamps',
        () {
      final t1 = DateTime(2026, 11, 9, 8, 15, 30);
      final t2 = DateTime(2026, 11, 9, 12, 30, 0);
      final t3 = DateTime(2026, 11, 9, 19, 45, 15);

      final entry1 = FoodLogEntry(
        id: 101,
        date: '2026-11-09',
        mealType: MealType.breakfast,
        foodId: 1,
        foodName: 'Idli & Sambar',
        servingQuantity: 2.0,
        unitName: 'Plate',
        gramWeight: 240.0,
        calories: 300.0,
        protein: 10.0,
        carbs: 55.0,
        fat: 4.0,
        fiber: 6.0,
        oilModifier: OilModifier.standard,
        loggedAt: t1,
      );

      final entry2 = FoodLogEntry(
        id: 102,
        date: '2026-11-09',
        mealType: MealType.lunch,
        foodId: 2,
        foodName: 'Brown Rice & Dal',
        servingQuantity: 1.0,
        unitName: 'Bowl',
        gramWeight: 350.0,
        calories: 450.0,
        protein: 16.0,
        carbs: 80.0,
        fat: 6.0,
        fiber: 10.0,
        oilModifier: OilModifier.lowOil,
        loggedAt: t2,
      );

      final entry3 = FoodLogEntry(
        id: 103,
        date: '2026-11-09',
        mealType: MealType.dinner,
        foodId: 3,
        foodName: 'Paneer Bhurji',
        servingQuantity: 1.0,
        unitName: 'Serving',
        gramWeight: 180.0,
        calories: 380.0,
        protein: 22.0,
        carbs: 12.0,
        fat: 26.0,
        fiber: 3.0,
        oilModifier: OilModifier.oneTsp,
        loggedAt: t3,
      );

      // Restore all 3
      db.restoreFoodLog(entry1);
      db.restoreFoodLog(entry2);
      db.restoreFoodLog(entry3);

      var logs = db.getFoodLogsForDate('2026-11-09');
      expect(logs.length, equals(3));
      expect(logs.map((e) => e.id).toList(), equals([101, 102, 103]));

      // Adversarial delete entry 102 and entry 101
      db.deleteFoodLog(102);
      db.deleteFoodLog(101);

      logs = db.getFoodLogsForDate('2026-11-09');
      expect(logs.length, equals(1));
      expect(logs.first.id, equals(103));

      // Interleaved: insert a completely fresh entry without specifying an explicit ID
      final freshId = db.insertFoodLog(FoodLogEntry(
        date: '2026-11-09',
        mealType: MealType.snacks,
        foodId: 4,
        foodName: 'Roasted Almonds',
        servingQuantity: 1.0,
        unitName: 'Handful',
        gramWeight: 30.0,
        calories: 160.0,
        protein: 6.0,
        carbs: 6.0,
        fat: 14.0,
        fiber: 3.0,
        oilModifier: OilModifier.standard,
        loggedAt: DateTime(2026, 11, 9, 16, 0),
      ));

      expect(freshId, isNot(equals(101)));
      expect(freshId, isNot(equals(102)));

      // Out-of-order Undo: Restore 102 first, then 101
      final restoredId2 = db.restoreFoodLog(entry2);
      expect(restoredId2, equals(102));

      final restoredId1 = db.restoreFoodLog(entry1);
      expect(restoredId1, equals(101));

      // Verify all 4 entries exist and retain exact primary keys and timestamps
      logs = db.getFoodLogsForDate('2026-11-09');
      expect(logs.length, equals(4));

      final log101 = logs.firstWhere((e) => e.id == 101);
      final log102 = logs.firstWhere((e) => e.id == 102);
      final log103 = logs.firstWhere((e) => e.id == 103);

      expect(log101.id, equals(101));
      expect(log101.loggedAt, equals(t1));
      expect(log101.foodName, equals('Idli & Sambar'));
      expect(log101.oilModifier, equals(OilModifier.standard));

      expect(log102.id, equals(102));
      expect(log102.loggedAt, equals(t2));
      expect(log102.foodName, equals('Brown Rice & Dal'));
      expect(log102.oilModifier, equals(OilModifier.lowOil));

      expect(log103.id, equals(103));
      expect(log103.loggedAt, equals(t3));
      expect(log103.oilModifier, equals(OilModifier.oneTsp));
    });

    test(
        'State Integrity: Expenditure and Macro Totals Recompute Accurately across Multiple Deletions and Restores',
        () {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => DateTime(2026, 11, 9, 12, 0)),
          selectedDateProvider.overrideWith((ref) => '2026-11-09'),
        ],
      );
      addTearDown(container.dispose);

      // Seed 7 days of scale weight to allow expenditure engine to process
      for (int i = 0; i < 7; i++) {
        final d = DateTime(2026, 11, 3 + i);
        db.insertScaleWeight(d, 75.0);
      }

      final profile = defaultUserProfile.copyWith(
        baselineExpenditureKcal: 2200.0,
        currentWeightKg: 75.0,
        targetWeightKg: 70.0,
      );
      db.saveUserProfile(profile);

      // Verify initial baseline state
      final initialExpenditure = container.read(expenditureStateProvider);
      expect(initialExpenditure.expenditureKcal, isPositive);
      final initialRevision = container.read(foodLogsRevisionProvider);

      final notifier = container.read(dailyFoodLogsProvider.notifier);

      final heavyMeal = FoodLogEntry(
        id: 505,
        date: '2026-11-09',
        mealType: MealType.dinner,
        foodId: 99,
        foodName: 'Feast Biryani',
        servingQuantity: 2.0,
        unitName: 'Plate',
        gramWeight: 700.0,
        calories: 1200.0,
        protein: 60.0,
        carbs: 140.0,
        fat: 45.0,
        fiber: 8.0,
        oilModifier: OilModifier.oneTbsp,
        loggedAt: DateTime(2026, 11, 9, 20, 0),
      );

      // 1. Restore heavy meal
      notifier.restoreEntry(heavyMeal);
      expect(container.read(foodLogsRevisionProvider),
          equals(initialRevision + 1));

      final afterAddNutrition = container.read(dailyNutritionSummaryProvider);
      expect(afterAddNutrition.calories, equals(1200.0));
      expect(afterAddNutrition.protein, equals(60.0));

      final afterAddExpenditure = container.read(expenditureStateProvider);
      expect(afterAddExpenditure.date, equals(DateTime(2026, 11, 9)));

      // 2. Delete heavy meal
      notifier.removeEntry(505);
      expect(container.read(foodLogsRevisionProvider),
          equals(initialRevision + 2));

      final afterDeleteNutrition =
          container.read(dailyNutritionSummaryProvider);
      expect(afterDeleteNutrition.calories, equals(0.0));
      expect(afterDeleteNutrition.protein, equals(0.0));

      // 3. Restore again
      final restoredId = notifier.restoreEntry(heavyMeal);
      expect(restoredId, equals(505));
      expect(container.read(foodLogsRevisionProvider),
          equals(initialRevision + 3));

      final afterRestoreNutrition =
          container.read(dailyNutritionSummaryProvider);
      expect(afterRestoreNutrition.calories, equals(1200.0));
      expect(afterRestoreNutrition.protein, equals(60.0));

      final afterRestoreExpenditure = container.read(expenditureStateProvider);
      expect(afterRestoreExpenditure.expenditureKcal,
          equals(afterAddExpenditure.expenditureKcal));
    });

    testWidgets(
        'Adversarial SnackBar: programmatic date change via selectedDateProvider dismisses active SnackBar immediately',
        (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dateState = StateProvider<String>((ref) => '2026-11-09');

      final entry = FoodLogEntry(
        id: 701,
        date: '2026-11-09',
        mealType: MealType.breakfast,
        foodId: 10,
        foodName: 'Masala Dosa',
        servingQuantity: 1.0,
        unitName: 'Dosa',
        gramWeight: 150.0,
        calories: 320.0,
        protein: 6.0,
        carbs: 45.0,
        fat: 12.0,
        fiber: 3.0,
        oilModifier: OilModifier.standard,
        loggedAt: DateTime(2026, 11, 9, 8, 30),
      );
      db.restoreFoodLog(entry);

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            clockProvider.overrideWithValue(() => DateTime(2026, 11, 9, 12, 0)),
            selectedDateProvider.overrideWith((ref) => ref.watch(dateState)),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return MaterialApp(
                theme: AppTheme.darkTheme,
                home: const FoodLogScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Masala Dosa'), findsOneWidget);

      // Delete item via swipe
      await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Removed Masala Dosa'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Now change selected date provider programmatically (simulating midnight rollover or deep link)
      capturedRef.read(dateState.notifier).state = '2026-11-10';
      await tester.pumpAndSettle();

      // Verify active SnackBar is immediately dismissed
      expect(find.text('Removed Masala Dosa'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets(
        'Bottom Nav Dock: Scaffold(extendBody: true), BackdropFilter sigma 20, zero Icons.apple, and bottom padding >= 80px',
        (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ScaffoldWithNavBar(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Scaffold(extendBody: true)
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsWidgets);
      final rootScaffold = tester.widget<Scaffold>(scaffoldFinder.first);
      expect(rootScaffold.extendBody, isTrue);

      // 2. Verify BackdropFilter with sigmaX: 20, sigmaY: 20 on the dock
      final dockBackdropFilter = tester.widget<BackdropFilter>(
        find.ancestor(
          of: find.byKey(const Key('center_action_fab')),
          matching: find.byType(BackdropFilter),
        ),
      );
      final blur = dockBackdropFilter.filter as ImageFilter;
      expect(blur.toString(), contains('20.0'));

      // 3. Verify zero instances of Icons.apple across the entire widget hierarchy
      final icons = tester.widgetList<Icon>(find.byType(Icon));
      for (final icon in icons) {
        expect(icon.icon, isNot(equals(Icons.apple)));
      }

      // 4. Verify Food Log tab icon is restaurant
      expect(find.byIcon(Icons.restaurant), findsOneWidget);

      // 5. Verify Food Log bottom scroll padding >= 80px
      // FoodLogScreen has SizedBox(height: 80) at the end of sliver list
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final hasAtLeast80pxPadding =
          sizedBoxes.any((box) => (box.height ?? 0) >= 80.0);
      expect(hasAtLeast80pxPadding, isTrue);

      // 6. Switch to Dashboard tab (index 0)
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      // Verify Dashboard has bottom scroll padding >= 80px
      final dashboardSizedBoxes =
          tester.widgetList<SizedBox>(find.byType(SizedBox));
      final dashboardHas80pxPadding =
          dashboardSizedBoxes.any((box) => (box.height ?? 0) >= 80.0);
      expect(dashboardHas80pxPadding, isTrue);
    });
  });
}
