/// Represents a single day's caloric intake and weight trend slope observation.
class DailyEnergyObservation {
  const DailyEnergyObservation({
    required this.date,
    required this.loggedIntakeKcal,
    required this.trendWeightDeltaKg,
    this.isFullyLogged = true,
  }) : assert(loggedIntakeKcal >= 0, 'Intake must be non-negative');

  final DateTime date;
  final double loggedIntakeKcal;
  final double trendWeightDeltaKg;
  final bool isFullyLogged;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyEnergyObservation &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          loggedIntakeKcal == other.loggedIntakeKcal &&
          trendWeightDeltaKg == other.trendWeightDeltaKg &&
          isFullyLogged == other.isFullyLogged;

  @override
  int get hashCode =>
      date.hashCode ^
      loggedIntakeKcal.hashCode ^
      trendWeightDeltaKg.hashCode ^
      isFullyLogged.hashCode;
}

/// The state of the Bayesian dynamic expenditure tracker.
class ExpenditureState {
  const ExpenditureState({
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

  ExpenditureState copyWith({
    double? expenditureKcal,
    double? variance,
    double? confidence,
    bool? isPaused,
    int? consecutiveMissingDays,
    DateTime? lastObservationDate,
  }) {
    return ExpenditureState(
      expenditureKcal: expenditureKcal ?? this.expenditureKcal,
      variance: variance ?? this.variance,
      confidence: confidence ?? this.confidence,
      isPaused: isPaused ?? this.isPaused,
      consecutiveMissingDays:
          consecutiveMissingDays ?? this.consecutiveMissingDays,
      lastObservationDate: lastObservationDate ?? this.lastObservationDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenditureState &&
          runtimeType == other.runtimeType &&
          expenditureKcal == other.expenditureKcal &&
          variance == other.variance &&
          confidence == other.confidence &&
          isPaused == other.isPaused &&
          consecutiveMissingDays == other.consecutiveMissingDays &&
          lastObservationDate == other.lastObservationDate;

  @override
  int get hashCode =>
      expenditureKcal.hashCode ^
      variance.hashCode ^
      confidence.hashCode ^
      isPaused.hashCode ^
      consecutiveMissingDays.hashCode ^
      lastObservationDate.hashCode;
}

/// MacroFactor V3 Bayesian Adaptive State-Space Expenditure Algorithm.
/// Adherence-neutral, flux-dampened (+/- 150 kcal/day), with 3-day missing gap resilience.
class ExpenditureAlgorithmV3 {
  ExpenditureAlgorithmV3({
    required double initialExpenditureKcal,
    double initialVariance = 40000.0,
  })  : assert(
            initialExpenditureKcal > 0, 'Initial expenditure must be positive'),
        _state = ExpenditureState(
          expenditureKcal: initialExpenditureKcal,
          variance: initialVariance,
          confidence: 0.5,
          isPaused: false,
          consecutiveMissingDays: 0,
        );

  ExpenditureState _state;
  ExpenditureState get currentState => _state;

  /// Human tissue energy density (7,700 kcal per 1 kg).
  static const double kcalPerKg = 7700.0;

  /// Maximum allowed daily expenditure adjustment flux to prevent volatility.
  static const double maxDailyFluxKcal = 150.0;

  /// Maximum consecutive days of missing food logs before expenditure is paused.
  static const int maxMissingDaysBeforePause = 3;

  /// Observation noise variance in daily human calorie/weight reporting.
  static const double observationNoise = 60000.0;

  /// Process noise variance (daily metabolic variation).
  static const double processNoise = 2500.0;

  /// Updates the dynamic expenditure with a daily observation.
  void updateDaily(DailyEnergyObservation observation) {
    if (!observation.isFullyLogged) {
      recordMissingDay(observation.date);
      return;
    }

    const isPaused = false;
    const consecutiveMissing = 0;

    // Weight delta equivalent in calories: deltaKg * 7700 kcal/kg
    final weightDeltaKcal = observation.trendWeightDeltaKg * kcalPerKg;

    // First principles energy balance: Observed_TDEE = Intake - deltaWeightCalories
    final observedExpenditure = observation.loggedIntakeKcal - weightDeltaKcal;

    // Bayesian Kalman Gain: K = P / (P + R)
    final priorVariance = _state.isPaused
        ? _state.variance * 2.0
        : _state.variance + processNoise;
    final kalmanGain = priorVariance / (priorVariance + observationNoise);

    // Innovation step
    final error = observedExpenditure - _state.expenditureKcal;
    final rawAdjustment = kalmanGain * error;

    // Apply strict daily flux clamp [-150, +150]
    final clampedAdjustment =
        rawAdjustment.clamp(-maxDailyFluxKcal, maxDailyFluxKcal);
    final updatedExpenditure = _state.expenditureKcal + clampedAdjustment;

    // Effective Kalman gain accounting for clamping truncation:
    // Avoids premature variance shrinkage when flux is truncated.
    final effectiveGain = (error == 0.0)
        ? kalmanGain
        : (clampedAdjustment / error).abs().clamp(0.0, kalmanGain);

    // Posterior variance: P = (1 - K_eff) * P
    final posteriorVariance = (1.0 - effectiveGain) * priorVariance;

    // Normalized confidence metric: 0.0 (high uncertainty) to 1.0 (high precision)
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

  /// Records a missed or partially logged day.
  void recordMissingDay(DateTime date) {
    final newMissing = _state.consecutiveMissingDays + 1;
    final shouldPause = newMissing > maxMissingDaysBeforePause;

    _state = _state.copyWith(
      consecutiveMissingDays: newMissing,
      isPaused: shouldPause,
      // Increase variance on missed days due to growing uncertainty
      variance: _state.variance + processNoise * 2.0,
      confidence: (_state.confidence * 0.95).clamp(0.1, 0.95),
      lastObservationDate: date,
    );
  }
}
