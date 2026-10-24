import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/presentation/providers/workout_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Section 3: Weekly Consistency Tracker showing 7-day visual indicator.
class WorkoutConsistencyTracker extends ConsumerWidget {
  const WorkoutConsistencyTracker({super.key});

  static const List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(workoutStatsProvider);
    final todayWeekday = DateTime.now().weekday; // 1 = Monday, 7 = Sunday

    return AppleGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: AppTheme.activeBlue,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Weekly Consistency',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppleBadge(
                label: '${stats.formattedWeeklyFrequency} / wk',
                color: AppTheme.activeBlue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final weekday = index + 1; // 1 to 7
              final isActive = stats.activeDaysThisWeek.contains(weekday);
              final isToday = weekday == todayWeekday;
              return _buildDayPill(
                label: _dayLabels[index],
                isActive: isActive,
                isToday: isToday,
              );
            }),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${stats.workoutsThisWeek} sessions this week',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '4-wk avg: ${stats.formattedWeeklyFrequency} / wk',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayPill({
    required String label,
    required bool isActive,
    required bool isToday,
  }) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 44,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.activeBlue.withValues(alpha: 0.25)
                : AppTheme.cardElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? AppTheme.activeBlue
                  : (isToday
                      ? AppTheme.textSecondary.withValues(alpha: 0.6)
                      : AppTheme.cardBorder),
              width: isToday ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 13,
                  fontWeight:
                      isActive || isToday ? FontWeight.w800 : FontWeight.w500,
                  color: isActive
                      ? Colors.white
                      : (isToday ? AppTheme.textPrimary : AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 2),
              if (isActive)
                const Icon(
                  Icons.check_rounded,
                  size: 12,
                  color: AppTheme.activeBlue,
                )
              else
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isToday ? AppTheme.textMuted : Colors.transparent,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
