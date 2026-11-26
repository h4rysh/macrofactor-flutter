import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/food_models.dart';
import '../providers/app_providers.dart';
import '../providers/plate_staging_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_tactile_card.dart';
import '../widgets/food/ai_describe_meal_sheet.dart';
import '../widgets/food/barcode_scanner_sheet.dart';
import '../widgets/food/recipe_builder_sheet.dart';
import '../widgets/food/search_food_result_tile.dart';
import '../widgets/food/staging_plate_sheet.dart';
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

  void _quickAddFromSearch(FoodItem food) {
    AppHaptics.mediumImpact();
    final db = ref.read(databaseProvider);
    final portionUnits = db.getPortionUnits(food.id);
    final defaultUnit =
        portionUnits.isNotEmpty ? portionUnits.first : food.defaultPortionUnit;

    ref.read(plateStagingProvider.notifier).addItem(
          food,
          unit: defaultUnit,
          quantity: 1.0,
          oilModifier: OilModifier.none,
        );

    final staged = ref.read(plateStagingProvider);
    final totalKcal =
        staged.fold(0.0, (sum, i) => sum + i.nutrition.calories).round();
    SemanticsService.sendAnnouncement(
      View.of(context),
      'Staged ${food.name} on plate. ${staged.length} items staged, $totalKcal calories total',
      TextDirection.ltr,
    );
  }

  void _commitStagedPlate() {
    final loggedAt = widget.initialLoggedAt ?? DateTime.now();
    final count = ref.read(plateStagingProvider.notifier).commitToLog(
          mealType: widget.mealType,
          loggedAt: loggedAt,
        );
    if (!mounted) return;
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Logged $count staged ${count == 1 ? 'item' : 'items'}'),
          backgroundColor: AppTheme.cardElevated,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    Navigator.pop(context);
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
    final stagedItems = ref.watch(plateStagingProvider);
    final stagedFoodIds = stagedItems.map((i) => i.food.id).toSet();
    final stagedKcal =
        stagedItems.fold(0.0, (sum, i) => sum + i.nutrition.calories).round();

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
        actions: [
          IconButton(
            tooltip: 'AI Describe Meal',
            icon: const Icon(Icons.auto_awesome_rounded,
                size: 21, color: AppTheme.calories),
            onPressed: () {
              AiDescribeMealSheet.show(
                context,
                mealType: widget.mealType,
                loggedAt: widget.initialLoggedAt ?? DateTime.now(),
              );
            },
          ),
          IconButton(
            tooltip: 'Custom Recipes',
            icon: const Icon(Icons.menu_book_rounded, size: 22),
            onPressed: () {
              RecipeBuilderSheet.show(
                context,
                mealType: widget.mealType,
                loggedAt: widget.initialLoggedAt ?? DateTime.now(),
                onLogged: (msg) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: AppTheme.cardElevated,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.of(context).pop();
                },
              );
            },
          ),
          IconButton(
            tooltip: 'Scan Barcode',
            icon: const Icon(
              Icons.qr_code_scanner_rounded,
              size: 22,
              color: AppTheme.activeBlue,
            ),
            onPressed: () {
              BarcodeScannerSheet.show(
                context,
                mealType: widget.mealType,
                loggedAt: widget.initialLoggedAt ?? DateTime.now(),
                stageMode: true,
              );
            },
          ),
        ],
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
                        borderSide: BorderSide(color: AppTheme.cardBorder)),
                    enabledBorder: const OutlineInputBorder(
                        borderRadius: AppRadii.lgBorderRadius,
                        borderSide: BorderSide(color: AppTheme.cardBorder)),
                    focusedBorder: const OutlineInputBorder(
                        borderRadius: AppRadii.lgBorderRadius,
                        borderSide:
                            BorderSide(color: AppTheme.activeBlue, width: 1.5)),
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
                                onAction:
                                    _searchController.text.trim().isNotEmpty
                                        ? _openManualFoodSheet
                                        : null,
                              ))
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              16,
                              16,
                              stagedItems.isNotEmpty ? 96 : 16,
                            ),
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final food = _searchResults[index];
                              return SearchFoodResultTile(
                                food: food,
                                searchQuery: _searchController.text,
                                index: index,
                                totalCount: _searchResults.length,
                                isStaged: stagedFoodIds.contains(food.id),
                                onTap: () => _openPlateSheet(food),
                                onQuickStage: () => _quickAddFromSearch(food),
                              );
                            },
                          ),
              ),
            ],
          ),
          if (stagedItems.isNotEmpty)
            PlateReviewBar(
              itemCount: stagedItems.length,
              totalCalories: stagedKcal,
              buttonLabel: 'Log (${stagedItems.length})',
              onExpand: () {
                StagingPlateSheet.show(
                  context,
                  mealType: widget.mealType,
                  loggedAt: widget.initialLoggedAt ?? DateTime.now(),
                  onCommitted: (count) {
                    if (!mounted || count <= 0) return;
                    Navigator.of(context).pop();
                  },
                );
              },
              onDone: _commitStagedPlate,
            ),
        ],
      ),
    );
  }
}
