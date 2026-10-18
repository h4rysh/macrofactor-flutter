import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/algorithms/coaching_engine.dart';
import '../../providers/strategy_providers.dart';
import '../../theme/app_theme.dart';
import '../apple_tactile_card.dart';
import 'checkin_history_sheet.dart';
import 'checkin_review_sheet.dart';

/// Card displaying weekly check-in readiness, countdown, and history trigger.
class CoachingCheckinCard extends ConsumerWidget {
  const CoachingCheckinCard({super.key});

  void _openCheckInSheet(BuildContext context, CheckInRecommendation rec) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CheckinReviewSheet(recommendation: rec),
    );
  }

  void _openHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CheckinHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendation = ref.watch(coachingCheckInStatusProvider);
    final isDue = recommendation.isDue;

    if (isDue) {
      return AppleTactileCard(
        onTap: () => _openCheckInSheet(context, recommendation),
        backgroundColor: AppTheme.cardSurface,
        borderRadius: 20,
        border: Border.all(
          color: AppTheme.calories.withValues(alpha: 0.6),
          width: 1.5,
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.calories.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.calories,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHECK-IN READY',
                        style: TextStyle(
                          fontFamily: 'MacroSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.calories,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Weekly Metabolic Review',
                        style: TextStyle(
                          fontFamily: 'MacroSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _openHistorySheet(context),
                  icon: const Icon(
                    Icons.history_rounded,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  tooltip: 'Check-in History',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recommendation.metabolicInsight,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.calories,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Review & Adjust Strategy',
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Not due yet: Countdown state
    return AppleTactileCard(
      onTap: () => _openHistorySheet(context),
      backgroundColor: AppTheme.cardSurface,
      borderRadius: 18,
      border: Border.all(color: AppTheme.cardBorder, width: 1),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.expenditure.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: AppTheme.expenditure,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WEEKLY CHECK-IN',
                  style: TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  recommendation.daysUntilNextCheckIn <= 1
                      ? 'Due tomorrow'
                      : 'Next check-in in ${recommendation.daysUntilNextCheckIn} days',
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.history_rounded,
            color: AppTheme.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
