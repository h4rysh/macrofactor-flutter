import 'dart:math' as math;

import 'package:sique/domain/algorithms/expenditure_kalman_v4.dart';

/// Multi-modal daily observation for [ExpenditureKalmanV5].
class DailyExpenditureInputV5 extends DailyExpenditureInput {
  const DailyExpenditureInputV5({
    required super.date,
    super.scaleWeightKg,
    super.loggedIntakeKcal,
    super.isLogged = true,
    super.isDayComplete = true,
    this.workoutLoadKcal = 0.0,
    this.hasWorkoutOnDay = false,
    this.waterMl,
    this.sodiumMg,
    this.hadExtendedFast = false,
  });

  /// Workout energy expenditure in kcal for this day (0.0 if rest day).
  final double workoutLoadKcal;

  /// Whether at least one workout session occurred on this day.
  final bool hasWorkoutOnDay;

  /// Total logged hydration in ml (null if not logged on this day).
  final int? waterMl;

  /// Coverage-validated sodium intake in mg (null if <60% coverage or unlogged).
  final double? sodiumMg;

  /// Whether an active or recently ended fast (>=18h) touched day t or t-1.
  final bool hadExtendedFast;
}

/// 3-Band Probabilistic Goal ETA projection with Recomp & Singularity guards.
class GoalEtaProjection {
  const GoalEtaProjection({
    this.optimisticWeeks,
    this.expectedWeeks,
    this.conservativeWeeks,
    this.optimisticDate,
    this.expectedDate,
    this.conservativeDate,
    this.isRecompMode = false,
    this.recompSummary,
    this.atGoal = false,
    this.velocityKgPerWeek = 0.0,
  });

  final int? optimisticWeeks;
  final int? expectedWeeks;
  final int? conservativeWeeks;
  final DateTime? optimisticDate;
  final DateTime? expectedDate;
  final DateTime? conservativeDate;
  final bool isRecompMode;
  final String? recompSummary;
  final bool atGoal;
  final double velocityKgPerWeek;

  String get headlineLabel {
    if (atGoal) return 'At goal weight';
    if (isRecompMode && recompSummary != null) return recompSummary!;
    if (expectedWeeks == null) return 'Maintain';
    return '~$expectedWeeks wks';
  }
}

/// 2-Dimensional Multi-Modal Adaptive Kalman Expenditure Filter (V5).
///
/// Fuses:
/// 1. Constrained Training-Volume Prior Drift from WorkoutDao (7d vs 21d delta,
///    beta_comp = 0.60, +/-120 kcal clamp, detraining vs unlogged guard).
/// 2. Heteroscedastic observation noise R_t in [0.36, 1.25] kg^2 driven by
///    hydration swings (>=5/7d gate), lag-1 sodium spikes, and >=18h fasts.
/// 3. Katch-McArdle + Mifflin-St Jeor BMR blending when bodyFatPct is available.
class ExpenditureKalmanV5 {
  ExpenditureKalmanV5({
    required double initialExpenditureKcal,
    double? initialWeightKg,
    this.bmrKcal,
    this.sigmaW0 = 0.5,
    this.sigmaE0 = 300.0,
    this.qW = 0.0016,
    this.qE = 100.0,
    this.rBase = 0.36,
    this.huberSigma = 3.0,
    this.kcalPerKg = 7700.0,
    this.unloggedIntakeCv = 0.15,
    this.pauseThresholdDays = 3,
  })  : assert(
          initialExpenditureKcal > 0,
          'Initial expenditure must be positive',
        ),
        _expenditureKcal = initialExpenditureKcal,
        _weightKg = initialWeightKg ?? 0.0,
        _pWW = sigmaW0 * sigmaW0,
        _pEE = sigmaE0 * sigmaE0,
        _pWE = 0.0,
        _baselineExpenditure = initialExpenditureKcal;

  static const double rMax = 1.25;
  static const double trainingCompensationBeta = 0.60;
  static const double trainingDriftThresholdKcal = 75.0;
  static const double maxTrainingDriftKcal = 120.0;

  final double? bmrKcal;
  final double sigmaW0;
  final double sigmaE0;
  final double qW;
  final double qE;
  final double rBase;
  final double huberSigma;
  final double kcalPerKg;
  final double unloggedIntakeCv;
  final int pauseThresholdDays;
  final double _baselineExpenditure;

  double _weightKg;
  double _expenditureKcal;
  double _pWW;
  double _pWE;
  double _pEE;

  final List<double> _loggedIntakeHistory14 = [];
  final List<bool> _trailingAdherence7 = [];
  final List<double> _workoutLoadHistory21 = [];
  final List<bool> _workoutActiveHistory14 = [];
  final List<int> _waterHistory7 = [];
  final List<double> _sodiumHistory14 = [];
  double? _prevSodiumMg;
  bool _isPaused = false;
  DateTime? _lastDate;

  ExpenditureState get currentState =>
      _buildState(_lastDate ?? DateTime.now(), isComplete: true);

  double get expenditureKcal => _expenditureKcal;
  double get weightKg => _weightKg;
  double get variance => _pEE;
  bool get isPaused => _isPaused;

  double get effectiveBmr {
    if (bmrKcal != null && bmrKcal! > 0) return bmrKcal!;
    if (_weightKg > 0.0) return _weightKg * 20.0;
    return _baselineExpenditure / 1.5;
  }

  double get minExpenditureBound => 0.8 * effectiveBmr;
  double get maxExpenditureBound => 2.5 * effectiveBmr;

  /// Computes a blended Katch-McArdle + Mifflin-St Jeor BMR when BF% is known.
  static double? computeBlendedBmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required bool isMale,
    double? bodyFatPct,
  }) {
    if (weightKg <= 0) return null;
    final double? mifflin = (heightCm > 0 && age > 0)
        ? (10.0 * weightKg) +
            (6.25 * heightCm) -
            (5.0 * age) +
            (isMale ? 5.0 : -161.0)
        : null;
    if (bodyFatPct != null && bodyFatPct > 2.0 && bodyFatPct < 65.0) {
      final leanMassKg = weightKg * (1.0 - bodyFatPct / 100.0);
      final katchMcArdle = 370.0 + (21.6 * leanMassKg);
      if (mifflin != null) {
        return 0.5 * mifflin + 0.5 * katchMcArdle;
      }
      return katchMcArdle;
    }
    return mifflin;
  }

  /// Processes a single calendar day observation sequentially.
  ExpenditureState processDay(DailyExpenditureInputV5 input) {
    _lastDate = input.date;

    // 1. Cold start bootstrap if weight uninitialized
    if (_weightKg == 0.0 && input.scaleWeightKg != null) {
      _weightKg = input.scaleWeightKg!;
      _pWW = rBase;
    }

    // 2. Trailing 7-day adherence window update
    _trailingAdherence7.add(input.isLogged);
    if (_trailingAdherence7.length > 7) {
      _trailingAdherence7.removeAt(0);
    }
    final unloggedCount7 =
        _trailingAdherence7.where((logged) => !logged).length;
    _isPaused = unloggedCount7 > pauseThresholdDays;

    // 3. Training-volume tracking & constrained prior drift
    final double deltaLoad = _updateTrainingBuffersAndDelta(
      workoutLoadKcal: input.workoutLoadKcal,
      hasWorkout: input.hasWorkoutOnDay,
    );
    if (!_isPaused && deltaLoad.abs() > trainingDriftThresholdKcal) {
      final hasRecentWorkout = _workoutActiveHistory14.any((w) => w);
      if (deltaLoad > 0 || hasRecentWorkout) {
        final rawDrift = (1.0 - trainingCompensationBeta) * deltaLoad;
        final clampedDrift =
            rawDrift.clamp(-maxTrainingDriftKcal, maxTrainingDriftKcal);
        // Apply fractional daily prior drift (scaled by 1/7 so 7-day step converges smoothly)
        _expenditureKcal = (_expenditureKcal + (clampedDrift / 7.0))
            .clamp(minExpenditureBound, maxExpenditureBound);
      }
    }

    // 4. Compute heteroscedastic observation noise R_t
    final effectiveR = _computeHeteroscedasticR(input);

    // 5. Measurement update step (Scale weight observation)
    if (input.scaleWeightKg != null && _weightKg > 0.0) {
      _performMeasurementUpdate(input.scaleWeightKg!, effectiveR);
    }

    // 6. Incomplete day gating
    if (!input.isDayComplete) {
      return _buildState(input.date, isComplete: false);
    }

    // 7. Complete day: compute effective intake & record history
    final double rollingMean = _computeRollingMeanIntake();
    final double effectiveIntake;
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

    // 8. Time update (physics prediction) to t+1 with training-block qE scaling
    final isUnloggedDay =
        !input.isLogged || (input.loggedIntakeKcal ?? 0.0) <= 0.0;
    final qEScale = deltaLoad.abs() > trainingDriftThresholdKcal
        ? 1.0 + math.min(1.5, deltaLoad.abs() / 200.0)
        : 1.0;

    _performTimeUpdate(
      effectiveIntakeKcal: effectiveIntake,
      isUnlogged: isUnloggedDay,
      meanIntake: rollingMean,
      qEScale: qEScale,
    );

    return posteriorToday;
  }

  double _updateTrainingBuffersAndDelta({
    required double workoutLoadKcal,
    required bool hasWorkout,
  }) {
    _workoutLoadHistory21.add(math.max(0.0, workoutLoadKcal));
    if (_workoutLoadHistory21.length > 21) {
      _workoutLoadHistory21.removeAt(0);
    }
    _workoutActiveHistory14.add(hasWorkout);
    if (_workoutActiveHistory14.length > 14) {
      _workoutActiveHistory14.removeAt(0);
    }
    if (_workoutLoadHistory21.length < 7) return 0.0;

    final avg21 = _workoutLoadHistory21.reduce((a, b) => a + b) /
        _workoutLoadHistory21.length;
    final last7 =
        _workoutLoadHistory21.sublist(_workoutLoadHistory21.length - 7);
    final avg7 = last7.reduce((a, b) => a + b) / last7.length;
    if (avg21 == 0.0 && avg7 == 0.0) return 0.0;
    return avg7 - avg21;
  }

  double _computeHeteroscedasticR(DailyExpenditureInputV5 input) {
    var mWater = 1.0;
    if (input.waterMl != null && input.waterMl! > 0) {
      _waterHistory7.add(input.waterMl!);
      if (_waterHistory7.length > 7) _waterHistory7.removeAt(0);
      if (_waterHistory7.length >= 5) {
        final avgWater =
            _waterHistory7.reduce((a, b) => a + b) / _waterHistory7.length;
        if ((input.waterMl! - avgWater).abs() > 750.0) {
          mWater = 1.45;
        }
      }
    }

    var mSodium = 1.0;
    final curNa = input.sodiumMg;
    final effNa = math.max(curNa ?? 0.0, 0.7 * (_prevSodiumMg ?? 0.0));
    if (curNa != null && curNa > 0) {
      _sodiumHistory14.add(curNa);
      if (_sodiumHistory14.length > 14) _sodiumHistory14.removeAt(0);
    }
    if (effNa > 0) {
      final double naThreshold;
      if (_sodiumHistory14.length >= 5) {
        final sorted = List<double>.from(_sodiumHistory14)..sort();
        final median = sorted[sorted.length ~/ 2];
        naThreshold = math.max(median * 1.4, 2800.0);
      } else {
        naThreshold = 3200.0;
      }
      if (effNa > naThreshold) {
        mSodium = 1.60;
      }
    }
    _prevSodiumMg = curNa;

    final mFast = input.hadExtendedFast ? 1.50 : 1.0;
    return (rBase * mWater * mSodium * mFast).clamp(rBase, rMax);
  }

  void _performMeasurementUpdate(double scaleWeightKg, double effectiveR) {
    final innovation = scaleWeightKg - _weightKg;
    final sVar = _pWW + effectiveR;
    final sigmaS = math.sqrt(math.max(sVar, 1e-9));

    final tau = huberSigma * sigmaS;
    final clippedInnovation = innovation.clamp(-tau, tau);
    final absInnov = innovation.abs();
    final psi = absInnov > 1e-9 ? (clippedInnovation.abs() / absInnov) : 1.0;

    final kW = _pWW / sVar;
    final kE = _pWE / sVar;
    final priorPww = _pWW;
    final priorPwe = _pWE;
    final priorPee = _pEE;

    if (!_isPaused) {
      _weightKg += kW * clippedInnovation;
      _expenditureKcal += kE * clippedInnovation;
      _expenditureKcal =
          _expenditureKcal.clamp(minExpenditureBound, maxExpenditureBound);

      final oneMinusPsiKw = 1.0 - (psi * kW);
      _pWW = (oneMinusPsiKw * oneMinusPsiKw * priorPww) +
          (psi * kW * psi * kW * effectiveR);
      _pWE = (oneMinusPsiKw * priorPwe) -
          (psi * kE * (oneMinusPsiKw * priorPww - psi * kW * effectiveR));
      _pEE = priorPee - (psi * (2.0 - psi) * (kE * priorPwe));
    } else {
      _weightKg += kW * clippedInnovation;
      final oneMinusPsiKw = 1.0 - (psi * kW);
      _pWW = (oneMinusPsiKw * oneMinusPsiKw * priorPww) +
          (psi * kW * psi * kW * effectiveR);
      _pWE = oneMinusPsiKw * priorPwe;
    }

    _regularizeCovariance();
  }

  void _performTimeUpdate({
    required double effectiveIntakeKcal,
    required bool isUnlogged,
    required double meanIntake,
    required double qEScale,
  }) {
    final gamma = 1.0 / kcalPerKg;
    final stepQe = qE * qEScale;

    if (_weightKg > 0.0) {
      final double stepQw;
      if (isUnlogged) {
        final intakeUncertaintyKg = (unloggedIntakeCv * meanIntake) / kcalPerKg;
        stepQw = qW + (intakeUncertaintyKg * intakeUncertaintyKg);
      } else {
        stepQw = qW;
      }

      _weightKg = _weightKg + gamma * (effectiveIntakeKcal - _expenditureKcal);

      final pWWNext =
          _pWW - (2.0 * gamma * _pWE) + (gamma * gamma * _pEE) + stepQw;
      final pWENext = _pWE - (gamma * _pEE);
      final pEENext = _pEE + stepQe;

      _pWW = pWWNext;
      _pWE = pWENext;
      _pEE = pEENext;
    } else {
      _pEE = _pEE + stepQe;
    }

    _regularizeCovariance();
  }

  double _computeRollingMeanIntake() {
    if (_loggedIntakeHistory14.isNotEmpty) {
      final sum = _loggedIntakeHistory14.reduce((a, b) => a + b);
      return sum / _loggedIntakeHistory14.length;
    }
    return _baselineExpenditure;
  }

  void _regularizeCovariance() {
    _pWW = math.max(_pWW, 1e-6);
    _pEE = math.max(_pEE, 1.0);
    final maxCov = 0.999 * math.sqrt(_pWW * _pEE);
    _pWE = _pWE.clamp(-maxCov, maxCov);
  }

  ExpenditureState _buildState(DateTime date, {required bool isComplete}) {
    final sigmaE = math.sqrt(_pEE);
    final baseConfidence = (1.0 - (sigmaE / (sigmaE + 150.0))).clamp(0.1, 0.99);
    final finalConfidence =
        _isPaused ? (baseConfidence * 0.75).clamp(0.1, 0.90) : baseConfidence;

    return ExpenditureState(
      date: date,
      expenditureKcal:
          _expenditureKcal.clamp(minExpenditureBound, maxExpenditureBound),
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
}

/// Computes a singularity-guarded 3-band Goal ETA projection.
class GoalEtaCalculator {
  const GoalEtaCalculator._();

  static GoalEtaProjection compute({
    required DateTime now,
    required double trendWeightKg,
    required double goalWeightKg,
    required String goalType,
    required double targetRatePctPerWeek,
    required double observedVelocityKgPerWeek,
    required double expenditureKcal,
    required double expenditureVariance,
    bool isSilentRecomp = false,
    double? currentWaistCm,
    double? waistDelta14Cm,
    double? heightCm,
  }) {
    if (goalType == 'maintain') {
      return const GoalEtaProjection();
    }

    final diffKg = trendWeightKg - goalWeightKg;
    if ((goalType == 'lose' && diffKg <= 0.2) ||
        (goalType == 'gain' && diffKg >= -0.2) ||
        diffKg.abs() <= 0.2) {
      return const GoalEtaProjection(atGoal: true);
    }

    final remainingKg = diffKg.abs();
    final targetRateKgWk =
        (trendWeightKg * targetRatePctPerWeek.abs() / 100.0).clamp(0.10, 1.50);

    // Observed velocity in the goal direction (positive = moving toward goal)
    final directedVelocity = goalType == 'lose'
        ? -observedVelocityKgPerWeek
        : observedVelocityKgPerWeek;

    // Singularity guard: Recomp Mode or near-zero velocity switches Expected to Waist-to-Goal ETA
    if (isSilentRecomp || directedVelocity <= 0.05) {
      String? recompLabel;
      int? waistWeeks;
      if (heightCm != null &&
          heightCm > 0 &&
          currentWaistCm != null &&
          waistDelta14Cm != null &&
          waistDelta14Cm < -0.1) {
        final targetWaist = 0.50 * heightCm;
        if (currentWaistCm > targetWaist) {
          final weeklyWaistDrop = (-waistDelta14Cm / 2.0).clamp(0.05, 5.0);
          waistWeeks = ((currentWaistCm - targetWaist) / weeklyWaistDrop)
              .ceil()
              .clamp(1, 104);
          recompLabel = 'Recomp Mode — ~$waistWeeks wks to <0.50 WHtR';
        }
      }
      recompLabel ??= 'Recomp Mode — Hold & Track Waist';

      final optWks = (remainingKg / targetRateKgWk).ceil().clamp(1, 260);
      final safeWks = (remainingKg / math.max(directedVelocity, 0.10))
          .ceil()
          .clamp(optWks, 260);
      final sigmaE = math.sqrt(math.max(expenditureVariance, 1.0));
      final uncFactor =
          (1.0 + (sigmaE / math.max(expenditureKcal, 1200.0)) * 2.0)
              .clamp(1.1, 1.6);
      final consWks = (safeWks * uncFactor).ceil().clamp(safeWks, 260);

      return GoalEtaProjection(
        optimisticWeeks: optWks,
        expectedWeeks: waistWeeks ?? safeWks,
        conservativeWeeks: consWks,
        optimisticDate: now.add(Duration(days: optWks * 7)),
        expectedDate: now.add(Duration(days: (waistWeeks ?? safeWks) * 7)),
        conservativeDate: now.add(Duration(days: consWks * 7)),
        isRecompMode: true,
        recompSummary: recompLabel,
        velocityKgPerWeek: directedVelocity,
      );
    }

    // Adaptive thermogenesis decay (-12 kcal/kg lost slows expected rate slightly)
    final adaptationPenaltyFactor =
        (1.0 - math.min(0.18, (remainingKg * 12.0) / 1400.0)).clamp(0.82, 1.0);
    final effectiveExpectedRate =
        math.max(directedVelocity * adaptationPenaltyFactor, 0.10);

    final optRate = math.max(targetRateKgWk, effectiveExpectedRate);
    final optWks = (remainingKg / optRate).ceil().clamp(1, 260);
    final expWks =
        (remainingKg / effectiveExpectedRate).ceil().clamp(optWks, 260);

    final sigmaE = math.sqrt(math.max(expenditureVariance, 1.0));
    final sigmaFactor =
        (1.0 + (sigmaE / math.max(expenditureKcal, 1200.0)) * 2.2)
            .clamp(1.10, 1.65);
    final consWks = (expWks * sigmaFactor).ceil().clamp(expWks, 260);

    return GoalEtaProjection(
      optimisticWeeks: optWks,
      expectedWeeks: expWks,
      conservativeWeeks: consWks,
      optimisticDate: now.add(Duration(days: optWks * 7)),
      expectedDate: now.add(Duration(days: expWks * 7)),
      conservativeDate: now.add(Duration(days: consWks * 7)),
      velocityKgPerWeek: directedVelocity,
    );
  }
}
