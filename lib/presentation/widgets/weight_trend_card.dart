import 'package:flutter/material.dart';
import 'package:macro_factor_app/domain/algorithms/weight_trend_v2.dart';
import 'package:macro_factor_app/presentation/theme/app_theme.dart';

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
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF161E36),
              AppTheme.cardSurface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
                    const Text(
                      'WEIGHT TREND',
                      style: TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.trendWeight,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
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
                    textStyle: const TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (latestTrendPoint == null) ...[
              const Text(
                'No Scale Entries Yet',
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Log your morning weight to activate zero-phase trend smoothing.',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    latestTrendPoint!.trendWeightKg.toStringAsFixed(1),
                    style: const TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'kg trend',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.cardBorder, width: 1),
                    ),
                    child: Text(
                      'Scale: ${latestTrendPoint!.scaleWeightKg.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
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
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 11,
                      color: AppTheme.textMuted,
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
