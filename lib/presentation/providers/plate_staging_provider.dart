import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/recipe_models.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/providers/recipes_providers.dart';

/// Single staged food entry held in the multi-add Staging Plate before
/// batch-committing to the timeline or converting into a Custom Recipe.
@immutable
class StagedPlateItem {
  const StagedPlateItem({
    required this.id,
    required this.food,
    required this.portionUnit,
    this.quantity = 1.0,
    this.oilModifier = OilModifier.standard,
  });

  final String id;
  final FoodItem food;
  final PortionUnit portionUnit;
  final double quantity;
  final OilModifier oilModifier;

  NutritionalValues get nutrition => food.calculateNutrition(
        quantity: quantity,
        unit: portionUnit,
        oilModifier: oilModifier,
      );

  StagedPlateItem copyWith({
    String? id,
    FoodItem? food,
    PortionUnit? portionUnit,
    double? quantity,
    OilModifier? oilModifier,
  }) {
    return StagedPlateItem(
      id: id ?? this.id,
      food: food ?? this.food,
      portionUnit: portionUnit ?? this.portionUnit,
      quantity: quantity ?? this.quantity,
      oilModifier: oilModifier ?? this.oilModifier,
    );
  }
}

/// Manages the persistent multi-add Staging Plate across searches, recipes,
/// and barcode scans until the user confirms batch logging.
class PlateStagingNotifier extends StateNotifier<List<StagedPlateItem>> {
  PlateStagingNotifier(this._ref) : super(const []);

  final Ref _ref;
  int _seq = 0;

  double get totalCalories =>
      state.fold(0.0, (sum, item) => sum + item.nutrition.calories);
  double get totalProtein =>
      state.fold(0.0, (sum, item) => sum + item.nutrition.protein);
  double get totalCarbs =>
      state.fold(0.0, (sum, item) => sum + item.nutrition.carbs);
  double get totalFat =>
      state.fold(0.0, (sum, item) => sum + item.nutrition.fat);
  double get totalFiber =>
      state.fold(0.0, (sum, item) => sum + item.nutrition.fiber);

  /// Adds an item to the staging plate, merging identical `(food, unit, oil)` entries.
  void addItem(
    FoodItem food, {
    PortionUnit? unit,
    double quantity = 1.0,
    OilModifier oilModifier = OilModifier.standard,
  }) {
    final resolvedUnit = unit ?? food.defaultPortionUnit;
    final idx = state.indexWhere(
      (i) =>
          i.food.id == food.id &&
          i.portionUnit.unitName == resolvedUnit.unitName &&
          i.oilModifier == oilModifier,
    );
    if (idx >= 0) {
      final existing = state[idx];
      final next = List<StagedPlateItem>.from(state);
      next[idx] = existing.copyWith(quantity: existing.quantity + quantity);
      state = next;
      return;
    }

    _seq++;
    final newItem = StagedPlateItem(
      id: 'stage_${DateTime.now().microsecondsSinceEpoch}_$_seq',
      food: food,
      portionUnit: resolvedUnit,
      quantity: math.max(0.25, quantity),
      oilModifier: oilModifier,
    );
    state = [...state, newItem];
  }

  /// Updates the quantity multiplier for a staged item, removing if <= 0.
  void updateQuantity(String itemId, double quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    state = [
      for (final item in state)
        if (item.id == itemId) item.copyWith(quantity: quantity) else item,
    ];
  }

  /// Updates the cooking oil modifier for a staged item.
  void updateOilModifier(String itemId, OilModifier oilModifier) {
    state = [
      for (final item in state)
        if (item.id == itemId)
          item.copyWith(oilModifier: oilModifier)
        else
          item,
    ];
  }

  /// Removes a single item from the staging plate.
  void removeItem(String itemId) {
    state = state.where((i) => i.id != itemId).toList(growable: false);
  }

  /// Empties the staging plate without logging.
  void clear() {
    state = const [];
  }

  /// Batch-commits all staged items into `dailyFoodLogsProvider` in one step
  /// and clears the staging plate. Returns number of entries logged.
  int commitToLog({
    required MealType mealType,
    required DateTime loggedAt,
  }) {
    if (state.isEmpty) return 0;
    final logsNotifier = _ref.read(dailyFoodLogsProvider.notifier);
    final toCommit = List<StagedPlateItem>.from(state);
    final dateStr = DateFormat('yyyy-MM-dd').format(loggedAt);
    final entries = toCommit.map((item) {
      final n = item.nutrition;
      return FoodLogEntry(
        id: 0,
        date: dateStr,
        mealType: mealType,
        foodId: item.food.id,
        foodName: item.food.name,
        servingQuantity: item.quantity,
        unitName: item.portionUnit.unitName,
        gramWeight: n.totalGrams,
        calories: n.calories,
        protein: n.protein,
        carbs: n.carbs,
        fat: n.fat,
        fiber: n.fiber,
        oilModifier: item.oilModifier,
        loggedAt: loggedAt,
        iconSvg: item.food.category,
      );
    }).toList(growable: false);
    logsNotifier.addEntries(entries);
    clear();
    return entries.length;
  }

  /// Saves all staged items as a reusable [CustomRecipe] with computed totals.
  CustomRecipe? saveAsCustomRecipe({
    required String name,
    int servings = 1,
    String? prepInstructions,
  }) {
    final trimmed = name.trim();
    if (state.isEmpty || trimmed.isEmpty) return null;
    final db = _ref.read(databaseProvider);
    final now = DateTime.now();
    final recipeId = 'rec_${now.millisecondsSinceEpoch}';
    final safeServings = math.max(1, servings);

    final ingredients = <RecipeIngredient>[];
    var totalGrams = 0.0;
    for (var i = 0; i < state.length; i++) {
      final item = state[i];
      final vals = item.nutrition;
      totalGrams += vals.totalGrams;
      ingredients.add(
        RecipeIngredient(
          id: '${recipeId}_ing_$i',
          recipeId: recipeId,
          foodId: item.food.id,
          foodName: item.food.name,
          servingQuantity: item.quantity,
          unitName: item.portionUnit.unitName,
          gramWeight: vals.totalGrams,
          calories: vals.calories,
          protein: vals.protein,
          carbs: vals.carbs,
          fat: vals.fat,
          fiber: vals.fiber,
        ),
      );
    }

    final recipe = CustomRecipe(
      id: recipeId,
      userId: db.currentUserId,
      name: trimmed,
      servings: safeServings,
      totalWeightG: totalGrams,
      prepInstructions: prepInstructions,
      createdAt: now,
      updatedAt: now,
      ingredients: ingredients,
    );

    _ref.read(customRecipesProvider.notifier).saveRecipe(recipe);
    return recipe;
  }
}

final plateStagingProvider =
    StateNotifierProvider<PlateStagingNotifier, List<StagedPlateItem>>((ref) {
  ref.watch(userDataEpochProvider);
  return PlateStagingNotifier(ref);
});
