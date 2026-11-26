import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sique/domain/algorithms/weight_trend_v2.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/animated_primitives.dart';
import 'package:sique/presentation/widgets/charts/metabolic_series_chart.dart';
import 'package:sique/utils/unit_formatter.dart';

/// Weight Trend Card displaying smoothed trend weight vs raw scale observation,
/// water-weight noise range, interactive trend chart, and Goal ETA.
class WeightTrendCard extends StatelessWidget {
  const WeightTrendCard({
    super.key,
    required this.latestTrendPoint,
    required this.onLogWeightTap,
    this.trendSeries = const [],
    this.targetWeightKg,
    this.weeklyRatePct,
    this.useLbs = false,
  });

  final WeightTrendPoint? latestTrendPoint;
  final VoidCallback onLogWeightTap;
  final List<WeightTrendPoint> trendSeries;
  final double? targetWeightKg;
  final double? weeklyRatePct;
  final bool useLbs;

  double _toDisplay(double kg) => useLbs ? UnitFormatter.kgToLbs(kg) : kg;

  String? _computeGoalEtaText() {
    if (latestTrendPoint == null || targetWeightKg == null) return null;
    final diffKg = latestTrendPoint!.trendWeightKg - targetWeightKg!;
    if (diffKg.abs() < 0.25) return 'Goal weight reached!';
    final ratePct = (weeklyRatePct ?? 0).abs();
    if (ratePct < 0.05) return null;
    final weeklyKgDelta = latestTrendPoint!.trendWeightKg * (ratePct / 100.0);
    if (weeklyKgDelta <= 0) return null;
    final weeks = (diffKg.abs() / weeklyKgDelta).ceil().clamp(1, 260);
    return 'Est. Goal ETA: ~$weeks ${weeks == 1 ? 'week' : 'weeks'}';
  }

  @override
  Widget build(BuildContext context) {
    final unit = UnitFormatter.weightUnit(useLbs: useLbs);
    final goalEtaText = _computeGoalEtaText();
    final semanticsLabel = latestTrendPoint != null
        ? 'Weight Trend: ${_toDisplay(latestTrendPoint!.trendWeightKg).toStringAsFixed(1)} $unit trend, ${_toDisplay(latestTrendPoint!.scaleWeightKg).toStringAsFixed(1)} $unit raw scale.'
        : 'Weight Trend: No weight entries logged yet.';

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: AppleTactileCard(
        padding: const EdgeInsets.all(20.0),
        borderRadius: 18,
        backgroundColor: AppTheme.cardSurface.withValues(alpha: 0.9),
        borderColor: AppTheme.trendWeight.withValues(alpha: 0.18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.trendWeight.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.show_chart,
                          size: 16,
                          color: AppTheme.trendWeight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'WEIGHT TREND',
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.trendWeight,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  onPressed: onLogWeightTap,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Log Scale'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.calories,
                    side: const BorderSide(color: AppTheme.calories, width: 1),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    textStyle: AppTypography.labelSmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (latestTrendPoint == null) ...[
              Text(
                'No Scale Entries Yet',
                style: AppTypography.headlineSmall.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Log your morning weight to activate zero-phase trend smoothing.',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          AnimatedCountText(
                            value: _toDisplay(latestTrendPoint!.trendWeightKg),
                            formatter: (v) => v.toStringAsFixed(1),
                            style: AppTypography.numericLarge.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$unit trend',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: AppTheme.cardBorder, width: 1),
                      ),
                      child: Text(
                        'Scale: ${_toDisplay(latestTrendPoint!.scaleWeightKg).toStringAsFixed(1)} $unit',
                        style: AppTypography.numericCaption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (trendSeries.length >= 2) ...[
                const SizedBox(height: 14),
                MetabolicSeriesChart(
                  points: trendSeries
                      .map((p) => ChartSeriesPoint(
                            dateLabel: DateFormat('MM-dd').format(p.date),
                            value: _toDisplay(p.trendWeightKg),
                            bandLow: _toDisplay(p.noiseMinKg),
                            bandHigh: _toDisplay(p.noiseMaxKg),
                            scatterValue: _toDisplay(p.scaleWeightKg),
                          ))
                      .toList(),
                  accentColor: AppTheme.trendWeight,
                  unitLabel: unit,
                  decimals: 1,
                  targetLineValue: targetWeightKg != null
                      ? _toDisplay(targetWeightKg!)
                      : null,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.water_drop_outlined,
                    size: 14,
                    color: AppTheme.neutralInfo,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Water noise range: ${_toDisplay(latestTrendPoint!.noiseMinKg).toStringAsFixed(1)} – ${_toDisplay(latestTrendPoint!.noiseMaxKg).toStringAsFixed(1)} $unit (±1.5%)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.numericCaption.copyWith(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.auto_graph_rounded,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      goalEtaText ??
                          'Steady progress (pacing adapts to actual trend)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.numericCaption.copyWith(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
