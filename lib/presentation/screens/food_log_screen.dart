import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/food_models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/date_carousel_ribbon.dart';
import '../widgets/nutrition_summary_banner.dart';
import '../widgets/persistent_search_bar.dart';
import '../widgets/timeline_hour_slot.dart';
import 'food_search_screen.dart';
import 'plate_serving_sheet.dart';

/// Authentic Sique Food Log Screen (v5+ Experience).
/// Houses the Date Carousel, Nutrition Summary, and Hourly Timeline.
class FoodLogScreen extends ConsumerStatefulWidget {
  const FoodLogScreen({super.key});

  @override
  ConsumerState<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends ConsumerState<FoodLogScreen> {
  bool _isCollapsed = false;

  /// Tracks whether we have already fired the celebratory haptic this session
  /// for calories and protein independently to avoid repeat firing.
  bool _calHapticFired = false;
  bool _proteinHapticFired = false;

  DateTime get _selectedDate {
    final str = ref.read(selectedDateProvider);
    return DateTime.tryParse(str) ?? ref.read(clockProvider)();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _onAddForHour(int hour) {
    final current = _selectedDate;
    final entryTime = DateTime(
      current.year,
      current.month,
      current.day,
      hour,
      0,
    );
    Navigator.push(
      context,
      FoodSearchScreen.route(
        mealType: _getMealTypeForHour(hour),
        initialLoggedAt: entryTime,
      ),
    );
  }

  MealType _getMealTypeForHour(int hour) {
    if (hour < 11) return MealType.breakfast;
    if (hour < 16) return MealType.lunch;
    if (hour < 21) return MealType.dinner;
    return MealType.snacks;
  }

  void _onEntryTap(DailyFoodLogEntry entry) {
    final db = ref.read(databaseProvider);
    final portionUnits = db.getPortionUnits(entry.food.id);
    final macroTargets = ref.read(macroTargetProvider);

    PlateServingSheet.show(
      context: context,
      food: entry.food,
      portionUnits: portionUnits,
      macroTargets: macroTargets,
      initialLoggedAt: entry.loggedAt,
      onLogConfirmed: ({
        required PortionUnit unit,
        required double quantity,
        required OilModifier oilModifier,
        required DateTime loggedAt,
      }) {
        // Remove old and add updated
        ref.read(dailyFoodLogsProvider.notifier).removeEntry(entry.id);
        ref.read(dailyFoodLogsProvider.notifier).addEntry(
              food: entry.food,
              portionUnit: unit,
              quantity: quantity,
              mealType: entry.mealType,
              oilModifier: oilModifier,
              loggedAt: loggedAt,
            );
      },
    );
  }

  /// Fires celebratory haptic when daily calories or protein first reach their target.
  void _checkAndFireCelebratoryHaptic({
    required double totalCalories,
    required double totalProtein,
    required double targetCalories,
    required double targetProteinGrams,
  }) {
    final calReached = targetCalories > 0 && totalCalories >= targetCalories;
    final proteinReached =
        targetProteinGrams > 0 && totalProtein >= targetProteinGrams;

    if (calReached && !_calHapticFired) {
      _calHapticFired = true;
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 120), () {
        HapticFeedback.lightImpact();
      });
    }
    if (proteinReached && !_proteinHapticFired) {
      _proteinHapticFired = true;
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 120), () {
        HapticFeedback.lightImpact();
      });
    }
  }

  /// Copies entries from yesterday's same hour slot to the current selected date.
  void _copyYesterdayEntries(
    List<DailyFoodLogEntry> yesterdayEntries,
    DateTime selectedDate,
    int hour,
  ) {
    for (final entry in yesterdayEntries) {
      final newLoggedAt = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        hour,
        entry.loggedAt.minute,
      );
      ref.read(dailyFoodLogsProvider.notifier).addEntry(
            food: entry.food,
            portionUnit: PortionUnit(
              id: 0,
              foodId: entry.food.id,
              unitName: entry.unitName,
              gramsPerUnit: entry.gramWeight /
                  (entry.servingQuantity > 0 ? entry.servingQuantity : 1.0),
            ),
            quantity: entry.servingQuantity,
            mealType: _getMealTypeForHour(hour),
            oilModifier: entry.oilModifier,
            loggedAt: newLoggedAt,
          );
    }

    final count = yesterdayEntries.length;
    // Show floating SnackBar with Undo support
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied $count ${count == 1 ? 'item' : 'items'} from yesterday',
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppTheme.activeBlue,
          onPressed: () {
            // Remove the just-added entries (last `count` entries of this hour)
            final current = ref.read(dailyFoodLogsProvider);
            final todayStr = DateFormat('yyyy-MM-dd').format(selectedDate);
            final toRemove = current
                .where(
                  (e) => e.date == todayStr && e.loggedAt.hour == hour,
                )
                .toList()
                .reversed
                .take(count)
                .toList();
            for (final e in toRemove) {
              ref.read(dailyFoodLogsProvider.notifier).removeEntry(e.id);
            }
          },
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(selectedDateProvider, (prev, next) {
      if (prev != next) {
        // Reset celebratory haptic flags when date changes
        _calHapticFired = false;
        _proteinHapticFired = false;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });

    final clock = ref.watch(clockProvider);
    final now = clock();
    final selectedDateStr = ref.watch(selectedDateProvider);
    final selectedDate = DateTime.tryParse(selectedDateStr) ?? now;
    final allLogs = ref.watch(dailyFoodLogsProvider);
    final macroTargets = ref.watch(macroTargetProvider);

    // Filter logs for selected date
    final dayLogs =
        allLogs.where((log) => _isSameDay(log.loggedAt, selectedDate)).toList();

    // Compute daily nutrition aggregate for selected date
    final dailyAggregate = dayLogs.fold<DailyNutritionAggregate>(
      const DailyNutritionAggregate(
        totalCalories: 0,
        totalProtein: 0,
        totalFat: 0,
        totalCarbs: 0,
      ),
      (acc, entry) => DailyNutritionAggregate(
        totalCalories: acc.totalCalories + entry.effectiveCalories,
        totalProtein: acc.totalProtein + entry.effectiveProtein,
        totalFat: acc.totalFat + entry.effectiveFat,
        totalCarbs: acc.totalCarbs + entry.effectiveCarbs,
      ),
    );

    // Check for celebratory haptic (runs after each build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndFireCelebratoryHaptic(
        totalCalories: dailyAggregate.totalCalories,
        totalProtein: dailyAggregate.totalProtein,
        targetCalories: macroTargets.targetCalories,
        targetProteinGrams: macroTargets.targetProteinGrams,
      );
    });

    // Fetch yesterday's logs for Copy Yesterday feature
    final yesterday = selectedDate.subtract(const Duration(days: 1));
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);
    final db = ref.read(databaseProvider);
    final yesterdayLogs = db.getFoodLogsForDate(yesterdayStr);

    // Continuous 24-hour timeline slots (12 AM to 11 PM)
    final allHours = List<int>.generate(24, (i) => i);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // 1. Signature Date Carousel Ribbon with Authentic Header:
                // [ ≡ ]           < Today ▾ >           [ ☰ ]
                // and 7-day circular ribbon (M 12, T 13, W 14...)
                SliverToBoxAdapter(
                  child: DateCarouselRibbon(
                    selectedDate: selectedDate,
                    now: now,
                    onDateSelected: (date) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ref.read(selectedDateProvider.notifier).state =
                          DateFormat('yyyy-MM-dd').format(date);
                    },
                    leading: IconButton(
                      icon: const Icon(Icons.menu_rounded, size: 24),
                      color: AppTheme.textSecondary,
                      tooltip: 'Menu',
                      onPressed: () {},
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        _isCollapsed
                            ? Icons.view_agenda_outlined
                            : Icons.format_list_bulleted_rounded,
                        size: 22,
                      ),
                      color: AppTheme.textSecondary,
                      tooltip: _isCollapsed
                          ? 'Expand Timeline'
                          : 'Collapse Timeline',
                      onPressed: () {
                        setState(() => _isCollapsed = !_isCollapsed);
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // 3. Nutrition Summary Progress Banner (with streak)
                SliverToBoxAdapter(
                  child: NutritionSummaryBanner(
                    consumed: dailyAggregate,
                    targets: macroTargets,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // 4. Hourly Timeline Slots
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final hour = allHours[index];
                      final hourEntries = dayLogs
                          .where((e) => e.loggedAt.hour == hour)
                          .toList();
                      final hourYesterday = yesterdayLogs
                          .where((e) => e.loggedAt.hour == hour)
                          .toList();

                      return TimelineHourSlot(
                        hour: hour,
                        entries: hourEntries,
                        isCollapsed: _isCollapsed,
                        onAddTap: () => _onAddForHour(hour),
                        onEntryTap: _onEntryTap,
                        yesterdayEntries: hourYesterday,
                        onCopyYesterday: (entriesToCopy) =>
                            _copyYesterdayEntries(
                          entriesToCopy,
                          selectedDate,
                          hour,
                        ),
                        onEntryDelete: (entry) {
                          ref
                              .read(dailyFoodLogsProvider.notifier)
                              .removeEntry(entry.id);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed ${entry.foodName}'),
                              action: SnackBarAction(
                                label: 'Undo',
                                textColor: AppTheme.activeBlue,
                                onPressed: () {
                                  ref
                                      .read(dailyFoodLogsProvider.notifier)
                                      .restoreEntry(entry);
                                },
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        },
                      );
                    },
                    childCount: allHours.length,
                  ),
                ),

                // Bottom padding to avoid persistent search bar and navigation dock overlap
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),

            // Navigation dock avoidance placeholder (always in widget tree)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(height: 80),
            ),

            // 5. Docked Persistent Quick Search Bar (above Bottom Nav)
            Positioned(
              left: 0,
              right: 0,
              bottom: 4,
              child: PersistentSearchBar(
                onSearchTap: () {
                  Navigator.push(
                    context,
                    FoodSearchScreen.route(
                      mealType: _getMealTypeForHour(DateTime.now().hour),
                      initialLoggedAt: _selectedDate,
                    ),
                  );
                },
                onBarcodeTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Barcode scanner active'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                onCustomFoodTap: () {
                  Navigator.push(
                    context,
                    FoodSearchScreen.route(
                      mealType: _getMealTypeForHour(DateTime.now().hour),
                      initialLoggedAt: _selectedDate,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
