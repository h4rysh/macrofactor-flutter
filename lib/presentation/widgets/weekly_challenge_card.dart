import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/app_database.dart';
import '../../domain/algorithms/challenge_generation_service.dart';
import '../../domain/models/weekly_challenge_model.dart';
import '../providers/app_providers.dart';
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
      case ChallengeType.proteinVolume:
        return Icons.fitness_center_rounded;
      case ChallengeType.fiberBuilder:
        return Icons.grass_rounded;
      case ChallengeType.produceBooster:
        return Icons.eco_rounded;
      case ChallengeType.micronutrientFix:
        return Icons.science_rounded;
      case ChallengeType.scaleCadence:
        return Icons.monitor_weight_outlined;
      case ChallengeType.hydrationHero:
        return Icons.water_drop_rounded;
      case ChallengeType.trainingConsistency:
        return Icons.directions_run_rounded;
      case ChallengeType.nightCapTamer:
        return Icons.nightlight_round;
      case ChallengeType.recompMeasure:
        return Icons.straighten_rounded;
    }
  }

  Color _colorForType(ChallengeType type) {
    switch (type) {
      case ChallengeType.proteinAnchor:
      case ChallengeType.proteinVolume:
        return AppTheme.protein;
      case ChallengeType.fiberBuilder:
        return const Color(0xFF66BB6A);
      case ChallengeType.produceBooster:
        return AppTheme.carbs;
      case ChallengeType.micronutrientFix:
        return const Color(0xFF26C6DA);
      case ChallengeType.scaleCadence:
        return AppTheme.calories;
      case ChallengeType.hydrationHero:
        return AppTheme.activeBlue;
      case ChallengeType.trainingConsistency:
        return const Color(0xFFFF7043);
      case ChallengeType.nightCapTamer:
        return const Color(0xFFAB47BC);
      case ChallengeType.recompMeasure:
        return const Color(0xFF9CCC65);
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
      borderColor:
          isDone ? themeColor.withValues(alpha: 0.5) : AppTheme.cardBorder,
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

          // Progress Metric, 7-Day Dot Strip & Auto-Synced Actions
          _buildFooterStrip(context, ref, themeColor, isDone),
        ],
      ),
    );
  }

  Widget _buildFooterStrip(
    BuildContext context,
    WidgetRef ref,
    Color themeColor,
    bool isDone,
  ) {
    final db = ref.watch(databaseProvider);
    final profile = ref.watch(userProfileProvider);
    final pTarget = profile.proteinPreference.gramsPerKg *
        (profile.currentWeightKg > 0 ? profile.currentWeightKg : 70.0);
    final dots = db.challengesDao.getDailyCompletionDots(
      challenge,
      proteinTargetG: pTarget,
    );
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final supportsFoods = challenge.type == ChallengeType.proteinAnchor ||
        challenge.type == ChallengeType.proteinVolume ||
        challenge.type == ChallengeType.fiberBuilder ||
        challenge.type == ChallengeType.produceBooster ||
        challenge.type == ChallengeType.micronutrientFix;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${challenge.currentValue.toStringAsFixed(challenge.currentValue % 1 == 0 ? 0 : 1)} / ${challenge.targetValue.toStringAsFixed(challenge.targetValue % 1 == 0 ? 0 : 1)} ${challenge.unit} · Auto-synced',
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(7, (i) {
                final hit = i < dots.length && dots[i];
                final wd = (challenge.weekStartDate.weekday - 1 + i) % 7;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Column(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hit ? themeColor : AppTheme.cardElevated,
                          border: Border.all(
                            color: hit ? themeColor : AppTheme.cardBorder,
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dayLabels[wd],
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (supportsFoods)
              AppleBouncy(
                scaleDown: 0.96,
                onTap: () => _showFixingFoodsSheet(context, db, themeColor),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant_rounded,
                          size: 13, color: themeColor),
                      const SizedBox(width: 5),
                      Text(
                        'Foods that fix this',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: themeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!isDone)
              AppleBouncy(
                scaleDown: 0.96,
                onTap: () {
                  AppHaptics.lightImpact();
                  ref
                      .read(weeklyChallengesProvider.notifier)
                      .swapChallenge(challenge.id);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.cardElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded,
                          size: 13, color: AppTheme.textSecondary),
                      SizedBox(width: 4),
                      Text(
                        'Swap',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _showFixingFoodsSheet(
    BuildContext context,
    AppDatabase db,
    Color themeColor,
  ) {
    final foods = ChallengeGenerationService.suggestFixingFoods(db, challenge);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Foods for ${challenge.title}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (foods.isEmpty)
              const Text(
                'Log whole foods matching this target to auto-sync your 7-day dots.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              )
            else
              for (final f in foods)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: themeColor.withValues(alpha: 0.16),
                    child:
                        Icon(Icons.bolt_rounded, color: themeColor, size: 18),
                  ),
                  title: Text(
                    f.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Text(
                    f.badge,
                    style: TextStyle(
                      color: themeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
