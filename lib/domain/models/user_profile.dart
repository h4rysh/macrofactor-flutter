import 'package:flutter/foundation.dart';

/// Primary goal for diet configuration.
enum GoalType {
  fatLoss('Fat Loss'),
  maintenance('Maintenance'),
  muscleGain('Muscle Gain');

  const GoalType(this.displayName);
  final String displayName;
}

/// Coaching program mode.
/// Coached: Algorithmic adjustments weekly based on Bayesian expenditure.
/// Collaborative: Algorithmic expenditure with customizable macro distributions.
/// Manual: Fixed targets set directly by user.
enum ProgramMode {
  coached('Coached (Algorithmic)'),
  collaborative('Collaborative'),
  manual('Manual Targets');

  const ProgramMode(this.displayName);
  final String displayName;
}

/// Protein target recommendation tier.
enum ProteinPreference {
  moderate('Moderate (1.6 g/kg)', 1.6),
  high('High (2.0 g/kg)', 2.0),
  extraHigh('Extra High (2.4 g/kg)', 2.4);

  const ProteinPreference(this.displayName, this.gramsPerKg);
  final String displayName;
  final double gramsPerKg;
}

/// Target macronutrient distribution.
@immutable
class MacroTarget {
  const MacroTarget({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  final double calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  double get targetCalories => calories;
  double get targetProteinGrams => proteinGrams;
  double get targetCarbsGrams => carbsGrams;
  double get targetFatGrams => fatGrams;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MacroTarget &&
          runtimeType == other.runtimeType &&
          calories == other.calories &&
          proteinGrams == other.proteinGrams &&
          carbsGrams == other.carbsGrams &&
          fatGrams == other.fatGrams;

  @override
  int get hashCode => Object.hash(calories, proteinGrams, carbsGrams, fatGrams);
}

typedef MacroTargets = MacroTarget;

/// User profile and active coaching program.
@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.heightCm,
    required this.age,
    required this.isMale,
    required this.goalType,
    required this.programMode,
    required this.weeklyRateOfChangePct,
    required this.proteinPreference,
    required this.calorieFloor,
    required this.baselineExpenditureKcal,
    this.customCalories,
    this.customProteinGrams,
    this.customCarbsGrams,
    this.customFatGrams,
    this.dietType = 'standard',
    this.calorieFloorType = 'standard',
    this.liftingExperience = 'beginner',
    this.cardioExperience = 'beginner',
    this.bodyFatRange,
    this.weightHistoryMax,
    this.distributionMode = 'even',
  });

  final String id;
  final String name;
  final double currentWeightKg;
  final double targetWeightKg;
  final double heightCm;
  final int age;
  final bool isMale;
  final GoalType goalType;
  final ProgramMode programMode;
  final double weeklyRateOfChangePct; // e.g., -0.5% of bodyweight per week
  final ProteinPreference proteinPreference;
  final double calorieFloor; // Safety floor e.g. 1200 kcal
  final double baselineExpenditureKcal;
  final double? customCalories;
  final double? customProteinGrams;
  final double? customCarbsGrams;
  final double? customFatGrams;
  final String dietType;
  final String calorieFloorType;
  final String liftingExperience;
  final String cardioExperience;
  final String? bodyFatRange;
  final double? weightHistoryMax;
  final String distributionMode;

  /// Calculates dynamic daily calorie and macro targets given current Bayesian expenditure.
  MacroTarget calculateTargetMacros(double currentExpenditureKcal) {
    if (customCalories != null) {
      final pG = customProteinGrams ??
          (proteinPreference.gramsPerKg * currentWeightKg).roundToDouble();
      final fG = customFatGrams ??
          (currentWeightKg * 0.7)
              .clamp(customCalories! * 0.25 / 9.0, 150.0)
              .roundToDouble();
      final remainingCals = (customCalories! - (pG * 4.0) - (fG * 9.0))
          .clamp(0.0, double.infinity);
      final cG = customCarbsGrams ?? (remainingCals / 4.0).roundToDouble();

      return MacroTarget(
        calories: customCalories!.roundToDouble(),
        proteinGrams: pG,
        carbsGrams: cG,
        fatGrams: fG,
      );
    }

    // 1 kg body mass delta ~= 7700 kcal
    // Weekly kg change = currentWeightKg * (weeklyRateOfChangePct / 100.0)
    // Daily deficit/surplus = (weeklyKg * 7700) / 7 days = weeklyKg * 1100 kcal
    double dailyEnergyDeltaKcal;

    switch (goalType) {
      case GoalType.fatLoss:
        final weeklyKgLoss =
            currentWeightKg * (weeklyRateOfChangePct.abs() / 100.0);
        dailyEnergyDeltaKcal = -(weeklyKgLoss * 1100.0);
        break;
      case GoalType.maintenance:
        dailyEnergyDeltaKcal = 0.0;
        break;
      case GoalType.muscleGain:
        final weeklyKgGain =
            currentWeightKg * (weeklyRateOfChangePct.abs() / 100.0);
        dailyEnergyDeltaKcal = (weeklyKgGain * 1100.0);
        break;
    }

    final rawTargetCalories = currentExpenditureKcal + dailyEnergyDeltaKcal;
    final targetCalories = rawTargetCalories.clamp(calorieFloor, 6000.0);

    // Protein Target: gramsPerKg * currentWeightKg
    final proteinGrams =
        (proteinPreference.gramsPerKg * currentWeightKg).roundToDouble();
    final proteinCalories = proteinGrams * 4.0;

    // Fat minimum: 25% of total calories, or 0.7g/kg minimum
    final minFatCalories = targetCalories * 0.25;
    final minFatGrams =
        (currentWeightKg * 0.7).clamp(minFatCalories / 9.0, 150.0);
    final fatCalories = minFatGrams * 9.0;

    // Remaining calories allocated to carbohydrates
    final remainingCalories = (targetCalories - proteinCalories - fatCalories)
        .clamp(0.0, double.infinity);
    final carbsGrams = (remainingCalories / 4.0).roundToDouble();

    return MacroTarget(
      calories: targetCalories.roundToDouble(),
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: minFatGrams.roundToDouble(),
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    double? currentWeightKg,
    double? targetWeightKg,
    double? heightCm,
    int? age,
    bool? isMale,
    GoalType? goalType,
    ProgramMode? programMode,
    double? weeklyRateOfChangePct,
    ProteinPreference? proteinPreference,
    double? calorieFloor,
    double? baselineExpenditureKcal,
    double? customCalories,
    double? customProteinGrams,
    double? customCarbsGrams,
    double? customFatGrams,
    String? dietType,
    String? calorieFloorType,
    String? liftingExperience,
    String? cardioExperience,
    String? bodyFatRange,
    double? weightHistoryMax,
    String? distributionMode,
    bool clearCustom = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      heightCm: heightCm ?? this.heightCm,
      age: age ?? this.age,
      isMale: isMale ?? this.isMale,
      goalType: goalType ?? this.goalType,
      programMode: programMode ?? this.programMode,
      weeklyRateOfChangePct:
          weeklyRateOfChangePct ?? this.weeklyRateOfChangePct,
      proteinPreference: proteinPreference ?? this.proteinPreference,
      calorieFloor: calorieFloor ?? this.calorieFloor,
      baselineExpenditureKcal:
          baselineExpenditureKcal ?? this.baselineExpenditureKcal,
      customCalories:
          clearCustom ? null : (customCalories ?? this.customCalories),
      customProteinGrams:
          clearCustom ? null : (customProteinGrams ?? this.customProteinGrams),
      customCarbsGrams:
          clearCustom ? null : (customCarbsGrams ?? this.customCarbsGrams),
      customFatGrams:
          clearCustom ? null : (customFatGrams ?? this.customFatGrams),
      dietType: dietType ?? this.dietType,
      calorieFloorType: calorieFloorType ?? this.calorieFloorType,
      liftingExperience: liftingExperience ?? this.liftingExperience,
      cardioExperience: cardioExperience ?? this.cardioExperience,
      bodyFatRange: bodyFatRange ?? this.bodyFatRange,
      weightHistoryMax: weightHistoryMax ?? this.weightHistoryMax,
      distributionMode: distributionMode ?? this.distributionMode,
    );
  }
}
