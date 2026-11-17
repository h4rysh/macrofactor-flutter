import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/food_models.dart';
import '../../domain/models/user_profile.dart';
import '../providers/logging_streak_provider.dart';
import '../theme/app_theme.dart';
import 'animated_primitives.dart';

/// Authentic Sique Nutrition Summary Banner right below the Date Carousel.
/// Shows consumed vs target for Calories, Protein (P), Fat (F), and Carbs (C).
/// Also renders a 🔥 logging streak badge when the user has a multi-day streak.
class NutritionSummaryBanner extends ConsumerWidget {
  const NutritionSummaryBanner({
    super.key,
    required this.consumed,
    required this.targets,
  });

  final DailyNutritionAggregate consumed;
  final MacroTargets targets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(loggingStreakProvider);

    final proteinProgress = targets.targetProteinGrams > 0
        ? (consumed.totalProtein / targets.targetProteinGrams).clamp(0.0, 1.0)
        : 0.0;
    final fatProgress = targets.targetFatGrams > 0
        ? (consumed.totalFat / targets.targetFatGrams).clamp(0.0, 1.0)
        : 0.0;
    final carbsProgress = targets.targetCarbsGrams > 0
        ? (consumed.totalCarbs / targets.targetCarbsGrams).clamp(0.0, 1.0)
        : 0.0;

    final semanticsLabel =
        'Daily Nutrition: ${consumed.totalCalories.round()} of ${targets.targetCalories.round()} calories consumed, '
        '${(targets.targetCalories - consumed.totalCalories).round()} calories remaining. '
        'Protein: ${consumed.totalProtein.round()}g of ${targets.targetProteinGrams.round()}g. '
        'Carbs: ${consumed.totalCarbs.round()}g of ${targets.targetCarbsGrams.round()}g. '
        'Fat: ${consumed.totalFat.round()}g of ${targets.targetFatGrams.round()}g.'
        '${streak > 1 ? ' Logging streak: $streak days.' : ''}';

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: AppleTactileCard(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Single Sleek Horizontal Row: 🔥 Cal | P | F | C | streak badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Calories (Flame)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🔥',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${consumed.totalCalories.round()} / ${targets.targetCalories.round()}',
                          style: AppTypography.numericSmall.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // 2. Protein (P)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _buildMacroPill(
                      label: 'P',
                      consumed: consumed.totalProtein.round(),
                      target: targets.targetProteinGrams.round(),
                      progress: proteinProgress,
                      color: AppTheme.protein,
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // 3. Fat (F)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _buildMacroPill(
                      label: 'F',
                      consumed: consumed.totalFat.round(),
                      target: targets.targetFatGrams.round(),
                      progress: fatProgress,
                      color: AppTheme.fat,
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // 4. Carbs (C)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _buildMacroPill(
                      label: 'C',
                      consumed: consumed.totalCarbs.round(),
                      target: targets.targetCarbsGrams.round(),
                      progress: carbsProgress,
                      color: AppTheme.carbs,
                    ),
                  ),
                ),

                // 5. Streak Badge (shown when streak >= 2 days)
                if (streak >= 2) ...[
                  const SizedBox(width: 6),
                  _StreakBadge(streak: streak),
                ],
              ],
            ),

            const SizedBox(height: 6),

            // Two-dot page indicator matching Sique
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppTheme.textPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withAlpha(120),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroPill({
    required String label,
    required int consumed,
    required int target,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              '$consumed/$target',
              style: AppTypography.numericCaption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: 46,
          child: AnimatedMacroBar(
            ratio: progress,
            color: color,
            height: 3.0,
          ),
        ),
      ],
    );
  }
}

/// Animated streak badge pill shown in the nutrition banner.
class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(streak),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B2B), Color(0xFFFFB347)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B2B).withAlpha(80),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 10)),
            const SizedBox(width: 2),
            Text(
              '${streak}d',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
