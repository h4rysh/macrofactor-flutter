import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/data/local/dao/nutrient_explorer_dao.dart';
import 'package:sique/domain/algorithms/challenge_generation_service.dart';
import 'package:sique/domain/algorithms/coaching_engine.dart';
import 'package:sique/domain/algorithms/expenditure_kalman_v5.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/domain/models/weekly_challenge_model.dart';
import 'package:sique/domain/services/nutrition_label_ocr_parser.dart';
import 'package:sique/presentation/widgets/food/sique_math_keyboard.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('Wave 1: ExpenditureKalmanV5 & GoalEtaCalculator', () {
    test('Training-volume prior drift responds to 7d vs 21d delta > 75 kcal',
        () {
      final filter = ExpenditureKalmanV5(
        initialExpenditureKcal: 2200,
        initialWeightKg: 75.0,
        bmrKcal: 1700,
      );
      final start = DateTime(2026, 1, 1);
      for (var i = 0; i < 14; i++) {
        filter.processDay(DailyExpenditureInputV5(
          date: start.add(Duration(days: i)),
          scaleWeightKg: 75.0,
          loggedIntakeKcal: 2200,
          workoutLoadKcal: 0,
          hasWorkoutOnDay: false,
        ));
      }
      final beforeRamp = filter.expenditureKcal;
      for (var i = 14; i < 21; i++) {
        filter.processDay(DailyExpenditureInputV5(
          date: start.add(Duration(days: i)),
          scaleWeightKg: 75.0,
          loggedIntakeKcal: 2200,
          workoutLoadKcal: 450,
          hasWorkoutOnDay: true,
        ));
      }
      expect(filter.expenditureKcal, greaterThan(beforeRamp));
    });

    test('Katch-McArdle BMR blends cleanly when bodyFatPct is present', () {
      final mifflinOnly = ExpenditureKalmanV5.computeBlendedBmr(
        weightKg: 80,
        heightCm: 178,
        age: 28,
        isMale: true,
      );
      final blended = ExpenditureKalmanV5.computeBlendedBmr(
        weightKg: 80,
        heightCm: 178,
        age: 28,
        isMale: true,
        bodyFatPct: 14.0,
      );
      expect(mifflinOnly, isNotNull);
      expect(blended, isNotNull);
      expect(blended, isNot(equals(mifflinOnly)));
    });

    test('GoalEtaCalculator switches to Recomp Mode on near-zero velocity', () {
      final eta = GoalEtaCalculator.compute(
        now: DateTime(2026, 1, 15),
        trendWeightKg: 75.0,
        goalWeightKg: 70.0,
        goalType: 'lose',
        targetRatePctPerWeek: 0.75,
        observedVelocityKgPerWeek: 0.0,
        expenditureKcal: 2400,
        expenditureVariance: 10000,
        isSilentRecomp: true,
        currentWaistCm: 92.0,
        waistDelta14Cm: -1.0,
        heightCm: 176.0,
      );
      expect(eta.isRecompMode, isTrue);
      expect(eta.recompSummary, contains('WHtR'));
      expect(eta.expectedWeeks, isNotNull);
    });

    test('CoachingEngine.rebalanceRemainingWeek adjusts remaining days safely',
        () {
      const profile = UserProfile(
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
        baselineExpenditureKcal: 2200.0,
      );
      final program = CoachingEngine.buildWeeklyProgram(
        profile: profile,
        expenditureKcal: 2200,
        style: MacroProgramStyle.balanced,
        allocationType: DayAllocationType.even,
        workoutDays: const {1, 3, 5},
      );
      final rebalanced = CoachingEngine.rebalanceRemainingWeek(
        currentProgram: program,
        profile: profile,
        consumedCaloriesSoFar: 5500,
        completedDaysCount: 2,
      );
      expect(
        rebalanced.dailyAverageCalories,
        greaterThanOrEqualTo(profile.calorieFloor),
      );
    });
  });

  group('Wave 1B & 2 & 3: Schema v7, DeficitMiningV2, Math, OCR & Explorer',
      () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(sqlite3.openInMemory(), isInMemory: true);
    });

    tearDown(() {
      db.rawDb.dispose();
    });

    test('Schema v7 seeds 36 nutrient definitions & DiaryToolsDao CRUD works',
        () {
      final defs = db.barcodeDao.getAllNutrientDefinitions();
      expect(defs.length, greaterThanOrEqualTo(36));

      db.diaryToolsDao.saveDayNote('2026-02-01', 'High sodium restaurant meal');
      expect(
        db.diaryToolsDao.getDayNote('2026-02-01'),
        'High sodium restaurant meal',
      );

      db.diaryToolsDao.setCustomMicroGoal(1, 24.0);
      expect(db.diaryToolsDao.getCustomMicroGoals()[1], 24.0);

      final repeat = RepeatItemRecord(
        id: 'rep_1',
        foodId: 1,
        foodName: 'Whey Shake',
        mealType: 'breakfast',
        hour: 8,
        servingQuantity: 1,
        unitName: 'scoop',
        gramWeight: 32,
        calories: 120,
        protein: 24,
        carbs: 2,
        fat: 1,
        fiber: 0,
        createdAt: DateTime(2026, 2, 1).toIso8601String(),
      );
      db.diaryToolsDao.upsertRepeatItem(repeat);
      final pending =
          db.diaryToolsDao.getPendingRepeatItemsForDate(DateTime(2026, 2, 1));
      expect(pending.length, 1);
      db.diaryToolsDao.markRepeatItemLogged('rep_1', '2026-02-01');
      final afterLog =
          db.diaryToolsDao.getPendingRepeatItemsForDate(DateTime(2026, 2, 1));
      expect(afterLog, isEmpty);

      final explorer = NutrientExplorerDao.loadWindow(
        db.rawDb,
        userId: db.currentUserId,
        windowDays: 7,
        isFemale: false,
        referenceDate: DateTime(2026, 2, 1),
      );
      expect(explorer.items.length, greaterThanOrEqualTo(36));
    });

    test('DeficitMiningV2 & Adaptive Challenges V2 generate cumulative protein',
        () {
      final now = DateTime(2026, 2, 10);
      for (var i = 0; i < 5; i++) {
        final d = now.subtract(Duration(days: i));
        db.insertFoodLog(
          FoodLogEntry(
            id: 0,
            foodId: 1,
            foodName: 'Dal Chawal',
            date:
                '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
            mealType: MealType.lunch,
            loggedAt: DateTime(d.year, d.month, d.day, 13, 0),
            servingQuantity: 1,
            unitName: 'bowl',
            gramWeight: 200,
            calories: 400,
            protein: 65,
            carbs: 60,
            fat: 10,
            fiber: 6,
            oilModifier: OilModifier.none,
          ),
        );
      }
      final metrics = db.challengesDao.mineDeficitMetricsV2(
        proteinTargetG: 150.0,
        referenceDate: now,
      );
      final challenges =
          ChallengeGenerationService.generateAdaptiveChallengesV2(
        metrics: metrics,
        weekStart: now,
        proteinTargetG: 150.0,
      );
      expect(challenges, isNotEmpty);
      expect(
        challenges.any((c) => c.type == ChallengeType.proteinVolume),
        isTrue,
      );
    });

    test('SiqueMathEvaluator parses inline math expressions accurately', () {
      expect(SiqueMathEvaluator.evaluate('150*2'), 300.0);
      expect(SiqueMathEvaluator.evaluate('300/4+25'), 100.0);
      expect(SiqueMathEvaluator.evaluate('10/0'), isNull);
    });

    test('NutritionLabelOcrParser extracts FSSAI and FDA label macros', () {
      final parsed = NutritionLabelOcrParser.parse(
        'Nutrition Facts Per 100g: Energy 380 kcal, Protein 24.5g, Carbohydrate 42g, Total Fat 11g, Dietary Fiber 6g, Sodium 220mg',
        fallbackName: 'Protein Oats',
      );
      expect(parsed, isNotNull);
      expect(parsed!.caloriesPer100g, 380.0);
      expect(parsed.proteinPer100g, 24.5);
      expect(parsed.fiberPer100g, 6.0);
      expect(parsed.sodiumMgPer100g, 220.0);
    });
  });
}
