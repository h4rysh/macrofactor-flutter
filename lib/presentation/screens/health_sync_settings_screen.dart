import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/presentation/providers/health_sync_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Dedicated settings and diagnostics screen for Health Connect synchronization.
class HealthSyncSettingsScreen extends ConsumerWidget {
  const HealthSyncSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(healthConnectSyncProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Health Connect Sync'),
        leading: IconButton(
          key: const Key('health_sync_back_btn'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildStatusCard(ref, sync),
          const SizedBox(height: 14),
          _buildSyncActionCard(ref, sync),
          const SizedBox(height: 14),
          _buildChannelsCard(),
          const SizedBox(height: 14),
          _buildPrivacyCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusCard(WidgetRef ref, HealthSyncState st) {
    final connected = st.isAvailable && st.hasPermissions;
    final color = !st.isAvailable
        ? AppTheme.textMuted
        : (connected ? const Color(0xFF34C759) : const Color(0xFFFF9500));
    final label = !st.isAvailable
        ? 'Not Available'
        : (connected ? 'Connected' : 'Action Required');

    return Container(
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
                            fontFamily: 'MacroSans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    Text(
                        st.isAvailable
                            ? 'Android Health API'
                            : 'Not available on device',
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 12,
                            color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(label,
                    style: TextStyle(
                        fontFamily: 'DMSans',
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
                  style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncActionCard(WidgetRef ref, HealthSyncState st) {
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
                      fontFamily: 'MacroSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              Text('Last: ${st.formattedLastSync}',
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Synchronizes 30 days of workouts and scale weights into local storage.',
            style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                color: AppTheme.textSecondary),
          ),
          if (st.isError && st.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(st.errorMessage!,
                style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 11,
                    color: Color(0xFFFF453A))),
          ],
          const SizedBox(height: 14),
          ElevatedButton(
            key: const Key('health_sync_trigger_btn'),
            onPressed: st.isSyncing
                ? null
                : () => ref.read(healthConnectSyncProvider.notifier).syncNow(),
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
                              fontFamily: 'DMSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sync_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Sync Now (30 Days)',
                          style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelsCard() {
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
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  Text(sub,
                      style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 11,
                          color: AppTheme.textSecondary)),
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
                  fontFamily: 'MacroSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          row(Icons.fitness_center_rounded, 'Workouts & Exercises',
              'Running, strength, HIIT, cycling & yoga'),
          const Divider(height: 16, color: AppTheme.cardBorder),
          row(Icons.monitor_weight_rounded, 'Scale Body Weight',
              'Smart scale daily logs feed trend weight'),
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
              '100% Local Privacy: Health Connect data is imported directly into SQLite on this device. No health data ever leaves your device.',
              style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
