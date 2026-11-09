import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/food_log_screen.dart';
import 'package:sique/presentation/theme/app_theme.dart';

void main() {
  group('Food Deletion & Undo State Integrity Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.inMemory();
      db.setSetting('onboarding_completed', 'true');
    });

    tearDown(() {
      db.close();
    });

    test('FoodDao.restoreFoodLog preserves original id, date, and timestamp',
        () {
      final specificTime = DateTime(2026, 11, 9, 13, 45);
      const originalId = 88;

      final entry = FoodLogEntry(
        id: originalId,
        date: '2026-11-09',
        mealType: MealType.lunch,
        foodId: 101,
        foodName: 'Grilled Chicken Salad',
        servingQuantity: 1.5,
        unitName: 'Bowl',
        gramWeight: 350.0,
        calories: 420.0,
        protein: 38.0,
        carbs: 18.0,
        fat: 14.0,
        fiber: 6.0,
        oilModifier: OilModifier.standard,
        loggedAt: specificTime,
      );

      final returnedId = db.restoreFoodLog(entry);
      expect(returnedId, equals(originalId));

      final fetchedLogs = db.getFoodLogsForDate('2026-11-09');
      expect(fetchedLogs.length, equals(1));

      final restored = fetchedLogs.first;
      expect(restored.id, equals(originalId));
      expect(restored.date, equals('2026-11-09'));
      expect(restored.foodName, equals('Grilled Chicken Salad'));
      expect(restored.calories, equals(420.0));
      expect(restored.protein, equals(38.0));
      expect(restored.loggedAt, equals(specificTime));
    });

    test(
        'DailyFoodLogsNotifier deletion and restoration updates state and invalidates foodLogsRevisionProvider',
        () {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          selectedDateProvider.overrideWith((ref) => '2026-11-09'),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(foodLogsRevisionProvider), equals(0));

      final notifier = container.read(dailyFoodLogsProvider.notifier);
      final loggedAt = DateTime(2026, 11, 9, 9, 30);

      final insertedId = notifier.addFood(FoodLogEntry(
        date: '2026-11-09',
        mealType: MealType.breakfast,
        foodId: 5,
        foodName: 'Oatmeal & Berries',
        servingQuantity: 1.0,
        unitName: 'Bowl',
        gramWeight: 200.0,
        calories: 250.0,
        protein: 10.0,
        carbs: 45.0,
        fat: 4.0,
        fiber: 7.0,
        oilModifier: OilModifier.standard,
        loggedAt: loggedAt,
      ));

      expect(insertedId, isPositive);
      expect(container.read(dailyFoodLogsProvider).length, equals(1));
      expect(container.read(foodLogsRevisionProvider), equals(1));

      final loggedEntry = container.read(dailyFoodLogsProvider).first;
      expect(loggedEntry.id, equals(insertedId));

      // Remove entry
      notifier.removeEntry(insertedId);
      expect(container.read(dailyFoodLogsProvider), isEmpty);
      expect(db.getFoodLogsForDate('2026-11-09'), isEmpty);
      expect(container.read(foodLogsRevisionProvider), equals(2));

      // Restore entry
      final restoredId = notifier.restoreEntry(loggedEntry);
      expect(restoredId, equals(insertedId));
      expect(container.read(dailyFoodLogsProvider).length, equals(1));

      final restoredFromState = container.read(dailyFoodLogsProvider).first;
      expect(restoredFromState.id, equals(insertedId));
      expect(restoredFromState.foodName, equals('Oatmeal & Berries'));
      expect(restoredFromState.loggedAt, equals(loggedAt));
      expect(container.read(foodLogsRevisionProvider), equals(3));
    });

    test(
        'Deleting and restoring food updates dailyNutritionSummary and triggers expenditure revision',
        () {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          selectedDateProvider.overrideWith((ref) => '2026-11-09'),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(dailyFoodLogsProvider.notifier);

      final initialSummary = container.read(dailyNutritionSummaryProvider);
      expect(initialSummary.calories, equals(0.0));

      final entry = FoodLogEntry(
        id: 77,
        date: '2026-11-09',
        mealType: MealType.lunch,
        foodId: 20,
        foodName: 'Salmon Bowl',
        servingQuantity: 1.0,
        unitName: 'Bowl',
        gramWeight: 300.0,
        calories: 600.0,
        protein: 45.0,
        carbs: 40.0,
        fat: 20.0,
        fiber: 5.0,
        oilModifier: OilModifier.standard,
        loggedAt: DateTime(2026, 11, 9, 13, 0),
      );

      notifier.restoreEntry(entry);

      final afterAddSummary = container.read(dailyNutritionSummaryProvider);
      expect(afterAddSummary.calories, equals(600.0));
      expect(afterAddSummary.protein, equals(45.0));

      notifier.removeEntry(77);

      final afterDeleteSummary = container.read(dailyNutritionSummaryProvider);
      expect(afterDeleteSummary.calories, equals(0.0));

      notifier.restoreEntry(entry);

      final afterRestoreSummary = container.read(dailyNutritionSummaryProvider);
      expect(afterRestoreSummary.calories, equals(600.0));
      expect(afterRestoreSummary.protein, equals(45.0));
    });

    testWidgets(
        'FoodLogScreen shows floating SnackBar on delete, restores on Undo, and dismisses on date change',
        (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final todayDateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final entry = FoodLogEntry(
        id: 99,
        date: todayDateStr,
        mealType: MealType.lunch,
        foodId: 10,
        foodName: 'Paneer Wrap',
        servingQuantity: 1.0,
        unitName: 'Wrap',
        gramWeight: 200.0,
        calories: 400.0,
        protein: 20.0,
        carbs: 40.0,
        fat: 15.0,
        fiber: 4.0,
        oilModifier: OilModifier.standard,
        loggedAt: DateTime(now.year, now.month, now.day, 13, 0),
      );

      db.restoreFoodLog(entry);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            selectedDateProvider.overrideWith((ref) => todayDateStr),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const FoodLogScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the item is initially visible
      expect(find.text('Paneer Wrap'), findsOneWidget);

      // Dismiss the food card
      final dismissibleFinder = find.byType(Dismissible);
      expect(dismissibleFinder, findsWidgets);

      await tester.drag(dismissibleFinder.first, const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Verify food item is removed and SnackBar is visible with Undo button
      expect(find.text('Paneer Wrap'), findsNothing);
      expect(find.text('Removed Paneer Wrap'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Tap "Undo"
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      // Verify item reappears
      expect(find.text('Paneer Wrap'), findsOneWidget);

      // Dismiss the item again
      await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Removed Paneer Wrap'), findsOneWidget);

      // Now tap the previous day chevron button to change the selected date
      final prevDayBtn = find.byTooltip('Previous day');
      expect(prevDayBtn, findsOneWidget);
      await tester.tap(prevDayBtn);
      await tester.pumpAndSettle();

      // Verify the SnackBar is dismissed
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
