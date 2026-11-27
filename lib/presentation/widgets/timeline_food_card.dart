import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../domain/models/food_models.dart';
import '../theme/app_theme.dart';
import 'food_svg_icon.dart';

/// Food card inside the Sique timeline slot.
class TimelineFoodCard extends StatelessWidget {
  const TimelineFoodCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDelete,
    this.onDuplicate,
  });

  final DailyFoodLogEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onDuplicate;

  @override
  Widget build(BuildContext context) {
    final period = entry.loggedAt.hour < 12 ? 'AM' : 'PM';
    final timeStr =
        '${entry.loggedAt.hour % 12 == 0 ? 12 : entry.loggedAt.hour % 12}:${entry.loggedAt.minute.toString().padLeft(2, '0')} $period';

    return Dismissible(
      key: ValueKey(entry.id),
      direction: onDuplicate != null
          ? DismissDirection.horizontal
          : DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onDuplicate?.call();
          return false;
        }
        return true;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppTheme.activeBlue.withValues(alpha: 0.16),
          borderRadius: AppRadii.lgBorderRadius,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.copy_rounded, color: AppTheme.activeBlueText, size: 20),
            SizedBox(width: 8),
            Text(
              'Duplicate',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.activeBlueText,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.protein.withAlpha(50),
          borderRadius: AppRadii.lgBorderRadius,
        ),
        child:
            const Icon(Icons.delete_outline_rounded, color: AppTheme.protein),
      ),
      child: Semantics(
        customSemanticsActions: {
          const CustomSemanticsAction(label: 'Delete food item'): onDelete,
          if (onDuplicate != null)
            const CustomSemanticsAction(label: 'Duplicate food item'):
                onDuplicate!,
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              borderRadius: AppRadii.lgBorderRadius,
              border: Border.all(color: AppTheme.cardBorder.withAlpha(120)),
            ),
            child: Row(
              children: [
                // Food Icon
                FoodSvgIcon(iconName: entry.food.iconName, size: 28),
                const SizedBox(width: 12),

                // Title, timestamp & macro subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            timeStr,
                            style: AppTypography.numericCaption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.food.name,
                              style: AppTypography.titleSmall.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Semantics(
                        label:
                            '${entry.effectiveCalories.round()} calories, ${entry.effectiveProtein.toStringAsFixed(1)} grams protein, ${entry.effectiveFat.toStringAsFixed(1)} grams fat, ${entry.effectiveCarbs.toStringAsFixed(1)} grams carbs, ${entry.quantity.toStringAsFixed(1)} ${entry.portionUnit.unitName}',
                        child: Text(
                          '${entry.effectiveCalories.round()} 🔥 • ${entry.effectiveProtein.toStringAsFixed(1)}P • ${entry.effectiveFat.toStringAsFixed(1)}F • ${entry.effectiveCarbs.toStringAsFixed(1)}C • ${entry.quantity.toStringAsFixed(1)} ${entry.portionUnit.unitName}',
                          style: AppTypography.numericCaption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
