import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sique/domain/models/food_models.dart';

/// Caloric density tier per gram (Volumetrics satiety index).
enum VolumetricDensity {
  low('Low Density', '< 1.0 kcal/g • High Satiety'),
  medium('Balanced', '1.0–2.4 kcal/g'),
  high('Energy Dense', '> 2.4 kcal/g');

  const VolumetricDensity(this.label, this.description);

  final String label;
  final String description;

  /// Classifies caloric density from per-100g energy content.
  static VolumetricDensity fromCaloriesPer100g(double caloriesPer100g) {
    final kcalPerGram = caloriesPer100g / 100.0;
    if (kcalPerGram < 1.0) return VolumetricDensity.low;
    if (kcalPerGram <= 2.4) return VolumetricDensity.medium;
    return VolumetricDensity.high;
  }
}

/// Ingredient row belonging to a [CustomRecipe].
@immutable
class RecipeIngredient {
  const RecipeIngredient({
    required this.id,
    required this.recipeId,
    required this.foodId,
    required this.foodName,
    required this.servingQuantity,
    required this.unitName,
    required this.gramWeight,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  final String id;
  final String recipeId;
  final int foodId;
  final String foodName;
  final double servingQuantity;
  final String unitName;
  final double gramWeight;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  RecipeIngredient copyWith({
    String? id,
    String? recipeId,
    int? foodId,
    String? foodName,
    double? servingQuantity,
    String? unitName,
    double? gramWeight,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
  }) {
    return RecipeIngredient(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      foodId: foodId ?? this.foodId,
      foodName: foodName ?? this.foodName,
      servingQuantity: servingQuantity ?? this.servingQuantity,
      unitName: unitName ?? this.unitName,
      gramWeight: gramWeight ?? this.gramWeight,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeIngredient &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          recipeId == other.recipeId &&
          foodId == other.foodId &&
          servingQuantity == other.servingQuantity &&
          gramWeight == other.gramWeight;

  @override
  int get hashCode =>
      Object.hash(id, recipeId, foodId, servingQuantity, gramWeight);
}

/// User-authored multi-ingredient recipe supporting single-serving logging
/// and Exploded Timeline decomposition.
@immutable
class CustomRecipe {
  const CustomRecipe({
    required this.id,
    required this.userId,
    required this.name,
    this.servings = 1,
    this.totalWeightG,
    this.cookedWeightG,
    this.prepInstructions,
    this.sourceUrl,
    required this.createdAt,
    required this.updatedAt,
    this.ingredients = const [],
  });

  final String id;
  final String userId;
  final String name;
  final int servings;
  final double? totalWeightG;
  final double? cookedWeightG;
  final String? prepInstructions;
  final String? sourceUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RecipeIngredient> ingredients;

  int get safeServings => math.max(1, servings);

  double get totalCalories =>
      ingredients.fold(0.0, (sum, item) => sum + item.calories);
  double get totalProtein =>
      ingredients.fold(0.0, (sum, item) => sum + item.protein);
  double get totalCarbs =>
      ingredients.fold(0.0, (sum, item) => sum + item.carbs);
  double get totalFat => ingredients.fold(0.0, (sum, item) => sum + item.fat);
  double get totalFiber =>
      ingredients.fold(0.0, (sum, item) => sum + item.fiber);

  double get computedWeightG {
    if (cookedWeightG != null && cookedWeightG! > 0) return cookedWeightG!;
    if (totalWeightG != null && totalWeightG! > 0) return totalWeightG!;
    final summed = ingredients.fold(0.0, (sum, item) => sum + item.gramWeight);
    return summed > 0 ? summed : 100.0 * safeServings;
  }

  double get caloriesPerServing => totalCalories / safeServings;
  double get proteinPerServing => totalProtein / safeServings;
  double get carbsPerServing => totalCarbs / safeServings;
  double get fatPerServing => totalFat / safeServings;
  double get fiberPerServing => totalFiber / safeServings;
  double get gramsPerServing => computedWeightG / safeServings;

  VolumetricDensity get density {
    final per100g =
        computedWeightG > 0 ? (totalCalories / computedWeightG) * 100.0 : 0.0;
    return VolumetricDensity.fromCaloriesPer100g(per100g);
  }

  /// Creates a synthetic [FoodItem] normalized per 100g for logging combined
  /// servings directly to `dailyFoodLogsProvider`.
  FoodItem toVirtualFoodItem() {
    final weight = computedWeightG > 0 ? computedWeightG : 100.0;
    final factor = 100.0 / weight;
    final syntheticId = -(id.hashCode.abs() + 1000);
    return FoodItem(
      id: syntheticId,
      uuid: 'recipe_$id',
      name: name,
      category: 'Custom Recipe',
      region: 'Home',
      caloriesPer100g: totalCalories * factor,
      proteinPer100g: totalProtein * factor,
      carbsPer100g: totalCarbs * factor,
      fatPer100g: totalFat * factor,
      fiberPer100g: totalFiber * factor,
      iconSvg: 'i2.svg',
      source: 'CUSTOM_RECIPE',
      aliases: 'recipe $name',
      portionUnits: [toDefaultServingUnit(foodId: syntheticId)],
      isVerified: true,
    );
  }

  PortionUnit toDefaultServingUnit({int? foodId}) {
    final resolvedFoodId = foodId ?? -(id.hashCode.abs() + 1000);
    final gPerServing = gramsPerServing;
    return PortionUnit(
      id: 0,
      foodId: resolvedFoodId,
      unitName: '1 Serving (${gPerServing.toStringAsFixed(0)}g)',
      gramWeight: gPerServing,
      isDefault: true,
    );
  }

  CustomRecipe copyWith({
    String? id,
    String? userId,
    String? name,
    int? servings,
    double? totalWeightG,
    double? cookedWeightG,
    String? prepInstructions,
    String? sourceUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<RecipeIngredient>? ingredients,
  }) {
    return CustomRecipe(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      servings: servings ?? this.servings,
      totalWeightG: totalWeightG ?? this.totalWeightG,
      cookedWeightG: cookedWeightG ?? this.cookedWeightG,
      prepInstructions: prepInstructions ?? this.prepInstructions,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ingredients: ingredients ?? this.ingredients,
    );
  }
}

/// Packaged product cached locally from bundled staples or OpenFoodFacts.
/// Macro/calorie values are per 100g, matching `foods` and `barcode_cache`.
@immutable
class BarcodeFoodProduct {
  const BarcodeFoodProduct({
    required this.barcode,
    required this.foodName,
    this.brandName,
    required this.servingSizeG,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.fiberPer100g,
    this.microsJson,
    required this.cachedAt,
  });

  final String barcode;
  final String foodName;
  final String? brandName;
  final double servingSizeG;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double fiberPer100g;
  final String? microsJson;
  final DateTime cachedAt;

  String get displayTitle => brandName != null && brandName!.trim().isNotEmpty
      ? '$foodName (${brandName!.trim()})'
      : foodName;

  VolumetricDensity get density =>
      VolumetricDensity.fromCaloriesPer100g(caloriesPer100g);

  FoodItem toFoodItem() {
    final safeServing = servingSizeG > 0 ? servingSizeG : 100.0;
    final syntheticId = -(barcode.hashCode.abs() + 50000);
    return FoodItem(
      id: syntheticId,
      uuid: 'barcode_$barcode',
      name: displayTitle,
      category: 'Packaged & Scanned',
      region: 'Retail',
      caloriesPer100g: caloriesPer100g,
      proteinPer100g: proteinPer100g,
      carbsPer100g: carbsPer100g,
      fatPer100g: fatPer100g,
      fiberPer100g: fiberPer100g,
      iconSvg: 'i11.svg',
      source: 'BARCODE_CACHE',
      aliases: '$barcode ${brandName ?? ''} $foodName',
      portionUnits: [
        PortionUnit(
          id: 0,
          foodId: syntheticId,
          unitName: '1 Serving (${safeServing.toStringAsFixed(0)}g)',
          gramWeight: safeServing,
          isDefault: true,
        ),
        PortionUnit(
          id: 0,
          foodId: syntheticId,
          unitName: 'Grams',
          gramWeight: 1.0,
          isDefault: false,
        ),
      ],
      isVerified: true,
    );
  }
}

/// Canonical micronutrient definition stored in `nutrient_definitions`.
@immutable
class NutrientDefinition {
  const NutrientDefinition({
    required this.id,
    required this.slug,
    required this.displayName,
    required this.category,
    required this.unit,
    this.defaultRdaMale,
    this.defaultRdaFemale,
    this.upperTolerableLimit,
  });

  final int id;
  final String slug;
  final String displayName;
  final String category;
  final String unit;
  final double? defaultRdaMale;
  final double? defaultRdaFemale;
  final double? upperTolerableLimit;

  double? targetForSex({required bool isFemale}) => isFemale
      ? (defaultRdaFemale ?? defaultRdaMale)
      : (defaultRdaMale ?? defaultRdaFemale);
}

/// Aggregated micronutrient consumption for a single day compared to RDA.
@immutable
class DailyMicronutrientIntake {
  const DailyMicronutrientIntake({
    required this.definition,
    required this.consumedAmount,
    this.targetAmount,
  });

  final NutrientDefinition definition;
  final double consumedAmount;
  final double? targetAmount;

  double get percentOfRda {
    if (targetAmount == null || targetAmount! <= 0) return 0.0;
    return (consumedAmount / targetAmount!) * 100.0;
  }

  bool get exceedsUpperLimit {
    final ul = definition.upperTolerableLimit;
    if (ul == null || ul <= 0) return false;
    return consumedAmount > ul;
  }
}
