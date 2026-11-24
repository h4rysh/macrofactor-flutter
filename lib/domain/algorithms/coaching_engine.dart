import 'dart:math' as math;
import 'package:meta/meta.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/domain/models/user_profile.dart';

/// Lifecycle status of a weekly metabolic calorie adjustment.
enum AdjustmentStatus {
  adjusted,
  clamped,
  deadbandHold,
  silentRecompHold,
}

/// Result payload of flux-damped metabolic adjustments.
@immutable
class DampedAdjustmentResult {
  const DampedAdjustmentResult({
    required this.recommendedCalories,
    required this.appliedDelta,
    required this.rawDelta,
    required this.status,
    required this.reason,
    this.wasClamped = false,
  });

  final double recommendedCalories;
  final double appliedDelta;
  final double rawDelta;
  final AdjustmentStatus status;
  final String reason;
  final bool wasClamped;
}

/// Recommendation payload generated during a coaching check-in.
@immutable
class CheckInRecommendation {
  const CheckInRecommendation({
    required this.isDue,
    required this.daysUntilNextCheckIn,
    required this.currentExpenditureKcal,
    required this.previousAverageCalories,
    required this.recommendedAverageCalories,
    required this.calorieDelta,
    required this.metabolicInsight,
    required this.suggestedProgram,
    this.rawCalorieDelta,
    this.dampedCalorieDelta,
    this.wasClamped = false,
    this.silentRecompDetected = false,
  });

  final bool isDue;
  final int daysUntilNextCheckIn;
  final double currentExpenditureKcal;
  final double previousAverageCalories;
  final double recommendedAverageCalories;
  final double calorieDelta;
  final String metabolicInsight;
  final WeeklyMacroProgram suggestedProgram;
  final double? rawCalorieDelta;
  final double? dampedCalorieDelta;
  final bool wasClamped;
  final bool silentRecompDetected;
}

/// Core reverse-engineered coaching engine for Sique.
/// Implements program styles, day shifting (with weekly energy conservation),
/// and algorithmic weekly metabolic check-in recalculations.
class CoachingEngine {
  const CoachingEngine._();

  static const List<String> _dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  /// Calculates baseline daily average calories for a user profile and Bayesian expenditure.
  static double calculateDailyAverageCalories({
    required UserProfile profile,
    required double expenditureKcal,
  }) {
    if (profile.customCalories != null) {
      return profile.customCalories!.roundToDouble();
    }

    double dailyEnergyDeltaKcal;
    switch (profile.goalType) {
      case GoalType.fatLoss:
        final weeklyKgLoss = profile.currentWeightKg *
            (profile.weeklyRateOfChangePct.abs() / 100.0);
        dailyEnergyDeltaKcal = -(weeklyKgLoss * 1100.0);
        break;
      case GoalType.maintenance:
        dailyEnergyDeltaKcal = 0.0;
        break;
      case GoalType.muscleGain:
        final weeklyKgGain = profile.currentWeightKg *
            (profile.weeklyRateOfChangePct.abs() / 100.0);
        dailyEnergyDeltaKcal = (weeklyKgGain * 1100.0);
        break;
    }

    final rawTarget = expenditureKcal + dailyEnergyDeltaKcal;
    return rawTarget.clamp(profile.calorieFloor, 6500.0).roundToDouble();
  }

  /// Calculates daily macronutrients based on caloric budget, body mass, and program style.
  static MacroTarget computeDayMacros({
    required double calories,
    required double weightKg,
    required MacroProgramStyle style,
    required ProteinPreference proteinPref,
    bool isWorkoutDay = false,
  }) {
    double proteinGrams;
    double fatGrams;
    double carbsGrams = 0.0;

    // Physiological floors
    final double minProteinGrams = math.max(30.0, weightKg * 1.0);
    final double minFatGrams = math.max(20.0, weightKg * 0.4);
    final double minCarbsGrams = switch (style) {
      MacroProgramStyle.keto => 20.0,
      MacroProgramStyle.lowCarb => 30.0,
      _ => math.max(20.0, (calories * 0.10) / 4.0),
    };

    switch (style) {
      case MacroProgramStyle.balanced:
        // Protein: standard tier (1.6 - 2.4 g/kg)
        proteinGrams = (proteinPref.gramsPerKg * weightKg).roundToDouble();
        // Fat: ~28% of calories
        final fatCalories = calories * 0.28;
        fatGrams = (fatCalories / 9.0).roundToDouble();
        break;

      case MacroProgramStyle.lowFat:
        proteinGrams = (proteinPref.gramsPerKg * weightKg).roundToDouble();
        // Fat minimized to ~18% of calories
        final fatCalories = calories * 0.18;
        fatGrams = (fatCalories / 9.0).roundToDouble();
        break;

      case MacroProgramStyle.lowCarb:
        proteinGrams = (proteinPref.gramsPerKg * weightKg).roundToDouble();
        // Carbs restricted to 20% of calories or 40-140g
        final carbCals = calories * 0.20;
        carbsGrams = (carbCals / 4.0).clamp(40.0, 140.0).roundToDouble();
        final remForFat = calories - (proteinGrams * 4.0) - (carbsGrams * 4.0);
        fatGrams = (remForFat / 9.0).roundToDouble();
        break;

      case MacroProgramStyle.keto:
        proteinGrams = (proteinPref.gramsPerKg * weightKg).roundToDouble();
        // Strict carb ceiling: 25g - 45g net carbs
        carbsGrams = (calories * 0.05 / 4.0).clamp(25.0, 45.0).roundToDouble();
        final remForFat = calories - (proteinGrams * 4.0) - (carbsGrams * 4.0);
        fatGrams = (remForFat / 9.0).roundToDouble();
        break;

      case MacroProgramStyle.highProtein:
        // Elevated protein: 2.4 - 2.8 g/kg
        final elevatedFactor = (proteinPref.gramsPerKg * 1.25).clamp(2.4, 2.8);
        proteinGrams = (elevatedFactor * weightKg).roundToDouble();
        final fatCalories = calories * 0.25;
        fatGrams = (fatCalories / 9.0).roundToDouble();
        break;
    }

    if (style == MacroProgramStyle.keto || style == MacroProgramStyle.lowCarb) {
      final maxAvailableForProtein =
          calories - (carbsGrams * 4.0) - (minFatGrams * 9.0);
      if (proteinGrams * 4.0 > maxAvailableForProtein) {
        proteinGrams = math.max(
          minProteinGrams,
          (maxAvailableForProtein / 4.0).roundToDouble(),
        );
        final remForFat = calories - (proteinGrams * 4.0) - (carbsGrams * 4.0);
        fatGrams = math.max(minFatGrams, (remForFat / 9.0).roundToDouble());
      }
      final remForCarbs = calories - (proteinGrams * 4.0) - (fatGrams * 9.0);
      carbsGrams = math.max(0.0, (remForCarbs / 4.0).roundToDouble());
    } else {
      final maxAvailableForProteinFat = calories - (minCarbsGrams * 4.0);
      final currentProteinFatCals = (proteinGrams * 4.0) + (fatGrams * 9.0);

      if (currentProteinFatCals > maxAvailableForProteinFat) {
        final minProteinCals = minProteinGrams * 4.0;
        final minFatCals = minFatGrams * 9.0;
        final baseFloorCals = minProteinCals + minFatCals;

        if (maxAvailableForProteinFat <= baseFloorCals) {
          final scale =
              (maxAvailableForProteinFat / baseFloorCals).clamp(0.4, 1.0);
          proteinGrams =
              math.max(30.0, (minProteinGrams * scale).roundToDouble());
          fatGrams = math.max(20.0, (minFatGrams * scale).roundToDouble());
        } else {
          final excess = currentProteinFatCals - baseFloorCals;
          final allowedSurplus = maxAvailableForProteinFat - baseFloorCals;
          final scale = (allowedSurplus / excess).clamp(0.0, 1.0);
          proteinGrams =
              (minProteinGrams + (proteinGrams - minProteinGrams) * scale)
                  .roundToDouble();
          fatGrams =
              (minFatGrams + (fatGrams - minFatGrams) * scale).roundToDouble();
        }
      }

      final remForCarbs = calories - (proteinGrams * 4.0) - (fatGrams * 9.0);
      carbsGrams = math.max(0.0, (remForCarbs / 4.0).roundToDouble());
    }

    final targetCals = calories.roundToDouble();
    var p = proteinGrams.clamp(30.0, 1000.0).roundToDouble();
    var f = fatGrams.clamp(20.0, 1000.0).roundToDouble();
    var c = carbsGrams.clamp(0.0, 2000.0).roundToDouble();

    // Reconcile integer macro targets so that |4P + 9F + 4C - calories| <= 2.0 kcal
    // (while respecting P >= 30, F >= 20, C >= 0).
    // Adjust carbohydrate grams (or fat grams if carbs would be negative)
    // by the residual difference divided by 4 (or 9).
    var residual = targetCals - ((p * 4.0) + (f * 9.0) + (c * 4.0));
    if (residual.abs() > 2.0) {
      final carbAdjustment = (residual / 4.0).roundToDouble();
      if (c + carbAdjustment >= 0.0) {
        c += carbAdjustment;
      } else {
        // Carbs would be negative: clamp carbs to 0 and adjust fat with residual
        c = 0.0;
        residual = targetCals - ((p * 4.0) + (f * 9.0));
        final fatAdjustment = (residual / 9.0).roundToDouble();
        f = math.max(20.0, f + fatAdjustment);
      }
    }

    // Guard pass to ensure |4P + 9F + 4C - calories| <= 2.0 kcal
    int guardIterations = 0;
    while (((p * 4.0) + (f * 9.0) + (c * 4.0) - targetCals).abs() > 2.0 &&
        guardIterations < 20) {
      guardIterations++;
      final diff = targetCals - ((p * 4.0) + (f * 9.0) + (c * 4.0));
      if (diff > 2.0) {
        c += 1.0;
      } else if (diff < -2.0) {
        if (c >= 1.0) {
          c -= 1.0;
        } else if (f > 20.0) {
          f -= 1.0;
        } else if (p > 30.0) {
          p -= 1.0;
        } else {
          break;
        }
      }
    }

    return MacroTarget(
      calories: targetCals,
      proteinGrams: p,
      carbsGrams: c,
      fatGrams: f,
    );
  }

  /// Builds a complete 7-day WeeklyMacroProgram preserving the weekly energy budget.
  static WeeklyMacroProgram buildWeeklyProgram({
    required UserProfile profile,
    required double expenditureKcal,
    required MacroProgramStyle style,
    required DayAllocationType allocationType,
    required Set<int> workoutDays,
    DateTime? programStartDate,
    DateTime? lastCheckInDate,
    int checkInDayOfWeek = 1, // Default Monday
    double? customDailyAverage,
  }) {
    final dailyAvgCalories = customDailyAverage ??
        calculateDailyAverageCalories(
          profile: profile,
          expenditureKcal: expenditureKcal,
        );

    final totalWeeklyBudget = dailyAvgCalories * 7.0;
    final List<DayMacroTarget> days = [];

    // Distribute calories per day based on allocation type
    final Map<int, double> dayCaloriesMap = {};

    switch (allocationType) {
      case DayAllocationType.even:
        for (int day = 1; day <= 7; day++) {
          dayCaloriesMap[day] = dailyAvgCalories;
        }
        break;

      case DayAllocationType.shiftedWorkout:
        final numWorkoutDays = workoutDays.length;
        if (numWorkoutDays == 0 || numWorkoutDays == 7) {
          // If all days or no days are workouts, shift is meaningless -> even
          for (int day = 1; day <= 7; day++) {
            dayCaloriesMap[day] =
                math.max(profile.calorieFloor, dailyAvgCalories);
          }
        } else {
          final numRestDays = 7 - numWorkoutDays;
          final maxRestReduction =
              math.max(0.0, dailyAvgCalories - profile.calorieFloor);
          var workoutBoost = (dailyAvgCalories * 0.09).clamp(150.0, 300.0);
          var totalWorkoutSurplus = workoutBoost * numWorkoutDays;
          var restDayReduction = totalWorkoutSurplus / numRestDays;

          if (restDayReduction > maxRestReduction) {
            restDayReduction = maxRestReduction;
            workoutBoost = numWorkoutDays > 0
                ? (restDayReduction * numRestDays) / numWorkoutDays
                : 0.0;
          }

          final workoutCals = math.max(
            profile.calorieFloor,
            (dailyAvgCalories + workoutBoost).roundToDouble(),
          );
          final restCals = math.max(
            profile.calorieFloor,
            (dailyAvgCalories - restDayReduction).roundToDouble(),
          );

          // Apply and ensure conservation by absorbing rounding in Sunday
          double assignedSum = 0.0;
          for (int day = 1; day <= 7; day++) {
            final isWorkout = workoutDays.contains(day);
            final cals = isWorkout ? workoutCals : restCals;
            dayCaloriesMap[day] = cals;
            assignedSum += cals;
          }

          // Adjust Sunday so sum exactly equals totalWeeklyBudget, strictly respecting floor
          final delta = totalWeeklyBudget - assignedSum;
          final sundayTarget =
              ((dayCaloriesMap[7] ?? dailyAvgCalories) + delta).roundToDouble();
          if (sundayTarget >= profile.calorieFloor) {
            dayCaloriesMap[7] = sundayTarget;
          } else {
            dayCaloriesMap[7] = profile.calorieFloor;
            var remainingDeficit = profile.calorieFloor - sundayTarget;
            // Redistribute remaining deficit across non-floor days (from Sat down to Mon)
            for (int day = 6; day >= 1 && remainingDeficit > 0; day--) {
              final current = dayCaloriesMap[day] ?? dailyAvgCalories;
              final canReduce = current - profile.calorieFloor;
              if (canReduce > 0) {
                final reduction = math.min(canReduce, remainingDeficit);
                dayCaloriesMap[day] = (current - reduction).roundToDouble();
                remainingDeficit -= reduction;
              }
            }
          }
        }
        break;

      case DayAllocationType.weekendShift:
        // Friday (5), Saturday (6), Sunday (7) get +220 kcal
        const weekendDays = {5, 6, 7};
        final maxWeekdayReduction =
            math.max(0.0, dailyAvgCalories - profile.calorieFloor);
        var weekendBoost = 220.0;
        var totalWeekendSurplus = weekendBoost * 3.0; // 660 kcal
        var weekdayReduction = totalWeekendSurplus / 4.0; // 165 kcal

        if (weekdayReduction > maxWeekdayReduction) {
          weekdayReduction = maxWeekdayReduction;
          weekendBoost = (weekdayReduction * 4.0) / 3.0;
        }

        double assignedWeekendSum = 0.0;
        for (int day = 1; day <= 7; day++) {
          if (weekendDays.contains(day)) {
            dayCaloriesMap[day] = math.max(
              profile.calorieFloor,
              (dailyAvgCalories + weekendBoost).roundToDouble(),
            );
          } else {
            dayCaloriesMap[day] = math.max(
              profile.calorieFloor,
              (dailyAvgCalories - weekdayReduction).roundToDouble(),
            );
          }
          assignedWeekendSum += dayCaloriesMap[day]!;
        }

        // Adjust Sunday so sum exactly equals totalWeeklyBudget, strictly respecting floor
        final weekendDelta = totalWeeklyBudget - assignedWeekendSum;
        final sundayWeekendTarget =
            ((dayCaloriesMap[7] ?? dailyAvgCalories) + weekendDelta)
                .roundToDouble();
        if (sundayWeekendTarget >= profile.calorieFloor) {
          dayCaloriesMap[7] = sundayWeekendTarget;
        } else {
          dayCaloriesMap[7] = profile.calorieFloor;
          var remainingDeficit = profile.calorieFloor - sundayWeekendTarget;
          for (int day = 6; day >= 1 && remainingDeficit > 0; day--) {
            final current = dayCaloriesMap[day] ?? dailyAvgCalories;
            final canReduce = current - profile.calorieFloor;
            if (canReduce > 0) {
              final reduction = math.min(canReduce, remainingDeficit);
              dayCaloriesMap[day] = (current - reduction).roundToDouble();
              remainingDeficit -= reduction;
            }
          }
        }
        break;

      case DayAllocationType.custom:
        for (int day = 1; day <= 7; day++) {
          dayCaloriesMap[day] =
              math.max(profile.calorieFloor, dailyAvgCalories);
        }
        break;
    }

    // Build the 7 DayMacroTargets
    for (int day = 1; day <= 7; day++) {
      final isWorkout = workoutDays.contains(day);
      final cals = math.max(
          profile.calorieFloor, dayCaloriesMap[day] ?? dailyAvgCalories);
      final macros = computeDayMacros(
        calories: cals,
        weightKg: profile.currentWeightKg,
        style: style,
        proteinPref: profile.proteinPreference,
        isWorkoutDay: isWorkout,
      );

      days.add(DayMacroTarget(
        dayOfWeek: day,
        dayName: _dayNames[day - 1],
        isWorkoutDay: isWorkout,
        calories: macros.calories,
        proteinGrams: macros.proteinGrams,
        carbsGrams: macros.carbsGrams,
        fatGrams: macros.fatGrams,
      ));
    }

    final now = DateTime.now();
    return WeeklyMacroProgram(
      id: 'prog_${now.millisecondsSinceEpoch}',
      style: style,
      mode: profile.programMode,
      allocationType: allocationType,
      workoutDays: workoutDays,
      dailyAverageCalories: dailyAvgCalories,
      days: days,
      createdAt: programStartDate ?? now,
      lastCheckInDate: lastCheckInDate ?? now,
      checkInDayOfWeek: checkInDayOfWeek,
    );
  }

  /// Computes physiological flux-damped calorie adjustment.
  /// Applies a confidence-weighted attenuation, a 20 kcal cognitive deadband,
  /// asymmetric clamping ([-100 kcal, +150 kcal]), and silent recomposition protection.
  static DampedAdjustmentResult computeDampedAdjustment({
    required double currentAvgCalories,
    required double unconstrainedTargetCalories,
    required double kalmanConfidence,
    required double calorieFloor,
    required bool silentRecompActive,
  }) {
    final rawDelta = unconstrainedTargetCalories - currentAvgCalories;

    // 1. Silent Recomposition Guard Override
    if (silentRecompActive && rawDelta < 0) {
      return DampedAdjustmentResult(
        recommendedCalories: currentAvgCalories,
        appliedDelta: 0.0,
        rawDelta: rawDelta,
        status: AdjustmentStatus.silentRecompHold,
        reason:
            'Waist circumference decreased despite scale weight plateau. Calories held to preserve muscle gain.',
      );
    }

    // 2. Cognitive Deadband Filter (Disregard noise < 20 kcal)
    if (rawDelta.abs() < 20.0) {
      return DampedAdjustmentResult(
        recommendedCalories: currentAvgCalories,
        appliedDelta: 0.0,
        rawDelta: rawDelta,
        status: AdjustmentStatus.deadbandHold,
        reason:
            'Your metabolism is tracking steadily within optimal tolerance (delta < 20 kcal). Your current program remains optimal.',
      );
    }

    // 3. Confidence Attenuation Factor: Gamma in [0.5, 1.0]
    final gamma = 0.5 + (0.5 * kalmanConfidence.clamp(0.0, 1.0));
    var scaledDelta = rawDelta * gamma;

    // 4. Asymmetric Physiological Clamping: [-100 kcal, +150 kcal]
    bool wasClamped = false;
    if (scaledDelta < -100.0) {
      scaledDelta = -100.0;
      wasClamped = true;
    } else if (scaledDelta > 150.0) {
      scaledDelta = 150.0;
      wasClamped = true;
    }

    // 5. Physiological Floor Protection
    var finalTarget = (currentAvgCalories + scaledDelta).roundToDouble();
    if (finalTarget < calorieFloor) {
      finalTarget = calorieFloor;
      scaledDelta = calorieFloor - currentAvgCalories;
      wasClamped = true;
    }

    final String reason;
    if (wasClamped) {
      reason = scaledDelta > 0
          ? 'Your dynamic expenditure has risen (+${scaledDelta.round()} kcal/day). Adjustment safety-damped to prevent metabolic whiplash.'
          : 'Your metabolic adaptation suggests an adjustment (${scaledDelta.round()} kcal/day). Adjustment safety-damped to prevent metabolic whiplash.';
    } else if (scaledDelta > 0) {
      reason =
          'Your dynamic expenditure has risen to ${finalTarget.round()} kcal/day (+${scaledDelta.round()} kcal intake recommended).';
    } else {
      reason =
          'Your metabolic adaptation suggests a target adjustment of ${scaledDelta.round()} kcal/day to stay on pace.';
    }

    return DampedAdjustmentResult(
      recommendedCalories: finalTarget,
      appliedDelta: scaledDelta,
      rawDelta: rawDelta,
      status: wasClamped ? AdjustmentStatus.clamped : AdjustmentStatus.adjusted,
      wasClamped: wasClamped,
      reason: reason,
    );
  }

  /// Evaluates weekly check-in status and calculates new metabolic adjustments.
  static CheckInRecommendation evaluateWeeklyCheckIn({
    required WeeklyMacroProgram currentProgram,
    required UserProfile profile,
    required double currentExpenditureKcal,
    required DateTime currentDate,
    double kalmanConfidence = 1.0,
    bool silentRecompActive = false,
  }) {
    final daysSinceCheckIn =
        currentDate.difference(currentProgram.lastCheckInDate).inDays;
    final isDue = daysSinceCheckIn >= 7;
    final daysUntilNext = isDue ? 0 : (7 - daysSinceCheckIn).clamp(0, 7);

    // Compute raw unconstrained target from Bayesian expenditure
    final rawTarget = calculateDailyAverageCalories(
      profile: profile,
      expenditureKcal: currentExpenditureKcal,
    );

    // Apply Confidence-Weighted Flux Damping Operator
    final damped = computeDampedAdjustment(
      currentAvgCalories: currentProgram.dailyAverageCalories,
      unconstrainedTargetCalories: rawTarget,
      kalmanConfidence: kalmanConfidence,
      calorieFloor: profile.calorieFloor,
      silentRecompActive: silentRecompActive,
    );

    final suggestedProgram = buildWeeklyProgram(
      profile: profile,
      expenditureKcal: currentExpenditureKcal,
      style: currentProgram.style,
      allocationType: currentProgram.allocationType,
      workoutDays: currentProgram.workoutDays,
      programStartDate: currentProgram.createdAt,
      lastCheckInDate: currentDate,
      checkInDayOfWeek: currentProgram.checkInDayOfWeek,
      customDailyAverage: damped.recommendedCalories,
    );

    return CheckInRecommendation(
      isDue: isDue,
      daysUntilNextCheckIn: daysUntilNext,
      currentExpenditureKcal: currentExpenditureKcal,
      previousAverageCalories: currentProgram.dailyAverageCalories,
      recommendedAverageCalories: damped.recommendedCalories,
      calorieDelta: damped.appliedDelta,
      metabolicInsight: damped.reason,
      suggestedProgram: suggestedProgram,
      rawCalorieDelta: damped.rawDelta,
      dampedCalorieDelta: damped.appliedDelta,
      wasClamped: damped.wasClamped,
      silentRecompDetected: silentRecompActive,
    );
  }
}
