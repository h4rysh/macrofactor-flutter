import 'package:flutter/material.dart';
import '../../domain/models/food_models.dart';
import '../theme/app_theme.dart';
import 'apple_tactile_card.dart';
import 'food_svg_icon.dart';
import 'timeline_food_card.dart';

/// Hourly slot on the Sique timeline (e.g. 8 AM +, 12 PM +).
class TimelineHourSlot extends StatelessWidget {
  const TimelineHourSlot({
    super.key,
    required this.hour,
    required this.entries,
    required this.isCollapsed,
    required this.onAddTap,
    required this.onEntryTap,
    required this.onEntryDelete,
    this.onEntryDuplicate,
    this.yesterdayEntries = const [],
    this.onCopyYesterday,
    this.isFastingWindow = false,
  });

  final int hour;
  final List<DailyFoodLogEntry> entries;
  final bool isCollapsed;
  final VoidCallback onAddTap;
  final ValueChanged<DailyFoodLogEntry> onEntryTap;
  final ValueChanged<DailyFoodLogEntry> onEntryDelete;
  final ValueChanged<DailyFoodLogEntry>? onEntryDuplicate;
  final bool isFastingWindow;

  /// Entries from the same hour slot on the previous day, used for Copy Yesterday.
  final List<DailyFoodLogEntry> yesterdayEntries;

  /// Called when user taps "Copy Yesterday". Receives the list to be copied.
  final ValueChanged<List<DailyFoodLogEntry>>? onCopyYesterday;

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

    final bool showCopyYesterday = entries.isEmpty &&
        yesterdayEntries.isNotEmpty &&
        onCopyYesterday != null;
    final bool isEmptySlot = entries.isEmpty && !showCopyYesterday;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isEmptySlot ? 1.5 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hour Header Row: [ 8 AM + ] ................ [ 298 🔥 17P 21F 13C ]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Time capsule with plus button
              Semantics(
                button: true,
                label: 'Add food at ${_formatHour(hour)}',
                child: AppleBouncy(
                  scaleDown: 0.94,
                  semanticLabel: 'Add food at ${_formatHour(hour)}',
                  onTap: () {
                    AppHaptics.lightImpact();
                    onAddTap();
                  },
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: isEmptySlot ? 28 : 44,
                      minWidth: 56,
                    ),
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(
                      horizontal: isEmptySlot ? 8 : 12,
                      vertical: isEmptySlot ? 3 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: isEmptySlot
                          ? AppTheme.cardSurface.withAlpha(140)
                          : AppTheme.cardSurface,
                      borderRadius: AppRadii.lgBorderRadius,
                      border: Border.all(
                        color: isEmptySlot
                            ? AppTheme.cardBorder.withAlpha(80)
                            : AppTheme.cardBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatHour(hour),
                          style: TextStyle(
                            fontSize: isEmptySlot ? 11 : 12,
                            fontWeight:
                                isEmptySlot ? FontWeight.w600 : FontWeight.w700,
                            color: isEmptySlot
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.add_rounded,
                          size: isEmptySlot ? 12 : 14,
                          color: AppTheme.activeBlue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Fasting window subtle pill when empty
              if (entries.isEmpty && isFastingWindow)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAB47BC).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Fasting Window',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFCE93D8),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${totalProtein.round()}P',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.protein,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${totalFat.round()}F',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.fat,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${totalCarbs.round()}C',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.carbs,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          if (entries.isNotEmpty || showCopyYesterday)
            const SizedBox(height: 8),

          // Body: Animated expansion/collapse for icons, cards, or copy yesterday
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubicEmphasized,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (entries.isNotEmpty) ...[
                  if (isCollapsed)
                    // Collapsed mode: horizontal scroll of food icons
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardSurface.withAlpha(150),
                        borderRadius: AppRadii.mdBorderRadius,
                        border: Border.all(
                            color: AppTheme.cardBorder.withAlpha(80)),
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
                        onDuplicate: onEntryDuplicate != null
                            ? () => onEntryDuplicate!(entry)
                            : null,
                      ),
                    ),
                ] else ...[
                  if (showCopyYesterday)
                    // "Copy Yesterday" subtle action button
                    _CopyYesterdayButton(
                      count: yesterdayEntries.length,
                      onTap: () {
                        AppHaptics.mediumImpact();
                        onCopyYesterday!(yesterdayEntries);
                      },
                    )
                  else
                    // Compact hairline for continuous 24h timeline
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      height: 0.6,
                      color: AppTheme.cardBorder.withAlpha(25),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle tactile "Copy Yesterday (N items)" button for empty hour slots.
class _CopyYesterdayButton extends StatelessWidget {
  const _CopyYesterdayButton({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Copy $count ${count == 1 ? 'item' : 'items'} from yesterday',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.activeBlue.withAlpha(18),
            borderRadius: AppRadii.mdBorderRadius,
            border: Border.all(
              color: AppTheme.activeBlue.withAlpha(60),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.content_copy_rounded,
                size: 13,
                color: AppTheme.activeBlue.withAlpha(200),
              ),
              const SizedBox(width: 6),
              Text(
                'Copy Yesterday ($count ${count == 1 ? 'item' : 'items'})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.activeBlue.withAlpha(220),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
