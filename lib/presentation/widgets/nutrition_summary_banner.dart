import 'package:flutter/material.dart';
import '../../domain/models/food_models.dart';
import '../../domain/models/user_profile.dart';
import '../theme/app_theme.dart';
import 'animated_primitives.dart';

/// Authentic MacroFactor Nutrition Summary Banner right below the Date Carousel.
/// Shows consumed vs target for Calories, Protein (P), Fat (F), and Carbs (C).
class NutritionSummaryBanner extends StatelessWidget {
  const NutritionSummaryBanner({
    super.key,
    required this.consumed,
    required this.targets,
  });

  final DailyNutritionAggregate consumed;
  final MacroTargets targets;

  @override
  Widget build(BuildContext context) {
    final proteinProgress = targets.targetProteinGrams > 0
        ? (consumed.totalProtein / targets.targetProteinGrams).clamp(0.0, 1.0)
        : 0.0;
    final fatProgress = targets.targetFatGrams > 0
        ? (consumed.totalFat / targets.targetFatGrams).clamp(0.0, 1.0)
        : 0.0;
    final carbsProgress = targets.targetCarbsGrams > 0
        ? (consumed.totalCarbs / targets.targetCarbsGrams).clamp(0.0, 1.0)
        : 0.0;

    return AppleTactileCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Single Sleek Horizontal Row: 🔥 Cal | P | F | C
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
                        style: const TextStyle(
                          fontFamily: 'MacroSans',
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
            ],
          ),

          const SizedBox(height: 6),

          // Two-dot page indicator matching MacroFactor
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
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              '$consumed/$target',
              style: const TextStyle(
                fontFamily: 'DMSans',
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
