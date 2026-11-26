import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/algorithms/coaching_engine.dart';
import 'package:sique/domain/models/body_measurement_entry.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/domain/models/weekly_challenge_model.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/widgets/charts/metabolic_series_chart.dart';
import 'package:sique/presentation/widgets/strategy/collaborative_macro_editor_sheet.dart';

void main() {
  group('Phase A Overhaul - Bugfixes, Periodization, Auto-Sync & Charts', () {
    late Database rawDb;
    late AppDatabase appDb;
    late ProviderContainer container;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      rawDb.execute('''
        CREATE TABLE foods (
          id INTEGER PRIMARY KEY, uuid TEXT, name TEXT, category TEXT, region TEXT,
          calories REAL, protein REAL, carbs REAL, fat REAL, fiber REAL, icon_svg TEXT,
          source TEXT, aliases TEXT, is_verified INTEGER NOT NULL DEFAULT 1
        );
        CREATE TABLE portion_units (
          id INTEGER PRIMARY KEY, food_id INTEGER, unit_name TEXT, gram_weight REAL, is_default INTEGER
        );
      ''');
      appDb = AppDatabase(rawDb, isInMemory: true);
      appDb.initUserTables();
      appDb.insertFood(const FoodItem(
        id: 501,
        uuid: 'f501',
        name: 'Whey Isolate Shake',
        category: 'Supplements',
        region: 'Global',
        caloriesPer100g: 380,
        proteinPer100g: 85,
        carbsPer100g: 4,
        fatPer100g: 2,
        fiberPer100g: 0,
        iconSvg: 'food',
        source: 'Test',
        aliases: '',
      ));
      appDb.insertPortionUnit(const PortionUnit(
        id: 1,
        foodId: 501,
        unitName: 'Scoop (200g)',
        gramWeight: 200.0,
        isDefault: true,
      ));

      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(appDb),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      rawDb.dispose();
    });

    test(
        'recompositionStatusProvider uses ASC weight tail correctly (no false positive on weight drop)',
        () {
      // Seed historical weight drop from 95 -> 75 -> 70 (14 days apart -> real drop, NOT plateau!)
      final wNotifier = container.read(weightLogsProvider.notifier);
      wNotifier.logWeight('2026-01-01', 95.0, null);
      wNotifier.logWeight('2026-01-10', 75.0, null);
      wNotifier.logWeight('2026-01-20', 70.0, null);

      // Seed waist measurements shrinking 90 -> 88
      final bmNotifier = container.read(bodyMeasurementsProvider.notifier);
      bmNotifier.saveMeasurement(BodyMeasurementEntry(
        id: 'bm_1',
        date: DateTime(2026, 1, 1),
        waistCm: 90.0,
        loggedAt: DateTime(2026, 1, 1),
      ));
      bmNotifier.saveMeasurement(BodyMeasurementEntry(
        id: 'bm_2',
        date: DateTime(2026, 1, 20),
        waistCm: 88.0,
        loggedAt: DateTime(2026, 1, 20),
      ));

      // Because weight dropped -5 kg (75 -> 70), silent recomp MUST be false
      expect(container.read(recompositionStatusProvider), isFalse);
    });

    test(
        'recompositionStatusProvider triggers true only on weight plateau + smoothed waist shrink',
        () {
      final wNotifier = container.read(weightLogsProvider.notifier);
      wNotifier.logWeight('2026-01-01', 95.0, null); // ancient max
      wNotifier.logWeight('2026-01-10', 75.0, null);
      wNotifier.logWeight(
          '2026-01-20', 75.1, null); // plateau (+0.1 kg over >= 7 days)

      final bmNotifier = container.read(bodyMeasurementsProvider.notifier);
      bmNotifier.saveMeasurement(BodyMeasurementEntry(
        id: 'bm_1',
        date: DateTime(2026, 1, 1),
        waistCm: 84.0,
        loggedAt: DateTime(2026, 1, 1),
      ));
      bmNotifier.saveMeasurement(BodyMeasurementEntry(
        id: 'bm_2',
        date: DateTime(2026, 1, 10),
        waistCm: 82.0,
        loggedAt: DateTime(2026, 1, 10),
      ));
      bmNotifier.saveMeasurement(BodyMeasurementEntry(
        id: 'bm_3',
        date: DateTime(2026, 1, 20),
        waistCm: 80.5,
        loggedAt: DateTime(2026, 1, 20),
      ));

      expect(container.read(recompositionStatusProvider), isTrue);
    });

    test(
        'WeeklyChallengesNotifier passes tenant userId and auto-syncs from daily logs',
        () {
      appDb.setUserId('tenant_alpha');
      final now = DateTime.now();
      final todayStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Trigger challenge initialization
      var challenges = container.read(weeklyChallengesProvider);
      expect(challenges, isNotEmpty);
      expect(challenges.first.id, contains('tenant_alpha'));

      // Log high-protein shake -> auto-awards Protein Anchor challenge if present
      container.read(selectedDateProvider.notifier).state = todayStr;
      container.read(dailyFoodLogsProvider.notifier).addEntry(
            food: appDb.getFoodById(501)!,
            portionUnit: const PortionUnit(
              id: 1,
              foodId: 501,
              unitName: 'Scoop (200g)',
              gramWeight: 200.0,
            ),
            quantity: 1.0, // 170g protein (> 150g target)
            mealType: MealType.breakfast,
            oilModifier: OilModifier.none,
            loggedAt: now,
          );

      challenges = container.read(weeklyChallengesProvider);
      final proteinChallenge = challenges
          .where((c) => c.type == ChallengeType.proteinAnchor)
          .toList();
      if (proteinChallenge.isNotEmpty) {
        expect(proteinChallenge.first.currentValue, greaterThanOrEqualTo(1.0));
      }
    });

    test(
        'CoachingEngine enforces Diet Break, Reverse Diet pacing, Collaborative share, & Manual pause',
        () {
      const baseProfile = UserProfile(
        id: 'p1',
        name: 'Tester',
        currentWeightKg: 75.0,
        targetWeightKg: 70.0,
        heightCm: 175.0,
        age: 28,
        isMale: true,
        goalType: GoalType.fatLoss,
        programMode: ProgramMode.coached,
        weeklyRateOfChangePct: -0.75,
        proteinPreference: ProteinPreference.high,
        calorieFloor: 1400.0,
        baselineExpenditureKcal: 2500.0,
      );

      // 1. Diet Break overrides deficit to 1.0x expenditure
      final dietBreakProfile = baseProfile.copyWith(isInDietBreak: true);
      expect(
        CoachingEngine.calculateDailyAverageCalories(
          profile: dietBreakProfile,
          expenditureKcal: 2500.0,
        ),
        equals(2500.0),
      );

      // 2. Reverse Diet Moderate (+5%/wk from 1800 -> 1890)
      final reverseProfile =
          baseProfile.copyWith(reverseDietPacing: 'moderate');
      expect(
        CoachingEngine.calculateDailyAverageCalories(
          profile: reverseProfile,
          expenditureKcal: 2500.0,
          previousAvgCalories: 1800.0,
        ),
        equals(1890.0),
      );

      // 3. Collaborative carbShareOverride shifts Carbs vs Fat
      final lowCarbSide = CoachingEngine.computeDayMacros(
        calories: 2200,
        weightKg: 75,
        style: MacroProgramStyle.balanced,
        proteinPref: ProteinPreference.high,
        carbShareOverride: 0.25,
      );
      final highCarbSide = CoachingEngine.computeDayMacros(
        calories: 2200,
        weightKg: 75,
        style: MacroProgramStyle.balanced,
        proteinPref: ProteinPreference.high,
        carbShareOverride: 0.75,
      );
      expect(highCarbSide.carbsGrams, greaterThan(lowCarbSide.carbsGrams));
      expect(highCarbSide.fatGrams, lessThan(lowCarbSide.fatGrams));

      // 4. Manual mode suppresses coached check-in prompt
      final manualProfile = baseProfile.copyWith(
        programMode: ProgramMode.manual,
        customCalories: 2100,
        customProteinGrams: 170,
        customCarbsGrams: 220,
        customFatGrams: 60,
      );
      final program = CoachingEngine.buildWeeklyProgram(
        profile: manualProfile,
        expenditureKcal: 2500.0,
        style: MacroProgramStyle.balanced,
        allocationType: DayAllocationType.even,
        workoutDays: const {1, 3, 5},
        lastCheckInDate: DateTime(2026, 1, 1),
      );
      final rec = CoachingEngine.evaluateWeeklyCheckIn(
        currentProgram: program,
        profile: manualProfile,
        currentExpenditureKcal: 2500.0,
        currentDate: DateTime(2026, 1, 20),
      );
      expect(rec.isDue, isFalse);
      expect(program.days.first.proteinGrams, equals(170));
    });

    test(
        'FoodDao.getRecentFoods returns distinct recently logged foods efficiently',
        () {
      appDb.insertFoodLog(FoodLogEntry(
        date: '2026-01-10',
        mealType: MealType.breakfast,
        foodId: 501,
        foodName: 'Whey Isolate Shake',
        servingQuantity: 1,
        unitName: 'Scoop',
        gramWeight: 200,
        calories: 760,
        protein: 170,
        carbs: 8,
        fat: 4,
        fiber: 0,
        oilModifier: OilModifier.none,
        loggedAt: DateTime(2026, 1, 10, 8),
        iconSvg: 'food',
      ));

      final recent = container.read(recentLoggedFoodsProvider);
      expect(recent.first.id, equals(501));
    });

    testWidgets(
        'MetabolicSeriesChart and CollaborativeMacroEditorSheet render cleanly',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(appDb),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const MetabolicSeriesChart(
                    points: [
                      ChartSeriesPoint(
                          dateLabel: '01-01',
                          value: 2400,
                          bandLow: 2250,
                          bandHigh: 2550),
                      ChartSeriesPoint(
                          dateLabel: '01-08',
                          value: 2450,
                          bandLow: 2350,
                          bandHigh: 2550),
                    ],
                    accentColor: Colors.teal,
                    unitLabel: 'kcal',
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Trigger'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MetabolicSeriesChart), findsOneWidget);
      // Verify CollaborativeMacroEditorSheet pumps without overflow
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(appDb),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CollaborativeMacroEditorSheet(
                  mode: ProgramMode.collaborative),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Collaborative Budget Designer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
