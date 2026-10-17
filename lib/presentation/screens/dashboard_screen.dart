import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:macro_factor_app/domain/models/food_models.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';
import 'package:macro_factor_app/presentation/screens/food_search_screen.dart';
import 'package:macro_factor_app/presentation/screens/weight_log_modal.dart';
import 'package:macro_factor_app/presentation/theme/app_theme.dart';
import 'package:macro_factor_app/presentation/widgets/expenditure_card.dart';
import 'package:macro_factor_app/presentation/widgets/macro_gauge_ring.dart';
import 'package:macro_factor_app/presentation/widgets/meal_section.dart';
import 'package:macro_factor_app/presentation/widgets/weight_trend_card.dart';

/// MacroFactor core Dashboard screen with adherence-neutral gauges,
/// dual Bayesian algorithm insight cards, date switcher, and food logs timeline.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({
    super.key,
    this.onNavigateToStrategy,
  });

  final VoidCallback? onNavigateToStrategy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDateStr = ref.watch(selectedDateProvider);
    final selectedDate = DateTime.tryParse(selectedDateStr) ?? DateTime.now();

    final dailyNutrition = ref.watch(dailyNutritionSummaryProvider);
    final macroTarget = ref.watch(dailyMacroTargetProvider);
    final expenditureState = ref.watch(expenditureStateProvider);
    final latestTrendPoint = ref.watch(latestTrendWeightProvider);
    final foodLogs = ref.watch(dailyFoodLogsProvider);

    final breakfastEntries =
        foodLogs.where((e) => e.mealType == MealType.breakfast).toList();
    final lunchEntries =
        foodLogs.where((e) => e.mealType == MealType.lunch).toList();
    final dinnerEntries =
        foodLogs.where((e) => e.mealType == MealType.dinner).toList();
    final snackEntries =
        foodLogs.where((e) => e.mealType == MealType.snacks).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.calories.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.calories.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: const Text(
                'MF',
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.calories,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'MacroFactor',
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // Scale Weight Quick Log Action
          IconButton(
            tooltip: 'Log Scale Weight',
            icon: const Icon(
              Icons.monitor_weight_outlined,
              color: AppTheme.trendWeight,
              size: 22,
            ),
            onPressed: () => WeightLogModal.show(context),
          ),
          // Strategy / Coaching Quick Action
          if (onNavigateToStrategy != null)
            IconButton(
              tooltip: 'Strategy & Coaching',
              icon: const Icon(
                Icons.tune_outlined,
                color: AppTheme.textSecondary,
                size: 22,
              ),
              onPressed: onNavigateToStrategy,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Switcher Bar
            _buildDateSwitcher(context, ref, selectedDate),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Macro Gauge Ring (Calories + P/F/C Progress)
                  MacroGaugeRing(
                    consumed: dailyNutrition,
                    targets: macroTarget,
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Bayesian Energy Expenditure Card
                  DynamicExpenditureCard(
                    expenditureState: expenditureState,
                  ),
                  const SizedBox(height: 14),

                  // Weight Trend V2 Card
                  WeightTrendCard(
                    latestTrendPoint: latestTrendPoint,
                    onLogWeightTap: () => WeightLogModal.show(context),
                  ),
                  const SizedBox(height: 20),

                  // Food Log Timeline Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'FOOD LOG TIMELINE',
                        style: TextStyle(
                          fontFamily: 'MacroSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        '${foodLogs.length} items logged',
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Breakfast Section
                  MealSection(
                    mealType: MealType.breakfast,
                    entries: breakfastEntries,
                    onAddTap: () => Navigator.push(
                      context,
                      FoodSearchScreen.route(MealType.breakfast),
                    ),
                    onDeleteEntry: (id) =>
                        ref.read(dailyFoodLogsProvider.notifier).deleteFood(id),
                  ),
                  const SizedBox(height: 12),

                  // Lunch Section
                  MealSection(
                    mealType: MealType.lunch,
                    entries: lunchEntries,
                    onAddTap: () => Navigator.push(
                      context,
                      FoodSearchScreen.route(MealType.lunch),
                    ),
                    onDeleteEntry: (id) =>
                        ref.read(dailyFoodLogsProvider.notifier).deleteFood(id),
                  ),
                  const SizedBox(height: 12),

                  // Dinner Section
                  MealSection(
                    mealType: MealType.dinner,
                    entries: dinnerEntries,
                    onAddTap: () => Navigator.push(
                      context,
                      FoodSearchScreen.route(MealType.dinner),
                    ),
                    onDeleteEntry: (id) =>
                        ref.read(dailyFoodLogsProvider.notifier).deleteFood(id),
                  ),
                  const SizedBox(height: 12),

                  // Snacks Section
                  MealSection(
                    mealType: MealType.snacks,
                    entries: snackEntries,
                    onAddTap: () => Navigator.push(
                      context,
                      FoodSearchScreen.route(MealType.snacks),
                    ),
                    onDeleteEntry: (id) =>
                        ref.read(dailyFoodLogsProvider.notifier).deleteFood(id),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSwitcher(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    String dateTitle;
    final diffDays = targetDay.difference(today).inDays;
    if (diffDays == 0) {
      dateTitle = 'Today, ${DateFormat('MMM d').format(selectedDate)}';
    } else if (diffDays == -1) {
      dateTitle = 'Yesterday, ${DateFormat('MMM d').format(selectedDate)}';
    } else if (diffDays == 1) {
      dateTitle = 'Tomorrow, ${DateFormat('MMM d').format(selectedDate)}';
    } else {
      dateTitle = DateFormat('EEEE, MMM d').format(selectedDate);
    }

    return Container(
      color: AppTheme.cardSurface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppTheme.textSecondary),
            tooltip: 'Previous Day',
            onPressed: () {
              final prev = selectedDate.subtract(const Duration(days: 1));
              ref.read(selectedDateProvider.notifier).state =
                  DateFormat('yyyy-MM-dd').format(prev);
            },
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppTheme.calories,
                        onPrimary: AppTheme.background,
                        surface: AppTheme.cardSurface,
                        onSurface: AppTheme.textPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                ref.read(selectedDateProvider.notifier).state =
                    DateFormat('yyyy-MM-dd').format(picked);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppTheme.calories,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateTitle,
                    style: const TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            tooltip: 'Next Day',
            onPressed: () {
              final next = selectedDate.add(const Duration(days: 1));
              ref.read(selectedDateProvider.notifier).state =
                  DateFormat('yyyy-MM-dd').format(next);
            },
          ),
        ],
      ),
    );
  }
}
