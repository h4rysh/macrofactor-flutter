import 'package:flutter/material.dart';
import 'package:sique/domain/algorithms/weight_trend_v2.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/animated_primitives.dart';
import 'package:sique/utils/unit_formatter.dart';

/// Weight Trend Card displaying smoothed trend weight vs raw scale observation
/// and water-weight noise range.
class WeightTrendCard extends StatelessWidget {
  const WeightTrendCard({
    super.key,
    required this.latestTrendPoint,
    required this.onLogWeightTap,
  });

  final WeightTrendPoint? latestTrendPoint;
  final VoidCallback onLogWeightTap;

  @override
  Widget build(BuildContext context) {
    final unit = UnitFormatter.weightUnit();
    final semanticsLabel = latestTrendPoint != null
        ? 'Weight Trend: ${latestTrendPoint!.trendWeightKg.toStringAsFixed(1)} $unit trend, ${latestTrendPoint!.scaleWeightKg.toStringAsFixed(1)} $unit raw scale.'
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
                            value: latestTrendPoint!.trendWeightKg,
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
                            '${UnitFormatter.weightUnit()} trend',
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
                        'Scale: ${latestTrendPoint!.scaleWeightKg.toStringAsFixed(1)} kg',
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
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.water_drop_outlined,
                    size: 14,
                    color: AppTheme.neutralInfo,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Water noise range: ${latestTrendPoint!.noiseMinKg.toStringAsFixed(1)} – ${latestTrendPoint!.noiseMaxKg.toStringAsFixed(1)} kg (±1.5%)',
                    style: AppTypography.numericCaption.copyWith(
                      fontSize: 11,
                      color: AppTheme.textMuted,
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
                  Text(
                    'Steady progress · Pacing adapts to actual trend',
                    style: AppTypography.numericCaption.copyWith(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
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
