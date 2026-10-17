import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/food_models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_tactile_card.dart';
import '../widgets/food_svg_icon.dart';
import 'plate_serving_sheet.dart';

enum FoodFilterType {
  all('All'),
  southIndian('South Indian'),
  northIndian('North Indian'),
  highProtein('High Protein'),
  vegetarian('Vegetarian');

  const FoodFilterType(this.displayName);
  final String displayName;
}

/// Instant FTS5 Food Search screen for Indian & Global foods.
/// Features cuisine and macro filter pills, and opens the authentic PlateServingSheet.
class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({
    super.key,
    this.mealType = MealType.lunch,
    this.initialLoggedAt,
  });

  final MealType mealType;
  final DateTime? initialLoggedAt;

  static MaterialPageRoute<void> route({
    MealType mealType = MealType.lunch,
    DateTime? initialLoggedAt,
  }) {
    return MaterialPageRoute(
      builder: (_) => FoodSearchScreen(
        mealType: mealType,
        initialLoggedAt: initialLoggedAt,
      ),
    );
  }

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<FoodItem> _searchResults = [];
  bool _isLoading = false;
  FoodFilterType _selectedFilter = FoodFilterType.all;

  @override
  void initState() {
    super.initState();
    _performSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _performSearch(text);
    });
  }

  void _performSearch(String query) {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    var results = db.searchFoods(query, limit: 60);

    // Apply active filter
    if (_selectedFilter == FoodFilterType.southIndian) {
      results = results
          .where((f) =>
              f.region.toLowerCase().contains('south') ||
              f.cuisine.toLowerCase().contains('south'))
          .toList();
    } else if (_selectedFilter == FoodFilterType.northIndian) {
      results = results
          .where((f) =>
              f.region.toLowerCase().contains('north') ||
              f.cuisine.toLowerCase().contains('north'))
          .toList();
    } else if (_selectedFilter == FoodFilterType.highProtein) {
      results = results.where((f) => f.proteinPer100g >= 12.0).toList();
    } else if (_selectedFilter == FoodFilterType.vegetarian) {
      results = results
          .where((f) =>
              !f.category.toLowerCase().contains('meat') &&
              !f.category.toLowerCase().contains('poultry') &&
              !f.category.toLowerCase().contains('fish'))
          .toList();
    }

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  void _openPlateSheet(FoodItem food) {
    final db = ref.read(databaseProvider);
    final portionUnits = db.getPortionUnits(food.id);
    final macroTargets = ref.read(macroTargetProvider);

    PlateServingSheet.show(
      context: context,
      food: food,
      portionUnits: portionUnits,
      macroTargets: macroTargets,
      initialLoggedAt: widget.initialLoggedAt ?? DateTime.now(),
      onLogConfirmed: ({
        required PortionUnit unit,
        required double quantity,
        required OilModifier oilModifier,
        required DateTime loggedAt,
      }) {
        ref.read(dailyFoodLogsProvider.notifier).addEntry(
              food: food,
              portionUnit: unit,
              quantity: quantity,
              mealType: widget.mealType,
              oilModifier: oilModifier,
              loggedAt: loggedAt,
            );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged ${food.name} to Plate'),
            backgroundColor: AppTheme.cardElevated,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Search Food',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search Input Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search 2,500+ Indian & Global foods...',
                    hintStyle: const TextStyle(
                      fontFamily: 'DMSans',
                      color: AppTheme.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.activeBlue,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.cardSurface,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppTheme.activeBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),

              const SizedBox(height: 10),

              // Filter Pills Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: FoodFilterType.values.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppleBouncy(
                        scaleDown: 0.94,
                        onTap: () {
                          setState(() => _selectedFilter = filter);
                          _performSearch(_searchController.text);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.activeBlue.withValues(alpha: 0.16)
                                : AppTheme.cardSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.activeBlue
                                  : AppTheme.cardBorder,
                              width: isSelected ? 1.2 : 0.8,
                            ),
                          ),
                          child: Text(
                            filter.displayName,
                            style: TextStyle(
                              fontFamily: 'MacroSans',
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.activeBlue
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.activeBlue),
            )
          : _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        size: 54,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No foods found for "${_searchController.text}"',
                        style: const TextStyle(
                          fontFamily: 'MacroSans',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final food = _searchResults[index];
                    return AppleBouncy(
                      scaleDown: 0.98,
                      onTap: () => _openPlateSheet(food),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.cardSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.cardBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            FoodSvgIcon(
                              iconName: food.iconName,
                              size: 34,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    food.name,
                                    style: const TextStyle(
                                      fontFamily: 'MacroSans',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      AppleBadge(
                                        label:
                                            '${food.caloriesPer100g.round()} kcal',
                                        color: AppTheme.calories,
                                      ),
                                      AppleBadge(
                                        label:
                                            '${food.proteinPer100g.toStringAsFixed(1)}P',
                                        color: AppTheme.protein,
                                      ),
                                      AppleBadge(
                                        label:
                                            '${food.fatPer100g.toStringAsFixed(1)}F',
                                        color: AppTheme.fat,
                                      ),
                                      AppleBadge(
                                        label:
                                            '${food.carbsPer100g.toStringAsFixed(1)}C',
                                        color: AppTheme.carbs,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: AppTheme.textMuted,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
