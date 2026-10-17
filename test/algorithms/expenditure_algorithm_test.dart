import 'package:flutter_test/flutter_test.dart';
import 'package:macro_factor_app/domain/algorithms/expenditure_algorithm_v3.dart';

void main() {
  group('ExpenditureAlgorithmV3 Tests', () {
    test('Initializes with baseline expenditure and prior variance', () {
      final algo = ExpenditureAlgorithmV3(
        initialExpenditureKcal: 2500.0,
      );

      final state = algo.currentState;
      expect(state.expenditureKcal, equals(2500.0));
      expect(state.confidence, closeTo(0.5, 0.1));
      expect(state.isPaused, isFalse);
    });

    test('Adapts expenditure up when user maintains weight on higher calories',
        () {
      final algo = ExpenditureAlgorithmV3(
        initialExpenditureKcal: 2200.0,
      );

      // User ate 2600 kcal every day for 7 days, but trend weight remained constant (delta = 0)
      for (int i = 0; i < 7; i++) {
        algo.updateDaily(
          DailyEnergyObservation(
            date: DateTime(2026, 1, i + 1),
            loggedIntakeKcal: 2600.0,
            trendWeightDeltaKg: 0.0,
            isFullyLogged: true,
          ),
        );
      }

      // Expenditure should adapt upward towards 2600 kcal
      expect(algo.currentState.expenditureKcal, greaterThan(2200.0));
      expect(algo.currentState.confidence, greaterThan(0.5));
      expect(
          algo.currentState.lastObservationDate, equals(DateTime(2026, 1, 7)));
    });

    test('Enforces daily flux clamp (+/- 150 kcal max adjustment per step)',
        () {
      final algo = ExpenditureAlgorithmV3(
        initialExpenditureKcal: 2000.0,
      );

      // Extreme one-day reading: 4000 kcal intake with no weight gain
      algo.updateDaily(
        DailyEnergyObservation(
          date: DateTime(2026, 1, 1),
          loggedIntakeKcal: 4000.0,
          trendWeightDeltaKg: 0.0,
          isFullyLogged: true,
        ),
      );

      // Max single-day flux dampening is 150 kcal
      expect(algo.currentState.expenditureKcal, lessThanOrEqualTo(2150.0));
    });

    test(
        'Transitions to missing day state when observation is not fully logged',
        () {
      final algo = ExpenditureAlgorithmV3(initialExpenditureKcal: 2500.0);
      algo.updateDaily(
        DailyEnergyObservation(
          date: DateTime(2026, 1, 1),
          loggedIntakeKcal: 1200.0,
          trendWeightDeltaKg: 0.0,
          isFullyLogged: false,
        ),
      );
      expect(algo.currentState.consecutiveMissingDays, equals(1));
      expect(
          algo.currentState.lastObservationDate, equals(DateTime(2026, 1, 1)));
    });

    test(
        'Maintains continuous state for short gaps (<= 3 days) and pauses on long gaps (> 3 days)',
        () {
      final algo = ExpenditureAlgorithmV3(
        initialExpenditureKcal: 2400.0,
      );

      // 2 missed days: should NOT pause
      algo.recordMissingDay(DateTime(2026, 1, 1));
      algo.recordMissingDay(DateTime(2026, 1, 2));
      expect(algo.currentState.isPaused, isFalse);
      expect(algo.currentState.consecutiveMissingDays, equals(2));

      // 4th consecutive missed day: should transition to paused state
      algo.recordMissingDay(DateTime(2026, 1, 3));
      algo.recordMissingDay(DateTime(2026, 1, 4));
      expect(algo.currentState.isPaused, isTrue);
      expect(algo.currentState.consecutiveMissingDays, equals(4));

      // Logging resumed on day 5: unpauses and widens prior variance
      algo.updateDaily(
        DailyEnergyObservation(
          date: DateTime(2026, 1, 5),
          loggedIntakeKcal: 2400.0,
          trendWeightDeltaKg: 0.0,
          isFullyLogged: true,
        ),
      );
      expect(algo.currentState.isPaused, isFalse);
      expect(algo.currentState.consecutiveMissingDays, equals(0));
    });

    test(
        'Value equality and copyWith on ExpenditureState and DailyEnergyObservation',
        () {
      final obs1 = DailyEnergyObservation(
        date: DateTime(2026, 1, 1),
        loggedIntakeKcal: 2000.0,
        trendWeightDeltaKg: 0.1,
      );
      final obs2 = DailyEnergyObservation(
        date: DateTime(2026, 1, 1),
        loggedIntakeKcal: 2000.0,
        trendWeightDeltaKg: 0.1,
      );
      expect(obs1, equals(obs2));
      expect(obs1.hashCode, equals(obs2.hashCode));

      const state1 = ExpenditureState(
        expenditureKcal: 2000.0,
        variance: 1000.0,
        confidence: 0.8,
        isPaused: false,
        consecutiveMissingDays: 0,
      );

      const state2 = ExpenditureState(
        expenditureKcal: 2000.0,
        variance: 1000.0,
        confidence: 0.8,
        isPaused: false,
        consecutiveMissingDays: 0,
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));

      final copied = state1.copyWith(expenditureKcal: 2100.0);
      expect(copied.expenditureKcal, equals(2100.0));
      expect(copied.variance, equals(1000.0));
      expect(copied.confidence, equals(0.8));
      expect(copied.isPaused, isFalse);
      expect(copied.consecutiveMissingDays, equals(0));
    });
  });
}
