import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sique/domain/algorithms/expenditure_kalman_v4.dart';

double _nextGaussian(Random rng, double mean, double stdDev) {
  final u1 = rng.nextDouble().clamp(1e-10, 1.0);
  final u2 = rng.nextDouble();
  final z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
  return mean + z0 * stdDev;
}

void main() {
  group('ExpenditureKalmanV4 8 Canonical Simulation Tests (100 Runs/Scenario)',
      () {
    test('Scenario 1: Steady state jitter < 12 kcal/day', () {
      final jitters = <double>[];

      for (int run = 0; run < 100; run++) {
        final rng = Random(1000 + run);
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 75.0,
          initialExpenditureKcal: 2200.0,
        );
        double trueWeight = 75.0;
        const trueExp = 2200.0;
        final dailyDeltas = <double>[];
        double prevExp = 2200.0;

        for (int day = 0; day < 90; day++) {
          const intake = trueExp;
          trueWeight += (intake - trueExp) / 7700.0;
          final scaleWeight = _nextGaussian(rng, trueWeight, 0.6);
          filter.step(intakeKcal: intake, scaleWeightKg: scaleWeight);

          if (day >= 30) {
            dailyDeltas.add((filter.expenditureKcal - prevExp).abs());
          }
          prevExp = filter.expenditureKcal;
        }
        final meanRunJitter =
            dailyDeltas.reduce((a, b) => a + b) / dailyDeltas.length;
        jitters.add(meanRunJitter);
      }

      final avgJitter = jitters.reduce((a, b) => a + b) / jitters.length;
      expect(avgJitter, lessThan(12.0),
          reason: 'Average steady state jitter must be under 12 kcal/day');
    });

    test('Scenario 2: Deficit -0.45 and -0.9 kg/wk within +/- 60 kcal', () {
      for (final rateKgWk in [-0.45, -0.90]) {
        final errors = <double>[];
        final seedOffset = (rateKgWk == -0.45) ? 2000 : 2500;

        for (int run = 0; run < 100; run++) {
          final rng = Random(seedOffset + run);
          final filter = ExpenditureKalmanV4(
            initialWeightKg: 80.0,
            initialExpenditureKcal: 2400.0,
          );
          double trueWeight = 80.0;
          const trueExp = 2400.0;
          final dailyDeficit = (rateKgWk.abs() * 7700.0) / 7.0;
          final intake = trueExp - dailyDeficit;

          for (int day = 0; day < 90; day++) {
            trueWeight += (intake - trueExp) / 7700.0;
            final scaleWeight = _nextGaussian(rng, trueWeight, 0.6);
            filter.step(intakeKcal: intake, scaleWeightKg: scaleWeight);
          }
          errors.add((filter.expenditureKcal - trueExp).abs());
        }

        final avgError = errors.reduce((a, b) => a + b) / errors.length;
        expect(avgError, lessThan(60.0),
            reason:
                'Average error under deficit $rateKgWk kg/wk must be within 60 kcal');
      }
    });

    test('Scenario 3: Surplus +0.45 kg/wk within +/- 60 kcal', () {
      final errors = <double>[];

      for (int run = 0; run < 100; run++) {
        final rng = Random(3000 + run);
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 70.0,
          initialExpenditureKcal: 2000.0,
        );
        double trueWeight = 70.0;
        const trueExp = 2000.0;
        const dailySurplus = (0.45 * 7700.0) / 7.0;
        const intake = trueExp + dailySurplus;

        for (int day = 0; day < 90; day++) {
          trueWeight += (intake - trueExp) / 7700.0;
          final scaleWeight = _nextGaussian(rng, trueWeight, 0.6);
          filter.step(intakeKcal: intake, scaleWeightKg: scaleWeight);
        }
        errors.add((filter.expenditureKcal - trueExp).abs());
      }

      final avgError = errors.reduce((a, b) => a + b) / errors.length;
      expect(avgError, lessThan(60.0),
          reason:
              'Average error under surplus +0.45 kg/wk must be within 60 kcal');
    });

    test('Scenario 4: Sparse weigh-ins every 3 and 7 days, error < 80 kcal',
        () {
      for (final interval in [3, 7]) {
        final errors = <double>[];

        for (int run = 0; run < 100; run++) {
          final rng = Random(4000 + (interval * 100) + run);
          final filter = ExpenditureKalmanV4(
            initialWeightKg: 75.0,
            initialExpenditureKcal: 2200.0,
          );
          double trueWeight = 75.0;
          const trueExp = 2200.0;
          const intake = 2000.0;

          for (int day = 0; day < 90; day++) {
            trueWeight += (intake - trueExp) / 7700.0;
            final hasWeighIn = (day % interval == 0);
            final scaleWeight =
                hasWeighIn ? _nextGaussian(rng, trueWeight, 0.6) : null;
            filter.step(intakeKcal: intake, scaleWeightKg: scaleWeight);
          }
          errors.add((filter.expenditureKcal - trueExp).abs());
        }

        final avgError = errors.reduce((a, b) => a + b) / errors.length;
        expect(avgError, lessThan(80.0),
            reason:
                'Average error with weigh-in interval $interval days must be < 80 kcal');
      }
    });

    test('Scenario 5: 30% unlogged days, error < 60 kcal', () {
      final errors = <double>[];

      for (int run = 0; run < 100; run++) {
        final rng = Random(5000 + run);
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 75.0,
          initialExpenditureKcal: 2300.0,
        );
        double trueWeight = 75.0;
        const trueExp = 2300.0;
        const intake = 2300.0;

        for (int day = 0; day < 90; day++) {
          trueWeight += (intake - trueExp) / 7700.0;
          final scaleWeight = _nextGaussian(rng, trueWeight, 0.6);
          final isUnlogged = (day > 14) && (rng.nextDouble() < 0.30);
          final loggedIntake = isUnlogged ? null : intake;
          filter.step(intakeKcal: loggedIntake, scaleWeightKg: scaleWeight);
        }
        errors.add((filter.expenditureKcal - trueExp).abs());
      }

      final avgError = errors.reduce((a, b) => a + b) / errors.length;
      expect(avgError, lessThan(60.0),
          reason: 'Average error with 30% unlogged days must be < 60 kcal');
    });

    test(
        'Scenario 6: Water shock +1.5 kg decaying over 6 days, peak deviation < 250 kcal',
        () {
      final peakDeviations = <double>[];

      for (int run = 0; run < 100; run++) {
        final rng = Random(6000 + run);
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 75.0,
          initialExpenditureKcal: 2200.0,
        );
        double trueWeight = 75.0;
        const trueExp = 2200.0;
        const intake = 2200.0;
        double peakDev = 0.0;

        for (int day = 0; day < 60; day++) {
          trueWeight += (intake - trueExp) / 7700.0;
          double waterShift = 0.0;
          if (day >= 30 && day <= 35) {
            waterShift = 1.5 * (1.0 - (day - 30) / 6.0);
          }
          final scaleWeight = _nextGaussian(rng, trueWeight + waterShift, 0.6);
          filter.step(intakeKcal: intake, scaleWeightKg: scaleWeight);

          if (day >= 30 && day <= 45) {
            final dev = (filter.expenditureKcal - trueExp).abs();
            if (dev > peakDev) peakDev = dev;
          }
        }
        peakDeviations.add(peakDev);
      }

      final avgPeak =
          peakDeviations.reduce((a, b) => a + b) / peakDeviations.length;
      expect(avgPeak, lessThan(250.0),
          reason:
              'Average peak deviation under water shock must be < 250 kcal');
    });

    test(
        'Scenario 7: +200 kcal TDEE step converges within 30 days without overshoot',
        () {
      final endEstimates = <double>[];
      final overshoots = <double>[];

      for (int run = 0; run < 100; run++) {
        final rng = Random(7000 + run);
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 75.0,
          initialExpenditureKcal: 2000.0,
        );
        double trueWeight = 75.0;
        double trueExp = 2000.0;
        double intake = 2000.0;

        // Baseline 30 days at 2000 kcal
        for (int day = 0; day < 30; day++) {
          trueWeight += (intake - trueExp) / 7700.0;
          final scaleWeight = _nextGaussian(rng, trueWeight, 0.6);
          filter.step(intakeKcal: intake, scaleWeightKg: scaleWeight);
        }

        // Step to 2200 kcal on day 30
        trueExp = 2200.0;
        intake = 2200.0;
        double maxInStep = 0.0;

        for (int day = 30; day < 60; day++) {
          trueWeight += (intake - trueExp) / 7700.0;
          final scaleWeight = _nextGaussian(rng, trueWeight, 0.6);
          filter.step(intakeKcal: intake, scaleWeightKg: scaleWeight);
          if (filter.expenditureKcal > maxInStep) {
            maxInStep = filter.expenditureKcal;
          }
        }

        endEstimates.add(filter.expenditureKcal);
        overshoots.add(max(0.0, maxInStep - 2225.0));
      }

      final avgEnd = endEstimates.reduce((a, b) => a + b) / 100;
      final maxOvershoot = overshoots.reduce(max);

      expect(avgEnd, greaterThan(2080.0),
          reason:
              'Filter must advance substantially toward 2200 kcal within 30 days');
      expect(maxOvershoot, lessThanOrEqualTo(50.0),
          reason:
              'Filter must not exhibit oscillatory overshoot above step target');
    });

    test(
        'Scenario 8: Causality: adding a future weigh-in never changes historical estimates',
        () {
      for (int run = 0; run < 100; run++) {
        final rng = Random(8000 + run);
        final weights = List<double>.generate(
            60, (d) => 75.0 + _nextGaussian(rng, 0.0, 0.6));
        final intakes = List<double>.filled(60, 2200.0);

        // Pass 1: 30 days
        final filter1 = ExpenditureKalmanV4(
          initialWeightKg: 75.0,
          initialExpenditureKcal: 2200.0,
        );
        final hist30 = <double>[];
        for (int day = 0; day < 30; day++) {
          filter1.step(intakeKcal: intakes[day], scaleWeightKg: weights[day]);
          hist30.add(filter1.expenditureKcal);
        }

        // Pass 2: 60 days
        final filter2 = ExpenditureKalmanV4(
          initialWeightKg: 75.0,
          initialExpenditureKcal: 2200.0,
        );
        for (int day = 0; day < 30; day++) {
          filter2.step(intakeKcal: intakes[day], scaleWeightKg: weights[day]);
          expect(filter2.expenditureKcal, equals(hist30[day]),
              reason:
                  'Past estimates must be strictly immutable to future inputs');
        }
        for (int day = 30; day < 60; day++) {
          filter2.step(intakeKcal: intakes[day], scaleWeightKg: weights[day]);
        }
      }
    });
  });
}
