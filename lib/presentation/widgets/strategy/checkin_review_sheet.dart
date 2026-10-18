import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/algorithms/coaching_engine.dart';
import '../../providers/strategy_providers.dart';
import '../../theme/app_theme.dart';
import '../apple_tactile_card.dart';

/// Modal sheet for reviewing weekly Bayesian coaching check-in recommendations.
class CheckinReviewSheet extends ConsumerWidget {
  const CheckinReviewSheet({
    super.key,
    required this.recommendation,
  });

  final CheckInRecommendation recommendation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final delta = recommendation.calorieDelta;
    final isIncrease = delta > 0;
    final isZero = delta == 0;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                        Text(
                          'WEEKLY COACHING CHECK-IN',
                          style: TextStyle(
                            fontFamily: 'MacroSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.calories,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Metabolic Recommendation',
                          style: TextStyle(
                            fontFamily: 'MacroSans',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
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
                              fontFamily: 'MacroSans',
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${recommendation.previousAverageCalories.round()}',
                            style: const TextStyle(
                              fontFamily: 'MacroSans',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Text(
                            'kcal / day',
                            style: TextStyle(
                              fontFamily: 'DMSans',
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
                              fontFamily: 'MacroSans',
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${recommendation.recommendedAverageCalories.round()}',
                            style: TextStyle(
                              fontFamily: 'MacroSans',
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: isZero
                                  ? AppTheme.textPrimary
                                  : isIncrease
                                      ? AppTheme.carbs
                                      : AppTheme.calories,
                            ),
                          ),
                          Text(
                            isZero
                                ? 'No adjustment needed'
                                : '${isIncrease ? '+' : ''}${delta.round()} kcal/day',
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isZero
                                  ? AppTheme.textSecondary
                                  : isIncrease
                                      ? AppTheme.carbs
                                      : AppTheme.calories,
                            ),
                          ),
                        ],
                      ),
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
                        Text(
                          'Estimated Expenditure: ${recommendation.currentExpenditureKcal.round()} kcal',
                          style: const TextStyle(
                            fontFamily: 'MacroSans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.expenditure,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recommendation.metabolicInsight,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // CTA 1: Accept Adjustment
              AppleTactileCard(
                onTap: () {
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
                backgroundColor: AppTheme.calories,
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Center(
                  child: Text(
                    'Accept & Update Program',
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // CTA 2: Keep Current
              AppleTactileCard(
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
                backgroundColor: AppTheme.cardElevated,
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: const Center(
                  child: Text(
                    'Keep Current Program',
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
