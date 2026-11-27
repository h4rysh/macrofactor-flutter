import 'dart:ui' show Tristate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/food_search_screen.dart';
import 'package:sique/presentation/screens/quick_actions_sheet.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
    db.setSetting('onboarding_completed', 'true');
  });

  tearDown(() {
    db.close();
  });

  group('Click-Path Audit & State Transition Tests', () {
    test(
        'DailyFoodLogsNotifier.copyFromDate duplicates yesterday food logs into today',
        () {
      final providerContainer = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          selectedDateProvider.overrideWith((ref) => '2026-11-22'),
        ],
      );
      addTearDown(providerContainer.dispose);

      // 1. Insert sample food logs for yesterday (2026-11-21)
      final yesterdayEntry = FoodLogEntry(
        id: 0,
        date: '2026-11-21',
        mealType: MealType.lunch,
        foodId: 1,
        foodName: 'Paneer Butter Masala',
        servingQuantity: 1.5,
        unitName: 'Cup (200g)',
        gramWeight: 300,
        calories: 450,
        protein: 18.0,
        carbs: 12.0,
        fat: 36.0,
        fiber: 2.0,
        oilModifier: OilModifier.standard,
        loggedAt: DateTime(2026, 11, 21, 13, 30),
      );
      db.insertFoodLog(yesterdayEntry);

      // Verify yesterday has 1 log and today (2026-11-22) has 0 logs
      expect(db.getFoodLogsForDate('2026-11-21').length, 1);
      expect(db.getFoodLogsForDate('2026-11-22').length, 0);

      // 2. Call copyFromDate('2026-11-21') via DailyFoodLogsNotifier
      final count = providerContainer
          .read(dailyFoodLogsProvider.notifier)
          .copyFromDate('2026-11-21');

      expect(count, 1);

      // 3. Verify today now has 1 log with exact duplicate nutritional data
      final todayLogs = db.getFoodLogsForDate('2026-11-22');
      expect(todayLogs.length, 1);
      expect(todayLogs.first.foodName, 'Paneer Butter Masala');
      expect(todayLogs.first.calories, 450);
      expect(todayLogs.first.protein, 18.0);
      expect(todayLogs.first.date, '2026-11-22');
      expect(todayLogs.first.loggedAt.year, 2026);
      expect(todayLogs.first.loggedAt.month, 11);
      expect(todayLogs.first.loggedAt.day, 22);
      expect(todayLogs.first.loggedAt.hour, 13);
      expect(todayLogs.first.loggedAt.minute, 30);
    });

    testWidgets('QuickActionsSheet Copy Yesterday executes real copy',
        (tester) async {
      // 1. Seed yesterday's food
      final yesterdayEntry = FoodLogEntry(
        id: 0,
        date: '2026-11-21',
        mealType: MealType.breakfast,
        foodId: 2,
        foodName: 'Oats with Almond Milk',
        servingQuantity: 1.0,
        unitName: 'Bowl',
        gramWeight: 250,
        calories: 320,
        protein: 12.0,
        carbs: 48.0,
        fat: 8.0,
        fiber: 6.0,
        oilModifier: OilModifier.lowOil,
        loggedAt: DateTime(2026, 11, 21, 8, 45),
      );
      db.insertFoodLog(yesterdayEntry);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            selectedDateProvider.overrideWith((ref) => '2026-11-22'),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => QuickActionsSheet.show(context),
                  child: const Text('Open Quick Actions'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.text('Open Quick Actions'));
      await tester.pumpAndSettle();

      // Tap 'Copy Yesterday'
      final copyYesterdayBtn = find.text('Copy Yesterday');
      expect(copyYesterdayBtn, findsOneWidget);

      await tester.tap(copyYesterdayBtn);
      await tester.pumpAndSettle();

      // Verify SnackBar feedback shows actual count
      expect(find.text('Copied 1 meal from yesterday'), findsOneWidget);

      // Verify db was updated
      final todayLogs = db.getFoodLogsForDate('2026-11-22');
      expect(todayLogs.length, 1);
      expect(todayLogs.first.foodName, 'Oats with Almond Milk');
    });

    testWidgets('DayNoteSheet loads existing note and persists updates',
        (tester) async {
      db.setSetting(
          'day_note:2026-11-22', 'Felt energetic after morning workout.');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    builder: (_) => const DayNoteSheet(date: '2026-11-22'),
                  ),
                  child: const Text('Open Day Note'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.text('Open Day Note'));
      await tester.pumpAndSettle();

      // Verify existing note was loaded into text field
      expect(
          find.text('Felt energetic after morning workout.'), findsOneWidget);

      // Edit note
      final textField = find.byType(TextField);
      await tester.enterText(
          textField, 'Updated reflection: Great recovery and high focus.');
      await tester.pumpAndSettle();

      // Tap Save Note
      final saveBtn = find.text('Save Note');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify updated note is persisted in DiaryToolsDao
      expect(
        db.diaryToolsDao.getDayNote('2026-11-22'),
        'Updated reflection: Great recovery and high focus.',
      );
      expect(find.text('Day note saved'), findsOneWidget);
    });

    testWidgets(
        'FoodSearchScreen category filter toggles back to all on second tap',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: FoodSearchScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Vegetarian filter chip
      final vegChip = find.text('Vegetarian');
      expect(vegChip, findsOneWidget);

      // 1. Tap Vegetarian chip -> selects Vegetarian
      await tester.tap(vegChip);
      await tester.pumpAndSettle();

      final vegSemanticsSelected =
          tester.getSemantics(find.bySemanticsLabel('Filter: Vegetarian'));
      expect(vegSemanticsSelected.flagsCollection.isSelected,
          equals(Tristate.isTrue));

      // 2. Tap Vegetarian chip again -> toggles back to All
      await tester.tap(vegChip);
      await tester.pumpAndSettle();

      final vegSemanticsDeselected =
          tester.getSemantics(find.bySemanticsLabel('Filter: Vegetarian'));
      expect(vegSemanticsDeselected.flagsCollection.isSelected,
          isNot(equals(Tristate.isTrue)));

      final allSemanticsSelected =
          tester.getSemantics(find.bySemanticsLabel('Filter: All'));
      expect(allSemanticsSelected.flagsCollection.isSelected,
          equals(Tristate.isTrue));

      // Verify search input TextField is present and active
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
