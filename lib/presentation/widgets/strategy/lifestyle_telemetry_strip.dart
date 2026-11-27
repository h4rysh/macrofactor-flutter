import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/animated_primitives.dart';
import 'package:sique/presentation/widgets/fasting_clock_widget.dart';
import 'package:sique/presentation/widgets/water_dial_widget.dart';

/// Compact Tier-3 telemetry strip summarizing Water, Fasting, and Workouts
/// while letting the user tap any pill to open its interactive logging card.
class LifestyleTelemetryStrip extends ConsumerWidget {
  const LifestyleTelemetryStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterMl = ref.watch(dailyWaterProvider);
    final useImperial = ref.watch(useImperialUnitsProvider);
    final fast = ref.watch(fastingSessionProvider);
    final workouts = ref.watch(workoutSessionsProvider);
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekWorkouts =
        workouts.where((w) => w.startTime.isAfter(weekAgo)).length;
    final waterLabel = useImperial
        ? '${(waterMl / 29.5735).round()} oz'
        : '${(waterMl / 1000.0).toStringAsFixed(1)}L';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'LIFESTYLE TELEMETRY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _pill(
                context,
                icon: Icons.water_drop_rounded,
                color: AppTheme.activeBlue,
                label: 'Water',
                value: waterLabel,
                onTap: () => _showModal(context, const WaterDialCard()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _pill(
                context,
                icon: Icons.timer_outlined,
                color: const Color(0xFFAB47BC),
                label: 'Fasting',
                value: fast != null ? fast.protocol.displayName : 'Off',
                onTap: () => _showModal(context, const FastingClockCard()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _pill(
                context,
                icon: Icons.fitness_center_rounded,
                color: const Color(0xFFFF7043),
                label: 'Workouts',
                value: '$weekWorkouts / 7d',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$weekWorkouts workouts factored into this week’s burn.',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pill(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return AppleBouncy(
      scaleDown: 0.96,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModal(BuildContext context, Widget child) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: child,
      ),
    );
  }
}
