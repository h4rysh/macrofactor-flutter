import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/food_models.dart';
import '../../domain/models/oil_modifier_display.dart';
import '../providers/app_providers.dart';
import '../providers/plate_staging_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_tactile_card.dart';
import '../widgets/food/barcode_scanner_sheet.dart';
import '../widgets/food/quick_add_macros_sheet.dart';
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
  String? _searchError;
  FoodFilterType _selectedFilter = FoodFilterType.all;

  DateTime get _resolvedLoggedAt =>
      widget.initialLoggedAt ?? ref.read(clockProvider)();

  void _quickAddFromSearch(FoodItem food) {
    AppHaptics.mediumImpact();
    final db = ref.read(databaseProvider);
    final portionUnits = db.getPortionUnits(food.id);
    final defaultUnit = OilModifierDisplay.resolveDefaultUnit(
      portionUnits,
      db.getSetting('default_portion_unit', 'Grams (g)'),
      food.defaultPortionUnit,
    );
    final defaultOil = OilModifierDisplay.fromPreferenceSetting(
      db.getSetting('default_oil_modifier', 'none'),
    );

    ref.read(plateStagingProvider.notifier).addItem(
          food,
          unit: defaultUnit,
          quantity: 1.0,
          oilModifier: defaultOil,
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
    final loggedAt = _resolvedLoggedAt;
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
    final loggedAt = _resolvedLoggedAt;
    QuickAddMacrosSheet.show(
      context,
      date: loggedAt,
      mealType: widget.mealType,
      loggedAt: loggedAt,
    );
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
    setState(() {
      _isLoading = true;
      _searchError = null;
    });
    try {
      final db = ref.read(databaseProvider);
      final filterKey = _selectedFilter.name;
      var results = await db.foodDao.searchFoodsFilteredAsync(
        query,
        filterKey: filterKey,
        limit: 60,
      );
      if (results.isEmpty && query.trim().isNotEmpty) {
        final alias = IndianFoodAliases.resolveAlias(query);
        if (alias != null &&
            alias.toLowerCase() != query.trim().toLowerCase()) {
          results = await db.foodDao.searchFoodsFilteredAsync(
            alias,
            filterKey: filterKey,
            limit: 60,
          );
        }
      }
      if (!mounted || searchId != _searchSequence) return;

      final rankedResults = _rankSearchResults(results, query);
      setState(() {
        _searchResults = rankedResults;
        _isLoading = false;
      });
      SemanticsService.sendAnnouncement(
        View.of(context),
        '${results.length} food items found for "$query"',
        TextDirection.ltr,
      );
    } catch (_) {
      if (!mounted || searchId != _searchSequence) return;
      setState(() {
        _isLoading = false;
        _searchError = 'Unable to search local food catalog right now.';
      });
    }
  }

  List<FoodItem> _rankSearchResults(List<FoodItem> items, String rawQuery) {
    final q = rawQuery.trim().toLowerCase();
    if (q.isEmpty || items.length <= 1) return items;

    final ranked = List<FoodItem>.from(items);
    ranked
        .sort((a, b) => _canonicalScore(b, q).compareTo(_canonicalScore(a, q)));
    return ranked;
  }

  int _canonicalScore(FoodItem item, String q) {
    final name = item.name.toLowerCase().trim();
    int score = 0;
    if (name == q) {
      score += 1000;
    } else if (name.startsWith('$q ') || name.startsWith('$q/')) {
      score += 500;
    } else if (name.startsWith(q)) {
      score += 350;
    } else if (name.contains(q)) {
      score += 150;
    }

    // Penalize size/restaurant qualifiers so the plain canonical staple ranks #1
    const variantKeywords = [
      'regular serving',
      'large',
      'small',
      'mini',
      'extra',
      'restaurant',
      'combo',
      'stuffed',
      'cheese',
      'butter',
      'ghee',
      'dum',
    ];
    for (final kw in variantKeywords) {
      if (name.contains(kw) && !q.contains(kw)) {
        score -= 120;
      }
    }

    // Shorter, cleaner canonical names win ties
    score -= name.length;
    return score;
  }

  void _openPlateSheet(FoodItem food) {
    final db = ref.read(databaseProvider);
    final profile = ref.read(userProfileProvider);
    final portionUnits = db.getPortionUnits(food.id);
    final macroTargets = ref.read(macroTargetProvider);
    final summary = ref.read(dailyNutritionSummaryProvider);
    final defaultOil = OilModifierDisplay.fromPreferenceSetting(
      db.getSetting('default_oil_modifier', 'none'),
    );
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    PlateServingSheet.show(
      context: context,
      food: food,
      portionUnits: portionUnits,
      macroTargets: macroTargets,
      initialLoggedAt: _resolvedLoggedAt,
      initialMealType: widget.mealType,
      initialOilModifier: defaultOil,
      defaultPortionPreference:
          db.getSetting('default_portion_unit', 'Grams (g)'),
      isVegan: OilModifierDisplay.isVegan(profile.dietType),
      remainingCaloriesToday: macroTargets.targetCalories - summary.calories,
      onDetailedConfirm: ({
        required FoodItem food,
        required PortionUnit unit,
        required double quantity,
        required OilModifier oilModifier,
        required MealType mealType,
        required DateTime loggedAt,
      }) {
        ref.read(dailyFoodLogsProvider.notifier).addEntry(
              food: food,
              portionUnit: unit,
              quantity: quantity,
              mealType: mealType,
              oilModifier: oilModifier,
              loggedAt: loggedAt,
            );

        messenger.showSnackBar(
          SnackBar(
            content: Text('Logged ${food.name} to Plate'),
            backgroundColor: AppTheme.cardElevated,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        nav.pop();
      },
      onLogConfirmed: ({
        required PortionUnit unit,
        required double quantity,
        required OilModifier oilModifier,
        required DateTime loggedAt,
      }) {},
    );
  }

  void _quickLogFood(FoodItem food) {
    AppHaptics.mediumImpact();
    final db = ref.read(databaseProvider);
    final portionUnits = db.getPortionUnits(food.id);
    final defaultUnit = OilModifierDisplay.resolveDefaultUnit(
      portionUnits,
      db.getSetting('default_portion_unit', 'Grams (g)'),
      food.defaultPortionUnit,
    );
    final defaultOil = OilModifierDisplay.fromPreferenceSetting(
      db.getSetting('default_oil_modifier', 'none'),
    );

    ref.read(dailyFoodLogsProvider.notifier).addEntry(
          food: food,
          portionUnit: defaultUnit,
          quantity: 1.0,
          mealType: widget.mealType,
          oilModifier: defaultOil,
          loggedAt: _resolvedLoggedAt,
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
                            constraints: const BoxConstraints(minHeight: 44),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
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
                              Semantics(
                                button: true,
                                label: 'Quick log ${food.name}',
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _quickLogFood(food),
                                  child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color:
                                              AppTheme.activeBlue.withAlpha(35),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add_rounded,
                                          size: 16,
                                          color: AppTheme.activeBlue,
                                        ),
                                      ),
                                    ),
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
              if (_searchController.text.isEmpty &&
                  _selectedFilter == FoodFilterType.all &&
                  _searchResults.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                  child: IndianStapleChips(
                    onStapleSelected: (staple) {
                      _searchController.text = staple;
                      _performSearch(staple);
                    },
                  ),
                ),
              ],
              Expanded(
                child: _isLoading
                    ? const FoodSearchSkeletonList()
                    : _searchError != null
                        ? SiqueEmptyState(
                            icon: Icons.error_outline_rounded,
                            title: 'Search unavailable',
                            message: _searchError!,
                            actionLabel: 'Retry',
                            onAction: () =>
                                _performSearch(_searchController.text),
                          )
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
                                  final hasQuery =
                                      _searchController.text.trim().isNotEmpty;
                                  if (hasQuery && index == 0) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _BestMatchFoodCard(
                                          food: food,
                                          isStaged:
                                              stagedFoodIds.contains(food.id),
                                          onTap: () => _openPlateSheet(food),
                                          onQuickStage: () =>
                                              _quickAddFromSearch(food),
                                        ),
                                        if (_searchResults.length > 1) ...[
                                          const SizedBox(height: 16),
                                          const Text(
                                            'OTHER VARIATIONS',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.textSecondary,
                                              letterSpacing: 0.7,
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  }
                                  return SearchFoodResultTile(
                                    food: food,
                                    searchQuery: _searchController.text,
                                    index: index,
                                    totalCount: _searchResults.length,
                                    isStaged: stagedFoodIds.contains(food.id),
                                    onTap: () => _openPlateSheet(food),
                                    onQuickStage: () =>
                                        _quickAddFromSearch(food),
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

class _BestMatchFoodCard extends StatelessWidget {
  const _BestMatchFoodCard({
    required this.food,
    required this.isStaged,
    required this.onTap,
    required this.onQuickStage,
  });

  final FoodItem food;
  final bool isStaged;
  final VoidCallback onTap;
  final VoidCallback onQuickStage;

  @override
  Widget build(BuildContext context) {
    final nutrition = food.calculateNutrition(
      quantity: 1.0,
      unit: food.defaultPortionUnit,
    );

    return AppleBouncy(
      scaleDown: 0.98,
      onTap: onTap,
      child: Container(
        key: const Key('food_search_best_match_card'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.activeBlue.withValues(alpha: 0.16),
              AppTheme.cardSurface,
            ],
          ),
          borderRadius: AppRadii.xlBorderRadius,
          border: Border.all(
            color: AppTheme.activeBlue.withValues(alpha: 0.55),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.cardElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              alignment: Alignment.center,
              child: FoodSvgIcon(iconName: food.iconName, size: 40),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.activeBlue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'BEST MATCH',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          food.defaultPortionUnit.unitName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        '${nutrition.calories.round()} kcal',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.calories,
                        ),
                      ),
                      Text(
                        '${nutrition.protein.toStringAsFixed(1)}P',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.protein,
                        ),
                      ),
                      Text(
                        '${nutrition.fat.toStringAsFixed(1)}F',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.fat,
                        ),
                      ),
                      Text(
                        '${nutrition.carbs.toStringAsFixed(1)}C',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.carbs,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              button: true,
              label: isStaged
                  ? '${food.name} staged on plate'
                  : 'Stage ${food.name} on plate',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onQuickStage,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color:
                            isStaged ? AppTheme.success : AppTheme.activeBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isStaged ? Icons.check_rounded : Icons.add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
