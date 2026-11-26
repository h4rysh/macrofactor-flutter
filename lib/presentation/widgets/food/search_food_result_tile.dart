import 'package:flutter/material.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/recipe_models.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';
import 'package:sique/presentation/widgets/food_search_highlight.dart';
import 'package:sique/presentation/widgets/food_svg_icon.dart';

/// Result row card rendered in [FoodSearchScreen] displaying macro pills,
/// Volumetric caloric density tier, and tactile + / checkmark stage action.
class SearchFoodResultTile extends StatelessWidget {
  const SearchFoodResultTile({
    super.key,
    required this.food,
    required this.searchQuery,
    required this.index,
    required this.totalCount,
    required this.isStaged,
    required this.onTap,
    required this.onQuickStage,
  });

  final FoodItem food;
  final String searchQuery;
  final int index;
  final int totalCount;
  final bool isStaged;
  final VoidCallback onTap;
  final VoidCallback onQuickStage;

  @override
  Widget build(BuildContext context) {
    final defaultNutrition = food.calculateNutrition(
      quantity: 1.0,
      unit: food.defaultPortionUnit,
    );
    final density = VolumetricDensity.fromCaloriesPer100g(food.caloriesPer100g);
    final Color densityColor = switch (density) {
      VolumetricDensity.low => AppTheme.protein,
      VolumetricDensity.medium => AppTheme.carbs,
      VolumetricDensity.high => AppTheme.calories,
    };

    return Semantics(
      button: true,
      label:
          '${food.name}, ${defaultNutrition.calories.round()} calories, ${defaultNutrition.protein.toStringAsFixed(1)} grams protein, item ${index + 1} of $totalCount',
      child: AppleBouncy(
        scaleDown: 0.98,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: AppRadii.lgBorderRadius,
            border: Border.all(color: AppTheme.cardBorder, width: 0.8),
          ),
          child: Row(
            children: [
              FoodSvgIcon(iconName: food.iconName, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FoodSearchHighlight(name: food.name, query: searchQuery),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        AppleBadge(
                          label: '${defaultNutrition.calories.round()} kcal',
                          color: AppTheme.calories,
                        ),
                        AppleBadge(
                          label:
                              '${defaultNutrition.protein.toStringAsFixed(1)}P',
                          color: AppTheme.protein,
                        ),
                        AppleBadge(
                          label: '${defaultNutrition.fat.toStringAsFixed(1)}F',
                          color: AppTheme.fat,
                        ),
                        AppleBadge(
                          label:
                              '${defaultNutrition.carbs.toStringAsFixed(1)}C',
                          color: AppTheme.carbs,
                        ),
                        AppleBadge(
                          label: density.label,
                          color: densityColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: AppleBouncy(
                  scaleDown: 0.88,
                  onTap: onQuickStage,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isStaged
                          ? Container(
                              key: const ValueKey('check'),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.activeBlue.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.activeBlue,
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: AppTheme.activeBlue,
                              ),
                            )
                          : Container(
                              key: const ValueKey('plus'),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.cardElevated,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.cardBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
