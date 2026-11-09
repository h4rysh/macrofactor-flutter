import 'package:flutter/material.dart';
import 'package:sique/domain/algorithms/expenditure_kalman_v4.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/animated_primitives.dart';

/// Dynamic Expenditure widget displaying Bayesian metabolic rate and confidence.
class DynamicExpenditureCard extends StatelessWidget {
  const DynamicExpenditureCard({
    super.key,
    required this.expenditureState,
  });

  final ExpenditureState expenditureState;

  @override
  Widget build(BuildContext context) {
    final confidencePct = (expenditureState.confidence * 100).round();
    final isPaused = expenditureState.isPaused;

    return AppleTactileCard(
      padding: const EdgeInsets.all(20.0),
      borderRadius: 18,
      backgroundColor: AppTheme.cardSurface.withValues(alpha: 0.9),
      borderColor: AppTheme.expenditure.withValues(alpha: 0.18),
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
                        color: AppTheme.expenditure.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bolt,
                        size: 16,
                        color: AppTheme.expenditure,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'ENERGY EXPENDITURE',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.expenditure,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPaused
                      ? AppTheme.warning.withValues(alpha: 0.15)
                      : AppTheme.expenditure.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPaused ? AppTheme.warning : AppTheme.expenditure,
                    width: 1,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isPaused ? 'Paused (Gaps)' : '$confidencePct% Confidence',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPaused ? AppTheme.warning : AppTheme.expenditure,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AnimatedCountText(
                  value: expenditureState.expenditureKcal,
                  style: AppTypography.numericLarge.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'kcal / day',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPaused
                ? 'Expenditure updates paused due to ${expenditureState.consecutiveMissingDays} days of missing logs. Resume logging to reactivate.'
                : 'Bayesian state-space tracker adapts to your true metabolism without manual formula guesswork.',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
