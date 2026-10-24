import 'dart:math' as math;

/// Represents a daily input observation for the ExpenditureKalmanV4 filter.
class DailyExpenditureInput {
  const DailyExpenditureInput({
    required this.date,
    this.scaleWeightKg,
    this.loggedIntakeKcal,
    this.isLogged = true,
    this.isDayComplete = true,
  });

  /// The calendar date of this observation.
  final DateTime date;

  /// Morning scale weight observation in kilograms (null if not weighed).
  final double? scaleWeightKg;

  /// Total calories consumed on this day in kcal (null or 0 if unlogged).
  final double? loggedIntakeKcal;

  /// Whether food logging was performed for this day.
  final bool isLogged;

  /// Whether this day has completed (false for the ongoing current day).
  final bool isDayComplete;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyExpenditureInput &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          scaleWeightKg == other.scaleWeightKg &&
          loggedIntakeKcal == other.loggedIntakeKcal &&
          isLogged == other.isLogged &&
          isDayComplete == other.isDayComplete;

  @override
  int get hashCode =>
      date.hashCode ^
      scaleWeightKg.hashCode ^
      loggedIntakeKcal.hashCode ^
      isLogged.hashCode ^
      isDayComplete.hashCode;
}

/// The posterior state of the ExpenditureKalmanV4 filter for a given date.
class ExpenditureState {
  const ExpenditureState({
    required this.date,
    required this.expenditureKcal,
    required this.trendWeightKg,
    required this.variance,
    required this.weightVariance,
    required this.crossCovariance,
    required this.confidence,
    required this.isPaused,
    required this.unloggedDaysInWindow,
    this.isDayComplete = true,
  });

  /// Calendar date of this estimate.
  final DateTime date;

  /// Latent daily energy expenditure in kcal/day.
  final double expenditureKcal;

  /// Latent true trend weight in kg.
  final double trendWeightKg;

  /// Expenditure error variance P_EE in (kcal/day)^2.
  final double variance;

  /// Weight error variance P_WW in kg^2.
  final double weightVariance;

  /// Weight-expenditure cross-covariance P_WE in kg * kcal.
  final double crossCovariance;

  /// Normalized statistical confidence score [0.0, 1.0].
  final double confidence;

  /// Whether expenditure updates are paused due to logging gaps.
  final bool isPaused;

  /// Count of unlogged days in the trailing 7-day window.
  final int unloggedDaysInWindow;

  /// Whether the observation date was complete.
  final bool isDayComplete;

  /// Backwards-compatible aliases for existing UI and tests:
  int get consecutiveMissingDays => unloggedDaysInWindow;
  DateTime? get lastObservationDate => date;

  ExpenditureState copyWith({
    DateTime? date,
    double? expenditureKcal,
    double? trendWeightKg,
    double? variance,
    double? weightVariance,
    double? crossCovariance,
    double? confidence,
    bool? isPaused,
    int? unloggedDaysInWindow,
    bool? isDayComplete,
  }) {
    return ExpenditureState(
      date: date ?? this.date,
      expenditureKcal: expenditureKcal ?? this.expenditureKcal,
      trendWeightKg: trendWeightKg ?? this.trendWeightKg,
      variance: variance ?? this.variance,
      weightVariance: weightVariance ?? this.weightVariance,
      crossCovariance: crossCovariance ?? this.crossCovariance,
      confidence: confidence ?? this.confidence,
      isPaused: isPaused ?? this.isPaused,
      unloggedDaysInWindow: unloggedDaysInWindow ?? this.unloggedDaysInWindow,
      isDayComplete: isDayComplete ?? this.isDayComplete,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenditureState &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          expenditureKcal == other.expenditureKcal &&
          trendWeightKg == other.trendWeightKg &&
          variance == other.variance &&
          weightVariance == other.weightVariance &&
          crossCovariance == other.crossCovariance &&
          confidence == other.confidence &&
          isPaused == other.isPaused &&
          unloggedDaysInWindow == other.unloggedDaysInWindow &&
          isDayComplete == other.isDayComplete;

  @override
  int get hashCode =>
      date.hashCode ^
      expenditureKcal.hashCode ^
      trendWeightKg.hashCode ^
      variance.hashCode ^
      weightVariance.hashCode ^
      crossCovariance.hashCode ^
      confidence.hashCode ^
      isPaused.hashCode ^
      unloggedDaysInWindow.hashCode ^
      isDayComplete.hashCode;
}

/// 2-Dimensional Joint-State Adaptive Kalman Expenditure Filter (V4).
///
/// Tracks state vector x = [W_t, E_t]^T (trend weight kg, expenditure kcal/day).
/// Features Huber-clipped innovation at 3*sigma, 14-day rolling mean intake
/// imputation with augmented process noise, 7-day pause gating, and incomplete-day gating.
class ExpenditureKalmanV4 {
  ExpenditureKalmanV4({
    required double initialExpenditureKcal,
    double? initialWeightKg,
    this.sigmaW0 = 0.5,
    this.sigmaE0 = 300.0,
    this.qW = 0.0016, // 0.04^2 kg^2
    this.qE = 100.0, // 10.0^2 (kcal/day)^2
    this.rNoise = 0.36, // 0.6^2 kg^2
    this.huberSigma = 3.0,
    this.kcalPerKg = 7700.0,
    this.unloggedIntakeCv = 0.15,
    this.pauseThresholdDays = 3,
  })  : assert(
            initialExpenditureKcal > 0, 'Initial expenditure must be positive'),
        _expenditureKcal = initialExpenditureKcal,
        _weightKg = initialWeightKg ?? 0.0,
        _pWW = sigmaW0 * sigmaW0,
        _pEE = sigmaE0 * sigmaE0,
        _pWE = 0.0,
        _baselineExpenditure = initialExpenditureKcal;

  final double sigmaW0;
  final double sigmaE0;
  final double qW;
  final double qE;
  final double rNoise;
  final double huberSigma;
  final double kcalPerKg;
  final double unloggedIntakeCv;
  final int pauseThresholdDays;
  final double _baselineExpenditure;

  // State vector x = [W, E]^T
  double _weightKg;
  double _expenditureKcal;

  // Covariance matrix P = [[pWW, pWE], [pWE, pEE]]
  double _pWW;
  double _pWE;
  double _pEE;

  // Rolling tracking buffers
  final List<double> _loggedIntakeHistory14 = [];
  final List<bool> _trailingAdherence7 = [];
  bool _isPaused = false;
  DateTime? _lastDate;

  /// Returns current posterior state.
  ExpenditureState get currentState => _buildState(
        _lastDate ?? DateTime.now(),
        isComplete: true,
      );

  /// Current estimated energy expenditure in kcal/day.
  double get currentExpenditureKcal => _expenditureKcal;
  double get expenditureKcal => _expenditureKcal;

  /// Current estimated true weight in kg.
  double get currentWeightKg => _weightKg;
  double get weightKg => _weightKg;

  /// Posterior variance of expenditure and weight
  double get variance => _pEE;
  double get weightVariance => _pWW;
  double get crossCovariance => _pWE;

  /// Whether updates are currently paused.
  bool get isPaused => _isPaused;

  /// Processes a single observation sequentially via step parameters.
  ExpenditureState step({
    required double? intakeKcal,
    required double? scaleWeightKg,
    bool isComplete = true,
    DateTime? date,
  }) {
    final effectiveDate = date ??
        (_lastDate != null
            ? DateTime(_lastDate!.year, _lastDate!.month, _lastDate!.day + 1)
            : DateTime(2026, 1, 1));
    return processDay(DailyExpenditureInput(
      date: effectiveDate,
      scaleWeightKg: scaleWeightKg,
      loggedIntakeKcal: intakeKcal,
      isLogged: intakeKcal != null && intakeKcal > 0,
      isDayComplete: isComplete,
    ));
  }

  /// Processes a single calendar day observation sequentially.
  ExpenditureState processDay(DailyExpenditureInput input) {
    _lastDate = input.date;

    // 1. Cold start bootstrap if weight uninitialized
    if (_weightKg == 0.0 && input.scaleWeightKg != null) {
      _weightKg = input.scaleWeightKg!;
      _pWW = rNoise;
    }

    // 2. Trailing 7-day adherence window update
    _trailingAdherence7.add(input.isLogged);
    if (_trailingAdherence7.length > 7) {
      _trailingAdherence7.removeAt(0);
    }
    final unloggedCount7 =
        _trailingAdherence7.where((logged) => !logged).length;
    _isPaused = unloggedCount7 > pauseThresholdDays;

    // 3. Measurement update step (Scale weight observation)
    if (input.scaleWeightKg != null && _weightKg > 0.0) {
      _performMeasurementUpdate(input.scaleWeightKg!);
    }

    // 4. Incomplete day gating:
    // Unclosed current days do NOT perform prediction step to t+1
    if (!input.isDayComplete) {
      return _buildState(input.date, isComplete: false);
    }

    // 5. Day is complete: compute effective intake & record history
    final double effectiveIntake;
    final double rollingMean = _computeRollingMeanIntake();

    if (input.isLogged && (input.loggedIntakeKcal ?? 0.0) > 0.0) {
      effectiveIntake = input.loggedIntakeKcal!;
      _loggedIntakeHistory14.add(effectiveIntake);
      if (_loggedIntakeHistory14.length > 14) {
        _loggedIntakeHistory14.removeAt(0);
      }
    } else {
      effectiveIntake = rollingMean;
    }

    final posteriorToday = _buildState(input.date, isComplete: true);

    // 6. Time update (physics prediction) to t+1
    final isUnloggedDay =
        !input.isLogged || (input.loggedIntakeKcal ?? 0.0) <= 0.0;
    _performTimeUpdate(
      effectiveIntakeKcal: effectiveIntake,
      isUnlogged: isUnloggedDay,
      meanIntake: rollingMean,
    );

    return posteriorToday;
  }

  /// Scale weight observation update with Huber innovation clipping & Joseph covariance update.
  void _performMeasurementUpdate(double scaleWeightKg) {
    final innovation = scaleWeightKg - _weightKg;
    final sVar = _pWW + rNoise;
    final sigmaS = math.sqrt(math.max(sVar, 1e-9));

    // Huber clipping threshold at 3 * sigma
    final tau = huberSigma * sigmaS;
    final clippedInnovation = innovation.clamp(-tau, tau);

    // Effective scaling factor psi in (0, 1]
    final absInnov = innovation.abs();
    final psi = absInnov > 1e-9 ? (clippedInnovation.abs() / absInnov) : 1.0;

    final kW = _pWW / sVar;
    final kE = _pWE / sVar;

    final priorPww = _pWW;
    final priorPwe = _pWE;
    final priorPee = _pEE;

    if (!_isPaused) {
      // Joint update of weight and expenditure
      _weightKg += kW * clippedInnovation;
      _expenditureKcal += kE * clippedInnovation;

      // Joseph-form Huber covariance update
      final oneMinusPsiKw = 1.0 - (psi * kW);
      _pWW = (oneMinusPsiKw * oneMinusPsiKw * priorPww) +
          (psi * kW * psi * kW * rNoise);
      _pWE = (oneMinusPsiKw * priorPwe) -
          (psi * kE * (oneMinusPsiKw * priorPww - psi * kW * rNoise));
      _pEE = priorPee - (psi * (2.0 - psi) * (kE * priorPwe));
    } else {
      // Paused: weight tracks, but expenditure state and variance are frozen
      _weightKg += kW * clippedInnovation;
      final oneMinusPsiKw = 1.0 - (psi * kW);
      _pWW = (oneMinusPsiKw * oneMinusPsiKw * priorPww) +
          (psi * kW * psi * kW * rNoise);
      _pWE = oneMinusPsiKw * priorPwe;
    }

    _regularizeCovariance();
  }

  /// Discrete time update: W_{t+1} = W_t + (I_t - E_t)/7700; E_{t+1} = E_t.
  void _performTimeUpdate({
    required double effectiveIntakeKcal,
    required bool isUnlogged,
    required double meanIntake,
  }) {
    final gamma = 1.0 / kcalPerKg;

    if (_weightKg > 0.0) {
      // Augmented weight process noise for unlogged days
      final double stepQw;
      if (isUnlogged) {
        final intakeUncertaintyKg = (unloggedIntakeCv * meanIntake) / kcalPerKg;
        stepQw = qW + (intakeUncertaintyKg * intakeUncertaintyKg);
      } else {
        stepQw = qW;
      }

      // State prediction
      _weightKg = _weightKg + gamma * (effectiveIntakeKcal - _expenditureKcal);
      // _expenditureKcal remains unchanged (random walk)

      // Covariance prediction: P_{t+1|t} = F P F^T + Q
      final pWWNext =
          _pWW - (2.0 * gamma * _pWE) + (gamma * gamma * _pEE) + stepQw;
      final pWENext = _pWE - (gamma * _pEE);
      final pEENext = _pEE + qE;

      _pWW = pWWNext;
      _pWE = pWENext;
      _pEE = pEENext;
    } else {
      // Weight uninitialized: keep _weightKg at 0.0, _pWE at 0.0; expenditure still undergoes random walk
      _pEE = _pEE + qE;
    }

    _regularizeCovariance();
  }

  /// Calculates trailing 14-day rolling mean intake.
  double _computeRollingMeanIntake() {
    if (_loggedIntakeHistory14.isNotEmpty) {
      final sum = _loggedIntakeHistory14.reduce((a, b) => a + b);
      return sum / _loggedIntakeHistory14.length;
    }
    return _baselineExpenditure;
  }

  /// Regularizes covariance matrix to maintain strict positive-definiteness.
  void _regularizeCovariance() {
    _pWW = math.max(_pWW, 1e-6);
    _pEE = math.max(_pEE, 1.0);
    final maxCov = 0.999 * math.sqrt(_pWW * _pEE);
    _pWE = _pWE.clamp(-maxCov, maxCov);
  }

  /// Formulates immutable state snapshot.
  ExpenditureState _buildState(DateTime date, {required bool isComplete}) {
    final sigmaE = math.sqrt(_pEE);
    final baseConfidence = (1.0 - (sigmaE / (sigmaE + 150.0))).clamp(0.1, 0.99);
    final finalConfidence =
        _isPaused ? (baseConfidence * 0.75).clamp(0.1, 0.90) : baseConfidence;

    return ExpenditureState(
      date: date,
      expenditureKcal: _expenditureKcal,
      trendWeightKg: _weightKg,
      variance: _pEE,
      weightVariance: _pWW,
      crossCovariance: _pWE,
      confidence: finalConfidence,
      isPaused: _isPaused,
      unloggedDaysInWindow:
          _trailingAdherence7.where((logged) => !logged).length,
      isDayComplete: isComplete,
    );
  }

  /// Batch processes chronological list of daily inputs.
  static List<ExpenditureState> batchProcess({
    required double initialExpenditureKcal,
    double? initialWeightKg,
    required List<DailyExpenditureInput> inputs,
  }) {
    final filter = ExpenditureKalmanV4(
      initialExpenditureKcal: initialExpenditureKcal,
      initialWeightKg: initialWeightKg,
    );
    final results = <ExpenditureState>[];
    for (final dayInput in inputs) {
      results.add(filter.processDay(dayInput));
    }
    return results;
  }
}
