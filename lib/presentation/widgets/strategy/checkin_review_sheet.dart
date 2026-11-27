import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/algorithms/coaching_engine.dart';
import '../../../domain/models/user_profile.dart';
import '../../../utils/unit_formatter.dart';
import '../../providers/app_providers.dart';
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
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
                        borderRadius: AppRadii.mdBorderRadius,
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
                if (recommendation.wasClamped ||
                    recommendation.silentRecompDetected) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: recommendation.silentRecompDetected
                          ? const Color(0xFF66BB6A).withValues(alpha: 0.14)
                          : AppTheme.calories.withValues(alpha: 0.12),
                      borderRadius: AppRadii.mdBorderRadius,
                      border: Border.all(
                        color: recommendation.silentRecompDetected
                            ? const Color(0xFF66BB6A).withValues(alpha: 0.35)
                            : AppTheme.calories.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          recommendation.silentRecompDetected
                              ? Icons.fitness_center_rounded
                              : Icons.security_rounded,
                          size: 15,
                          color: recommendation.silentRecompDetected
                              ? const Color(0xFF66BB6A)
                              : AppTheme.calories,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            recommendation.silentRecompDetected
                                ? 'Silent Recomp: Calories held to preserve muscle gain.'
                                : 'Protected Adjustment: Weekly changes stay within safe bounds (-100 to +150 kcal).',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: recommendation.silentRecompDetected
                                  ? const Color(0xFF66BB6A)
                                  : AppTheme.calories,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // 3-Row Metabolic Math Breakdown Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: AppRadii.lgBorderRadius,
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
                        value: UnitFormatter.formatWeeklyRate(
                          recommendation.calorieDelta / 7700.0 * 7.0,
                          useLbs: ref.watch(useImperialUnitsProvider),
                        ),
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
                    borderRadius: AppRadii.lgBorderRadius,
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
                const SizedBox(height: 16),

                // Interactive What-If Goal ETA Pace Simulator
                _WhatIfEtaSimulator(
                  expenditureKcal: recommendation.currentExpenditureKcal,
                  recommendedCalories:
                      recommendation.recommendedAverageCalories,
                ),
                const SizedBox(height: 20),

                // CTA 1: Accept Adjustment (#FAFAFA pill, #09090B ink)
                AppleBouncy(
                  scaleDown: 0.97,
                  onTap: () {
                    AppHaptics.mediumImpact();
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
                    decoration: const BoxDecoration(
                      color: AppTheme.buttonBackground,
                      borderRadius: AppRadii.lgBorderRadius,
                    ),
                    child: const Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Accept & Update Program',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.buttonText,
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
                      borderRadius: AppRadii.lgBorderRadius,
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

class _WhatIfEtaSimulator extends ConsumerStatefulWidget {
  const _WhatIfEtaSimulator({
    required this.expenditureKcal,
    required this.recommendedCalories,
  });

  final double expenditureKcal;
  final double recommendedCalories;

  @override
  ConsumerState<_WhatIfEtaSimulator> createState() =>
      _WhatIfEtaSimulatorState();
}

class _WhatIfEtaSimulatorState extends ConsumerState<_WhatIfEtaSimulator> {
  double? _pacePct;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final eta = ref.watch(goalEtaProjectionProvider);
    if (profile.goalType == GoalType.maintenance || eta.atGoal) {
      return const SizedBox.shrink();
    }
    final pace = (_pacePct ?? profile.weeklyRateOfChangePct).clamp(0.25, 1.50);
    final wt = profile.currentWeightKg > 0 ? profile.currentWeightKg : 70.0;
    final remKg = (wt - profile.targetWeightKg).abs();
    final weeklyKg = (wt * pace / 100.0).clamp(0.10, 1.50);
    final simWeeks = (remKg / weeklyKg).ceil().clamp(1, 260);
    final dailyDeficitKcal = (weeklyKg * 7700.0 / 7.0).round();
    final simDailyKcal = profile.goalType == GoalType.fatLoss
        ? (widget.expenditureKcal - dailyDeficitKcal)
            .clamp(profile.calorieFloor, widget.expenditureKcal)
        : widget.expenditureKcal + dailyDeficitKcal;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardElevated,
        borderRadius: AppRadii.lgBorderRadius,
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'WHAT-IF PACE SIMULATOR',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${pace.toStringAsFixed(2)}%/wk · ~$simWeeks wks (${simDailyKcal.round()} kcal)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.activeBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: pace,
            min: 0.25,
            max: 1.50,
            divisions: 5,
            activeColor: AppTheme.activeBlue,
            onChanged: (v) => setState(() => _pacePct = v),
          ),
        ],
      ),
    );
  }
}
