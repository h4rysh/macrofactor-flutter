import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/strategy_providers.dart';
import '../../theme/app_theme.dart';
import '../apple_sheet_grabber.dart';
import '../sique_empty_state.dart';

/// Modal sheet showing historical weekly coaching check-ins.
/// Styled with Apple Liquid Glass frosted obsidian blur.
class CheckinHistorySheet extends ConsumerWidget {
  const CheckinHistorySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(coachingCheckInHistoryProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface.withValues(alpha: 0.88),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
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
                  const AppleSheetGrabber(margin: EdgeInsets.only(bottom: 8)),
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Check-In History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
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
                  const SizedBox(height: 12),

                  if (history.isEmpty)
                    const SiqueEmptyState(
                      icon: Icons.history_toggle_off_rounded,
                      title: 'No Check-Ins Yet',
                      message:
                          'Weekly check-in logs will appear here after your first review.',
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
                          final dateStr = DateFormat('MMM d, yyyy')
                              .format(item.checkInDate);
                          final delta =
                              item.recommendedCalories - item.previousCalories;
                          final isSurplus = delta > 0;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppTheme.cardBorder, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
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
                                        item.isAccepted
                                            ? 'Accepted'
                                            : 'Kept Current',
                                        style: TextStyle(
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
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                if (item.statusNote.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    item.statusNote,
                                    style: const TextStyle(
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
        ),
      ),
    );
  }
}
