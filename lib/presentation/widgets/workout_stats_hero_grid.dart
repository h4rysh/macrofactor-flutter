import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_factor_app/presentation/providers/workout_providers.dart';
import 'package:macro_factor_app/presentation/theme/app_theme.dart';
import 'package:macro_factor_app/presentation/widgets/apple_tactile_card.dart';

/// Section 2: 2x2 Hero Workout Stats Grid displaying Total Workouts,
/// Workout Minutes, Average Duration, and Active Calories Burned.
class WorkoutStatsHeroGrid extends ConsumerWidget {
  const WorkoutStatsHeroGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(workoutStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Workout & Training Stats',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AppleBadge(
              label: '${stats.hevyWorkoutsCount} Hevy',
              color: const Color(0xFF8B5CF6),
              icon: Icons.fitness_center_rounded,
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            _buildStatCard(
              key: const Key('hero_stat_total_workouts'),
              title: 'Total Workouts',
              value: '${stats.totalWorkouts}',
              subtitle: stats.hevyWorkoutsCount > 0
                  ? '${stats.hevyWorkoutsCount} via Hevy'
                  : 'All sources',
              icon: Icons.fitness_center_rounded,
              accentColor: AppTheme.activeBlue,
            ),
            _buildStatCard(
              key: const Key('hero_stat_training_time'),
              title: 'Workout Minutes',
              value: stats.totalDurationMinutes >= 60
                  ? '${(stats.totalDurationMinutes / 60).toStringAsFixed(1)}h'
                  : '${stats.totalDurationMinutes}m',
              subtitle: '${stats.totalDurationMinutes} mins total',
              icon: Icons.timer_outlined,
              accentColor: AppTheme.expenditure,
            ),
            _buildStatCard(
              key: const Key('hero_stat_avg_duration'),
              title: 'Average Duration',
              value: '${stats.roundedAverageDurationMinutes}m',
              subtitle: 'Per workout',
              icon: Icons.timelapse_rounded,
              accentColor: AppTheme.protein,
            ),
            _buildStatCard(
              key: const Key('hero_stat_active_calories'),
              title: 'Active Calories',
              value: '${stats.totalCaloriesBurned.round()}',
              subtitle: 'Avg ${stats.roundedAverageCaloriesBurned} kcal',
              icon: Icons.local_fire_department_rounded,
              accentColor: AppTheme.calories,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required Key key,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
            ],
          ),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            subtitle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
