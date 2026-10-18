import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:macro_factor_app/domain/models/workout_session.dart';
import 'package:macro_factor_app/presentation/providers/workout_providers.dart';
import 'package:macro_factor_app/presentation/theme/app_theme.dart';
import 'package:macro_factor_app/presentation/widgets/apple_tactile_card.dart';

/// Section 4: Recent Hevy Workouts Feed container.
class RecentWorkoutsFeed extends ConsumerWidget {
  const RecentWorkoutsFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(recentWorkoutsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Workouts',
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '${workouts.length} total',
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (workouts.isEmpty)
          const _EmptyWorkoutsCard()
        else
          Column(
            children: workouts
                .map((session) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RecentWorkoutCard(session: session),
                    ))
                .toList(),
          ),
      ],
    );
  }
}

class _EmptyWorkoutsCard extends StatelessWidget {
  const _EmptyWorkoutsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('recent_workouts_empty_state'),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 36,
            color: AppTheme.textMuted,
          ),
          SizedBox(height: 8),
          Text(
            'No workouts synced yet',
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Workouts logged in Hevy or Google Health Connect will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card representing a single logged or synced workout session.
class RecentWorkoutCard extends StatelessWidget {
  const RecentWorkoutCard({super.key, required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('EEE, MMM d • h:mm a').format(session.startTime);

    return AppleBouncy(
      child: Container(
        key: Key('recent_workout_card_${session.id}'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    session.title,
                    style: const TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildSourceBadge(),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildMetricChip(
                  icon: Icons.timer_outlined,
                  text: session.formattedDuration,
                  color: AppTheme.expenditure,
                ),
                const SizedBox(width: 12),
                _buildMetricChip(
                  icon: Icons.local_fire_department_rounded,
                  text: '${session.caloriesBurned.round()} kcal',
                  color: AppTheme.calories,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceBadge() {
    if (session.isHevy) {
      return const AppleBadge(
        label: 'Hevy',
        color: Color(0xFF8B5CF6),
        icon: Icons.fitness_center_rounded,
      );
    }
    if (session.isHealthConnect) {
      return const AppleBadge(
        label: 'Health Connect',
        color: AppTheme.carbs,
        icon: Icons.sync_rounded,
      );
    }
    return AppleBadge(
      label: session.source,
      color: AppTheme.textSecondary,
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
