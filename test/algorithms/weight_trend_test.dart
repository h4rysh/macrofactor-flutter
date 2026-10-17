import 'package:flutter_test/flutter_test.dart';
import 'package:macro_factor_app/domain/algorithms/weight_trend_v2.dart';

void main() {
  group('WeightTrendV2Series Algorithm Tests', () {
    test('Calculates causal EMA trend weight accurately from scale weights',
        () {
      final entries = [
        ScaleWeightEntry(date: DateTime(2026, 1, 1), weightKg: 80.0),
        ScaleWeightEntry(date: DateTime(2026, 1, 2), weightKg: 80.5),
        ScaleWeightEntry(date: DateTime(2026, 1, 3), weightKg: 79.8),
        ScaleWeightEntry(date: DateTime(2026, 1, 4), weightKg: 80.2),
        ScaleWeightEntry(date: DateTime(2026, 1, 5), weightKg: 79.5),
      ];

      final series = WeightTrendV2Series.compute(
        entries: entries,
        alpha: TrendWeightAlpha.standard, // ~0.10
      );

      expect(series.points.length, equals(5));
      // First point initializes to scale weight
      expect(series.points[0].trendWeightKg, closeTo(80.0, 0.001));
      // Trend weight smooths out daily water-weight spikes
      expect(series.points[1].trendWeightKg, closeTo(80.05, 0.05));
      expect(series.points.last.trendWeightKg, lessThan(80.0));
    });

    test('Computes bidirectional zero-phase smoothed trend weight', () {
      final entries = [
        ScaleWeightEntry(date: DateTime(2026, 1, 1), weightKg: 80.0),
        ScaleWeightEntry(date: DateTime(2026, 1, 2), weightKg: 80.8),
        ScaleWeightEntry(date: DateTime(2026, 1, 3), weightKg: 79.4),
        ScaleWeightEntry(date: DateTime(2026, 1, 4), weightKg: 79.0),
      ];

      final bidirectionalSeries = WeightTrendV2Series.compute(
        entries: entries,
        bidirectional: true,
      );

      expect(bidirectionalSeries.points.length, equals(4));
      // Intermediate points should be smoothed without causal phase lag
      expect(bidirectionalSeries.points[1].trendWeightKg, lessThan(80.8));
    });

    test('Handles irregular sampling intervals (delta-t scaling)', () {
      final entries = [
        ScaleWeightEntry(date: DateTime(2026, 1, 1), weightKg: 80.0),
        ScaleWeightEntry(
            date: DateTime(2026, 1, 10), weightKg: 75.0), // 9 days gap
      ];

      final series = WeightTrendV2Series.compute(entries: entries);
      // Because 9 days passed, effective alpha should be much larger than single-day alpha
      expect(series.points.last.trendWeightKg, lessThan(78.0));
    });

    test('Computes biological water-weight noise range envelope', () {
      final entries = [
        ScaleWeightEntry(date: DateTime(2026, 1, 1), weightKg: 75.0),
      ];

      final series = WeightTrendV2Series.compute(entries: entries);
      final point = series.points.first;

      // Normal biological fluctuation is roughly +/- 1.5%
      expect(point.noiseMinKg, lessThan(75.0));
      expect(point.noiseMaxKg, greaterThan(75.0));
      expect(point.noiseMaxKg - point.noiseMinKg, closeTo(2.25, 0.5));
    });

    test('Returns empty series when entries list is empty', () {
      final series = WeightTrendV2Series.compute(entries: []);
      expect(series.points, isEmpty);
    });

    test(
        'Forward predicts weight trend based on prescribed deficit and energy density',
        () {
      const currentTrendKg = 80.0;
      const dailyCalorieDeficit = 500.0; // 500 kcal deficit per day
      const days = 14; // 2 weeks

      final prediction = WeightTrendV2Series.predict(
        startingTrendKg: currentTrendKg,
        dailyDeficitKcal: dailyCalorieDeficit,
        days: days,
      );

      expect(prediction.length, equals(days));
      // In 14 days at 500 kcal deficit/day (7000 kcal total / 7700 kcal/kg ~ 0.909 kg lost)
      const expectedLossKg = (dailyCalorieDeficit * days) / 7700.0;
      expect(prediction.last.projectedWeightKg,
          closeTo(currentTrendKg - expectedLossKg, 0.02));
    });

    test(
        'Value equality and hashCode for ScaleWeightEntry and WeightTrendPoint',
        () {
      final entry1 =
          ScaleWeightEntry(date: DateTime(2026, 1, 1), weightKg: 70.0);
      final entry2 =
          ScaleWeightEntry(date: DateTime(2026, 1, 1), weightKg: 70.0);
      expect(entry1, equals(entry2));
      expect(entry1.hashCode, equals(entry2.hashCode));

      final pt1 = WeightTrendPoint(
        date: DateTime(2026, 1, 1),
        scaleWeightKg: 70.0,
        trendWeightKg: 70.0,
        noiseMinKg: 69.0,
        noiseMaxKg: 71.0,
      );
      final pt2 = WeightTrendPoint(
        date: DateTime(2026, 1, 1),
        scaleWeightKg: 70.0,
        trendWeightKg: 70.0,
        noiseMinKg: 69.0,
        noiseMaxKg: 71.0,
      );
      expect(pt1, equals(pt2));
      expect(pt1.hashCode, equals(pt2.hashCode));
    });
  });
}
