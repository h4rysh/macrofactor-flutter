import 'dart:math' as math;
import 'package:meta/meta.dart';
import 'package:macro_factor_app/domain/models/macro_program.dart';
import 'package:macro_factor_app/domain/models/user_profile.dart';

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
  });

  final bool isDue;
  final int daysUntilNextCheckIn;
  final double currentExpenditureKcal;
  final double previousAverageCalories;
  final double recommendedAverageCalories;
  final double calorieDelta;
  final String metabolicInsight;
  final WeeklyMacroProgram suggestedProgram;
}

/// Core reverse-engineered coaching engine for MacroFactor.
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

    // Safety checks against negative values
    return MacroTarget(
      calories: calories.roundToDouble(),
      proteinGrams: proteinGrams.clamp(30.0, 1000.0),
      carbsGrams: carbsGrams.clamp(0.0, 2000.0),
      fatGrams: fatGrams.clamp(20.0, 1000.0),
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
            dayCaloriesMap[day] = dailyAvgCalories;
          }
        } else {
          final numRestDays = 7 - numWorkoutDays;
          // Workout day surplus: +200 kcal or ~10% of daily calories
          final workoutBoost = (dailyAvgCalories * 0.09).clamp(150.0, 300.0);
          final totalWorkoutSurplus = workoutBoost * numWorkoutDays;
          final restDayReduction = totalWorkoutSurplus / numRestDays;

          final workoutCals = (dailyAvgCalories + workoutBoost).roundToDouble();
          final restCals =
              (dailyAvgCalories - restDayReduction).roundToDouble();

          // Apply and ensure conservation by absorbing rounding in Sunday
          double assignedSum = 0.0;
          for (int day = 1; day <= 7; day++) {
            final isWorkout = workoutDays.contains(day);
            final cals = isWorkout ? workoutCals : restCals;
            dayCaloriesMap[day] = cals;
            assignedSum += cals;
          }

          // Adjust Sunday so sum exactly equals totalWeeklyBudget
          final delta = totalWeeklyBudget - assignedSum;
          dayCaloriesMap[7] =
              ((dayCaloriesMap[7] ?? dailyAvgCalories) + delta).roundToDouble();
        }
        break;

      case DayAllocationType.weekendShift:
        // Friday (5), Saturday (6), Sunday (7) get +220 kcal
        const weekendDays = {5, 6, 7};
        const weekendBoost = 220.0;
        const totalWeekendSurplus = weekendBoost * 3.0; // 660 kcal
        const weekdayReduction = totalWeekendSurplus / 4.0; // 165 kcal

        for (int day = 1; day <= 7; day++) {
          if (weekendDays.contains(day)) {
            dayCaloriesMap[day] =
                (dailyAvgCalories + weekendBoost).roundToDouble();
          } else {
            dayCaloriesMap[day] =
                (dailyAvgCalories - weekdayReduction).roundToDouble();
          }
        }
        break;

      case DayAllocationType.custom:
        for (int day = 1; day <= 7; day++) {
          dayCaloriesMap[day] = dailyAvgCalories;
        }
        break;
    }

    // Build the 7 DayMacroTargets
    for (int day = 1; day <= 7; day++) {
      final isWorkout = workoutDays.contains(day);
      final cals = dayCaloriesMap[day] ?? dailyAvgCalories;
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

  /// Evaluates weekly check-in status and calculates new metabolic adjustments.
  static CheckInRecommendation evaluateWeeklyCheckIn({
    required WeeklyMacroProgram currentProgram,
    required UserProfile profile,
    required double currentExpenditureKcal,
    required DateTime currentDate,
  }) {
    final daysSinceCheckIn =
        currentDate.difference(currentProgram.lastCheckInDate).inDays;
    final isDue = daysSinceCheckIn >= 7;
    final daysUntilNext = isDue ? 0 : (7 - daysSinceCheckIn).clamp(0, 7);

    // Compute what the new daily average would be with latest Bayesian expenditure
    final newAverageCalories = calculateDailyAverageCalories(
      profile: profile,
      expenditureKcal: currentExpenditureKcal,
    );
    final calorieDelta =
        newAverageCalories - currentProgram.dailyAverageCalories;

    String insight;
    if (calorieDelta.abs() < 15.0) {
      insight =
          'Your metabolism is tracking steadily at ${currentExpenditureKcal.round()} kcal/day. Your current program remains optimal.';
    } else if (calorieDelta > 0) {
      insight =
          'Your dynamic expenditure has risen to ${currentExpenditureKcal.round()} kcal/day (+${calorieDelta.round()} kcal intake recommended).';
    } else {
      insight =
          'Your metabolic adaptation suggests a target adjustment to ${newAverageCalories.round()} kcal/day (${calorieDelta.round()} kcal) to stay on pace.';
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
      customDailyAverage: newAverageCalories,
    );

    return CheckInRecommendation(
      isDue: isDue,
      daysUntilNextCheckIn: daysUntilNext,
      currentExpenditureKcal: currentExpenditureKcal,
      previousAverageCalories: currentProgram.dailyAverageCalories,
      recommendedAverageCalories: newAverageCalories,
      calorieDelta: calorieDelta,
      metabolicInsight: insight,
      suggestedProgram: suggestedProgram,
    );
  }
}
