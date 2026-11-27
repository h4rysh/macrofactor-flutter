import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/animated_primitives.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';
import 'package:sique/presentation/widgets/strategy/checkin_review_sheet.dart';

/// Tier 1 Metabolic Command Header showing Live TDEE + Confidence, 3-Band Goal ETA
/// cone, and Check-In action banner (with Adherence-Neutral info tooltip).
class MetabolicCommandHeader extends ConsumerStatefulWidget {
  const MetabolicCommandHeader({super.key});

  @override
  ConsumerState<MetabolicCommandHeader> createState() =>
      _MetabolicCommandHeaderState();
}

class _MetabolicCommandHeaderState
    extends ConsumerState<MetabolicCommandHeader> {
  bool _showCone = false;

  @override
  Widget build(BuildContext context) {
    final exp = ref.watch(expenditureStateProvider);
    final eta = ref.watch(goalEtaProjectionProvider);
    final checkIn = ref.watch(coachingCheckInStatusProvider);
    final confPct = (exp.confidence * 100).round();

    return AppleTactileCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      backgroundColor: AppTheme.cardSurface,
      borderColor: checkIn.isDue
          ? AppTheme.calories.withValues(alpha: 0.65)
          : AppTheme.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // TDEE Block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'ADAPTIVE BURN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.expenditure.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$confPct% conf',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.expenditure,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${exp.expenditureKcal.round()} kcal',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Goal ETA Block (tap to expand 3-band cone)
              Expanded(
                child: AppleBouncy(
                  scaleDown: 0.96,
                  onTap: () => setState(() => _showCone = !_showCone),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'GOAL ETA',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showCone
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 14,
                              color: AppTheme.textMuted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            eta.expectedDate != null && !eta.isRecompMode
                                ? '${eta.headlineLabel} · ${DateFormat('MMM d').format(eta.expectedDate!)}'
                                : eta.headlineLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: eta.isRecompMode
                                  ? const Color(0xFF9CCC65)
                                  : AppTheme.activeBlueText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showCone && eta.expectedWeeks != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.cardElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _bandCol('Optimistic', eta.optimisticWeeks,
                      eta.optimisticDate, AppTheme.calories),
                  _bandCol('Expected', eta.expectedWeeks, eta.expectedDate,
                      AppTheme.activeBlue),
                  _bandCol('Conservative', eta.conservativeWeeks,
                      eta.conservativeDate, AppTheme.textSecondary),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Check-in Action Banner + Adherence-Neutral tooltip
          Row(
            children: [
              Expanded(
                child: AppleBouncy(
                  scaleDown: 0.98,
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CheckinReviewSheet(recommendation: checkIn),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: checkIn.isDue
                          ? AppTheme.calories.withValues(alpha: 0.16)
                          : AppTheme.cardElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: checkIn.isDue
                            ? AppTheme.calories.withValues(alpha: 0.5)
                            : AppTheme.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          checkIn.isDue
                              ? Icons.auto_awesome_rounded
                              : Icons.event_available_rounded,
                          size: 16,
                          color: checkIn.isDue
                              ? AppTheme.caloriesSecondary
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            checkIn.isDue
                                ? 'Weekly Check-In Ready · Tap to Review'
                                : 'Next check-in in ${checkIn.daysUntilNextCheckIn}d · Tap to Preview',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: checkIn.isDue
                                  ? AppTheme.caloriesSecondary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message:
                    'No judgment tracking: higher-calorie or unlogged days simply help refine your targets — zero red warnings.',
                triggerMode: TooltipTriggerMode.tap,
                child: Semantics(
                  button: true,
                  label: 'No judgment tracking info',
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.cardElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bandCol(String label, int? wks, DateTime? date, Color color) {
    final text = wks == null
        ? '—'
        : '${wks}w (${date != null ? DateFormat('MMM d').format(date) : ''})';
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
