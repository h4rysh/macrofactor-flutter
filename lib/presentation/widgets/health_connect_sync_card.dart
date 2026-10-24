import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/presentation/providers/health_sync_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Section 6: Health Connect Sync Card with telemetry, last-synced time,
/// and "Sync Now" button (Key('profile_sync_now_btn')).
class HealthConnectSyncCard extends ConsumerWidget {
  const HealthConnectSyncCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthConnectSyncProvider);
    final isSyncing = healthState.isSyncing;

    return AppleGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.sync_rounded,
                    size: 18,
                    color: AppTheme.activeBlue,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Google Health Connect',
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(healthState),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last Synced',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    healthState.formattedLastSync,
                    key: const Key('profile_last_sync_text'),
                    style: const TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (healthState.syncedWorkoutsCount > 0 ||
                  healthState.syncedWeightsCount > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Synced Telemetry',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${healthState.syncedWorkoutsCount} workouts, ${healthState.syncedWeightsCount} weights',
                      style: const TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (healthState.isError && healthState.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.calories.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.calories.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: AppTheme.calories,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      healthState.errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        color: AppTheme.calories,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppleBouncy(
            onTap: isSyncing
                ? null
                : () {
                    ref.read(healthConnectSyncProvider.notifier).syncNow();
                  },
            child: Container(
              key: const Key('profile_sync_now_btn'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSyncing ? AppTheme.cardElevated : AppTheme.activeBlue,
                borderRadius: BorderRadius.circular(12),
                border:
                    isSyncing ? Border.all(color: AppTheme.cardBorder) : null,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSyncing) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Synchronizing Health Data...',
                      style: TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.sync_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Sync Now',
                      style: TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(HealthSyncState state) {
    if (state.isSyncing) {
      return const AppleBadge(
        label: 'Syncing',
        color: AppTheme.activeBlue,
      );
    }
    if (state.isSuccess) {
      return const AppleBadge(
        label: 'Active',
        color: AppTheme.success,
        icon: Icons.check_circle_rounded,
      );
    }
    if (state.isError) {
      return const AppleBadge(
        label: 'Sync Error',
        color: AppTheme.calories,
        icon: Icons.error_outline_rounded,
      );
    }
    return const AppleBadge(
      label: 'Idle',
      color: AppTheme.textSecondary,
    );
  }
}
