import 'package:flutter_test/flutter_test.dart';
import 'package:sique/domain/algorithms/anthropometric_service.dart';

void main() {
  group('AnthropometricService - US Navy Body Fat %', () {
    test('Male Navy formula calculates accurate body fat percentage', () {
      // Height: 180cm, Waist: 85cm, Neck: 40cm
      // Waist - Neck = 45cm
      final bf = AnthropometricService.calculateNavyBodyFatPct(
        isMale: true,
        heightCm: 180.0,
        waistCm: 85.0,
        neckCm: 40.0,
      );

      expect(bf, isNotNull);
      // Expected around 14.5% (DoD reference standard for 180cm / 85cm / 40cm)
      expect(bf!, closeTo(14.5, 0.3));
    });

    test('Female Navy formula requires hips and calculates accurate body fat',
        () {
      // Female missing hips returns null
      final missingHips = AnthropometricService.calculateNavyBodyFatPct(
        isMale: false,
        heightCm: 165.0,
        waistCm: 75.0,
        neckCm: 34.0,
      );
      expect(missingHips, isNull);

      // Height: 165cm, Waist: 75cm, Neck: 34cm, Hips: 98cm
      // Waist + Hips - Neck = 75 + 98 - 34 = 139cm
      final bf = AnthropometricService.calculateNavyBodyFatPct(
        isMale: false,
        heightCm: 165.0,
        waistCm: 75.0,
        neckCm: 34.0,
        hipsCm: 98.0,
      );

      expect(bf, isNotNull);
      // Expected around 28.2%
      expect(bf!, closeTo(28.2, 0.4));
    });

    test('Defensive bounds handling for invalid inputs', () {
      // Waist less than neck (physically impossible)
      final invalidWaist = AnthropometricService.calculateNavyBodyFatPct(
        isMale: true,
        heightCm: 180.0,
        waistCm: 35.0,
        neckCm: 40.0,
      );
      expect(invalidWaist, isNull);

      // Non-positive height
      final zeroHeight = AnthropometricService.calculateNavyBodyFatPct(
        isMale: true,
        heightCm: 0.0,
        waistCm: 80.0,
        neckCm: 38.0,
      );
      expect(zeroHeight, isNull);
    });
  });

  group('AnthropometricService - Waist-to-Height Ratio (WHtR)', () {
    test('Calculates and classifies clinical WHtR risk boundaries', () {
      // Underweight (< 0.40)
      final under = AnthropometricService.calculateWhtr(
        waistCm: 65.0,
        heightCm: 180.0,
      )!;
      expect(under, closeTo(0.361, 0.005));
      expect(
          AnthropometricService.classifyWhtr(under), WhtrCategory.underweight);

      // Healthy (0.40 - 0.49)
      final healthy = AnthropometricService.calculateWhtr(
        waistCm: 80.0,
        heightCm: 175.0,
      )!;
      expect(healthy, closeTo(0.457, 0.005));
      expect(AnthropometricService.classifyWhtr(healthy), WhtrCategory.healthy);

      // Increased Risk (0.50 - 0.59)
      final increased = AnthropometricService.calculateWhtr(
        waistCm: 92.0,
        heightCm: 175.0,
      )!;
      expect(increased, closeTo(0.526, 0.005));
      expect(AnthropometricService.classifyWhtr(increased),
          WhtrCategory.increasedRisk);

      // High Risk (>= 0.60)
      final high = AnthropometricService.calculateWhtr(
        waistCm: 108.0,
        heightCm: 175.0,
      )!;
      expect(high, closeTo(0.617, 0.005));
      expect(AnthropometricService.classifyWhtr(high), WhtrCategory.highRisk);
    });
  });

  group('AnthropometricService - Waist-to-Hip Ratio (WHR)', () {
    test('Calculates and verifies gender-specific WHR thresholds', () {
      // Male healthy <= 0.90
      final maleHealthy =
          AnthropometricService.calculateWhr(waistCm: 82.0, hipsCm: 98.0)!;
      expect(AnthropometricService.isWhrHealthy(whr: maleHealthy, isMale: true),
          isTrue);

      final maleHigh =
          AnthropometricService.calculateWhr(waistCm: 96.0, hipsCm: 100.0)!;
      expect(AnthropometricService.isWhrHealthy(whr: maleHigh, isMale: true),
          isFalse);

      // Female healthy <= 0.85
      final femaleHealthy =
          AnthropometricService.calculateWhr(waistCm: 72.0, hipsCm: 98.0)!;
      expect(
          AnthropometricService.isWhrHealthy(whr: femaleHealthy, isMale: false),
          isTrue);

      final femaleHigh =
          AnthropometricService.calculateWhr(waistCm: 88.0, hipsCm: 100.0)!;
      expect(AnthropometricService.isWhrHealthy(whr: femaleHigh, isMale: false),
          isFalse);
    });
  });

  group('AnthropometricService - 1D Exponential Smoothing & Silent Recomp', () {
    test('Applies exponential smoothing with alpha weight', () {
      // S_t = 0.3 * 85 + 0.7 * 82 = 25.5 + 57.4 = 82.9
      final smoothed = AnthropometricService.smoothCircumference(
        currentObservedCm: 85.0,
        previousSmoothedCm: 82.0,
        alpha: 0.30,
      );
      expect(smoothed, closeTo(82.9, 0.05));
    });

    test('Accurately identifies silent recomposition state', () {
      // True recomposition: weight holds steady (0.1 kg) and waist dropped 0.8 cm
      expect(
        AnthropometricService.isSilentRecomposition(
          weightDelta7DayKg: 0.1,
          smoothedWaistDelta14DayCm: -0.8,
        ),
        isTrue,
      );

      // False: weight dropped rapidly (-1.5 kg) - this is normal cutting, not recomposition
      expect(
        AnthropometricService.isSilentRecomposition(
          weightDelta7DayKg: -1.5,
          smoothedWaistDelta14DayCm: -1.0,
        ),
        isFalse,
      );

      // False: weight stable but waist did not shrink (-0.2 cm)
      expect(
        AnthropometricService.isSilentRecomposition(
          weightDelta7DayKg: 0.0,
          smoothedWaistDelta14DayCm: -0.2,
        ),
        isFalse,
      );
    });
  });
}
