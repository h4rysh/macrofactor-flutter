import 'package:flutter/material.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/food_svg_icon.dart';

/// Meal section for Breakfast, Lunch, Dinner, or Snacks in the food log timeline.
class MealSection extends StatelessWidget {
  const MealSection({
    super.key,
    required this.mealType,
    required this.entries,
    required this.onAddTap,
    required this.onDeleteEntry,
  });

  final MealType mealType;
  final List<FoodLogEntry> entries;
  final VoidCallback onAddTap;
  final ValueChanged<int> onDeleteEntry;

  @override
  Widget build(BuildContext context) {
    final totalCalories =
        entries.fold<double>(0.0, (acc, item) => acc + item.calories).round();
    final totalProtein =
        entries.fold<double>(0.0, (acc, item) => acc + item.protein).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealType.displayName.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entries.isEmpty
                          ? mealType.defaultTime
                          : '$totalCalories kcal • ${totalProtein}g protein',
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton.filledTonal(
                  onPressed: onAddTap,
                  icon: const Icon(Icons.add, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.surface,
                    foregroundColor: AppTheme.calories,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
            if (entries.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: AppTheme.cardBorder, height: 1),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _FoodLogRowItem(
                    entry: entry,
                    onDelete: () {
                      if (entry.id != null) {
                        onDeleteEntry(entry.id!);
                      }
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FoodLogRowItem extends StatelessWidget {
  const _FoodLogRowItem({
    required this.entry,
    required this.onDelete,
  });

  final FoodLogEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          FoodSvgIcon(iconSvg: entry.iconSvg, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.foodName,
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '${entry.servingQuantity.toStringAsFixed(entry.servingQuantity.truncateToDouble() == entry.servingQuantity ? 0 : 1)} × ${entry.unitName}',
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (entry.oilModifier != OilModifier.standard) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: entry.oilModifier == OilModifier.lowOil
                              ? AppTheme.carbs.withValues(alpha: 0.15)
                              : AppTheme.fat.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.oilModifier == OilModifier.lowOil
                              ? 'Low Oil'
                              : 'Desi Ghee',
                          style: TextStyle(
                            fontFamily: 'MacroSans',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: entry.oilModifier == OilModifier.lowOil
                                ? AppTheme.carbs
                                : AppTheme.fat,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.calories.round()} kcal',
                style: const TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.calories,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${entry.protein.round()}g P • ${entry.carbs.round()}g C • ${entry.fat.round()}g F',
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppTheme.textMuted),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Delete item',
          ),
        ],
      ),
    );
  }
}
