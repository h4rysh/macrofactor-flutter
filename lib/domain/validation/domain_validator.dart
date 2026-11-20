import '../models/user_profile.dart';

/// Centralized domain validation for nutritional math, demographic guardrails,
/// BMI safety limits, and rate-of-change boundaries.
class DomainValidator {
  DomainValidator._();

  /// Clinical underweight BMI threshold defined by WHO / ICMR.
  static const double minBmi = 18.5;

  /// Absolute allowable physical weight range in kilograms.
  static const double minWeightKg = 30.0;
  static const double maxWeightKg = 350.0;

  /// Rate-of-change safety limits (% of total bodyweight per week).
  /// Safe fat loss ceiling: max 1.5% bodyweight loss per week.
  static const double minFatLossRatePct = -1.5;
  static const double maxFatLossRatePct = -0.1;

  /// Safe hypertrophy ceiling: max 1.0% bodyweight gain per week.
  static const double minMuscleGainRatePct = 0.1;
  static const double maxMuscleGainRatePct = 1.0;

  // ---------------------------------------------------------------------------
  // BMI & Demographic Calculations
  // ---------------------------------------------------------------------------

  /// Calculates Body Mass Index (BMI = kg / m²).
  static double calculateBmi(double weightKg, double heightCm) {
    final heightM = heightCm / 100.0;
    if (heightM <= 0) return 22.0;
    return weightKg / (heightM * heightM);
  }

  /// Calculates the minimum safe body weight (kg) corresponding to BMI 18.5.
  static double minSafeWeightKg(double heightCm) {
    final heightM = heightCm / 100.0;
    if (heightM <= 0) return minWeightKg;
    return minBmi * (heightM * heightM);
  }

  /// Returns true if the given weight and height result in BMI < 18.5.
  static bool isUnderweightBmi(double weightKg, double heightCm) {
    return calculateBmi(weightKg, heightCm) < minBmi;
  }

  /// Computes chronological age given a Date of Birth and the current clock time.
  static int calculateAge(DateTime dob, DateTime now) {
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  /// Validates whether the user satisfies the strict adult 18+ requirement.
  static bool isAdult(int age) => age >= 18;

  // ---------------------------------------------------------------------------
  // Target Weight & Rate Validations
  // ---------------------------------------------------------------------------

  /// Validates target weight against absolute range and clinical BMI underweight guardrails.
  static ValidationResult validateTargetWeight({
    required double targetWeightKg,
    required double heightCm,
    required GoalType goalType,
  }) {
    if (targetWeightKg < minWeightKg || targetWeightKg > maxWeightKg) {
      return ValidationResult.invalid(
        'Target weight must be between ${minWeightKg.toStringAsFixed(0)} kg and ${maxWeightKg.toStringAsFixed(0)} kg.',
      );
    }

    if (goalType == GoalType.fatLoss &&
        isUnderweightBmi(targetWeightKg, heightCm)) {
      final safeMin = minSafeWeightKg(heightCm);
      final bmi = calculateBmi(targetWeightKg, heightCm);
      return ValidationResult.invalid(
        'Target weight ${targetWeightKg.toStringAsFixed(1)} kg places BMI (${bmi.toStringAsFixed(1)}) in the clinical underweight range (< 18.5). Safe minimum target is ${safeMin.toStringAsFixed(1)} kg.',
      );
    }

    return const ValidationResult.valid();
  }

  /// Validates weekly rate of change (%/wk) against physiological guardrails.
  static ValidationResult validateRateOfChange({
    required double ratePct,
    required GoalType goalType,
  }) {
    switch (goalType) {
      case GoalType.fatLoss:
        if (ratePct > 0) {
          return const ValidationResult.invalid(
            'Fat loss pace cannot have a positive rate of change.',
          );
        }
        if (ratePct < minFatLossRatePct) {
          return ValidationResult.invalid(
            'Weekly rate of ${ratePct.toStringAsFixed(2)}%/wk exceeds clinical safety limit (${minFatLossRatePct.abs()}%/wk).',
          );
        }
        return const ValidationResult.valid();

      case GoalType.muscleGain:
        if (ratePct < 0) {
          return const ValidationResult.invalid(
            'Hypertrophy pace cannot have a negative rate of change.',
          );
        }
        if (ratePct > maxMuscleGainRatePct) {
          return ValidationResult.invalid(
            'Weekly rate of +${ratePct.toStringAsFixed(2)}%/wk exceeds safe hypertrophy limit (+$maxMuscleGainRatePct%/wk).',
          );
        }
        return const ValidationResult.valid();

      case GoalType.maintenance:
        if (ratePct != 0.0) {
          return const ValidationResult.invalid(
            'Maintenance pace requires a rate of 0.0%/wk.',
          );
        }
        return const ValidationResult.valid();
    }
  }

  /// Clamps weekly rate of change to physiological bounds.
  static double clampRateOfChange(double ratePct, GoalType goalType) {
    switch (goalType) {
      case GoalType.fatLoss:
        return ratePct.clamp(minFatLossRatePct, 0.0);
      case GoalType.muscleGain:
        return ratePct.clamp(0.0, maxMuscleGainRatePct);
      case GoalType.maintenance:
        return 0.0;
    }
  }
}

/// Result of a domain validation check with validation status and error message.
class ValidationResult {
  const ValidationResult.valid()
      : isValid = true,
        errorMessage = null;

  const ValidationResult.invalid(this.errorMessage) : isValid = false;

  final bool isValid;
  final String? errorMessage;
}
