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
  /// Honors Manual custom calories, active Diet Breaks (1.0x TDEE maintenance),
  /// and Reverse Diet weekly ramp pacing when climbing back toward expenditure.
  static double calculateDailyAverageCalories({
    required UserProfile profile,
    required double expenditureKcal,
    double? previousAvgCalories,
    bool applyReverseRamp = true,
  }) {
    if (profile.customCalories != null && profile.customCalories!.isFinite) {
      return profile.customCalories!.clamp(400.0, 10000.0).roundToDouble();
    }

    if (profile.isInDietBreak) {
      return expenditureKcal
          .clamp(profile.calorieFloor, 6500.0)
          .roundToDouble();
    }

    if (profile.reverseDietPacing != 'none' &&
        previousAvgCalories != null &&
        previousAvgCalories > 0) {
      if (previousAvgCalories >= expenditureKcal) {
        return expenditureKcal
            .clamp(profile.calorieFloor, 6500.0)
            .roundToDouble();
      }
      if (!applyReverseRamp) {
        final upper = math.max(profile.calorieFloor, expenditureKcal);
        return previousAvgCalories
            .clamp(profile.calorieFloor, upper)
            .roundToDouble();
      }
      final rampPct = switch (profile.reverseDietPacing) {
        'conservative' => 0.025,
        'moderate' => 0.05,
        'aggressive' => 0.08,
        _ => 0.0,
      };
      if (rampPct > 0) {
        final ramped = math.min(
          expenditureKcal,
          previousAvgCalories * (1.0 + rampPct),
        );
        return ramped.clamp(profile.calorieFloor, 6500.0).roundToDouble();
      }
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
  /// When [carbShareOverride] is provided (e.g. Collaborative mode slider in `[0.2, 0.85]`),
  /// distributes non-protein calories smoothly by that carb-to-fat ratio.
  static MacroTarget computeDayMacros({
    required double calories,
    required double weightKg,
    required MacroProgramStyle style,
    required ProteinPreference proteinPref,
    bool isWorkoutDay = false,
    double? carbShareOverride,
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

    if (carbShareOverride != null) {
      proteinGrams = (proteinPref.gramsPerKg * weightKg).roundToDouble();
      final remainingCals = math.max(0.0, calories - (proteinGrams * 4.0));
      final share = carbShareOverride.clamp(0.15, 0.85);
      carbsGrams = math.max(
        minCarbsGrams,
        ((remainingCals * share) / 4.0).roundToDouble(),
      );
      fatGrams = math.max(
        minFatGrams,
        ((remainingCals * (1.0 - share)) / 9.0).roundToDouble(),
      );
    } else {
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
          final remForFat =
              calories - (proteinGrams * 4.0) - (carbsGrams * 4.0);
          fatGrams = (remForFat / 9.0).roundToDouble();
          break;

        case MacroProgramStyle.keto:
          proteinGrams = (proteinPref.gramsPerKg * weightKg).roundToDouble();
          // Strict carb ceiling: 25g - 45g net carbs
          carbsGrams =
              (calories * 0.05 / 4.0).clamp(25.0, 45.0).roundToDouble();
          final remForFat =
              calories - (proteinGrams * 4.0) - (carbsGrams * 4.0);
          fatGrams = (remForFat / 9.0).roundToDouble();
          break;

        case MacroProgramStyle.highProtein:
          // Elevated protein: 2.4 - 2.8 g/kg
          final elevatedFactor =
              (proteinPref.gramsPerKg * 1.25).clamp(2.4, 2.8);
          proteinGrams = (elevatedFactor * weightKg).roundToDouble();
          final fatCalories = calories * 0.25;
          fatGrams = (fatCalories / 9.0).roundToDouble();
          break;
      }
    }

    if (carbShareOverride == null &&
        (style == MacroProgramStyle.keto ||
            style == MacroProgramStyle.lowCarb)) {
      final carbCap = style == MacroProgramStyle.keto ? 35.0 : 120.0;
      carbsGrams = carbsGrams.clamp(0.0, carbCap);
      final minProteinCals = minProteinGrams * 4.0;
      final minFatCals = minFatGrams * 9.0;
      final availableForProteinFat =
          math.max(0.0, calories - (carbsGrams * 4.0));
      if (availableForProteinFat < (minProteinCals + minFatCals)) {
        final floorCals = minProteinCals + minFatCals;
        final scale = floorCals > 0
            ? (availableForProteinFat / floorCals).clamp(0.3, 1.0)
            : 1.0;
        proteinGrams =
            math.max(30.0, (minProteinGrams * scale).roundToDouble());
        fatGrams = math.max(20.0, (minFatGrams * scale).roundToDouble());
      } else {
        final maxAvailableForProtein = availableForProteinFat - minFatCals;
        if (proteinGrams * 4.0 > maxAvailableForProtein) {
          proteinGrams = math.max(
            minProteinGrams,
            (maxAvailableForProtein / 4.0).roundToDouble(),
          );
        }
        final remForFat = calories - (proteinGrams * 4.0) - (carbsGrams * 4.0);
        fatGrams = math.max(minFatGrams, (remForFat / 9.0).roundToDouble());
      }
      final remForCarbs = calories - (proteinGrams * 4.0) - (fatGrams * 9.0);
      carbsGrams = math
          .max(0.0, (remForCarbs / 4.0).roundToDouble())
          .clamp(0.0, carbCap);
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
    double? carbShareOverride,
    double? previousAvgCalories,
    bool applyReverseRamp = true,
  }) {
    final validWorkoutDays = workoutDays.where((d) => d >= 1 && d <= 7).toSet();
    final dailyAvgCalories = customDailyAverage ??
        calculateDailyAverageCalories(
          profile: profile,
          expenditureKcal: expenditureKcal,
          previousAvgCalories: previousAvgCalories,
          applyReverseRamp: applyReverseRamp,
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
        final numWorkoutDays = validWorkoutDays.length;
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
            final isWorkout = validWorkoutDays.contains(day);
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
    final isManualCustom = profile.programMode == ProgramMode.manual &&
        profile.customProteinGrams != null &&
        profile.customCarbsGrams != null &&
        profile.customFatGrams != null;

    for (int day = 1; day <= 7; day++) {
      final isWorkout = validWorkoutDays.contains(day);
      final MacroTarget macros;
      if (isManualCustom) {
        // Honor exact Manual calories and macros uniformly without floor clamping or day-shifting.
        macros = MacroTarget(
          calories: dailyAvgCalories,
          proteinGrams: profile.customProteinGrams!,
          carbsGrams: profile.customCarbsGrams!,
          fatGrams: profile.customFatGrams!,
        );
      } else {
        final rawDayCals = dayCaloriesMap[day] ?? dailyAvgCalories;
        final cals = (profile.programMode == ProgramMode.manual &&
                profile.customCalories != null)
            ? rawDayCals
            : math.max(profile.calorieFloor, rawDayCals);
        macros = computeDayMacros(
          calories: cals,
          weightKg: profile.currentWeightKg,
          style: style,
          proteinPref: profile.proteinPreference,
          isWorkoutDay: isWorkout,
          carbShareOverride: carbShareOverride,
        );
      }

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
      workoutDays: validWorkoutDays,
      dailyAverageCalories: dailyAvgCalories,
      days: days,
      createdAt: programStartDate ?? now,
      lastCheckInDate: lastCheckInDate ?? now,
      checkInDayOfWeek: checkInDayOfWeek,
      carbShareOverride: carbShareOverride,
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

    // 2. Cognitive Deadband Filter (Disregard noise < 20 kcal unless below floor)
    if (rawDelta.abs() < 20.0 && currentAvgCalories >= calorieFloor) {
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
    if (profile.programMode == ProgramMode.manual) {
      return CheckInRecommendation(
        isDue: false,
        daysUntilNextCheckIn: 7,
        currentExpenditureKcal: currentExpenditureKcal,
        previousAverageCalories: currentProgram.dailyAverageCalories,
        recommendedAverageCalories: currentProgram.dailyAverageCalories,
        calorieDelta: 0.0,
        metabolicInsight:
            'Manual mode active — your custom calorie & macro targets remain locked while expenditure tracks silently.',
        suggestedProgram: currentProgram,
        rawCalorieDelta: 0.0,
        dampedCalorieDelta: 0.0,
      );
    }

    final currentDay =
        DateTime(currentDate.year, currentDate.month, currentDate.day);
    final lastDay = DateTime(
      currentProgram.lastCheckInDate.year,
      currentProgram.lastCheckInDate.month,
      currentProgram.lastCheckInDate.day,
    );
    final daysSinceCheckIn = currentDay.difference(lastDay).inDays;
    final isDue = daysSinceCheckIn >= 7;
    final daysUntilNext = isDue ? 0 : (7 - daysSinceCheckIn).clamp(0, 7);

    // Compute raw unconstrained target from Bayesian expenditure & periodization
    final rawTarget = calculateDailyAverageCalories(
      profile: profile,
      expenditureKcal: currentExpenditureKcal,
      previousAvgCalories: currentProgram.dailyAverageCalories,
    );

    // Apply Confidence-Weighted Flux Damping Operator
    final damped = computeDampedAdjustment(
      currentAvgCalories: currentProgram.dailyAverageCalories,
      unconstrainedTargetCalories: rawTarget,
      kalmanConfidence: kalmanConfidence,
      calorieFloor: profile.calorieFloor,
      silentRecompActive: silentRecompActive,
    );

    final String insight;
    if (profile.isInDietBreak) {
      insight =
          'Diet Break active — maintenance calories (${damped.recommendedCalories.round()} kcal/day) help restore hormonal & training recovery.';
    } else if (profile.reverseDietPacing != 'none' && damped.appliedDelta > 0) {
      insight =
          'Reverse Diet (${profile.reverseDietPacing}) ramping intake by +${damped.appliedDelta.round()} kcal/day toward estimated expenditure.';
    } else {
      insight = damped.reason;
    }

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
      carbShareOverride: profile.programMode == ProgramMode.collaborative
          ? currentProgram.carbShareOverride
          : null,
    );

    return CheckInRecommendation(
      isDue: isDue,
      daysUntilNextCheckIn: daysUntilNext,
      currentExpenditureKcal: currentExpenditureKcal,
      previousAverageCalories: currentProgram.dailyAverageCalories,
      recommendedAverageCalories: damped.recommendedCalories,
      calorieDelta: damped.appliedDelta,
      metabolicInsight: insight,
      suggestedProgram: suggestedProgram,
      rawCalorieDelta: damped.rawDelta,
      dampedCalorieDelta: damped.appliedDelta,
      wasClamped: damped.wasClamped,
      silentRecompDetected: silentRecompActive,
    );
  }

  /// Rebalances the remaining days of the current 7-day week when actual intake
  /// deviated from plan (e.g. a high-calorie social dinner), smoothing the deficit
  /// without extreme crash-dieting or losing protein floors.
  static WeeklyMacroProgram rebalanceRemainingWeek({
    required WeeklyMacroProgram currentProgram,
    required UserProfile profile,
    required double consumedCaloriesSoFar,
    required int completedDaysCount,
  }) {
    final remainingDays = (7 - completedDaysCount).clamp(1, 6);
    final totalWeeklyBudget = currentProgram.dailyAverageCalories * 7.0;
    final rawRemainingDaily =
        (totalWeeklyBudget - consumedCaloriesSoFar) / remainingDays;
    final upperBound = math.max(
      profile.calorieFloor,
      currentProgram.dailyAverageCalories * 1.30,
    );
    final safeRemainingDaily = rawRemainingDaily.clamp(
      profile.calorieFloor,
      upperBound,
    );
    return buildWeeklyProgram(
      profile: profile,
      expenditureKcal: safeRemainingDaily,
      style: currentProgram.style,
      allocationType: currentProgram.allocationType,
      workoutDays: currentProgram.workoutDays,
      programStartDate: currentProgram.createdAt,
      lastCheckInDate: currentProgram.lastCheckInDate,
      checkInDayOfWeek: currentProgram.checkInDayOfWeek,
      customDailyAverage: safeRemainingDaily,
      carbShareOverride: profile.programMode == ProgramMode.collaborative
          ? currentProgram.carbShareOverride
          : null,
    );
  }
}
