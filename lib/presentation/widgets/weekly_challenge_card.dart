import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/weekly_challenge_model.dart';
import '../providers/strategy_providers.dart';
import '../theme/app_theme.dart';
import 'animated_primitives.dart';
import 'apple_tactile_card.dart';

/// Interactive container displaying active weekly behavioral challenges
/// mined from SQLite nutritional and cadence deficits.
class WeeklyChallengesSection extends ConsumerWidget {
  const WeeklyChallengesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(weeklyChallengesProvider);

    if (challenges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          child: Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 16,
                color: AppTheme.carbs,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'WEEKLY BEHAVIORAL CHALLENGES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${challenges.where((c) => c.isFulfilled).length}/${challenges.length} Done',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < challenges.length; i++) ...[
          WeeklyChallengeCard(
            challenge: challenges[i],
            key: Key('weekly_challenge_${challenges[i].id}'),
          ),
          if (i < challenges.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Card representing a single active behavioral challenge.
class WeeklyChallengeCard extends ConsumerWidget {
  const WeeklyChallengeCard({
    super.key,
    required this.challenge,
  });

  final WeeklyChallengeModel challenge;

  IconData _iconForType(ChallengeType type) {
    switch (type) {
      case ChallengeType.proteinAnchor:
        return Icons.fitness_center_rounded;
      case ChallengeType.fiberBuilder:
        return Icons.grass_rounded;
      case ChallengeType.produceBooster:
        return Icons.eco_rounded;
      case ChallengeType.scaleCadence:
        return Icons.monitor_weight_outlined;
      case ChallengeType.hydrationHero:
        return Icons.water_drop_rounded;
      case ChallengeType.nightCapTamer:
        return Icons.nightlight_round;
    }
  }

  Color _colorForType(ChallengeType type) {
    switch (type) {
      case ChallengeType.proteinAnchor:
        return AppTheme.protein;
      case ChallengeType.fiberBuilder:
        return const Color(0xFF66BB6A);
      case ChallengeType.produceBooster:
        return AppTheme.carbs;
      case ChallengeType.scaleCadence:
        return AppTheme.calories;
      case ChallengeType.hydrationHero:
        return AppTheme.activeBlue;
      case ChallengeType.nightCapTamer:
        return const Color(0xFFAB47BC);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColor = _colorForType(challenge.type);
    final iconData = _iconForType(challenge.type);
    final isDone = challenge.isFulfilled;
    final progress = challenge.progressFraction;

    return AppleTactileCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      backgroundColor: AppTheme.cardSurface,
      borderColor: isDone
          ? themeColor.withValues(alpha: 0.5)
          : AppTheme.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.14),
                  borderRadius: AppRadii.mdBorderRadius,
                ),
                child: Icon(iconData, size: 20, color: themeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            challenge.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (isDone)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: themeColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'COMPLETED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: themeColor,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 7,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.cardElevated,
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Progress Metric & 1-Tap Progress Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${challenge.currentValue.toStringAsFixed(challenge.currentValue % 1 == 0 ? 0 : 1)} / ${challenge.targetValue.toStringAsFixed(challenge.targetValue % 1 == 0 ? 0 : 1)} ${challenge.unit}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!isDone)
                AppleBouncy(
                  scaleDown: 0.94,
                  onTap: () {
                    AppHaptics.lightImpact();
                    ref
                        .read(weeklyChallengesProvider.notifier)
                        .incrementProgress(challenge.id, 1.0);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: themeColor.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 14, color: themeColor),
                        const SizedBox(width: 4),
                        Text(
                          '+1 ${challenge.unit}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: themeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
