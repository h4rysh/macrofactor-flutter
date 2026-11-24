import 'package:flutter_test/flutter_test.dart';
import 'package:sique/domain/algorithms/coaching_engine.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/domain/models/user_profile.dart';

void main() {
  group('CoachingEngine - Flux Damping & Physiological Safety Tests', () {
    test('Positive surge is clamped to asymmetric maximum (+150 kcal)', () {
      final result = CoachingEngine.computeDampedAdjustment(
        currentAvgCalories: 2000.0,
        unconstrainedTargetCalories: 2400.0, // raw +400
        kalmanConfidence: 1.0,
        calorieFloor: 1200.0,
        silentRecompActive: false,
      );

      expect(result.rawDelta, 400.0);
      expect(result.appliedDelta, 150.0);
      expect(result.recommendedCalories, 2150.0);
      expect(result.wasClamped, isTrue);
      expect(result.status, AdjustmentStatus.clamped);
    });

    test('Negative drop is clamped to asymmetric minimum (-100 kcal)', () {
      final result = CoachingEngine.computeDampedAdjustment(
        currentAvgCalories: 2200.0,
        unconstrainedTargetCalories: 1900.0, // raw -300
        kalmanConfidence: 1.0,
        calorieFloor: 1200.0,
        silentRecompActive: false,
      );

      expect(result.rawDelta, -300.0);
      expect(result.appliedDelta, -100.0);
      expect(result.recommendedCalories, 2100.0);
      expect(result.wasClamped, isTrue);
      expect(result.status, AdjustmentStatus.clamped);
    });

    test('Deadband filter holds program when raw delta is within [-20, +20 kcal]', () {
      final positiveNoise = CoachingEngine.computeDampedAdjustment(
        currentAvgCalories: 2100.0,
        unconstrainedTargetCalories: 2115.0, // +15 kcal noise
        kalmanConfidence: 1.0,
        calorieFloor: 1200.0,
        silentRecompActive: false,
      );

      expect(positiveNoise.appliedDelta, 0.0);
      expect(positiveNoise.recommendedCalories, 2100.0);
      expect(positiveNoise.status, AdjustmentStatus.deadbandHold);

      final negativeNoise = CoachingEngine.computeDampedAdjustment(
        currentAvgCalories: 2100.0,
        unconstrainedTargetCalories: 2085.0, // -15 kcal noise
        kalmanConfidence: 1.0,
        calorieFloor: 1200.0,
        silentRecompActive: false,
      );

      expect(negativeNoise.appliedDelta, 0.0);
      expect(negativeNoise.recommendedCalories, 2100.0);
      expect(negativeNoise.status, AdjustmentStatus.deadbandHold);
    });

    test('Low Kalman confidence attenuates raw adjustment', () {
      // Confidence factor = 0.50 + (0.50 * 0.50) = 0.75
      // Raw delta = +80 kcal -> attenuated = 80 * 0.75 = 60 kcal
      final lowConfidence = CoachingEngine.computeDampedAdjustment(
        currentAvgCalories: 2000.0,
        unconstrainedTargetCalories: 2080.0,
        kalmanConfidence: 0.50,
        calorieFloor: 1200.0,
        silentRecompActive: false,
      );

      expect(lowConfidence.rawDelta, 80.0);
      expect(lowConfidence.appliedDelta, 60.0);
      expect(lowConfidence.recommendedCalories, 2060.0);
      expect(lowConfidence.status, AdjustmentStatus.adjusted);
      expect(lowConfidence.wasClamped, isFalse);
    });

    test('Silent recomposition guard stops calorie cuts to preserve muscle mass', () {
      final result = CoachingEngine.computeDampedAdjustment(
        currentAvgCalories: 2100.0,
        unconstrainedTargetCalories: 1950.0, // raw -150 cut
        kalmanConfidence: 1.0,
        calorieFloor: 1200.0,
        silentRecompActive: true,
      );

      expect(result.rawDelta, -150.0);
      expect(result.appliedDelta, 0.0);
      expect(result.recommendedCalories, 2100.0);
      expect(result.status, AdjustmentStatus.silentRecompHold);
      expect(result.reason, contains('Calories held to preserve muscle gain'));
    });

    test('Silent recomposition allows surplus adjustments if gaining weight', () {
      final result = CoachingEngine.computeDampedAdjustment(
        currentAvgCalories: 2100.0,
        unconstrainedTargetCalories: 2200.0, // +100
        kalmanConfidence: 1.0,
        calorieFloor: 1200.0,
        silentRecompActive: true,
      );

      expect(result.appliedDelta, 100.0);
      expect(result.recommendedCalories, 2200.0);
      expect(result.status, AdjustmentStatus.adjusted);
    });

    test('Calorie floor protection prevents adjustments below floor', () {
      final result = CoachingEngine.computeDampedAdjustment(
        currentAvgCalories: 1250.0,
        unconstrainedTargetCalories: 1100.0, // raw -150
        kalmanConfidence: 1.0,
        calorieFloor: 1200.0,
        silentRecompActive: false,
      );

      // Raw is -150, clamped is -100 (1150), but floor is 1200 -> clamped to 1200 (delta -50)
      expect(result.recommendedCalories, 1200.0);
      expect(result.appliedDelta, -50.0);
      expect(result.wasClamped, isTrue);
    });
  });

  group('CoachingEngine - evaluateWeeklyCheckIn Integration with Damping', () {
    const profile = UserProfile(
      id: 'athlete_damping',
      name: 'Damping Athlete',
      age: 26,
      isMale: true,
      heightCm: 180,
      currentWeightKg: 80.0,
      targetWeightKg: 75.0,
      goalType: GoalType.fatLoss,
      weeklyRateOfChangePct: -0.5,
      proteinPreference: ProteinPreference.high,
      programMode: ProgramMode.coached,
      calorieFloor: 1300.0,
      baselineExpenditureKcal: 2600.0,
    );

    test('Propagates damped audit fields to CheckInRecommendation', () {
      final now = DateTime.now();
      final program = CoachingEngine.buildWeeklyProgram(
        profile: profile,
        expenditureKcal: 2600.0,
        style: MacroProgramStyle.balanced,
        allocationType: DayAllocationType.even,
        workoutDays: const {1, 3, 5},
        programStartDate: now.subtract(const Duration(days: 10)),
        lastCheckInDate: now.subtract(const Duration(days: 8)),
        customDailyAverage: 2500.0,
      );

      final rec = CoachingEngine.evaluateWeeklyCheckIn(
        currentProgram: program,
        profile: profile,
        currentExpenditureKcal: 2200.0, // drops target significantly
        currentDate: now,
        kalmanConfidence: 0.95,
        silentRecompActive: false,
      );

      expect(rec.isDue, isTrue);
      expect(rec.rawCalorieDelta, isNotNull);
      expect(rec.dampedCalorieDelta, isNotNull);
      expect(rec.wasClamped, isTrue);
      expect(rec.dampedCalorieDelta, -100.0); // clamped to -100 max drop
    });
  });
}
