import 'package:flutter_test/flutter_test.dart';

/// Embedded reference implementation of legacy V3 Bayesian Tracker.
/// Preserved as an immutable historical record to freeze legacy outputs
/// even after expenditure_algorithm_v3.dart is deleted from lib/.
class LegacyDailyEnergyObservation {
  const LegacyDailyEnergyObservation({
    required this.date,
    required this.loggedIntakeKcal,
    required this.trendWeightDeltaKg,
    this.isFullyLogged = true,
  }) : assert(loggedIntakeKcal >= 0, 'Intake must be non-negative');

  final DateTime date;
  final double loggedIntakeKcal;
  final double trendWeightDeltaKg;
  final bool isFullyLogged;
}

class LegacyExpenditureState {
  const LegacyExpenditureState({
    required this.expenditureKcal,
    required this.variance,
    required this.confidence,
    required this.isPaused,
    required this.consecutiveMissingDays,
    this.lastObservationDate,
  });

  final double expenditureKcal;
  final double variance;
  final double confidence;
  final bool isPaused;
  final int consecutiveMissingDays;
  final DateTime? lastObservationDate;

  LegacyExpenditureState copyWith({
    double? expenditureKcal,
    double? variance,
    double? confidence,
    bool? isPaused,
    int? consecutiveMissingDays,
    DateTime? lastObservationDate,
  }) {
    return LegacyExpenditureState(
      expenditureKcal: expenditureKcal ?? this.expenditureKcal,
      variance: variance ?? this.variance,
      confidence: confidence ?? this.confidence,
      isPaused: isPaused ?? this.isPaused,
      consecutiveMissingDays:
          consecutiveMissingDays ?? this.consecutiveMissingDays,
      lastObservationDate: lastObservationDate ?? this.lastObservationDate,
    );
  }
}

class LegacyExpenditureAlgorithmV3 {
  LegacyExpenditureAlgorithmV3({
    required double initialExpenditureKcal,
    double initialVariance = 40000.0,
  })  : assert(
            initialExpenditureKcal > 0, 'Initial expenditure must be positive'),
        _state = LegacyExpenditureState(
          expenditureKcal: initialExpenditureKcal,
          variance: initialVariance,
          confidence: 0.5,
          isPaused: false,
          consecutiveMissingDays: 0,
        );

  LegacyExpenditureState _state;
  LegacyExpenditureState get currentState => _state;

  static const double kcalPerKg = 7700.0;
  static const double maxDailyFluxKcal = 150.0;
  static const int maxMissingDaysBeforePause = 3;
  static const double observationNoise = 60000.0;
  static const double processNoise = 2500.0;

  void updateDaily(LegacyDailyEnergyObservation observation) {
    if (!observation.isFullyLogged) {
      recordMissingDay(observation.date);
      return;
    }

    const isPaused = false;
    const consecutiveMissing = 0;

    final weightDeltaKcal = observation.trendWeightDeltaKg * kcalPerKg;
    final observedExpenditure = observation.loggedIntakeKcal - weightDeltaKcal;

    final priorVariance = _state.isPaused
        ? _state.variance * 2.0
        : _state.variance + processNoise;
    final kalmanGain = priorVariance / (priorVariance + observationNoise);

    final error = observedExpenditure - _state.expenditureKcal;
    final rawAdjustment = kalmanGain * error;

    final clampedAdjustment =
        rawAdjustment.clamp(-maxDailyFluxKcal, maxDailyFluxKcal);
    final updatedExpenditure = _state.expenditureKcal + clampedAdjustment;

    final effectiveGain = (error == 0.0)
        ? kalmanGain
        : (clampedAdjustment / error).abs().clamp(0.0, kalmanGain);

    final posteriorVariance = (1.0 - effectiveGain) * priorVariance;

    final confidence =
        (1.0 - (posteriorVariance / (posteriorVariance + 20000.0)))
            .clamp(0.1, 0.99);

    _state = _state.copyWith(
      expenditureKcal: updatedExpenditure,
      variance: posteriorVariance,
      confidence: confidence,
      isPaused: isPaused,
      consecutiveMissingDays: consecutiveMissing,
      lastObservationDate: observation.date,
    );
  }

  void recordMissingDay(DateTime date) {
    final newMissing = _state.consecutiveMissingDays + 1;
    final shouldPause = newMissing > maxMissingDaysBeforePause;

    _state = _state.copyWith(
      consecutiveMissingDays: newMissing,
      isPaused: shouldPause,
      variance: _state.variance + processNoise * 2.0,
      confidence: (_state.confidence * 0.95).clamp(0.1, 0.95),
      lastObservationDate: date,
    );
  }
}

void main() {
  group('LegacyExpenditureAlgorithmV3 Baseline Frozen Golden Tests', () {
    test('Scenario 1: Steady Weight Maintenance (7 days @ 2000 kcal)', () {
      final algo = LegacyExpenditureAlgorithmV3(initialExpenditureKcal: 2000.0);

      // Verify Day 0 Initial State
      expect(algo.currentState.expenditureKcal, equals(2000.0));
      expect(algo.currentState.variance, equals(40000.0));
      expect(algo.currentState.confidence, equals(0.5));
      expect(algo.currentState.isPaused, isFalse);

      // Hardcoded golden outputs
      final goldenStates = [
        {'exp': 2000.0, 'var': 24878.048780487807, 'conf': 0.44565217391304346},
        {'exp': 2000.0, 'var': 18799.720865317515, 'conf': 0.5154676258992806},
        {'exp': 2000.0, 'var': 15719.405162979336, 'conf': 0.5599197385495267},
        {'exp': 2000.0, 'var': 13975.615226183627, 'conf': 0.5886574788081191},
        {'exp': 2000.0, 'var': 12926.171442326147, 'conf': 0.6074195426890802},
        {'exp': 2000.0, 'var': 12271.208638069304, 'conf': 0.6197474728729759},
        {'exp': 2000.0, 'var': 11853.125480078412, 'conf': 0.6278818702581762},
      ];

      for (int i = 0; i < 7; i++) {
        algo.updateDaily(LegacyDailyEnergyObservation(
          date: DateTime(2026, 1, i + 1),
          loggedIntakeKcal: 2000.0,
          trendWeightDeltaKg: 0.0,
          isFullyLogged: true,
        ));

        final expected = goldenStates[i];
        expect(algo.currentState.expenditureKcal, equals(expected['exp']));
        expect(algo.currentState.variance, closeTo(expected['var']!, 1e-6));
        expect(algo.currentState.confidence, closeTo(expected['conf']!, 1e-6));
      }
    });

    test('Scenario 2: Flux Clamping (+/- 150 kcal clamp)', () {
      final algo = LegacyExpenditureAlgorithmV3(initialExpenditureKcal: 2000.0);

      // Day 1: +2000 kcal intake surge clamped to +150 kcal
      algo.updateDaily(LegacyDailyEnergyObservation(
        date: DateTime(2026, 1, 1),
        loggedIntakeKcal: 4000.0,
        trendWeightDeltaKg: 0.0,
        isFullyLogged: true,
      ));
      expect(algo.currentState.expenditureKcal, equals(2150.0));
      expect(algo.currentState.variance, closeTo(39312.5, 1e-4));
      expect(algo.currentState.confidence, closeTo(0.3371970495, 1e-6));

      // Day 2: 500 kcal intake plunge clamped to -150 kcal
      algo.updateDaily(LegacyDailyEnergyObservation(
        date: DateTime(2026, 1, 2),
        loggedIntakeKcal: 500.0,
        trendWeightDeltaKg: 0.0,
        isFullyLogged: true,
      ));
      expect(algo.currentState.expenditureKcal, equals(2000.0));
      expect(algo.currentState.variance, closeTo(38011.363636, 1e-4));
      expect(algo.currentState.confidence, closeTo(0.344760039, 1e-6));
    });

    test('Scenario 3: Calorie Deficit & Weight Loss', () {
      final algo = LegacyExpenditureAlgorithmV3(initialExpenditureKcal: 2500.0);
      final goldenExps = [
        2570.487804878049,
        2601.6678297278436,
        2619.5701808974054,
        2631.3166433591373,
        2639.6504383575448,
        2645.85753507402,
        2650.6269295101206,
      ];

      for (int i = 0; i < 7; i++) {
        algo.updateDaily(LegacyDailyEnergyObservation(
          date: DateTime(2026, 1, i + 1),
          loggedIntakeKcal: 1900.0,
          trendWeightDeltaKg: -0.1, // -770 kcal delta -> observed = 2670 kcal
          isFullyLogged: true,
        ));
        expect(algo.currentState.expenditureKcal, closeTo(goldenExps[i], 1e-6));
      }
    });

    test('Scenario 4: Calorie Surplus & Weight Gain', () {
      final algo = LegacyExpenditureAlgorithmV3(initialExpenditureKcal: 2200.0);
      final goldenExps = [
        2289.1463414634145,
        2328.5799023028612,
        2351.2211111349543,
        2366.0769313071446,
        2376.6167308639538,
        2384.4668825936137,
        2390.4987637922113,
      ];

      for (int i = 0; i < 7; i++) {
        algo.updateDaily(LegacyDailyEnergyObservation(
          date: DateTime(2026, 1, i + 1),
          loggedIntakeKcal: 2800.0,
          trendWeightDeltaKg: 0.05, // +385 kcal delta -> observed = 2415 kcal
          isFullyLogged: true,
        ));
        expect(algo.currentState.expenditureKcal, closeTo(goldenExps[i], 1e-6));
      }
    });

    test('Scenario 5: Logging Gap > 3 Days (Pausing)', () {
      final algo = LegacyExpenditureAlgorithmV3(initialExpenditureKcal: 2400.0);

      algo.recordMissingDay(DateTime(2026, 1, 1));
      expect(algo.currentState.isPaused, isFalse);
      expect(algo.currentState.consecutiveMissingDays, equals(1));
      expect(algo.currentState.variance, equals(45000.0));
      expect(algo.currentState.confidence, equals(0.475));

      algo.recordMissingDay(DateTime(2026, 1, 2));
      expect(algo.currentState.isPaused, isFalse);
      expect(algo.currentState.consecutiveMissingDays, equals(2));
      expect(algo.currentState.variance, equals(50000.0));
      expect(algo.currentState.confidence, equals(0.45125));

      algo.recordMissingDay(DateTime(2026, 1, 3));
      expect(algo.currentState.isPaused, isFalse);
      expect(algo.currentState.consecutiveMissingDays, equals(3));
      expect(algo.currentState.variance, equals(55000.0));
      expect(algo.currentState.confidence, closeTo(0.4286875, 1e-6));

      algo.recordMissingDay(DateTime(2026, 1, 4));
      expect(algo.currentState.isPaused, isTrue);
      expect(algo.currentState.consecutiveMissingDays, equals(4));
      expect(algo.currentState.variance, equals(60000.0));
      expect(algo.currentState.confidence, closeTo(0.407253125, 1e-6));
    });

    test('Scenario 6: Recovery After Logging Pause', () {
      final algo = LegacyExpenditureAlgorithmV3(initialExpenditureKcal: 2400.0);
      for (int i = 1; i <= 4; i++) {
        algo.recordMissingDay(DateTime(2026, 1, i));
      }
      expect(algo.currentState.isPaused, isTrue);

      // Day 5: logging resumes
      algo.updateDaily(LegacyDailyEnergyObservation(
        date: DateTime(2026, 1, 5),
        loggedIntakeKcal: 2400.0,
        trendWeightDeltaKg: 0.0,
        isFullyLogged: true,
      ));
      expect(algo.currentState.isPaused, isFalse);
      expect(algo.currentState.consecutiveMissingDays, equals(0));
      expect(algo.currentState.expenditureKcal, equals(2400.0));
      expect(algo.currentState.variance, closeTo(40000.0, 1e-6));
      expect(algo.currentState.confidence, closeTo(0.333333333, 1e-6));

      // Day 6: subsequent update
      algo.updateDaily(LegacyDailyEnergyObservation(
        date: DateTime(2026, 1, 6),
        loggedIntakeKcal: 2500.0,
        trendWeightDeltaKg: 0.0,
        isFullyLogged: true,
      ));
      expect(algo.currentState.expenditureKcal, closeTo(2441.4634146, 1e-6));
      expect(algo.currentState.variance, closeTo(24878.04878, 1e-4));
      expect(algo.currentState.confidence, closeTo(0.44565217, 1e-6));
    });
  });
}
