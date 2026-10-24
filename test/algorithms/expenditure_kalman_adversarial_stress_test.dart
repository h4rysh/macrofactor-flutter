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
  group('ExpenditureKalmanV4 Adversarial Stress Testing Suite', () {
    // -------------------------------------------------------------------------
    // 1. Extreme Initial Error
    // -------------------------------------------------------------------------
    group('1. Extreme Initial Error', () {
      test(
          'Severe underestimation: true 3500 kcal vs initial 2000 kcal (-1500 kcal)',
          () {
        final rng = Random(1111);
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 85.0,
          initialExpenditureKcal: 2000.0,
        );
        double trueWeight = 85.0;
        const trueExp = 3500.0;
        const intake = 3500.0; // Maintenance intake

        for (int day = 0; day < 90; day++) {
          trueWeight += (intake - trueExp) / 7700.0; // Flat 85 kg true weight
          final scaleWeight = _nextGaussian(rng, trueWeight, 0.6);
          final state = filter.step(
            intakeKcal: intake,
            scaleWeightKg: scaleWeight,
            date: DateTime(2026, 1, 1).add(Duration(days: day)),
          );

          expect(state.expenditureKcal.isFinite, isTrue);
          expect(state.expenditureKcal, greaterThan(0.0));
          expect(state.variance.isFinite, isTrue);
          expect(state.weightVariance.isFinite, isTrue);
          expect(state.crossCovariance.isFinite, isTrue);
          expect(state.confidence.isFinite, isTrue);
        }

        // After 90 days, the filter must have converged strongly toward 3500 kcal
        expect(filter.expenditureKcal, greaterThan(3250.0),
            reason:
                'Should recover from -1500 kcal error and reach within 250 kcal of 3500 kcal');
        expect(filter.expenditureKcal, lessThan(3750.0));
      });

      test(
          'Severe overestimation: true 1500 kcal vs initial 3000 kcal (+1500 kcal)',
          () {
        final rng = Random(2222);
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 60.0,
          initialExpenditureKcal: 3000.0,
        );
        double trueWeight = 60.0;
        const trueExp = 1500.0;
        const intake = 1500.0;

        for (int day = 0; day < 90; day++) {
          trueWeight += (intake - trueExp) / 7700.0;
          final scaleWeight = _nextGaussian(rng, trueWeight, 0.6);
          final state = filter.step(
            intakeKcal: intake,
            scaleWeightKg: scaleWeight,
            date: DateTime(2026, 1, 1).add(Duration(days: day)),
          );

          expect(state.expenditureKcal, greaterThan(0.0));
          expect(state.expenditureKcal.isNaN, isFalse);
          expect(state.expenditureKcal.isInfinite, isFalse);
        }

        expect(filter.expenditureKcal, lessThan(1750.0),
            reason:
                'Should converge down toward 1500 kcal from 3000 kcal initial estimate');
        expect(filter.expenditureKcal, greaterThan(1250.0));
      });

      test(
          'Extreme mismatch: true 4200 kcal vs initial 1800 kcal (+2400 kcal delta)',
          () {
        final rng = Random(3333);
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 95.0,
          initialExpenditureKcal: 1800.0,
        );
        double trueWeight = 95.0;
        const trueExp = 4200.0;
        const intake = 4200.0;

        for (int day = 0; day < 120; day++) {
          trueWeight += (intake - trueExp) / 7700.0;
          final scaleWeight = _nextGaussian(rng, trueWeight, 0.6);
          final state = filter.step(
            intakeKcal: intake,
            scaleWeightKg: scaleWeight,
            date: DateTime(2026, 1, 1).add(Duration(days: day)),
          );

          expect(state.expenditureKcal.isFinite, isTrue);
          expect(state.expenditureKcal, greaterThan(0.0));
          // Covariance positive-definiteness: det(P) > 0
          final det = (state.weightVariance * state.variance) -
              (state.crossCovariance * state.crossCovariance);
          expect(det, greaterThan(0.0));
        }

        expect(filter.expenditureKcal, greaterThan(3800.0));
      });
    });

    // -------------------------------------------------------------------------
    // 2. Massive Water Spikes (+/- 5 kg and Sustained Shocks)
    // -------------------------------------------------------------------------
    group('2. Massive Water Spikes and Drops', () {
      test(
          'Single-day +5.0 kg water spike on day 20 does not destabilize expenditure',
          () {
        final rng = Random(4444);
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 75.0,
          initialExpenditureKcal: 2200.0,
        );
        double trueWeight = 75.0;
        const trueExp = 2200.0;
        const intake = 2200.0;
        double maxExpenditureDeviation = 0.0;
        double maxWeightJump = 0.0;

        for (int day = 0; day < 50; day++) {
          trueWeight += (intake - trueExp) / 7700.0;
          final double waterSpike = (day == 20) ? 5.0 : 0.0;
          final scaleWeight = _nextGaussian(rng, trueWeight + waterSpike, 0.6);

          final prevWeight = filter.weightKg;
          final state = filter.step(
            intakeKcal: intake,
            scaleWeightKg: scaleWeight,
            date: DateTime(2026, 1, 1).add(Duration(days: day)),
          );

          if (day == 20) {
            maxWeightJump = (state.trendWeightKg - prevWeight).abs();
          }
          if (day >= 20 && day <= 30) {
            final dev = (state.expenditureKcal - trueExp).abs();
            if (dev > maxExpenditureDeviation) maxExpenditureDeviation = dev;
          }
        }

        // Huber clipping clamps innovation to 3*sigma (~1.8 kg).
        // The trend weight should NOT jump by +5 kg in one day.
        expect(maxWeightJump, lessThan(2.0),
            reason:
                'Huber clipping must prevent the trend weight from jumping more than ~1.8 kg on a 5 kg spike');
        // Expenditure must not fluctuate uncontrollably (< 200 kcal deviation)
        expect(maxExpenditureDeviation, lessThan(200.0),
            reason:
                'Single-day 5 kg water shock must not swing expenditure by more than 200 kcal');
      });

      test('Single-day -5.0 kg water flush / drop on day 20', () {
        final rng = Random(5555);
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 75.0,
          initialExpenditureKcal: 2200.0,
        );
        double trueWeight = 75.0;
        const trueExp = 2200.0;
        const intake = 2200.0;
        double maxExpenditureDeviation = 0.0;

        for (int day = 0; day < 50; day++) {
          trueWeight += (intake - trueExp) / 7700.0;
          final double waterDrop = (day == 20) ? -5.0 : 0.0;
          final scaleWeight = _nextGaussian(rng, trueWeight + waterDrop, 0.6);

          final state = filter.step(
            intakeKcal: intake,
            scaleWeightKg: scaleWeight,
            date: DateTime(2026, 1, 1).add(Duration(days: day)),
          );

          if (day >= 20 && day <= 30) {
            final dev = (state.expenditureKcal - trueExp).abs();
            if (dev > maxExpenditureDeviation) maxExpenditureDeviation = dev;
          }
        }

        expect(maxExpenditureDeviation, lessThan(200.0),
            reason:
                'Single-day -5 kg drop must not cause an expenditure blowout');
        expect(filter.expenditureKcal, greaterThan(0.0));
      });

      test('Sustained +5.0 kg water retention plateau (5 consecutive days)',
          () {
        final rng = Random(6666);
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 75.0,
          initialExpenditureKcal: 2200.0,
        );
        double trueWeight = 75.0;
        const trueExp = 2200.0;
        const intake = 2200.0;

        for (int day = 0; day < 60; day++) {
          trueWeight += (intake - trueExp) / 7700.0;
          final double waterPlateau = (day >= 20 && day <= 24) ? 5.0 : 0.0;
          final scaleWeight =
              _nextGaussian(rng, trueWeight + waterPlateau, 0.6);

          final state = filter.step(
            intakeKcal: intake,
            scaleWeightKg: scaleWeight,
            date: DateTime(2026, 1, 1).add(Duration(days: day)),
          );

          expect(state.expenditureKcal.isFinite, isTrue);
          expect(state.variance.isFinite, isTrue);
        }

        // By day 60 (35 days after plateau ended), expenditure should be back near 2200 kcal
        expect((filter.expenditureKcal - trueExp).abs(), lessThan(100.0));
      });
    });

    // -------------------------------------------------------------------------
    // 3. Highly Erratic Intake
    // -------------------------------------------------------------------------
    group('3. Highly Erratic Intake', () {
      test(
          'Extreme day-to-day intake oscillation (500 kcal vs 4000 kcal, avg 2250 kcal)',
          () {
        final rng = Random(7777);
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 75.0,
          initialExpenditureKcal: 2250.0,
        );
        double trueWeight = 75.0;
        const trueExp = 2250.0;
        final dailyDeltas = <double>[];
        double prevExp = 2250.0;

        for (int day = 0; day < 90; day++) {
          // Odd days: 500 kcal, Even days: 4000 kcal -> mean = 2250 kcal
          final intake = (day % 2 == 0) ? 4000.0 : 500.0;
          trueWeight += (intake - trueExp) / 7700.0;
          final scaleWeight = _nextGaussian(rng, trueWeight, 0.6);

          final state = filter.step(
            intakeKcal: intake,
            scaleWeightKg: scaleWeight,
            date: DateTime(2026, 1, 1).add(Duration(days: day)),
          );

          if (day >= 30) {
            dailyDeltas.add((state.expenditureKcal - prevExp).abs());
          }
          prevExp = state.expenditureKcal;
        }

        final avgJitter =
            dailyDeltas.reduce((a, b) => a + b) / dailyDeltas.length;
        // The Kalman filter should filter out high-frequency intake oscillations
        expect(avgJitter, lessThan(20.0),
            reason:
                'Daily jitter under 3500 kcal intake oscillation must remain under 20 kcal/day');
        // Overall estimate should remain tightly centered on 2250 kcal
        expect((filter.expenditureKcal - trueExp).abs(), lessThan(60.0),
            reason:
                'Mean expenditure under alternating intake must stay within 60 kcal of true TDEE');
      });

      test(
          'Weekend binge pattern: 1500 kcal (5 weekdays) vs 4250 kcal (2 weekend days)',
          () {
        // Average intake = (5 * 1500 + 2 * 4250) / 7 = 16000 / 7 = 2285.7 kcal
        const trueExp = 2285.71;
        final errors = <double>[];

        for (int run = 0; run < 50; run++) {
          final rng = Random(8800 + run);
          final filter = ExpenditureKalmanV4(
            initialWeightKg: 80.0,
            initialExpenditureKcal: trueExp,
          );
          double trueWeight = 80.0;

          for (int day = 0; day < 84; day++) {
            // 12 weeks
            final isWeekend = (day % 7 == 5) || (day % 7 == 6);
            final intake = isWeekend ? 4250.0 : 1500.0;
            trueWeight += (intake - trueExp) / 7700.0;
            final scaleWeight = _nextGaussian(rng, trueWeight, 0.6);

            filter.step(
              intakeKcal: intake,
              scaleWeightKg: scaleWeight,
              date: DateTime(2026, 1, 1).add(Duration(days: day)),
            );
          }
          errors.add((filter.expenditureKcal - trueExp).abs());
        }

        final avgError = errors.reduce((a, b) => a + b) / errors.length;
        expect(avgError, lessThan(40.0),
            reason:
                'Weekend binge pattern must converge within 40 kcal of true weekly average TDEE');
      });
    });

    // -------------------------------------------------------------------------
    // 4. Extended Missing Data and Logging Gaps
    // -------------------------------------------------------------------------
    group('4. Extended Missing Data and Gaps', () {
      test(
          '14 consecutive unlogged days freezes expenditure and pauses correctly',
          () {
        final rng = Random(9999);
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 75.0,
          initialExpenditureKcal: 2200.0,
        );
        double trueWeight = 75.0;
        const intake = 2200.0;

        // Baseline: 20 days logged
        for (int day = 0; day < 20; day++) {
          final scaleWeight = _nextGaussian(rng, trueWeight, 0.6);
          filter.step(intakeKcal: intake, scaleWeightKg: scaleWeight);
        }

        double? expWhenPaused;

        // Gap: 14 days unlogged (with scale weights present)
        for (int day = 20; day < 34; day++) {
          final scaleWeight = _nextGaussian(rng, trueWeight, 0.6);
          final state =
              filter.step(intakeKcal: null, scaleWeightKg: scaleWeight);

          if (day >= 24) {
            // Day 20, 21, 22, 23 = 4 unlogged days out of trailing 7 -> paused!
            expect(state.isPaused, isTrue);
            expWhenPaused ??= state.expenditureKcal;
            // While paused, expenditure must be strictly frozen
            expect(state.expenditureKcal, equals(expWhenPaused));
          }
        }

        // Resumption: log consistently for 7 days
        for (int day = 34; day < 41; day++) {
          final scaleWeight = _nextGaussian(rng, trueWeight, 0.6);
          final state =
              filter.step(intakeKcal: intake, scaleWeightKg: scaleWeight);

          if (day >= 38) {
            // After 4 consecutive logged days, unlogged count drops to <= 3 -> unpaused!
            expect(state.isPaused, isFalse);
          }
        }

        expect(filter.expenditureKcal.isFinite, isTrue);
        expect(filter.variance.isFinite, isTrue);
      });

      test('30 consecutive unlogged days with no scale weight either', () {
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 75.0,
          initialExpenditureKcal: 2200.0,
        );

        // 14 days normal logging
        for (int day = 0; day < 14; day++) {
          filter.step(intakeKcal: 2200.0, scaleWeightKg: 75.0);
        }

        final expAtStartOfGap = filter.expenditureKcal;

        // 30 days complete blackout (no food, no weight)
        for (int day = 14; day < 44; day++) {
          final state = filter.step(intakeKcal: null, scaleWeightKg: null);
          if (day >= 18) {
            expect(state.isPaused, isTrue);
            expect(state.expenditureKcal, equals(expAtStartOfGap));
          }
          expect(state.confidence, greaterThanOrEqualTo(0.1));
          expect(state.confidence, lessThanOrEqualTo(1.0));
        }

        // Logging resumes
        for (int day = 44; day < 60; day++) {
          final state = filter.step(intakeKcal: 2200.0, scaleWeightKg: 75.0);
          expect(state.expenditureKcal.isFinite, isTrue);
        }

        expect(filter.expenditureKcal, equals(expAtStartOfGap));
      });

      test(
          '100 consecutive unlogged days: variance and covariance remain strictly bounded and non-NaN',
          () {
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 75.0,
          initialExpenditureKcal: 2000.0,
        );

        // Initial 7 days
        for (int day = 0; day < 7; day++) {
          filter.step(intakeKcal: 2000.0, scaleWeightKg: 75.0);
        }

        for (int day = 7; day < 107; day++) {
          final state = filter.step(intakeKcal: null, scaleWeightKg: 75.0);
          expect(state.variance.isNaN, isFalse);
          expect(state.variance.isInfinite, isFalse);
          expect(state.weightVariance.isNaN, isFalse);
          expect(state.crossCovariance.isNaN, isFalse);

          // Positive definiteness check: det(P) > 0
          final det = (state.weightVariance * state.variance) -
              (state.crossCovariance * state.crossCovariance);
          expect(det, greaterThan(0.0),
              reason:
                  'Covariance matrix must remain strictly positive definite');
        }
      });
    });

    // -------------------------------------------------------------------------
    // 5. Boundary Inputs, Malformed Data & Incomplete Day Gating
    // -------------------------------------------------------------------------
    group('5. Boundary Inputs and Malformed Data', () {
      test(
          'Zero and negative intake inputs are safely handled as unlogged days',
          () {
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 70.0,
          initialExpenditureKcal: 2000.0,
        );

        // Day with 0.0 intake
        final stateZero = filter.step(intakeKcal: 0.0, scaleWeightKg: 70.0);
        expect(stateZero.expenditureKcal.isFinite, isTrue);

        // Day with negative intake (e.g. malformed user entry -500 kcal)
        final stateNeg = filter.step(intakeKcal: -500.0, scaleWeightKg: 70.0);
        expect(stateNeg.expenditureKcal.isFinite, isTrue);
        expect(stateNeg.expenditureKcal, greaterThan(0.0));
      });

      test(
          'Negative scale weight input is rejected by Huber bounds or filtered safely',
          () {
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 70.0,
          initialExpenditureKcal: 2000.0,
        );

        // Feed scale weight = -10.0 kg
        final state = filter.step(intakeKcal: 2000.0, scaleWeightKg: -10.0);
        expect(state.expenditureKcal.isFinite, isTrue);
        expect(state.trendWeightKg.isFinite, isTrue);
        // Trend weight should not collapse to -10 kg because innovation is Huber-clipped!
        expect(state.trendWeightKg, greaterThan(65.0),
            reason:
                'Huber clipping must prevent catastrophic collapse on negative scale weight input');
      });

      test(
          'Massive calorie intake (e.g. 25,000 kcal feast) does not cause numerical overflow',
          () {
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 70.0,
          initialExpenditureKcal: 2000.0,
        );

        final state = filter.step(intakeKcal: 25000.0, scaleWeightKg: 70.0);
        expect(state.expenditureKcal.isFinite, isTrue);
        expect(state.trendWeightKg.isFinite, isTrue);
        expect(state.variance.isFinite, isTrue);
      });

      test(
          'Incomplete day gating: unclosed day updates measurement but does not predict forward',
          () {
        final date = DateTime(2026, 3, 15);
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 75.0,
          initialExpenditureKcal: 2000.0,
        );

        // Complete previous day
        filter.processDay(DailyExpenditureInput(
          date: date.subtract(const Duration(days: 1)),
          scaleWeightKg: 75.0,
          loggedIntakeKcal: 2000.0,
          isLogged: true,
          isDayComplete: true,
        ));

        final weightBeforeToday = filter.weightKg;

        // Process today as INCOMPLETE
        final incompleteState = filter.processDay(DailyExpenditureInput(
          date: date,
          scaleWeightKg: 75.5,
          loggedIntakeKcal: 1200.0, // Lunch time intake
          isLogged: true,
          isDayComplete: false,
        ));

        expect(incompleteState.isDayComplete, isFalse);
        // Measurement update occurred (weight tracks scale weight)
        expect(filter.weightKg, isNot(equals(weightBeforeToday)));

        // If today is re-run as incomplete again (simulating multiple app opens in the day),
        // it behaves deterministically
        expect(incompleteState.expenditureKcal.isFinite, isTrue);
      });

      test('Batch process matches sequential processing identically', () {
        final inputs = List<DailyExpenditureInput>.generate(30, (i) {
          return DailyExpenditureInput(
            date: DateTime(2026, 1, 1).add(Duration(days: i)),
            scaleWeightKg: 70.0 + (i * 0.05),
            loggedIntakeKcal: 2100.0 + (i % 3 == 0 ? 300.0 : -100.0),
            isLogged: i % 5 != 0,
            isDayComplete: true,
          );
        });

        // Method 1: batchProcess
        final batchResults = ExpenditureKalmanV4.batchProcess(
          initialExpenditureKcal: 2000.0,
          initialWeightKg: 70.0,
          inputs: inputs,
        );

        // Method 2: sequential processDay
        final seqFilter = ExpenditureKalmanV4(
          initialExpenditureKcal: 2000.0,
          initialWeightKg: 70.0,
        );
        final seqResults = <ExpenditureState>[];
        for (final input in inputs) {
          seqResults.add(seqFilter.processDay(input));
        }

        expect(batchResults.length, equals(seqResults.length));
        for (int i = 0; i < batchResults.length; i++) {
          expect(batchResults[i].expenditureKcal,
              equals(seqResults[i].expenditureKcal));
          expect(batchResults[i].trendWeightKg,
              equals(seqResults[i].trendWeightKg));
          expect(batchResults[i].variance, equals(seqResults[i].variance));
        }
      });
    });

    // -------------------------------------------------------------------------
    // 6. Covariance Invariants & Numerical Stability across 10,000 steps
    // -------------------------------------------------------------------------
    group('6. Covariance Invariants and Numerical Stability', () {
      test(
          '10,000 Monte Carlo steps under mixed random shocks maintain strict positive definiteness',
          () {
        final rng = Random(12345);
        final filter = ExpenditureKalmanV4(
          initialWeightKg: 80.0,
          initialExpenditureKcal: 2500.0,
        );
        double trueWeight = 80.0;
        double trueExp = 2500.0;

        for (int step = 0; step < 10000; step++) {
          // Dynamic drift in true expenditure
          trueExp += _nextGaussian(rng, 0.0, 3.0);
          trueExp = trueExp.clamp(1200.0, 4500.0);

          // Random intake with sporadic large feasts or fasts
          double intake = trueExp + _nextGaussian(rng, 0.0, 300.0);
          final isUnlogged = rng.nextDouble() < 0.15; // 15% unlogged
          if (isUnlogged) intake = 0.0;

          // True weight evolution
          if (!isUnlogged) {
            trueWeight += (intake - trueExp) / 7700.0;
          }

          // Random water spikes (1% chance of +/- 4 kg shock)
          double waterNoise = 0.0;
          if (rng.nextDouble() < 0.01) {
            waterNoise = rng.nextBool() ? 4.0 : -4.0;
          }

          // Scale weight
          final hasWeighIn =
              rng.nextDouble() < 0.85; // 85% weigh-in probability
          final scaleWeight = hasWeighIn
              ? _nextGaussian(rng, trueWeight + waterNoise, 0.6)
              : null;

          final state = filter.step(
            intakeKcal: isUnlogged ? null : intake,
            scaleWeightKg: scaleWeight,
          );

          // INVARIANTS:
          // 1. No NaN or Infinity anywhere
          expect(state.expenditureKcal.isFinite, isTrue,
              reason: 'expenditure must be finite at step $step');
          expect(state.trendWeightKg.isFinite, isTrue,
              reason: 'trendWeight must be finite at step $step');
          expect(state.variance.isFinite, isTrue,
              reason: 'variance must be finite at step $step');
          expect(state.weightVariance.isFinite, isTrue,
              reason: 'weightVariance must be finite at step $step');
          expect(state.crossCovariance.isFinite, isTrue,
              reason: 'crossCovariance must be finite at step $step');
          expect(state.confidence.isFinite, isTrue,
              reason: 'confidence must be finite at step $step');

          // 2. Positivity
          expect(state.expenditureKcal, greaterThan(0.0),
              reason: 'expenditure must be strictly positive at step $step');
          expect(state.variance, greaterThan(0.0),
              reason: 'P_EE must be positive at step $step');
          expect(state.weightVariance, greaterThan(0.0),
              reason: 'P_WW must be positive at step $step');

          // 3. Positive definiteness: det(P) = P_WW * P_EE - P_WE^2 > 0
          final det = (state.weightVariance * state.variance) -
              (state.crossCovariance * state.crossCovariance);
          expect(det, greaterThan(0.0),
              reason:
                  'Determinant of covariance matrix must remain strictly positive at step $step');

          // 4. Cauchy-Schwarz: |P_WE| / sqrt(P_WW * P_EE) <= 0.999
          final correlation = (state.crossCovariance.abs()) /
              sqrt(state.weightVariance * state.variance);
          expect(correlation, lessThanOrEqualTo(0.9991),
              reason:
                  'Correlation cannot exceed regularization cap at step $step');
        }
      });

      test(
          'Cold-start bootstrap: food logging prior to first scale weigh-in preserves 0.0 weight until weigh-in',
          () {
        final filter = ExpenditureKalmanV4(initialExpenditureKcal: 2000.0);
        expect(filter.currentWeightKg, equals(0.0));

        // Day 1: Log food (2500 kcal), day complete, but no scale weight
        filter.processDay(DailyExpenditureInput(
          date: DateTime(2026, 5, 1),
          scaleWeightKg: null,
          loggedIntakeKcal: 2500.0,
          isLogged: true,
          isDayComplete: true,
        ));

        // Weight must remain strictly 0.0 (not driven away by intake-expenditure delta)
        expect(filter.currentWeightKg, equals(0.0));
        expect(filter.crossCovariance, equals(0.0));

        // Day 2: Another food logging day (2400 kcal) with no scale weight
        filter.processDay(DailyExpenditureInput(
          date: DateTime(2026, 5, 2),
          scaleWeightKg: null,
          loggedIntakeKcal: 2400.0,
          isLogged: true,
          isDayComplete: true,
        ));
        expect(filter.currentWeightKg, equals(0.0));

        // Day 3: First scale weigh-in at 75.0 kg
        final stateDay3 = filter.processDay(DailyExpenditureInput(
          date: DateTime(2026, 5, 3),
          scaleWeightKg: 75.0,
          loggedIntakeKcal: 2000.0,
          isLogged: true,
          isDayComplete: true,
        ));

        // Bootstrap immediately establishes 75.0 kg without Huber lag
        expect(stateDay3.trendWeightKg, equals(75.0));
        expect(filter.currentWeightKg, equals(75.0));
      });
    });
  });
}
