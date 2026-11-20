import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/domain/validation/domain_validator.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/food_log_settings_screen.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_03_dob.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_19_calorie_floor.dart';
import 'package:sique/presentation/screens/questionnaire_steps/adaptive_pacing_step.dart';
import 'package:sique/presentation/screens/questionnaire_steps/indian_dietary_step.dart';
import 'package:sique/utils/unit_formatter.dart';

void main() {
  group('AUD-05: Calorie Floor Clinical Guardrail (Step 19)', () {
    testWidgets('Disabled uncapped floor card is completely removed',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Step19CalorieFloor(
            isMale: true,
            initialFloorType: 'standard',
            onNext: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('step_19_floor_standard')), findsOneWidget);
      expect(find.byKey(const Key('step_19_floor_aggressive')), findsOneWidget);
      expect(find.byKey(const Key('step_19_floor_disabled')), findsNothing);
      expect(find.textContaining('No Lower Bound'), findsNothing);
    });

    testWidgets(
        'Male standard floor displays 1500 kcal, female displays 1200 kcal',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Step19CalorieFloor(
            isMale: true,
            initialFloorType: 'standard',
            onNext: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('1500 kcal'), findsOneWidget);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Step19CalorieFloor(
            isMale: false,
            initialFloorType: 'standard',
            onNext: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('1200 kcal'), findsOneWidget);
    });

    testWidgets('initialFloorType disabled falls back safely to standard',
        (tester) async {
      String? selectedFloor;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Step19CalorieFloor(
            isMale: false,
            initialFloorType: 'disabled',
            onNext: (floor) => selectedFloor = floor,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('step_19_continue_btn')));
      await tester.pumpAndSettle();
      expect(selectedFloor, equals('standard'));
    });
  });

  group('AUD-06: Dynamic Adaptive Pacing Calorie Deltas', () {
    testWidgets('Computes dynamic kcal surplus based on weight and rate',
        (tester) async {
      // 80 kg user with +0.25%/wk, +0.50%/wk, +0.75%/wk
      // 80 * 0.0025 * 1100 = 220 kcal surplus
      // 80 * 0.0050 * 1100 = 440 kcal surplus
      // 80 * 0.0075 * 1100 = 660 kcal surplus
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AdaptivePacingStep(
            selectedGoal: GoalType.muscleGain,
            weeklyRate: 0.50,
            currentWeightKg: 80.0,
            onRateSelected: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('~220 kcal surplus'), findsOneWidget);
      expect(find.textContaining('~440 kcal surplus'), findsOneWidget);
      expect(find.textContaining('~660 kcal surplus'), findsOneWidget);
      // Hardcoded strings must be absent
      expect(find.textContaining('~190 kcal surplus'), findsNothing);
      expect(find.textContaining('~380 kcal surplus'), findsNothing);
      expect(find.textContaining('~570 kcal surplus'), findsNothing);
    });

    testWidgets('Computes dynamic kcal deficit based on weight and rate',
        (tester) async {
      // 70 kg user with -0.50%/wk, -0.75%/wk, -1.00%/wk
      // 70 * 0.0050 * 1100 = 385 kcal deficit
      // 70 * 0.0075 * 1100 = 578 kcal deficit
      // 70 * 0.0100 * 1100 = 770 kcal deficit
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AdaptivePacingStep(
            selectedGoal: GoalType.fatLoss,
            weeklyRate: -0.75,
            currentWeightKg: 70.0,
            onRateSelected: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('~385 kcal/day'), findsOneWidget);
      expect(find.textContaining('~578 kcal deficit'), findsOneWidget);
      expect(find.textContaining('~770 kcal'), findsOneWidget);
    });
  });

  group('AUD-32: Nutritional Clamping with OilModifier.lowOil', () {
    test('Low calorie / low fat food never produces negative calories or fat',
        () {
      const lowCalFood = FoodItem(
        id: 999,
        uuid: 'food_test_low_cal',
        name: 'Black Coffee / Green Tea',
        category: 'Beverage',
        region: 'All',
        caloriesPer100g: 4.0,
        proteinPer100g: 0.2,
        carbsPer100g: 0.4,
        fatPer100g: 0.05,
        fiberPer100g: 0.0,
        iconSvg: 'i10.svg',
        source: 'test',
        aliases: '',
        portionUnits: [
          PortionUnit(
            id: 1,
            foodId: 999,
            unitName: 'cup',
            gramWeight: 100.0,
            isDefault: true,
          ),
        ],
      );

      final portionUnit = lowCalFood.portionUnits.first;
      // lowOil is -30 kcal, -3.3g fat.
      // 100g of black coffee is 4 kcal. 4 - 30 = -26 -> must clamp to 0.0
      final nutrition = lowCalFood.calculateNutrition(
        quantity: 1.0,
        unit: portionUnit,
        oilModifier: OilModifier.lowOil,
      );

      expect(nutrition.calories, equals(0.0));
      expect(nutrition.fat, equals(0.0));
      expect(nutrition.totalCalories, equals(0.0));
      expect(nutrition.totalFat, equals(0.0));
    });

    test('FoodLogEntry getters and copyWith enforce non-negative values', () {
      final entry = FoodLogEntry(
        id: 1,
        date: '2026-11-20',
        mealType: MealType.breakfast,
        foodId: 999,
        foodName: 'Test Food',
        servingQuantity: 1.0,
        unitName: 'Cup',
        gramWeight: 100.0,
        calories: 0.0,
        protein: 10.0,
        carbs: 5.0,
        fat: 0.0,
        fiber: 2.0,
        oilModifier: OilModifier.lowOil,
        loggedAt: DateTime.now(),
      );

      expect(entry.effectiveCalories, equals(0.0));
      expect(entry.effectiveFat, equals(0.0));

      final copied = entry.copyWith(calories: -15.0, fat: -2.0);
      expect(copied.effectiveCalories, equals(0.0));
      expect(copied.effectiveFat, equals(0.0));
    });
  });

  group('AUD-33: Vegan Oil Modifier Copy Adaptations', () {
    testWidgets('IndianDietaryStep adapts ghee copy to oil for Vegan users',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: IndianDietaryStep(
            dietSlug: 'vegan',
            stapleSlug: 'balanced',
            oilSlug: 'standard',
            onDietSelected: (_) {},
            onStapleSelected: (_) {},
            onOilSelected: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Standard (1 tbsp oil)'), findsOneWidget);
      expect(find.text('Standard (1 tbsp oil/ghee)'), findsNothing);
      expect(find.text('TYPICAL COOKING OIL HABIT'), findsOneWidget);
      expect(find.text('TYPICAL COOKING OIL / GHEE HABIT'), findsNothing);
    });

    testWidgets('IndianDietaryStep preserves ghee copy for Non-Vegan users',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: IndianDietaryStep(
            dietSlug: 'pure_veg',
            stapleSlug: 'balanced',
            oilSlug: 'standard',
            onDietSelected: (_) {},
            onStapleSelected: (_) {},
            onOilSelected: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Standard (1 tbsp oil/ghee)'), findsOneWidget);
      expect(find.text('TYPICAL COOKING OIL / GHEE HABIT'), findsOneWidget);
    });

    testWidgets('FoodLogSettingsScreen adapts oil copy for Vegan profile',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase.inMemory();
      addTearDown(() => db.close());

      const veganProfile = UserProfile(
        id: 'u_vegan',
        name: 'Vegan Athlete',
        currentWeightKg: 65.0,
        targetWeightKg: 60.0,
        heightCm: 170.0,
        age: 26,
        isMale: false,
        goalType: GoalType.fatLoss,
        programMode: ProgramMode.coached,
        weeklyRateOfChangePct: -0.5,
        proteinPreference: ProteinPreference.high,
        calorieFloor: 1200.0,
        baselineExpenditureKcal: 2000.0,
        dietType: 'vegan',
      );

      db.saveUserProfile(veganProfile);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          userProfileProvider.overrideWith((ref) => UserProfileNotifier(db)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: FoodLogSettingsScreen()),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Standard (1 tbsp oil, ~120 kcal)'), findsOneWidget);
      expect(find.text('Standard (1 tbsp oil/ghee, ~120 kcal)'), findsNothing);
    });
  });

  group('AUD-34: Centralized DomainValidator (BMI & Rate Limits)', () {
    test('calculateBmi and minSafeWeightKg match clinical standards', () {
      // 180 cm height -> 1.80 m
      // minSafeWeight = 18.5 * (1.80^2) = 18.5 * 3.24 = 59.94 kg
      final minWeight = DomainValidator.minSafeWeightKg(180.0);
      expect(minWeight, closeTo(59.94, 0.05));

      final bmiAt60kg = DomainValidator.calculateBmi(60.0, 180.0);
      expect(bmiAt60kg, greaterThanOrEqualTo(18.5));

      final bmiAt55kg = DomainValidator.calculateBmi(55.0, 180.0);
      expect(bmiAt55kg, lessThan(18.5));
      expect(DomainValidator.isUnderweightBmi(55.0, 180.0), isTrue);
    });

    test('validateTargetWeight blocks underweight target for fat loss', () {
      final invalidRes = DomainValidator.validateTargetWeight(
        targetWeightKg: 50.0,
        heightCm: 180.0,
        goalType: GoalType.fatLoss,
      );
      expect(invalidRes.isValid, isFalse);
      expect(invalidRes.errorMessage, contains('underweight range (< 18.5)'));

      final validRes = DomainValidator.validateTargetWeight(
        targetWeightKg: 65.0,
        heightCm: 180.0,
        goalType: GoalType.fatLoss,
      );
      expect(validRes.isValid, isTrue);
    });

    test(
        'validateRateOfChange and clampRateOfChange enforce physiological limits',
        () {
      expect(
        DomainValidator.validateRateOfChange(
          ratePct: -2.0,
          goalType: GoalType.fatLoss,
        ).isValid,
        isFalse,
      );
      expect(
        DomainValidator.validateRateOfChange(
          ratePct: -0.75,
          goalType: GoalType.fatLoss,
        ).isValid,
        isTrue,
      );

      expect(
        DomainValidator.clampRateOfChange(-2.5, GoalType.fatLoss),
        equals(-1.5),
      );
      expect(
        DomainValidator.clampRateOfChange(1.5, GoalType.muscleGain),
        equals(1.0),
      );
      expect(
        DomainValidator.clampRateOfChange(-0.5, GoalType.maintenance),
        equals(0.0),
      );
    });
  });

  group('AUD-36: Step03Dob Actual Date of Birth & Dynamic Age Lock', () {
    testWidgets(
        'Computes age dynamically from clockProvider and DOB dd/MM/yyyy',
        (tester) async {
      // Fixed clock: 2026-11-20
      final fixedClock = DateTime(2026, 11, 20);
      int? updatedAge;

      await tester.pumpWidget(ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(() => fixedClock),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Step03Dob(
              initialAge: 25,
              onNext: (age) => updatedAge = age,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Enter DOB: 20/11/2000 -> exactly 26 years old on 20/11/2026
      final dobField = find.byKey(const Key('step_03_dob_input'));
      expect(dobField, findsOneWidget);

      await tester.enterText(dobField, '20/11/2000');
      await tester.pumpAndSettle();

      expect(find.text('26'), findsOneWidget);

      // Continue enabled and submits 26
      await tester.tap(find.byKey(const Key('step_03_continue_btn')));
      await tester.pumpAndSettle();
      expect(updatedAge, equals(26));
    });

    testWidgets('Enforces adult 18+ lock when DOB indicates minor',
        (tester) async {
      final fixedClock = DateTime(2026, 11, 20);
      int? submittedAge;

      await tester.pumpWidget(ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(() => fixedClock),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Step03Dob(
              initialAge: 20,
              onNext: (age) => submittedAge = age,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Enter DOB: 20/11/2010 -> 16 years old (< 18)
      await tester.enterText(
          find.byKey(const Key('step_03_dob_input')), '20/11/2010');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('step_03_age_guardrail_banner')),
          findsOneWidget);
      expect(find.textContaining('adults 18 and older'), findsOneWidget);

      // Continue button must be disabled
      await tester.tap(find.byKey(const Key('step_03_continue_btn')));
      await tester.pumpAndSettle();
      expect(submittedAge, isNull);
    });
  });

  group('AUD-40: UnitFormatter Centralized Conversions & Date Parsing', () {
    test('formatDateDdMmYyyy and parseDateDdMmYyyy operate symmetrically', () {
      final date = DateTime(2026, 8, 15);
      final formatted = UnitFormatter.formatDateDdMmYyyy(date);
      expect(formatted, equals('15/08/2026'));

      final parsed = UnitFormatter.parseDateDdMmYyyy('15/08/2026');
      expect(parsed, isNotNull);
      expect(parsed!.year, equals(2026));
      expect(parsed.month, equals(8));
      expect(parsed.day, equals(15));
    });

    test('parseDateDdMmYyyy handles invalid dates safely', () {
      expect(UnitFormatter.parseDateDdMmYyyy(''), isNull);
      expect(UnitFormatter.parseDateDdMmYyyy('invalid-date'), isNull);
      expect(UnitFormatter.parseDateDdMmYyyy('31/02/2026'), isNull); // Feb 31
      expect(UnitFormatter.parseDateDdMmYyyy('32/01/2026'), isNull); // Day 32
      expect(UnitFormatter.parseDateDdMmYyyy('15/13/2026'), isNull); // Month 13
    });

    test('Weight formatting and conversions (kg vs lbs)', () {
      expect(
          UnitFormatter.formatWeight(70.0, useLbs: false), equals('70.0 kg'));
      expect(
          UnitFormatter.formatWeight(70.0, useLbs: true), equals('154.3 lbs'));

      expect(UnitFormatter.kgToLbs(100.0), closeTo(220.46, 0.05));
      expect(UnitFormatter.lbsToKg(220.462), closeTo(100.0, 0.05));
    });

    test('Height formatting and conversions (cm vs ft/in)', () {
      expect(UnitFormatter.formatHeight(175.0, useImperial: false),
          equals('175 cm'));
      expect(UnitFormatter.formatHeight(175.0, useImperial: true),
          equals('5 ft 9 in'));

      final imperial = UnitFormatter.cmToFeetInches(182.88);
      expect(imperial.feet, equals(6));
      expect(imperial.inches, closeTo(0.0, 0.1));

      final cm = UnitFormatter.feetInchesToCm(6, 0.0);
      expect(cm, closeTo(182.88, 0.1));
    });
  });
}
