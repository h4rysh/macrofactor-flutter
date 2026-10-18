import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/strategy_providers.dart';
import '../../theme/app_theme.dart';

/// Modal sheet showing historical weekly coaching check-ins.
class CheckinHistorySheet extends ConsumerWidget {
  const CheckinHistorySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(coachingCheckInHistoryProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Check-In History',
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (history.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: const Column(
                    children: [
                      Icon(
                        Icons.history_toggle_off_rounded,
                        size: 44,
                        color: AppTheme.textSecondary,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No Check-Ins Yet',
                        style: TextStyle(
                          fontFamily: 'MacroSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Weekly check-in logs will appear here after your first review.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final dateStr =
                          DateFormat('MMM d, yyyy').format(item.checkInDate);
                      final delta = item.recommendedCalories - item.previousCalories;
                      final isSurplus = delta > 0;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: AppTheme.cardBorder, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontFamily: 'MacroSans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: item.isAccepted
                                        ? AppTheme.calories
                                            .withValues(alpha: 0.15)
                                        : AppTheme.cardElevated,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.isAccepted ? 'Accepted' : 'Kept Current',
                                    style: TextStyle(
                                      fontFamily: 'MacroSans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: item.isAccepted
                                          ? AppTheme.calories
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  '${item.previousCalories.round()} → ${item.recommendedCalories.round()} kcal',
                                  style: const TextStyle(
                                    fontFamily: 'MacroSans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  delta == 0
                                      ? '(0)'
                                      : '(${isSurplus ? '+' : ''}${delta.round()} kcal)',
                                  style: TextStyle(
                                    fontFamily: 'DMSans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSurplus
                                        ? AppTheme.carbs
                                        : AppTheme.calories,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Weight Trend: ${item.weightTrendKg.toStringAsFixed(1)} kg • TDEE: ${item.expenditureKcal.round()} kcal',
                              style: const TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            if (item.statusNote.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                item.statusNote,
                                style: const TextStyle(
                                  fontFamily: 'DMSans',
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
