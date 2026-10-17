import 'package:flutter/material.dart';
import '../../domain/models/food_models.dart';
import '../theme/app_theme.dart';
import 'apple_tactile_card.dart';
import 'food_svg_icon.dart';
import 'timeline_food_card.dart';

/// Hourly slot on the MacroFactor timeline (e.g. 8 AM +, 12 PM +).
class TimelineHourSlot extends StatelessWidget {
  const TimelineHourSlot({
    super.key,
    required this.hour,
    required this.entries,
    required this.isCollapsed,
    required this.onAddTap,
    required this.onEntryTap,
    required this.onEntryDelete,
  });

  final int hour;
  final List<DailyFoodLogEntry> entries;
  final bool isCollapsed;
  final VoidCallback onAddTap;
  final ValueChanged<DailyFoodLogEntry> onEntryTap;
  final ValueChanged<DailyFoodLogEntry> onEntryDelete;

  String _formatHour(int h) {
    if (h == 0) return '12 AM';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }

  @override
  Widget build(BuildContext context) {
    final totalCalories = entries.fold<double>(
      0,
      (sum, e) => sum + e.effectiveCalories,
    );
    final totalProtein = entries.fold<double>(
      0,
      (sum, e) => sum + e.effectiveProtein,
    );
    final totalFat = entries.fold<double>(
      0,
      (sum, e) => sum + e.effectiveFat,
    );
    final totalCarbs = entries.fold<double>(
      0,
      (sum, e) => sum + e.effectiveCarbs,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hour Header Row: [ 8 AM + ] ................ [ 298 🔥 17P 21F 13C ]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Time capsule with plus button
              AppleBouncy(
                scaleDown: 0.94,
                onTap: onAddTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatHour(hour),
                        style: const TextStyle(
                          fontFamily: 'MacroSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: AppTheme.activeBlue,
                      ),
                    ],
                  ),
                ),
              ),

              // Macro Subtotals for this Hour (if items logged)
              if (entries.isNotEmpty)
                Row(
                  children: [
                    Text(
                      '${totalCalories.round()} 🔥',
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${totalProtein.round()}P',
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.protein,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${totalFat.round()}F',
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.fat,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${totalCarbs.round()}C',
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.carbs,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Body: Collapsed Icon Row OR Detailed Cards
          if (entries.isNotEmpty) ...[
            if (isCollapsed)
              // Collapsed mode: horizontal scroll of food icons
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface.withAlpha(150),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder.withAlpha(80)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: AppleBouncy(
                          scaleDown: 0.90,
                          onTap: () => onEntryTap(entry),
                          child: FoodSvgIcon(
                            iconName: entry.food.iconName,
                            size: 26,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              )
            else
              // Detailed mode: full food cards
              ...entries.map(
                (entry) => TimelineFoodCard(
                  entry: entry,
                  onTap: () => onEntryTap(entry),
                  onDelete: () => onEntryDelete(entry),
                ),
              ),
          ] else ...[
            // Empty placeholder for this hour slot
            Container(
              height: 1,
              color: AppTheme.cardBorder.withAlpha(40),
            ),
          ],
        ],
      ),
    );
  }
}
