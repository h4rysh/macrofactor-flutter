import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/presentation/providers/health_sync_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Dedicated settings and diagnostics screen for Health Connect synchronization.
class HealthSyncSettingsScreen extends ConsumerStatefulWidget {
  const HealthSyncSettingsScreen({super.key});

  @override
  ConsumerState<HealthSyncSettingsScreen> createState() =>
      _HealthSyncSettingsScreenState();
}

class _HealthSyncSettingsScreenState
    extends ConsumerState<HealthSyncSettingsScreen> {
  int _selectedDays = 30;

  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(healthConnectSyncProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Health Connect Sync'),
        leading: IconButton(
          key: const Key('health_sync_back_btn'),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildStatusCard(sync),
          const SizedBox(height: 14),
          _buildSyncActionCard(sync),
          const SizedBox(height: 14),
          _buildChannelsCard(sync),
          const SizedBox(height: 14),
          _buildPrivacyCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusCard(HealthSyncState st) {
    final connected = st.isAvailable && st.hasPermissions;
    final color = !st.isAvailable
        ? AppTheme.textMuted
        : (connected ? const Color(0xFF34C759) : const Color(0xFFFF9500));
    final label = !st.isAvailable
        ? 'Not Available'
        : (connected ? 'Connected' : 'Action Required');

    return Semantics(
      liveRegion: true,
      label: 'Health Connect Status: $label',
      child: Container(
        key: const Key('health_sync_status_card'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.favorite_rounded, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Google Health Connect',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      Text(
                          st.isAvailable
                              ? 'Android Health API'
                              : 'Not available on device',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
              ],
            ),
            if (st.isAvailable && !st.hasPermissions) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref
                    .read(healthConnectSyncProvider.notifier)
                    .requestPermissions(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.activeBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Grant Read Permissions',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncActionCard(HealthSyncState st) {
    return Container(
      key: const Key('health_sync_manual_card'),
      padding: const EdgeInsets.all(16),
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
              const Text('Synchronization',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              Text('Last: ${st.formattedLastSync}',
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Synchronizes past $_selectedDays days of workouts and scale weights directly from device into local SQLite. Works 100% offline in Guest Mode without cloud sign-in.',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment<int>(value: 30, label: Text('30 Days')),
              ButtonSegment<int>(value: 90, label: Text('90 Days')),
            ],
            selected: {_selectedDays},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() => _selectedDays = newSelection.first);
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor:
                  AppTheme.activeBlue.withValues(alpha: 0.2),
              selectedForegroundColor: AppTheme.activeBlue,
              foregroundColor: AppTheme.textSecondary,
            ),
          ),
          if (st.isError && st.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('health_sync_settings_error_recovery_card'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF453A).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF453A).withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: Color(0xFFFF453A),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          st.errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFF453A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => ref
                              .read(healthConnectSyncProvider.notifier)
                              .requestPermissions(),
                          icon: const Icon(Icons.security_rounded, size: 14),
                          label: const Text('Permissions'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(color: AppTheme.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: st.isSyncing
                              ? null
                              : () => ref
                                  .read(healthConnectSyncProvider.notifier)
                                  .syncNow(trailingDays: _selectedDays),
                          icon: const Icon(Icons.refresh_rounded, size: 14),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.activeBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Semantics(
            button: true,
            label: st.isSyncing
                ? 'Syncing health data...'
                : 'Sync Now ($_selectedDays days)',
            child: ElevatedButton(
              key: const Key('health_sync_trigger_btn'),
              onPressed: st.isSyncing
                  ? null
                  : () => ref
                      .read(healthConnectSyncProvider.notifier)
                      .syncNow(trailingDays: _selectedDays),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.activeBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.cardElevated,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: st.isSyncing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Syncing...',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sync_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text('Sync Now (${_selectedDays}d)',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelsCard(HealthSyncState sync) {
    Widget row(IconData icon, String title, String sub) => Row(
          children: [
            Icon(icon, color: AppTheme.activeBlue, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Supported Channels',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          row(Icons.fitness_center_rounded, 'Workouts & Exercises',
              'Running, strength, HIIT, cycling & yoga'),
          const Divider(height: 16, color: AppTheme.cardBorder),
          row(Icons.monitor_weight_rounded, 'Scale Body Weight',
              'Smart scale daily logs feed trend weight'),
          const Divider(height: 16, color: AppTheme.cardBorder),
          row(Icons.directions_walk_rounded, 'Steps & Sleep Duration',
              'Reads daily steps and sleep recovery signals'),
          const Divider(height: 16, color: AppTheme.cardBorder),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Two-Way Nutrition Write-Back',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Write daily logged macros back to Health Connect Nutrition',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: sync.writeNutritionEnabled,
                onChanged: (val) {
                  ref
                      .read(healthConnectSyncProvider.notifier)
                      .setNutritionWriteBack(val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: Color(0xFF34C759)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '100% On-Device Privacy: Health Connect data is imported directly into SQLite on this device. Fully functional in Guest Mode without Google Sign-In or cloud accounts.',
              style: TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
