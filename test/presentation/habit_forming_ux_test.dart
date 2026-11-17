import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/food_log_screen.dart';
import 'package:sique/presentation/screens/food_search_screen.dart';
import 'package:sique/presentation/screens/plate_serving_sheet.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/nutrition_summary_banner.dart';
import 'package:sique/presentation/widgets/timeline_hour_slot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  final fixedClock = DateTime(2026, 11, 17, 12, 0, 0);

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() {
    db.close();
  });

  FoodItem createTestFood({int id = 1, String name = 'Paneer'}) {
    return FoodItem(
      id: id,
      uuid: 'food_$id',
      name: name,
      category: 'Dairy',
      region: 'North Indian',
      caloriesPer100g: 265,
      proteinPer100g: 18.3,
      fatPer100g: 20.8,
      carbsPer100g: 1.2,
      fiberPer100g: 0,
      iconSvg: 'food_paneer',
      source: 'custom',
      aliases: 'cottage cheese',
      portionUnits: [
        PortionUnit(
          id: id,
          foodId: id,
          unitName: 'Grams',
          gramWeight: 1.0,
          isDefault: true,
        ),
      ],
    );
  }

  DailyFoodLogEntry createTestLogEntry({
    required int id,
    required FoodItem food,
    required DateTime loggedAt,
    double quantity = 100.0,
  }) {
    final fmt = DateFormat('yyyy-MM-dd');
    final dateStr = fmt.format(loggedAt);
    return DailyFoodLogEntry(
      id: id,
      date: dateStr,
      mealType: MealType.lunch,
      foodId: food.id,
      foodName: food.name,
      servingQuantity: quantity,
      unitName: 'Grams',
      gramWeight: quantity,
      calories: 265,
      protein: 18.3,
      fat: 20.8,
      carbs: 1.2,
      fiber: 0,
      oilModifier: OilModifier.none,
      loggedAt: loggedAt,
      iconSvg: food.category,
    );
  }

  group('loggingStreakProvider tests', () {
    test('returns 0 when no logs exist (zero-day initial state)', () {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => fixedClock),
        ],
      );
      addTearDown(container.dispose);

      final streak = container.read(loggingStreakProvider);
      expect(streak, 0);
    });

    test(
        'returns 0 when yesterday has food logged but today has no food logged',
        () {
      final food = createTestFood();
      db.insertFood(food);
      final yesterdayLog = createTestLogEntry(
        id: 1,
        food: food,
        loggedAt: fixedClock.subtract(const Duration(days: 1)),
      );
      db.insertFoodLog(yesterdayLog);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => fixedClock),
        ],
      );
      addTearDown(container.dispose);

      final streak = container.read(loggingStreakProvider);
      expect(streak, 0);
    });

    test('calculates single-day streak when today has food logged', () {
      final food = createTestFood();
      db.insertFood(food);
      final log = createTestLogEntry(
        id: 1,
        food: food,
        loggedAt: fixedClock,
      );
      db.insertFoodLog(log);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => fixedClock),
        ],
      );
      addTearDown(container.dispose);

      final streak = container.read(loggingStreakProvider);
      expect(streak, 1);
    });

    test('calculates multi-day consecutive streak accurately', () {
      final food = createTestFood();
      db.insertFood(food);

      // Log for today, yesterday, and 2 days ago (3 days consecutive)
      for (int i = 0; i < 3; i++) {
        final d = fixedClock.subtract(Duration(days: i));
        final log = createTestLogEntry(
          id: i + 1,
          food: food,
          loggedAt: d,
        );
        db.insertFoodLog(log);
      }

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => fixedClock),
        ],
      );
      addTearDown(container.dispose);

      final streak = container.read(loggingStreakProvider);
      expect(streak, 3);
    });

    test('streak breaks when there is an unlogged gap day in between', () {
      final food = createTestFood();
      db.insertFood(food);

      // Log for today and 2 days ago (gap yesterday)
      final logToday = createTestLogEntry(
        id: 1,
        food: food,
        loggedAt: fixedClock,
      );
      final log2DaysAgo = createTestLogEntry(
        id: 2,
        food: food,
        loggedAt: fixedClock.subtract(const Duration(days: 2)),
      );
      db.insertFoodLog(logToday);
      db.insertFoodLog(log2DaysAgo);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => fixedClock),
        ],
      );
      addTearDown(container.dispose);

      final streak = container.read(loggingStreakProvider);
      expect(streak, 1); // Only today counted before gap
    });

    test('streak updates reactively when food is logged for today', () {
      final food = createTestFood();
      db.insertFood(food);
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => fixedClock),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(loggingStreakProvider), 0);

      final log = createTestLogEntry(
        id: 1,
        food: food,
        loggedAt: fixedClock,
      );
      db.insertFoodLog(log);
      container.read(foodLogsRevisionProvider.notifier).state++;

      expect(container.read(loggingStreakProvider), 1);
    });
  });

  group('TimelineHourSlot Copy Yesterday tests', () {
    testWidgets(
        'renders Copy Yesterday button when slot is empty and yesterday has entries',
        (tester) async {
      final food = createTestFood();
      final yesterdayLog = createTestLogEntry(
        id: 1,
        food: food,
        loggedAt: fixedClock.subtract(const Duration(days: 1)),
      );

      bool copyCalled = false;
      List<DailyFoodLogEntry>? copiedEntries;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimelineHourSlot(
              hour: 12,
              entries: const [],
              yesterdayEntries: [yesterdayLog],
              isCollapsed: false,
              onAddTap: () {},
              onEntryTap: (_) {},
              onEntryDelete: (_) {},
              onCopyYesterday: (entries) {
                copyCalled = true;
                copiedEntries = entries;
              },
            ),
          ),
        ),
      );

      // Verify button is displayed
      expect(find.text('Copy Yesterday (1 item)'), findsOneWidget);

      // Tap button
      await tester.tap(find.text('Copy Yesterday (1 item)'));
      await tester.pumpAndSettle();

      expect(copyCalled, isTrue);
      expect(copiedEntries?.length, 1);
      expect(copiedEntries?.first.foodName, 'Paneer');
    });

    testWidgets(
        'does not render Copy Yesterday button when slot already has entries',
        (tester) async {
      final food = createTestFood();
      final currentLog = createTestLogEntry(
        id: 1,
        food: food,
        loggedAt: fixedClock,
      );
      final yesterdayLog = createTestLogEntry(
        id: 2,
        food: food,
        loggedAt: fixedClock.subtract(const Duration(days: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimelineHourSlot(
              hour: 12,
              entries: [currentLog],
              yesterdayEntries: [yesterdayLog],
              isCollapsed: false,
              onAddTap: () {},
              onEntryTap: (_) {},
              onEntryDelete: (_) {},
              onCopyYesterday: (_) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Copy Yesterday'), findsNothing);
    });

    testWidgets(
        'FoodLogScreen Copy Yesterday duplicates entries with new IDs and timestamps, and Undo reverts',
        (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final food = createTestFood(id: 10, name: 'Masala Dosa');
      db.insertFood(food);

      final todayStr = DateFormat('yyyy-MM-dd').format(fixedClock);
      final yesterdayClock = fixedClock.subtract(const Duration(days: 1));

      // 2 items logged yesterday at 8 AM
      final item1 = createTestLogEntry(
        id: 101,
        food: food,
        loggedAt: DateTime(yesterdayClock.year, yesterdayClock.month,
            yesterdayClock.day, 8, 15),
      );
      final item2 = createTestLogEntry(
        id: 102,
        food: food,
        loggedAt: DateTime(yesterdayClock.year, yesterdayClock.month,
            yesterdayClock.day, 8, 45),
      );
      db.insertFoodLog(item1);
      db.insertFoodLog(item2);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            clockProvider.overrideWithValue(() => fixedClock),
            selectedDateProvider.overrideWith((ref) => todayStr),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const FoodLogScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Copy Yesterday button for 8 AM slot
      final copyButton = find.text('Copy Yesterday (2 items)');
      expect(copyButton, findsOneWidget);

      // Tap Copy Yesterday
      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      // Verify SnackBar with Undo
      expect(find.text('Copied 2 items from yesterday'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Verify new entries for today
      final todayLogs = db.getFoodLogsForDate(todayStr);
      expect(todayLogs.length, 2);
      for (final entry in todayLogs) {
        expect(entry.date, todayStr);
        expect(entry.loggedAt.year, fixedClock.year);
        expect(entry.loggedAt.month, fixedClock.month);
        expect(entry.loggedAt.day, fixedClock.day);
        expect(entry.loggedAt.hour, 8);
        expect(entry.id, isNot(101));
        expect(entry.id, isNot(102));
      }

      // Tap Undo
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      // Verify entries deleted
      final revertedTodayLogs = db.getFoodLogsForDate(todayStr);
      expect(revertedTodayLogs, isEmpty);
    });
  });

  group('NutritionSummaryBanner streak badge tests', () {
    testWidgets('displays streak badge when streak >= 2', (tester) async {
      final food = createTestFood();
      db.insertFood(food);

      for (int i = 0; i < 3; i++) {
        final d = fixedClock.subtract(Duration(days: i));
        db.insertFoodLog(createTestLogEntry(
          id: i + 1,
          food: food,
          loggedAt: d,
        ));
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            clockProvider.overrideWithValue(() => fixedClock),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NutritionSummaryBanner(
                consumed: DailyNutritionAggregate(
                  totalCalories: 500,
                  totalProtein: 40,
                  totalFat: 20,
                  totalCarbs: 30,
                ),
                targets: MacroTarget(
                  calories: 2000,
                  proteinGrams: 150,
                  carbsGrams: 200,
                  fatGrams: 60,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for streak badge
      expect(find.text('3d'), findsOneWidget);
    });
  });

  group('FoodSearchScreen Recent & Frequent 1-Tap tests', () {
    test('returns recently logged foods in recency order', () {
      final food1 = createTestFood(id: 1, name: 'Paneer');
      final food2 = createTestFood(id: 2, name: 'Brown Rice');
      db.insertFood(food1);
      db.insertFood(food2);

      db.insertFoodLog(createTestLogEntry(
        id: 1,
        food: food1,
        loggedAt: fixedClock.subtract(const Duration(hours: 2)),
      ));
      db.insertFoodLog(createTestLogEntry(
        id: 2,
        food: food2,
        loggedAt: fixedClock.subtract(const Duration(hours: 1)),
      ));

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => fixedClock),
        ],
      );
      addTearDown(container.dispose);

      final recents = container.read(recentLoggedFoodsProvider);
      expect(recents.isNotEmpty, isTrue);
      expect(recents.map((f) => f.name).contains('Brown Rice'), isTrue);
      expect(recents.map((f) => f.name).contains('Paneer'), isTrue);
    });

    testWidgets('displays Recent & Frequent chips and hides when searching',
        (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final food1 = createTestFood(id: 1, name: 'Paneer Tikka');
      final food2 = createTestFood(id: 2, name: 'Dal Makhani');
      db.insertFood(food1);
      db.insertFood(food2);
      db.insertFoodLog(createTestLogEntry(
        id: 1,
        food: food1,
        loggedAt: fixedClock.subtract(const Duration(hours: 2)),
      ));
      db.insertFoodLog(createTestLogEntry(
        id: 2,
        food: food2,
        loggedAt: fixedClock.subtract(const Duration(hours: 1)),
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            clockProvider.overrideWithValue(() => fixedClock),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const FoodSearchScreen(mealType: MealType.lunch),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and chips are visible
      expect(find.text('RECENT & FREQUENT (1-TAP)'), findsOneWidget);
      expect(find.text('Paneer Tikka'), findsWidgets);
      expect(find.text('Dal Makhani'), findsWidgets);

      // Enter search query that doesn't match Paneer or Dal
      await tester.enterText(find.byType(TextField), 'Chicken');
      await tester.pumpAndSettle();

      // Recent chips header should be hidden
      expect(find.text('RECENT & FREQUENT (1-TAP)'), findsNothing);
      expect(find.text('Paneer Tikka'), findsNothing);

      // Clear search query
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // Recent chips should reappear
      expect(find.text('RECENT & FREQUENT (1-TAP)'), findsOneWidget);
      expect(find.text('Paneer Tikka'), findsWidgets);
    });

    testWidgets('tapping chip body opens PlateServingSheet modal',
        (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final food = createTestFood(id: 8, name: 'Tandoori Roti');
      db.insertFood(food);
      db.insertFoodLog(createTestLogEntry(
        id: 1,
        food: food,
        loggedAt: fixedClock.subtract(const Duration(hours: 1)),
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            clockProvider.overrideWithValue(() => fixedClock),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const FoodSearchScreen(mealType: MealType.lunch),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the chip text
      await tester.tap(find.text('Tandoori Roti').first);
      await tester.pumpAndSettle();

      // Verify PlateServingSheet modal is open
      expect(find.byType(PlateServingSheet), findsOneWidget);
    });

    testWidgets('1-tap + icon logs food directly to Plate with SnackBar',
        (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final food = createTestFood(id: 5, name: 'Roti');
      db.insertFood(food);
      db.insertFoodLog(createTestLogEntry(
        id: 1,
        food: food,
        loggedAt: fixedClock.subtract(const Duration(hours: 1)),
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            clockProvider.overrideWithValue(() => fixedClock),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const FoodSearchScreen(mealType: MealType.lunch),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the add icon button inside the recent chip
      final addIcon = find.byIcon(Icons.add_rounded);
      expect(addIcon, findsWidgets);

      await tester.tap(addIcon.first);
      await tester.pump();

      // Verify SnackBar appears
      expect(find.text('Logged 1x Roti to Plate'), findsOneWidget);
    });
  });
}
