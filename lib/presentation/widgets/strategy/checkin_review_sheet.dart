import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/algorithms/coaching_engine.dart';
import '../../providers/strategy_providers.dart';
import '../../theme/app_theme.dart';
import '../apple_sheet_grabber.dart';
import '../apple_tactile_card.dart';

/// Modal sheet for reviewing weekly Bayesian coaching check-in recommendations.
class CheckinReviewSheet extends ConsumerWidget {
  const CheckinReviewSheet({
    super.key,
    required this.recommendation,
  });

  final CheckInRecommendation recommendation;

  static Widget _buildMathRow({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final delta = recommendation.calorieDelta;
    final isIncrease = delta > 0;
    final isZero = delta == 0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AppTheme.cardBorder,
          width: 0.8,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            bottomPadding > 0 ? bottomPadding : 16,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppleSheetGrabber(margin: EdgeInsets.only(bottom: 8)),
                // Title Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.calories.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppTheme.calories,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'WEEKLY COACHING CHECK-IN',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.calories,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Metabolic Recommendation',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded,
                          color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Calorie Comparison Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.cardBorder, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Target',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${recommendation.previousAverageCalories.round()}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                            const Text(
                              'kcal / day',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: isZero
                            ? AppTheme.textSecondary
                            : isIncrease
                                ? AppTheme.carbs
                                : AppTheme.calories,
                        size: 22,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Recommended',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${recommendation.recommendedAverageCalories.round()}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: isZero
                                      ? AppTheme.textPrimary
                                      : isIncrease
                                          ? AppTheme.carbs
                                          : AppTheme.calories,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                isZero
                                    ? 'No adjustment needed'
                                    : '${isIncrease ? '+' : ''}${delta.round()} kcal/day',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isZero
                                      ? AppTheme.textSecondary
                                      : isIncrease
                                          ? AppTheme.carbs
                                          : AppTheme.calories,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3-Row Metabolic Math Breakdown Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'METABOLIC MATH BREAKDOWN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMathRow(
                        label: '14d Avg Intake',
                        value:
                            '${recommendation.previousAverageCalories.round()} kcal/day',
                        icon: Icons.restaurant_rounded,
                        iconColor: AppTheme.calories,
                      ),
                      const Divider(height: 16, color: AppTheme.cardBorder),
                      _buildMathRow(
                        label: 'Trend Weight Shift vs Target',
                        value: recommendation.calorieDelta >= 0
                            ? '+${(recommendation.calorieDelta / 7700 * 7).toStringAsFixed(2)} kg/wk'
                            : '-${(recommendation.calorieDelta.abs() / 7700 * 7).toStringAsFixed(2)} kg/wk',
                        icon: Icons.trending_up_rounded,
                        iconColor: AppTheme.trendWeight,
                      ),
                      const Divider(height: 16, color: AppTheme.cardBorder),
                      _buildMathRow(
                        label: 'Updated Expenditure',
                        value:
                            '${recommendation.currentExpenditureKcal.round()} kcal/day',
                        icon: Icons.psychology_rounded,
                        iconColor: AppTheme.expenditure,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Metabolic Context & Rationale
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.expenditure.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.expenditure.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.psychology_rounded,
                            size: 18,
                            color: AppTheme.expenditure,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Estimated Expenditure: ${recommendation.currentExpenditureKcal.round()} kcal',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.expenditure,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recommendation.metabolicInsight,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // CTA 1: Accept Adjustment (#FAFAFA pill, #09090B ink)
                AppleBouncy(
                  scaleDown: 0.97,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref
                        .read(weeklyMacroProgramProvider.notifier)
                        .applyCheckIn(recommendation);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Weekly coaching targets updated!'),
                        backgroundColor: AppTheme.calories,
                      ),
                    );
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Accept & Update Program',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF09090B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // CTA 2: Keep Current
                AppleBouncy(
                  scaleDown: 0.97,
                  onTap: () {
                    ref
                        .read(weeklyMacroProgramProvider.notifier)
                        .declineCheckIn(recommendation);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Current program targets retained.'),
                        backgroundColor: AppTheme.cardSurface,
                      ),
                    );
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.cardElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: const Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Keep Current Program',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
