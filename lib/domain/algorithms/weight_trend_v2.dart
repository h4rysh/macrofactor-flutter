import 'dart:math' as math;

/// Smoothing speed for the Exponentially Weighted Moving Average (EWMA).
enum TrendWeightAlpha {
  low(0.05),
  standard(0.10),
  responsive(0.15);

  const TrendWeightAlpha(this.value);
  final double value;
}

/// A raw scale weight observation on a specific date.
class ScaleWeightEntry {
  const ScaleWeightEntry({
    required this.date,
    required this.weightKg,
    this.note,
  });

  final DateTime date;
  final double weightKg;
  final String? note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScaleWeightEntry &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          weightKg == other.weightKg &&
          note == other.note;

  @override
  int get hashCode => Object.hash(date, weightKg, note);
}

/// A processed trend weight point with biological noise envelope.
class WeightTrendPoint {
  const WeightTrendPoint({
    required this.date,
    required this.scaleWeightKg,
    required this.trendWeightKg,
    required this.noiseMinKg,
    required this.noiseMaxKg,
  });

  final DateTime date;
  final double scaleWeightKg;
  final double trendWeightKg;
  final double noiseMinKg;
  final double noiseMaxKg;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightTrendPoint &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          scaleWeightKg == other.scaleWeightKg &&
          trendWeightKg == other.trendWeightKg &&
          noiseMinKg == other.noiseMinKg &&
          noiseMaxKg == other.noiseMaxKg;

  @override
  int get hashCode =>
      date.hashCode ^
      scaleWeightKg.hashCode ^
      trendWeightKg.hashCode ^
      noiseMinKg.hashCode ^
      noiseMaxKg.hashCode;
}

/// Projected future weight trend point based on energy balance.
class WeightTrendPredictionPoint {
  const WeightTrendPredictionPoint({
    required this.dayIndex,
    required this.projectedWeightKg,
  });

  final int dayIndex;
  final double projectedWeightKg;
}

/// The V2 Weight Trend Filter matching MacroFactor's causal & bidirectional EWMA
/// and biological water-weight noise range envelope.
class WeightTrendV2Series {
  const WeightTrendV2Series({
    required this.points,
  });

  final List<WeightTrendPoint> points;

  /// Caloric equivalent of 1 kilogram of human body tissue (fat + lean tissue).
  static const double kcalPerKg = 7700.0;

  /// Default biological water weight fluctuation factor (+/- 1.5%).
  static const double biologicalNoiseFactor = 0.015;

  /// Computes the trend weight series from raw scale weight entries.
  /// When [bidirectional] is true, applies a backward zero-phase smoothing pass
  /// to eliminate historical phase lag.
  factory WeightTrendV2Series.compute({
    required List<ScaleWeightEntry> entries,
    TrendWeightAlpha alpha = TrendWeightAlpha.standard,
    bool bidirectional = false,
  }) {
    if (entries.isEmpty) {
      return const WeightTrendV2Series(points: []);
    }

    final sorted = List<ScaleWeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Forward causal pass
    final forwardTrends = <double>[];
    double currentTrend = sorted.first.weightKg;

    for (int i = 0; i < sorted.length; i++) {
      final entry = sorted[i];

      if (i == 0) {
        currentTrend = entry.weightKg;
      } else {
        final prevDate = sorted[i - 1].date;
        final deltaDays = entry.date.difference(prevDate).inDays.clamp(1, 30);
        // Effective alpha accounting for irregular sample time: alpha_eff = 1 - (1 - alpha)^deltaDays
        final effectiveAlpha =
            1.0 - math.pow(1.0 - alpha.value, deltaDays).toDouble();
        currentTrend = (effectiveAlpha * entry.weightKg) +
            ((1.0 - effectiveAlpha) * currentTrend);
      }
      forwardTrends.add(currentTrend);
    }

    // Bidirectional backward pass if enabled (zero-phase filtering)
    List<double> finalTrends;
    if (bidirectional && sorted.length > 1) {
      final backwardTrends = List<double>.filled(sorted.length, 0.0);
      double backTrend = sorted.last.weightKg;

      for (int i = sorted.length - 1; i >= 0; i--) {
        if (i == sorted.length - 1) {
          backTrend = sorted.last.weightKg;
        } else {
          final nextDate = sorted[i + 1].date;
          final deltaDays =
              nextDate.difference(sorted[i].date).inDays.clamp(1, 30);
          final effectiveAlpha =
              1.0 - math.pow(1.0 - alpha.value, deltaDays).toDouble();
          backTrend = (effectiveAlpha * sorted[i].weightKg) +
              ((1.0 - effectiveAlpha) * backTrend);
        }
        backwardTrends[i] = backTrend;
      }

      // Average forward and backward series to eliminate phase lag
      finalTrends = List<double>.generate(
        sorted.length,
        (i) => (forwardTrends[i] + backwardTrends[i]) / 2.0,
      );
    } else {
      finalTrends = forwardTrends;
    }

    final points = <WeightTrendPoint>[];
    for (int i = 0; i < sorted.length; i++) {
      final trend = finalTrends[i];
      final noiseMargin = trend * biologicalNoiseFactor;

      points.add(
        WeightTrendPoint(
          date: sorted[i].date,
          scaleWeightKg: sorted[i].weightKg,
          trendWeightKg: trend,
          noiseMinKg: trend - noiseMargin,
          noiseMaxKg: trend + noiseMargin,
        ),
      );
    }

    return WeightTrendV2Series(points: List.unmodifiable(points));
  }

  /// Forward-predicts weight loss or gain based on caloric deficit or surplus.
  static List<WeightTrendPredictionPoint> predict({
    required double startingTrendKg,
    required double dailyDeficitKcal,
    required int days,
  }) {
    assert(days >= 0, 'Days must be non-negative');
    final predictions = <WeightTrendPredictionPoint>[];
    double runningWeight = startingTrendKg;
    final dailyDeltaKg = dailyDeficitKcal / kcalPerKg;

    for (int day = 1; day <= days; day++) {
      runningWeight -= dailyDeltaKg;
      predictions.add(
        WeightTrendPredictionPoint(
          dayIndex: day,
          projectedWeightKg: runningWeight,
        ),
      );
    }

    return List.unmodifiable(predictions);
  }
}
