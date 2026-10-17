import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/food_models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/date_carousel_ribbon.dart';
import '../widgets/nutrition_summary_banner.dart';
import '../widgets/persistent_search_bar.dart';
import '../widgets/timeline_hour_slot.dart';
import 'food_search_screen.dart';
import 'plate_serving_sheet.dart';

/// Authentic MacroFactor Food Log Screen (v5+ Experience).
/// Houses the Date Carousel, Nutrition Summary, and Hourly Timeline.
class FoodLogScreen extends ConsumerStatefulWidget {
  const FoodLogScreen({super.key});

  @override
  ConsumerState<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends ConsumerState<FoodLogScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isCollapsed = false;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _onAddForHour(int hour) {
    final entryTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
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

  @override
  Widget build(BuildContext context) {
    final allLogs = ref.watch(dailyFoodLogsProvider);
    final macroTargets = ref.watch(macroTargetProvider);

    // Filter logs for selected date
    final dayLogs =
        allLogs.where((log) => _isSameDay(log.loggedAt, _selectedDate)).toList();

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

    // Define canonical hourly milestones
    const baseHours = [8, 10, 13, 16, 20];
    final loggedHours = dayLogs.map((e) => e.loggedAt.hour).toSet();
    final allHours = {...baseHours, ...loggedHours}.toList()..sort();

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
                    selectedDate: _selectedDate,
                    onDateSelected: (date) {
                      setState(() => _selectedDate = date);
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

                // 3. Nutrition Summary Progress Banner
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

                      return TimelineHourSlot(
                        hour: hour,
                        entries: hourEntries,
                        isCollapsed: _isCollapsed,
                        onAddTap: () => _onAddForHour(hour),
                        onEntryTap: _onEntryTap,
                        onEntryDelete: (entry) {
                          ref
                              .read(dailyFoodLogsProvider.notifier)
                              .removeEntry(entry.id);
                        },
                      );
                    },
                    childCount: allHours.length,
                  ),
                ),

                // Bottom padding to avoid persistent search bar overlap
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
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
