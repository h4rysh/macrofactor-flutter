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
    final profile = ref.watch(userProfileProvider);
    final targetWaterMl = profile.dailyWaterTargetMl;

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
                        fontWeight: FontWeight.w800,
                        color: AppTheme.activeBlue,
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
                            '$currentWaterMl',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            ' / $targetWaterMl ml',
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
                          size: 13, color: AppTheme.activeBlue),
                      SizedBox(width: 4),
                      Text(
                        'OPTIMAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.activeBlue,
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
                label: '+250ml',
                onTap: () {
                  AppHaptics.lightImpact();
                  ref.read(dailyWaterProvider.notifier).addWater(250);
                },
              ),
              const SizedBox(width: 8),
              _buildWaterBtn(
                label: '+500ml',
                onTap: () {
                  AppHaptics.lightImpact();
                  ref.read(dailyWaterProvider.notifier).addWater(500);
                },
              ),
              const SizedBox(width: 8),
              _buildWaterBtn(
                label: '+750ml',
                onTap: () {
                  AppHaptics.lightImpact();
                  ref.read(dailyWaterProvider.notifier).addWater(750);
                },
              ),
              const SizedBox(width: 8),
              _buildResetBtn(
                onTap: () {
                  AppHaptics.selectionClick();
                  ref.read(dailyWaterProvider.notifier).resetToday();
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
                color: AppTheme.activeBlue,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetBtn({required VoidCallback onTap}) {
    return AppleBouncy(
      scaleDown: 0.92,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.cardElevated,
          borderRadius: AppRadii.mdBorderRadius,
          border: Border.all(
            color: AppTheme.cardBorder,
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.refresh_rounded,
          size: 16,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
