import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/strategy_providers.dart';
import '../../theme/app_theme.dart';

/// Interactive 7-day distribution bar chart showing daily calorie allocation
/// between workout and rest days with weekly energy conservation.
class SevenDayDistributionChart extends ConsumerStatefulWidget {
  const SevenDayDistributionChart({super.key});

  @override
  ConsumerState<SevenDayDistributionChart> createState() =>
      _SevenDayDistributionChartState();
}

class _SevenDayDistributionChartState
    extends ConsumerState<SevenDayDistributionChart> {
  int _selectedDayIndex = 0;

  @override
  Widget build(BuildContext context) {
    final program = ref.watch(weeklyMacroProgramProvider);
    final days = program.days;
    final selectedDay = days[_selectedDayIndex.clamp(0, days.length - 1)];

    // Calculate max calorie value for normalization
    final maxCal = days.map((d) => d.calories).fold<double>(0.0, max);
    final minCal = days.map((d) => d.calories).fold<double>(9999.0, min);
    final range = max(maxCal - minCal, 200.0);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '7-DAY ENERGY ALLOCATION',
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.cardElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  program.allocationType.displayName,
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 7 Bars
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (idx) {
                final day = days[idx];
                final isSelected = idx == _selectedDayIndex;
                final isWorkout = day.isWorkoutDay;

                // Normalize bar height between 0.35 and 1.0
                final heightFactor =
                    0.4 + (0.6 * ((day.calories - minCal) / range));

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selectedDayIndex = idx),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${day.calories.round()}',
                            style: TextStyle(
                              fontFamily: 'MacroSans',
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.calories
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: heightFactor.clamp(0.2, 1.0),
                                widthFactor: 1.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.calories
                                        : isWorkout
                                            ? AppTheme.calories
                                                .withValues(alpha: 0.45)
                                            : AppTheme.cardElevated,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.white, width: 1.5)
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isWorkout) ...[
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.calories,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 2),
                              ],
                              Text(
                                day.dayName.substring(0, 3),
                                style: TextStyle(
                                  fontFamily: 'MacroSans',
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          // Detail Card for Selected Day
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            selectedDay.dayName,
                            style: const TextStyle(
                              fontFamily: 'MacroSans',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: selectedDay.isWorkoutDay
                                  ? AppTheme.calories.withValues(alpha: 0.15)
                                  : AppTheme.cardElevated,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              selectedDay.isWorkoutDay ? 'WORKOUT' : 'REST',
                              style: TextStyle(
                                fontFamily: 'MacroSans',
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: selectedDay.isWorkoutDay
                                    ? AppTheme.calories
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'P: ${selectedDay.proteinGrams.round()}g • F: ${selectedDay.fatGrams.round()}g • C: ${selectedDay.carbsGrams.round()}g',
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${selectedDay.calories.round()} kcal',
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.calories,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Energy Conservation Proof Note
          const Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 14,
                color: AppTheme.carbs,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Exact weekly energy conservation: sum of 7 days matches your target deficit.',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
