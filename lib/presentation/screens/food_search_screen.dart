import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/food_models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_tactile_card.dart';
import '../widgets/food_search_highlight.dart';
import '../widgets/food_search_indian_staples.dart';
import '../widgets/food_svg_icon.dart';
import '../widgets/sique_empty_state.dart';
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
  int _searchSequence = 0;
  List<FoodItem> _searchResults = [];
  bool _isLoading = false;
  FoodFilterType _selectedFilter = FoodFilterType.all;
  final List<FoodItem> _plateItems = [];
  final Set<int> _recentlyAddedIds = {};

  int get _totalPlateKcal {
    double total = 0;
    for (final item in _plateItems) {
      total += item
          .calculateNutrition(
            quantity: 1.0,
            unit: item.defaultPortionUnit,
          )
          .calories;
    }
    return total.round();
  }

  void _quickAddFromSearch(FoodItem food) {
    AppHaptics.mediumImpact();
    final db = ref.read(databaseProvider);
    final portionUnits = db.getPortionUnits(food.id);
    final defaultUnit =
        portionUnits.isNotEmpty ? portionUnits.first : food.defaultPortionUnit;

    ref.read(dailyFoodLogsProvider.notifier).addEntry(
          food: food,
          portionUnit: defaultUnit,
          quantity: 1.0,
          mealType: widget.mealType,
          oilModifier: OilModifier.none,
          loggedAt: widget.initialLoggedAt ?? DateTime.now(),
        );

    setState(() {
      _plateItems.add(food);
      _recentlyAddedIds.add(food.id);
    });
    SemanticsService.sendAnnouncement(
      View.of(context),
      'Added ${food.name} to plate. ${_plateItems.length} items on plate, $_totalPlateKcal calories total',
      TextDirection.ltr,
    );
  }

  void _openManualFoodSheet() {
    final query = _searchController.text.trim();
    final customFood = FoodItem(
      id: 999000 + DateTime.now().millisecondsSinceEpoch % 1000,
      uuid: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: query.isNotEmpty ? query : 'Custom Food',
      category: 'Custom',
      region: 'Custom',
      caloriesPer100g: 100.0,
      proteinPer100g: 5.0,
      carbsPer100g: 15.0,
      fatPer100g: 2.0,
      fiberPer100g: 1.0,
      iconSvg: 'food',
      source: 'custom',
      aliases: '',
      portionUnits: const [
        PortionUnit(
          id: 0,
          foodId: 0,
          unitName: 'Serving',
          gramWeight: 100.0,
        ),
      ],
    );
    _openPlateSheet(customFood);
  }

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

  Future<void> _performSearch(String query) async {
    final searchId = ++_searchSequence;
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    var results = await db.searchFoodsAsync(query, limit: 60);
    if (results.isEmpty && query.trim().isNotEmpty) {
      final alias = IndianFoodAliases.resolveAlias(query);
      if (alias != null && alias.toLowerCase() != query.trim().toLowerCase()) {
        results = await db.searchFoodsAsync(alias, limit: 60);
      }
    }
    if (!mounted || searchId != _searchSequence) return;

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

    if (!mounted || searchId != _searchSequence) return;
    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
    SemanticsService.sendAnnouncement(
      View.of(context),
      '${results.length} food items found for "$query"',
      TextDirection.ltr,
    );
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
      initialMealType: widget.mealType,
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

  void _quickLogFood(FoodItem food) {
    AppHaptics.mediumImpact();
    final db = ref.read(databaseProvider);
    final portionUnits = db.getPortionUnits(food.id);
    final defaultUnit =
        portionUnits.isNotEmpty ? portionUnits.first : food.defaultPortionUnit;

    ref.read(dailyFoodLogsProvider.notifier).addEntry(
          food: food,
          portionUnit: defaultUnit,
          quantity: 1.0,
          mealType: widget.mealType,
          oilModifier: OilModifier.none,
          loggedAt: widget.initialLoggedAt ?? DateTime.now(),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged 1x ${food.name} to Plate'),
        backgroundColor: AppTheme.cardElevated,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final recentFoods = ref.watch(recentLoggedFoodsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Search Food',
          style: TextStyle(
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
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  textCapitalization: TextCapitalization.none,
                  scrollPadding: const EdgeInsets.only(bottom: 250),
                  onSubmitted: (query) {
                    _debounceTimer?.cancel();
                    _performSearch(query);
                    FocusScope.of(context).unfocus();
                  },
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search 2,500+ Indian & Global foods...',
                    hintStyle: const TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.activeBlue,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear search',
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () {
                              _debounceTimer?.cancel();
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.cardSurface,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    border: const OutlineInputBorder(
                        borderRadius: AppRadii.lgBorderRadius,
                        borderSide:
                            BorderSide(color: AppTheme.cardBorder)),
                    enabledBorder: const OutlineInputBorder(
                        borderRadius: AppRadii.lgBorderRadius,
                        borderSide:
                            BorderSide(color: AppTheme.cardBorder)),
                    focusedBorder: const OutlineInputBorder(
                        borderRadius: AppRadii.lgBorderRadius,
                        borderSide: BorderSide(
                            color: AppTheme.activeBlue, width: 1.5)),
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
                      child: Semantics(
                        button: true,
                        selected: isSelected,
                        label: 'Filter: ${filter.displayName}',
                        child: AppleBouncy(
                          scaleDown: 0.94,
                          onTap: () {
                            _debounceTimer?.cancel();
                            setState(() {
                              if (isSelected && filter != FoodFilterType.all) {
                                _selectedFilter = FoodFilterType.all;
                              } else {
                                _selectedFilter = filter;
                              }
                            });
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
                              borderRadius: AppRadii.xlBorderRadius,
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
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent & Frequent 1-Tap Row
              if (_searchController.text.isEmpty && recentFoods.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 16,
                        color: AppTheme.activeBlue,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'RECENT & FREQUENT (1-TAP)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 46,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recentFoods.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final food = recentFoods[index];
                      return AppleBouncy(
                        scaleDown: 0.94,
                        onTap: () {
                          AppHaptics.lightImpact();
                          _openPlateSheet(food);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.cardSurface,
                            borderRadius: AppRadii.mdBorderRadius,
                            border: Border.all(
                              color: AppTheme.cardBorder,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FoodSvgIcon(iconName: food.iconName, size: 22),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 160),
                                child: Text(
                                  food.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _quickLogFood(food),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.activeBlue.withAlpha(35),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    size: 14,
                                    color: AppTheme.activeBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppTheme.cardBorder),
              ],
              Expanded(
                child: _isLoading
                    ? const FoodSearchSkeletonList()
                    : _searchResults.isEmpty
                        ? (_searchController.text.isEmpty
                            ? IndianStapleChips(
                                onStapleSelected: (staple) {
                                  _searchController.text = staple;
                                  _performSearch(staple);
                                },
                              )
                            : SiqueEmptyState(
                                icon: Icons.search_off_rounded,
                                title: 'No foods found',
                                message:
                                    'Couldn\'t find "${_searchController.text}". You can quick-add it in 5 seconds.',
                                actionLabel: _searchController.text
                                        .trim()
                                        .isNotEmpty
                                    ? 'Quick add "${_searchController.text.trim()}" manually'
                                    : null,
                                onAction: _searchController.text.trim().isNotEmpty
                                    ? _openManualFoodSheet
                                    : null,
                              ))
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              16,
                              16,
                              _plateItems.isNotEmpty ? 96 : 16,
                            ),
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final food = _searchResults[index];
                              final defaultNutrition = food.calculateNutrition(
                                quantity: 1.0,
                                unit: food.defaultPortionUnit,
                              );
                              final isAdded =
                                  _recentlyAddedIds.contains(food.id);
                              return Semantics(
                                button: true,
                                label:
                                    '${food.name}, ${defaultNutrition.calories.round()} calories, ${defaultNutrition.protein.toStringAsFixed(1)} grams protein, item ${index + 1} of ${_searchResults.length}',
                                child: AppleBouncy(
                                  scaleDown: 0.98,
                                  onTap: () => _openPlateSheet(food),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardSurface,
                                      borderRadius: AppRadii.lgBorderRadius,
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              FoodSearchHighlight(
                                                name: food.name,
                                                query: _searchController.text,
                                              ),
                                              const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                AppleBadge(
                                                  label:
                                                      '${defaultNutrition.calories.round()} kcal',
                                                  color: AppTheme.calories,
                                                ),
                                                AppleBadge(
                                                  label:
                                                      '${defaultNutrition.protein.toStringAsFixed(1)}P',
                                                  color: AppTheme.protein,
                                                ),
                                                AppleBadge(
                                                  label:
                                                      '${defaultNutrition.fat.toStringAsFixed(1)}F',
                                                  color: AppTheme.fat,
                                                ),
                                                AppleBadge(
                                                  label:
                                                      '${defaultNutrition.carbs.toStringAsFixed(1)}C',
                                                  color: AppTheme.carbs,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: AppleBouncy(
                                          scaleDown: 0.88,
                                          onTap: () =>
                                              _quickAddFromSearch(food),
                                          child: Center(
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              child: isAdded
                                                  ? Container(
                                                      key: const ValueKey(
                                                          'check'),
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: AppTheme
                                                            .activeBlue
                                                            .withValues(
                                                                alpha: 0.2),
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: AppTheme
                                                              .activeBlue,
                                                          width: 1.2,
                                                        ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.check_rounded,
                                                        size: 18,
                                                        color:
                                                            AppTheme.activeBlue,
                                                      ),
                                                    )
                                                  : Container(
                                                      key: const ValueKey(
                                                          'plus'),
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: AppTheme
                                                            .cardElevated,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: AppTheme
                                                              .cardBorder,
                                                          width: 0.8,
                                                        ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.add_rounded,
                                                        size: 18,
                                                        color: AppTheme
                                                            .textPrimary,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
        if (_plateItems.isNotEmpty)
          PlateReviewBar(
            itemCount: _plateItems.length,
            totalCalories: _totalPlateKcal,
            onDone: () => Navigator.pop(context),
          ),
      ],
    ),
  );
}
}
