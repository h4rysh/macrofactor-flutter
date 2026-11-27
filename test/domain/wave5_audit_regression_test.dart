import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/data/utils/backup_codec.dart';
import 'package:sique/domain/algorithms/coaching_engine.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/domain/models/weekly_challenge_model.dart';
import 'package:sique/domain/models/workout_session.dart';
import 'package:sique/domain/services/nutrition_label_ocr_parser.dart';
import 'package:sique/domain/validation/domain_validator.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/utils/quantity_parser.dart';
import 'package:sique/presentation/widgets/physical_stats_summary_card.dart';
import 'package:sique/presentation/widgets/water_dial_widget.dart';
import 'package:sique/utils/unit_formatter.dart';

void main() {
  group('Wave 1-5 Audit Remediation Regressions', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.inMemory();
    });

    tearDown(() {
      db.close();
    });

    test(
        'FoodDao.searchFoodsFiltered filters SQL pre-LIMIT and preserves veg eggless/eggplant',
        () {
      for (var i = 1; i <= 5; i++) {
        db.insertFood(
          FoodItem(
            id: i,
            uuid: 'nv_$i',
            name: 'Grilled Chicken Curry $i',
            category: 'Meat & Poultry',
            region: 'North',
            caloriesPer100g: 190,
            proteinPer100g: 22,
            carbsPer100g: 4,
            fatPer100g: 9,
            fiberPer100g: 0,
            iconSvg: 'meat',
            source: 'IFCT',
            aliases: 'murgh chicken',
            isVerified: true,
          ),
        );
      }

      db.insertFood(
        const FoodItem(
          id: 6,
          uuid: 'veg_eggplant',
          name: 'Baingan Bharta / Eggplant Mash',
          category: 'Vegetarian Curries',
          region: 'North',
          caloriesPer100g: 95,
          proteinPer100g: 2.5,
          carbsPer100g: 10,
          fatPer100g: 5,
          fiberPer100g: 4,
          iconSvg: 'curry',
          source: 'IFCT',
          aliases: 'eggplant baingan',
          isVerified: true,
        ),
      );
      db.insertFood(
        const FoodItem(
          id: 7,
          uuid: 'veg_eggless',
          name: 'Eggless Rava Cake',
          category: 'Snacks',
          region: 'South',
          caloriesPer100g: 280,
          proteinPer100g: 6,
          carbsPer100g: 45,
          fatPer100g: 8,
          fiberPer100g: 2,
          iconSvg: 'snack',
          source: 'IFCT',
          aliases: 'eggless semolina',
          isVerified: true,
        ),
      );
      db.insertFood(
        const FoodItem(
          id: 8,
          uuid: 'nv_egg',
          name: 'Boiled Egg Bhurji',
          category: 'Eggs',
          region: 'Pan-Indian',
          caloriesPer100g: 165,
          proteinPer100g: 13,
          carbsPer100g: 2,
          fatPer100g: 12,
          fiberPer100g: 0,
          iconSvg: 'egg',
          source: 'IFCT',
          aliases: 'anda egg',
          isVerified: true,
        ),
      );

      final vegResults = db.foodDao.searchFoodsFiltered(
        '',
        filterKey: 'vegetarian',
        limit: 2,
      );
      expect(vegResults.length, equals(2));
      expect(vegResults.map((f) => f.id), containsAll([6, 7]));
      expect(vegResults.any((f) => f.id == 8 || f.id <= 5), isFalse);

      final southResults = db.foodDao.searchFoodsFiltered(
        '',
        filterKey: 'southIndian',
        limit: 5,
      );
      expect(southResults.map((f) => f.id), equals([7]));

      final literalPercent = db.foodDao.searchFoodsFiltered(
        '%',
        filterKey: 'all',
        limit: 10,
      );
      expect(literalPercent, isEmpty);
    });

    test(
        'WorkoutDao.getWorkoutSessionsInRange supports sub-second end timestamps and user isolation',
        () {
      final target = WorkoutSession(
        id: 'w_evening',
        source: 'manual',
        title: 'Late Pull Session',
        startTime: DateTime(2026, 3, 10, 23, 59, 50),
        endTime: DateTime(2026, 3, 11, 0, 45, 0),
        durationMinutes: 55,
        caloriesBurned: 380,
        createdAt: DateTime(2026, 3, 10, 23, 59, 50),
      );
      final otherUser = WorkoutSession(
        id: 'w_other',
        source: 'manual',
        title: 'Other User Session',
        startTime: DateTime(2026, 3, 10, 10, 0, 0),
        endTime: DateTime(2026, 3, 10, 11, 0, 0),
        durationMinutes: 60,
        caloriesBurned: 400,
        createdAt: DateTime(2026, 3, 10, 10, 0, 0),
      );
      db.workoutDao.insertWorkoutSessions([target], userId: 'athlete_a');
      db.workoutDao.insertWorkoutSessions([otherUser], userId: 'athlete_b');

      final foundDateOnly = db.workoutDao.getWorkoutSessionsInRange(
        DateTime(2026, 3, 10),
        DateTime(2026, 3, 10),
        userId: 'athlete_a',
      );
      expect(foundDateOnly.map((w) => w.id), equals(['w_evening']));

      final foundExactTime = db.workoutDao.getWorkoutSessionsInRange(
        DateTime(2026, 3, 10, 0, 0, 0),
        DateTime(2026, 3, 10, 23, 59, 50),
        userId: 'athlete_a',
      );
      expect(foundExactTime.map((w) => w.id), equals(['w_evening']));
    });

    test(
        'ChallengesDao tracks fiber & hydration goals and clears completed_at on reopen',
        () {
      db.setUserId('default_user');
      final start = DateTime(2026, 4, 6);
      final end = DateTime(2026, 4, 12);

      final fiberChallenge = WeeklyChallengeModel(
        id: 'ch_fiber',
        type: ChallengeType.fiberBuilder,
        title: 'Hit 30g Fiber Days',
        description: 'Log 30g fiber across the week',
        targetMetric: 'fiber:30',
        targetValue: 2,
        unit: 'days',
        weekStartDate: start,
        weekEndDate: end,
        createdAt: start,
      );
      final waterChallenge = WeeklyChallengeModel(
        id: 'ch_water',
        type: ChallengeType.hydrationHero,
        title: 'Hydration 2.5L Days',
        description: 'Drink 2.5L per day',
        targetMetric: 'hydration:2500',
        targetValue: 2,
        unit: 'days',
        weekStartDate: start,
        weekEndDate: end,
        createdAt: start,
      );

      db.challengesDao.upsertChallenge(fiberChallenge);
      db.challengesDao.upsertChallenge(waterChallenge);

      db.insertFoodLog(
        FoodLogEntry(
          id: 0,
          foodId: 1,
          foodName: 'Chana Masala',
          date: '2026-04-07',
          mealType: MealType.lunch,
          loggedAt: DateTime(2026, 4, 7, 13, 0),
          servingQuantity: 1,
          unitName: 'bowl',
          gramWeight: 250,
          calories: 320,
          protein: 14,
          carbs: 48,
          fat: 7,
          fiber: 34,
          oilModifier: OilModifier.none,
        ),
      );
      db.waterDao.logWater(2600, date: DateTime(2026, 4, 7));

      final syncedFiber = db.challengesDao.syncChallengeWithLogs(
        fiberChallenge,
        proteinTargetG: 140,
      );
      final syncedWater = db.challengesDao.syncChallengeWithLogs(
        waterChallenge,
        proteinTargetG: 140,
      );

      expect(syncedFiber, equals(1.0));
      expect(syncedWater, equals(1.0));

      db.challengesDao.updateChallengeStatus(
        'ch_fiber',
        ChallengeStatus.completed,
        completedAt: DateTime(2026, 4, 7, 15, 0),
      );
      var loaded = db.challengesDao
          .getChallengeHistory()
          .firstWhere((c) => c.id == 'ch_fiber');
      expect(loaded.status, equals(ChallengeStatus.completed));
      expect(loaded.completedAt, isNotNull);

      db.challengesDao.updateChallengeStatus(
        'ch_fiber',
        ChallengeStatus.active,
      );
      loaded = db.challengesDao
          .getActiveChallenges()
          .firstWhere((c) => c.id == 'ch_fiber');
      expect(loaded.status, equals(ChallengeStatus.active));
      expect(loaded.completedAt, isNull);
    });

    test(
        'CoachingEngine.computeDayMacros enforces keto carb cap and scales floors safely',
        () {
      final macros = CoachingEngine.computeDayMacros(
        calories: 1400,
        weightKg: 75,
        style: MacroProgramStyle.keto,
        proteinPref: ProteinPreference.high,
      );
      expect(macros.carbsGrams, lessThanOrEqualTo(50.0));
      expect(macros.proteinGrams, greaterThan(0.0));
      expect(macros.fatGrams, greaterThan(0.0));
    });

    test(
        'BackupCodec v7 preserves repeatItems, dayNotes, and microGoals roundtrip',
        () {
      final profile = UserProfile.fromMap(const {});
      final repeat = RepeatItemRecord(
        id: 'rep_v7',
        foodId: 10,
        foodName: 'Idli',
        mealType: 'breakfast',
        hour: 8,
        servingQuantity: 2,
        unitName: 'piece',
        gramWeight: 120,
        calories: 160,
        protein: 5,
        carbs: 32,
        fat: 1,
        fiber: 2,
        createdAt: DateTime(2026, 5, 1).toIso8601String(),
      );

      final encoded = BackupCodec.encodeBackup(
        profile: profile,
        foodLogs: const [],
        weightLogs: const [],
        repeatItems: [repeat],
        dayNotes: const {'2026-05-01': 'Feeling recovered'},
        microGoals: const {1: 28.0, 2: 3000.0},
      );
      final decoded = BackupCodec.decodeAndValidate(encoded);

      expect(decoded.schemaVersion, equals(7));
      expect(decoded.repeatItems.length, equals(1));
      expect(decoded.repeatItems.first.foodName, equals('Idli'));
      expect(decoded.dayNotes['2026-05-01'], equals('Feeling recovered'));
      expect(decoded.microGoals[1], equals(28.0));
      expect(decoded.microGoals[2], equals(3000.0));
    });

    test('QuantityParser handles mixed fractions, decimals, and bad input', () {
      expect(QuantityParser.parse('1 1/2'), closeTo(1.5, 1e-6));
      expect(QuantityParser.parse('3/4'), closeTo(0.75, 1e-6));
      expect(QuantityParser.parse('2,5'), closeTo(2.5, 1e-6));
      expect(QuantityParser.parse('1/0'), isNull);
      expect(QuantityParser.parse(''), isNull);
    });

    testWidgets(
        'PhysicalStatsSummaryCard & WaterDialCard render imperial lbs, ft/in, and oz',
        (tester) async {
      db.setSetting('unit_system', 'imperial');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    PhysicalStatsSummaryCard(),
                    SizedBox(height: 12),
                    WaterDialCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('lbs'), findsWidgets);
      expect(find.textContaining('ft'), findsWidgets);
      expect(find.text('+8 oz'), findsOneWidget);
      expect(find.textContaining('oz'), findsWidgets);

      await tester.tap(find.text('+8 oz'));
      await tester.pumpAndSettle();
      expect(db.waterDao.getDailyWaterMl(DateTime.now()), equals(237));
    });

    test(
        'UnitFormatter carries 12-inch height rollover & OCR/DomainValidator clamp safely',
        () {
      final rollover = UnitFormatter.cmToRoundedFeetInches(182.0);
      expect(rollover.feet, equals(6));
      expect(rollover.inches, equals(0));
      expect(UnitFormatter.formatHeight(182.0, useImperial: true),
          equals('6 ft 0 in'));

      final impValidation = DomainValidator.validateTargetWeight(
        targetWeightKg: 45.0,
        heightCm: 175.0,
        goalType: GoalType.fatLoss,
        useImperial: true,
      );
      expect(impValidation.isValid, isFalse);
      expect(impValidation.errorMessage, contains('lbs'));

      final ocr = NutritionLabelOcrParser.parse(
        'Serving Size 0.001g Energy 500 kcal Protein 50g Carbs 10g Fat 20g',
      );
      expect(ocr, isNotNull);
      expect(ocr!.proteinPer100g, lessThanOrEqualTo(100.0));
      expect(ocr.caloriesPer100g, lessThanOrEqualTo(1000.0));
    });
  });
}
