import 'dart:math' as math;

/// Clinical risk category for Waist-to-Height Ratio.
enum WhtrCategory {
  underweight('Underweight / Thin', 'Below healthy circumference bounds.'),
  healthy('Optimal / Healthy', 'Circumference is within clinical target.'),
  increasedRisk('Increased Health Risk', 'Abdominal fat warrants monitoring.'),
  highRisk('Very High Health Risk', 'Substantial visceral adipose accumulation.');

  const WhtrCategory(this.displayName, this.clinicalNote);
  final String displayName;
  final String clinicalNote;
}

/// Service providing US Navy Body Fat estimation, anthropometric indices, and recomposition detection.
class AnthropometricService {
  const AnthropometricService._();

  /// Calculates Body Fat Percentage using the official US Navy Circumference Method.
  ///
  /// Converts metric cm measurements to inches, applying DoD standard coefficients:
  /// Males: %BF = 86.010 * log10(waist - neck) - 70.041 * log10(height) + 36.76
  /// Females: %BF = 163.205 * log10(waist + hips - neck) - 97.684 * log10(height) - 78.387
  ///
  /// Standard Error of Estimate (SEE) ~ 3.5%.
  static double? calculateNavyBodyFatPct({
    required bool isMale,
    required double heightCm,
    required double waistCm,
    required double neckCm,
    double? hipsCm,
  }) {
    if (heightCm <= 0 || waistCm <= 0 || neckCm <= 0) return null;

    final heightIn = heightCm / 2.54;
    final waistIn = waistCm / 2.54;
    final neckIn = neckCm / 2.54;

    if (isMale) {
      final waistMinusNeckIn = waistIn - neckIn;
      if (waistMinusNeckIn <= 0) return null;

      final logDiff = _log10(waistMinusNeckIn);
      final logHeight = _log10(heightIn);
      final bf = (86.010 * logDiff) - (70.041 * logHeight) + 36.76;
      return bf.clamp(3.0, 60.0);
    } else {
      if (hipsCm == null || hipsCm <= 0) return null;
      final hipsIn = hipsCm / 2.54;
      final sumMinusNeckIn = waistIn + hipsIn - neckIn;
      if (sumMinusNeckIn <= 0) return null;

      final logSum = _log10(sumMinusNeckIn);
      final logHeight = _log10(heightIn);
      final bf = (163.205 * logSum) - (97.684 * logHeight) - 78.387;
      return bf.clamp(8.0, 65.0);
    }
  }

  /// Calculates Waist-to-Height Ratio (WHtR) = waistCm / heightCm.
  static double? calculateWhtr({
    required double waistCm,
    required double heightCm,
  }) {
    if (waistCm <= 0 || heightCm <= 0) return null;
    return waistCm / heightCm;
  }

  /// Classifies Waist-to-Height Ratio according to UK NICE & WHO guidelines.
  static WhtrCategory classifyWhtr(double whtr) {
    if (whtr < 0.40) return WhtrCategory.underweight;
    if (whtr < 0.50) return WhtrCategory.healthy;
    if (whtr < 0.60) return WhtrCategory.increasedRisk;
    return WhtrCategory.highRisk;
  }

  /// Calculates Waist-to-Hip Ratio (WHR) = waistCm / hipsCm.
  static double? calculateWhr({
    required double waistCm,
    required double hipsCm,
  }) {
    if (waistCm <= 0 || hipsCm <= 0) return null;
    return waistCm / hipsCm;
  }

  /// Determines whether Waist-to-Hip Ratio is within healthy limits.
  /// Healthy: Male <= 0.90, Female <= 0.85.
  static bool isWhrHealthy({
    required double whr,
    required bool isMale,
  }) {
    final threshold = isMale ? 0.90 : 0.85;
    return whr <= threshold;
  }

  /// Applies 1D Exponential Smoothing Filter (alpha = 0.30 by default)
  /// to eliminate tape measurement noise and postprandial fluctuations.
  static double smoothCircumference({
    required double currentObservedCm,
    required double previousSmoothedCm,
    double alpha = 0.30,
  }) {
    final clampedAlpha = alpha.clamp(0.05, 1.0);
    return (clampedAlpha * currentObservedCm) +
        ((1.0 - clampedAlpha) * previousSmoothedCm);
  }

  /// Evaluates whether a user is undergoing "Silent Recomposition".
  ///
  /// Criteria:
  /// 1. Scale weight is tracking flat over 7-14 days (delta between -0.2 kg and +0.3 kg).
  /// 2. Smoothed waist circumference has dropped significantly (delta <= -0.5 cm).
  ///
  /// When true, the user is building lean muscle mass while losing visceral/subcutaneous fat.
  /// Coaching engines must NOT recommend an aggressive calorie cut during this state.
  static bool isSilentRecomposition({
    required double weightDelta7DayKg,
    required double smoothedWaistDelta14DayCm,
  }) {
    final isWeightStable =
        weightDelta7DayKg >= -0.2 && weightDelta7DayKg <= 0.3;
    final isWaistShrinking = smoothedWaistDelta14DayCm <= -0.5;
    return isWeightStable && isWaistShrinking;
  }

  static double _log10(double x) => math.log(x) / math.ln10;
}
