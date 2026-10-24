import 'package:flutter/material.dart';
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
  });

  final DailyFoodLogEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${entry.loggedAt.hour % 12 == 0 ? 12 : entry.loggedAt.hour % 12}:${entry.loggedAt.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.protein.withAlpha(50),
          borderRadius: BorderRadius.circular(14),
        ),
        child:
            const Icon(Icons.delete_outline_rounded, color: AppTheme.protein),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(14),
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
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.food.name,
                            style: const TextStyle(
                              fontFamily: 'MacroSans',
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
                    Text(
                      '${entry.effectiveCalories.round()} 🔥 • ${entry.effectiveProtein.toStringAsFixed(1)}P • ${entry.effectiveFat.toStringAsFixed(1)}F • ${entry.effectiveCarbs.toStringAsFixed(1)}C • ${entry.quantity.toStringAsFixed(1)} ${entry.portionUnit.unitName}',
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),
              const Icon(
                Icons.menu_rounded,
                size: 18,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
