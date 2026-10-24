import 'package:flutter_test/flutter_test.dart';
import 'package:sique/domain/algorithms/weight_trend_v2.dart';

void main() {
  group('Issue 3 Regression: Causal vs Bidirectional Trend Weight', () {
    test(
        'Causal forward pass does not jump by 50% toward outlier on a single weigh-in',
        () {
      // 14 days of stable 70.0 kg weigh-ins
      final entries = <ScaleWeightEntry>[];
      for (int i = 0; i < 14; i++) {
        entries.add(ScaleWeightEntry(
          date: DateTime(2026, 1, i + 1),
          weightKg: 70.0,
        ));
      }

      // Day 15: Acute water retention spike (+3.0 kg jump to 73.0 kg)
      entries.add(ScaleWeightEntry(
        date: DateTime(2026, 1, 15),
        weightKg: 73.0,
      ));

      // 1. Causal series (used for current status & expenditure)
      final causalSeries = WeightTrendV2Series.compute(
        entries: entries,
        bidirectional: false,
      );

      final latestCausal = causalSeries.points.last.trendWeightKg;

      // With standard alpha (0.1), a +3.0 kg jump moves causal trend by ~0.3 kg (to ~70.3 kg)
      expect(latestCausal, closeTo(70.3, 0.05),
          reason: 'Causal trend should only absorb effective alpha (~10%)');

      // 2. Bidirectional series with fix:
      // Starting backward pass at forwardTrends.last must NOT force the last point to (forward + raw) / 2 = 71.65 kg!
      final bidirectionalSeries = WeightTrendV2Series.compute(
        entries: entries,
        bidirectional: true,
      );

      final latestBidir = bidirectionalSeries.points.last.trendWeightKg;
      expect(latestBidir, closeTo(70.3, 0.1),
          reason:
              'Last point in bidirectional pass must not jump to (forward + raw) / 2');
    });

    test(
        'Causal mode preserves historical values when future weights are added',
        () {
      final week1Entries = List<ScaleWeightEntry>.generate(
        7,
        (i) => ScaleWeightEntry(
          date: DateTime(2026, 1, i + 1),
          weightKg: 70.0 + (i * 0.1),
        ),
      );

      final week1Series = WeightTrendV2Series.compute(
        entries: week1Entries,
        bidirectional: false,
      );
      final day7TrendPrior = week1Series.points.last.trendWeightKg;

      // Now user adds week 2 entries
      final week2Entries = List<ScaleWeightEntry>.from(week1Entries)
        ..addAll(
          List<ScaleWeightEntry>.generate(
            7,
            (i) => ScaleWeightEntry(
              date: DateTime(2026, 1, i + 8),
              weightKg: 70.7 + (i * 0.1),
            ),
          ),
        );

      final week2Series = WeightTrendV2Series.compute(
        entries: week2Entries,
        bidirectional: false,
      );
      final day7TrendPosterior = week2Series.points[6].trendWeightKg;

      // Causal invariant: past trend values must never change based on future observations
      expect(day7TrendPosterior, equals(day7TrendPrior),
          reason:
              'Causal filter strictly prevents future data from retroactively rewriting history');
    });
  });
}
