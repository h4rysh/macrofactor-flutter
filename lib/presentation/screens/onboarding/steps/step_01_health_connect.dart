import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/presentation/providers/auth_providers.dart';
import 'package:sique/presentation/providers/health_sync_providers.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 1: Health Connect & Wearable Hardware Synchronization (Optional)
class Step01HealthConnect extends ConsumerStatefulWidget {
  const Step01HealthConnect({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  ConsumerState<Step01HealthConnect> createState() =>
      _Step01HealthConnectState();
}

class _Step01HealthConnectState extends ConsumerState<Step01HealthConnect> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Health & Hardware Sync',
      subtitle:
          'Optionally connect Google Health Connect to auto-import body scale weights and training workouts.',
      icon: Icons.sync_rounded,
      continueKey: const Key('step_01_continue_btn'),
      onContinue: () {
        ref
            .read(authNotifierProvider.notifier)
            .setHealthConnectEnabled(_enabled);
        if (_enabled) {
          ref.read(healthConnectSyncProvider.notifier).syncNow();
        }
        widget.onNext();
      },
      child: Column(
        children: [
          const SizedBox(height: 12),
          AppleTactileCard(
            backgroundColor: AppTheme.cardSurface,
            borderRadius: 16,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.activeBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.favorite_rounded,
                      color: AppTheme.activeBlue, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Connect Sync',
                        style: TextStyle(
                          fontFamily: 'MacroSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sync smart scale body weights & Hevy workouts automatically in the background.',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  key: const Key('step_01_sync_toggle'),
                  value: _enabled,
                  activeTrackColor: AppTheme.activeBlue,
                  onChanged: (val) => setState(() => _enabled = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cardBorder, width: 1),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline_rounded,
                    color: AppTheme.textMuted, size: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Optional. You can always input your daily weight and training manually.',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
