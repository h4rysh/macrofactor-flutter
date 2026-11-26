import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sique/data/services/open_food_facts_service.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/recipe_models.dart';
import 'package:sique/presentation/providers/app_providers.dart';

/// Manages tenant-scoped Custom Recipes in SQLite and supports logging recipes
/// either as a single combined entry or via Exploded Timeline Decomposition.
class CustomRecipesNotifier extends StateNotifier<List<CustomRecipe>> {
  CustomRecipesNotifier(this._ref) : super(_load(_ref));

  final Ref _ref;

  static List<CustomRecipe> _load(Ref ref) {
    final db = ref.read(databaseProvider);
    return db.recipesDao.getAllRecipes(userId: db.currentUserId);
  }

  void refresh() {
    state = _load(_ref);
  }

  void saveRecipe(CustomRecipe recipe) {
    final db = _ref.read(databaseProvider);
    db.recipesDao.upsertRecipe(recipe, userId: db.currentUserId);
    refresh();
  }

  void deleteRecipe(String recipeId) {
    final db = _ref.read(databaseProvider);
    db.recipesDao.deleteRecipe(recipeId, userId: db.currentUserId);
    refresh();
  }

  /// Logs [recipe] to `dailyFoodLogsProvider`.
  /// When [explodeIngredients] is `true`, decomposes the recipe into individual
  /// ingredient entries proportional to `(servings / recipe.safeServings)` so
  /// users can tweak or delete single items post-log (MacroFactor-style Explode).
  int logRecipe({
    required CustomRecipe recipe,
    required double servings,
    required MealType mealType,
    required DateTime loggedAt,
    bool explodeIngredients = false,
  }) {
    final clampedServings = math.max(0.25, servings);
    final logsNotifier = _ref.read(dailyFoodLogsProvider.notifier);

    if (!explodeIngredients || recipe.ingredients.isEmpty) {
      logsNotifier.addEntry(
        food: recipe.toVirtualFoodItem(),
        portionUnit: recipe.toDefaultServingUnit(),
        quantity: clampedServings,
        mealType: mealType,
        oilModifier: OilModifier.standard,
        loggedAt: loggedAt,
      );
      return 1;
    }

    final db = _ref.read(databaseProvider);
    final ratio = clampedServings / recipe.safeServings;
    final dateStr = DateFormat('yyyy-MM-dd').format(loggedAt);
    final batchEntries = <FoodLogEntry>[];

    for (final ing in recipe.ingredients) {
      final safeGrams = ing.gramWeight > 0 ? ing.gramWeight : 100.0;
      final catalogFood = ing.foodId > 0 ? db.getFoodById(ing.foodId) : null;
      final per100Factor = 100.0 / safeGrams;

      final food = catalogFood ??
          FoodItem(
            id: ing.foodId,
            uuid: 'ing_${ing.id}',
            name: ing.foodName,
            category: 'Recipe Ingredient',
            region: 'Home',
            caloriesPer100g: ing.calories * per100Factor,
            proteinPer100g: ing.protein * per100Factor,
            carbsPer100g: ing.carbs * per100Factor,
            fatPer100g: ing.fat * per100Factor,
            fiberPer100g: ing.fiber * per100Factor,
            iconSvg: 'i2.svg',
            source: 'CUSTOM_RECIPE',
            aliases: ing.foodName,
          );

      final qty = ing.servingQuantity > 0 ? ing.servingQuantity : 1.0;
      final unitWeight = safeGrams / qty;
      final scaledUnit = PortionUnit(
        id: 0,
        foodId: food.id,
        unitName: ing.unitName,
        gramWeight: unitWeight,
        isDefault: true,
      );
      final n = food.calculateNutrition(
        quantity: qty * ratio,
        unit: scaledUnit,
        oilModifier: OilModifier.standard,
      );

      batchEntries.add(
        FoodLogEntry(
          id: 0,
          date: dateStr,
          mealType: mealType,
          foodId: food.id,
          foodName: food.name,
          servingQuantity: qty * ratio,
          unitName: scaledUnit.unitName,
          gramWeight: n.totalGrams,
          calories: n.calories,
          protein: n.protein,
          carbs: n.carbs,
          fat: n.fat,
          fiber: n.fiber,
          oilModifier: OilModifier.standard,
          loggedAt: loggedAt,
          iconSvg: food.category,
        ),
      );
    }
    logsNotifier.addEntries(batchEntries);
    return batchEntries.length;
  }
}

final customRecipesProvider =
    StateNotifierProvider<CustomRecipesNotifier, List<CustomRecipe>>((ref) {
  ref.watch(userDataEpochProvider);
  ref.watch(databaseProvider);
  return CustomRecipesNotifier(ref);
});

/// Offline-first barcode lookup service backed by `BarcodeDao` + OpenFoodFacts.
final openFoodFactsServiceProvider = Provider<OpenFoodFactsService>((ref) {
  final db = ref.watch(databaseProvider);
  final client = http.Client();
  ref.onDispose(client.close);
  return OpenFoodFactsService(barcodeDao: db.barcodeDao, client: client);
});

/// Aggregated micronutrient intake vs RDA for the active selected date.
final dailyMicronutrientsProvider =
    Provider<List<DailyMicronutrientIntake>>((ref) {
  ref.watch(dailyFoodLogsProvider);
  ref.watch(foodLogsRevisionProvider);
  final dateStr = ref.watch(selectedDateProvider);
  final profile = ref.watch(userProfileProvider);
  final db = ref.watch(databaseProvider);
  final parsedDate = DateTime.tryParse(dateStr) ?? ref.read(clockProvider)();
  return db.barcodeDao.getDailyMicronutrientIntake(
    parsedDate,
    userId: db.currentUserId,
    isFemale: !profile.isMale,
  );
});
