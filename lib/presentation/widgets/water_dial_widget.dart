import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'animated_primitives.dart';
import 'apple_tactile_card.dart';

/// Interactive card for tracking daily water intake with quick-log buttons.
class WaterDialCard extends ConsumerWidget {
  const WaterDialCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWaterMl = ref.watch(dailyWaterProvider);
    final useImperial = ref.watch(useImperialUnitsProvider);
    final profile = ref.watch(userProfileProvider);
    final targetWaterMl = profile.dailyWaterTargetMl;
    const mlPerOz = 29.5735;
    final currentDisplay =
        useImperial ? (currentWaterMl / mlPerOz).round() : currentWaterMl;
    final targetDisplay =
        useImperial ? (targetWaterMl / mlPerOz).round() : targetWaterMl;
    final unitSuffix = useImperial ? 'oz' : 'ml';

    final progress = targetWaterMl > 0
        ? (currentWaterMl / targetWaterMl).clamp(0.0, 1.0)
        : 0.0;
    final isTargetReached = currentWaterMl >= targetWaterMl;

    return AppleTactileCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      backgroundColor: AppTheme.cardSurface,
      borderColor: isTargetReached
          ? AppTheme.activeBlue.withValues(alpha: 0.5)
          : AppTheme.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.activeBlue.withValues(alpha: 0.15),
                  borderRadius: AppRadii.mdBorderRadius,
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  size: 20,
                  color: AppTheme.activeBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DAILY HYDRATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.activeBlueText,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Text(
                            '$currentDisplay',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            ' / $targetDisplay $unitSuffix',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isTargetReached)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.activeBlue.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 13, color: AppTheme.activeBlueText),
                      SizedBox(width: 4),
                      Text(
                        'OPTIMAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.activeBlueText,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 7,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.cardElevated,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.activeBlue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Quick Increment Buttons
          Row(
            children: [
              _buildWaterBtn(
                label: useImperial ? '+8 oz' : '+250ml',
                onTap: () {
                  AppHaptics.lightImpact();
                  ref
                      .read(dailyWaterProvider.notifier)
                      .addWater(useImperial ? 237 : 250);
                },
              ),
              const SizedBox(width: 8),
              _buildWaterBtn(
                label: useImperial ? '+16 oz' : '+500ml',
                onTap: () {
                  AppHaptics.lightImpact();
                  ref
                      .read(dailyWaterProvider.notifier)
                      .addWater(useImperial ? 473 : 500);
                },
              ),
              const SizedBox(width: 8),
              _buildWaterBtn(
                label: useImperial ? '+24 oz' : '+750ml',
                onTap: () {
                  AppHaptics.lightImpact();
                  ref
                      .read(dailyWaterProvider.notifier)
                      .addWater(useImperial ? 710 : 750);
                },
              ),
              const SizedBox(width: 8),
              _buildResetBtn(
                onTap: currentWaterMl <= 0
                    ? null
                    : () async {
                        AppHaptics.selectionClick();
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppTheme.cardSurface,
                            title: const Text('Reset daily water?'),
                            content: const Text(
                              'This clears today’s logged water intake back to 0.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          ref.read(dailyWaterProvider.notifier).resetToday();
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterBtn({
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: AppleBouncy(
        scaleDown: 0.94,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.cardElevated,
            borderRadius: AppRadii.mdBorderRadius,
            border: Border.all(
              color: AppTheme.activeBlue.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.activeBlueText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetBtn({required VoidCallback? onTap}) {
    return Tooltip(
      message: 'Reset water',
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: 'Reset today water intake',
        child: AppleBouncy(
          scaleDown: 0.92,
          enabled: onTap != null,
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.cardElevated,
              borderRadius: AppRadii.mdBorderRadius,
              border: Border.all(
                color: AppTheme.cardBorder,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.refresh_rounded,
              size: 18,
              color:
                  onTap != null ? AppTheme.textSecondary : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
