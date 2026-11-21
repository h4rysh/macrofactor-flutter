import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sique/domain/models/workout_session.dart';
import 'package:sique/presentation/providers/workout_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

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
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '${workouts.length} total',
              style: const TextStyle(
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
        borderRadius: AppRadii.lgBorderRadius,
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
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Workouts synced from Health Connect, fitness apps, or logged manually will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
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
          borderRadius: AppRadii.lgBorderRadius,
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
    final lower = session.source.toLowerCase();
    if (session.isHevy || lower.contains('hevy')) {
      return const AppleBadge(
        label: 'Hevy',
        color: Color(0xFF8B5CF6),
        icon: Icons.fitness_center_rounded,
      );
    }
    if (lower.contains('strava')) {
      return const AppleBadge(
        label: 'Strava',
        color: Color(0xFFFC6100),
        icon: Icons.directions_run_rounded,
      );
    }
    if (session.isHealthConnect ||
        lower.contains('health_connect') ||
        lower.contains('health connect')) {
      return const AppleBadge(
        label: 'Health Connect',
        color: AppTheme.carbs,
        icon: Icons.sync_rounded,
      );
    }
    final displaySource = session.source.isEmpty ? 'Workout' : session.source;
    return AppleBadge(
      label: displaySource,
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
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
