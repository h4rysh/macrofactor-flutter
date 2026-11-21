import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Portion unit for a food item (e.g. "Standard Piece (40g)", "Katori (150g)", "Grams").
@immutable
class PortionUnit {
  const PortionUnit({
    this.id = 0,
    required this.foodId,
    required this.unitName,
    double? gramWeight,
    double? gramsPerUnit,
    this.isDefault = false,
  }) : gramWeight = gramWeight ?? gramsPerUnit ?? 100.0;

  final int id;
  final int foodId;
  final String unitName;
  final double gramWeight;
  final bool isDefault;

  String get name => unitName;
  double get gramsPerUnit => gramWeight;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PortionUnit &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          foodId == other.foodId &&
          unitName == other.unitName &&
          gramWeight == other.gramWeight &&
          isDefault == other.isDefault;

  @override
  int get hashCode => Object.hash(id, foodId, unitName, gramWeight, isDefault);
}

/// Food item model matching ICMR-NIN IFCT + Sique master catalog.
@immutable
class FoodItem {
  const FoodItem({
    required this.id,
    required this.uuid,
    required this.name,
    required this.category,
    required this.region,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.fiberPer100g,
    required this.iconSvg,
    required this.source,
    required this.aliases,
    this.portionUnits = const [],
    this.isVerified = true,
  });

  final int id;
  final String uuid;
  final String name;
  final String category;
  final String region;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double fiberPer100g;
  final String iconSvg;
  final String source;
  final String aliases;
  final List<PortionUnit> portionUnits;
  final bool isVerified;

  String get iconName => iconSvg;
  String get cuisine => region;

  PortionUnit get defaultPortionUnit {
    return portionUnits.firstWhere(
      (unit) => unit.isDefault,
      orElse: () => portionUnits.isNotEmpty
          ? portionUnits.first
          : PortionUnit(
              id: 0,
              foodId: id,
              unitName: 'Grams',
              gramWeight: 1.0,
              isDefault: true,
            ),
    );
  }

  /// Calculates nutritional values for a given quantity of a portion unit and oil modifier.
  NutritionalValues calculateNutrition({
    required double quantity,
    required PortionUnit unit,
    OilModifier oilModifier = OilModifier.standard,
    double? oilGrams,
  }) {
    final clampedQuantity = math.max(0.0, quantity);
    final unitWeight = unit.gramWeight > 0 ? unit.gramWeight : 100.0;
    final totalGrams = clampedQuantity * unitWeight;
    final ratio = totalGrams / 100.0;

    final baseCalories = math.max(0.0, caloriesPer100g * ratio);
    final baseProtein = math.max(0.0, proteinPer100g * ratio);
    final baseCarbs = math.max(0.0, carbsPer100g * ratio);
    final baseFat = math.max(0.0, fatPer100g * ratio);
    final baseFiber = math.max(0.0, fiberPer100g * ratio);

    // Apply oil modifier or explicit oil grams scaled proportionally by quantity and clamped at 0
    final double addedFat;
    final double addedCalories;
    if (oilGrams != null) {
      final clampedOil = math.max(0.0, oilGrams);
      addedFat = clampedOil * clampedQuantity;
      addedCalories = addedFat * 9.0;
    } else {
      addedFat = oilModifier.additionalFatGrams * clampedQuantity;
      addedCalories = oilModifier.additionalCalories * clampedQuantity;
    }

    final adjustedCalories = math.max(0.0, baseCalories + addedCalories);
    final adjustedFat = math.max(0.0, baseFat + addedFat);

    return NutritionalValues(
      calories: adjustedCalories,
      protein: baseProtein,
      carbs: baseCarbs,
      fat: adjustedFat,
      fiber: baseFiber,
      totalGrams: totalGrams,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          uuid == other.uuid;

  @override
  int get hashCode => id.hashCode ^ uuid.hashCode;
}

/// Cooking oil modification level for authentic Indian meals.
enum OilModifier {
  lowOil('Low Oil (-30 kcal)', -30.0, -3.3),
  standard('Standard Recipe (0 kcal)', 0.0, 0.0),
  halfTsp('+½ tsp Oil (+22.5 kcal)', 22.5, 2.5),
  oneTsp('+1 tsp Oil (+45 kcal)', 45.0, 5.0),
  oneTbsp('+1 tbsp Oil (+120 kcal)', 120.0, 13.5),
  twoTbsp('+2 tbsp Oil (+240 kcal)', 240.0, 27.0);

  const OilModifier(this.label, this.approxCalorieDelta, this.approxFatGrams);
  final String label;
  final double approxCalorieDelta;
  final double approxFatGrams;

  static const OilModifier none = OilModifier.standard;
  static const OilModifier light = OilModifier.oneTsp;
  static const OilModifier home = OilModifier.oneTbsp;
  static const OilModifier rich = OilModifier.twoTbsp;
  static const OilModifier extraGheeOrOil = OilModifier.oneTsp;

  String get displayName => label;
  double get additionalCalories => approxCalorieDelta;
  double get additionalFatGrams => approxFatGrams;
}

/// Calculated nutritional values.
@immutable
class NutritionalValues {
  const NutritionalValues({
    double calories = 0.0,
    double protein = 0.0,
    double carbs = 0.0,
    double fat = 0.0,
    this.fiber = 0.0,
    this.totalGrams = 0.0,
    double? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    double? totalFiber,
  })  : calories = totalCalories ?? calories,
        protein = totalProtein ?? protein,
        carbs = totalCarbs ?? carbs,
        fat = totalFat ?? fat;

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double totalGrams;

  const NutritionalValues.zero()
      : calories = 0,
        protein = 0,
        carbs = 0,
        fat = 0,
        fiber = 0,
        totalGrams = 0;

  double get totalCalories => math.max(0.0, calories);
  double get totalProtein => math.max(0.0, protein);
  double get totalCarbs => math.max(0.0, carbs);
  double get totalFat => math.max(0.0, fat);
  double get totalFiber => math.max(0.0, fiber);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionalValues &&
          runtimeType == other.runtimeType &&
          calories == other.calories &&
          protein == other.protein &&
          carbs == other.carbs &&
          fat == other.fat &&
          fiber == other.fiber &&
          totalGrams == other.totalGrams;

  @override
  int get hashCode =>
      Object.hash(calories, protein, carbs, fat, fiber, totalGrams);
}

/// Meal category in the daily food timeline.
enum MealType {
  breakfast('Breakfast', '08:00'),
  lunch('Lunch', '13:00'),
  dinner('Dinner', '20:00'),
  snacks('Snacks & Chai', '17:00');

  const MealType(this.displayName, this.defaultTime);
  final String displayName;
  final String defaultTime;
}

/// Logged entry for an individual meal item.
@immutable
class FoodLogEntry {
  const FoodLogEntry({
    this.id,
    required this.date,
    required this.mealType,
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
    required this.oilModifier,
    required this.loggedAt,
    this.iconSvg = 'i10.svg',
  });

  final int? id;
  final String date; // YYYY-MM-DD
  final MealType mealType;
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
  final OilModifier oilModifier;
  final DateTime loggedAt;
  final String iconSvg;

  FoodLogEntry copyWith({
    int? id,
    String? date,
    MealType? mealType,
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
    OilModifier? oilModifier,
    DateTime? loggedAt,
    String? iconSvg,
  }) {
    return FoodLogEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      foodId: foodId ?? this.foodId,
      foodName: foodName ?? this.foodName,
      servingQuantity: servingQuantity ?? this.servingQuantity,
      unitName: unitName ?? this.unitName,
      gramWeight: gramWeight ?? this.gramWeight,
      calories: calories != null ? math.max(0.0, calories) : this.calories,
      protein: protein != null ? math.max(0.0, protein) : this.protein,
      carbs: carbs != null ? math.max(0.0, carbs) : this.carbs,
      fat: fat != null ? math.max(0.0, fat) : this.fat,
      fiber: fiber != null ? math.max(0.0, fiber) : this.fiber,
      oilModifier: oilModifier ?? this.oilModifier,
      loggedAt: loggedAt ?? this.loggedAt,
      iconSvg: iconSvg ?? this.iconSvg,
    );
  }

  double get effectiveCalories => math.max(0.0, calories);
  double get effectiveProtein => math.max(0.0, protein);
  double get effectiveCarbs => math.max(0.0, carbs);
  double get effectiveFat => math.max(0.0, fat);
  double get effectiveFiber => math.max(0.0, fiber);
  double get quantity => servingQuantity;
  double get grams => gramWeight;
  FoodItem get food {
    final effectiveQuantity = math.max(0.0, servingQuantity);
    final oilCals = oilModifier.additionalCalories * effectiveQuantity;
    final oilFat = oilModifier.additionalFatGrams * effectiveQuantity;
    final baseCalories = math.max(0.0, calories - oilCals);
    final baseFat = math.max(0.0, fat - oilFat);
    return FoodItem(
      id: foodId,
      uuid: 'food_$foodId',
      name: foodName,
      category: 'Food',
      region: 'All',
      caloriesPer100g:
          gramWeight > 0 ? (baseCalories / gramWeight) * 100 : baseCalories,
      proteinPer100g: gramWeight > 0 ? (protein / gramWeight) * 100 : protein,
      carbsPer100g: gramWeight > 0 ? (carbs / gramWeight) * 100 : carbs,
      fatPer100g: gramWeight > 0 ? (baseFat / gramWeight) * 100 : baseFat,
      fiberPer100g: gramWeight > 0 ? (fiber / gramWeight) * 100 : fiber,
      iconSvg: iconSvg,
      source: 'Catalog',
      aliases: foodName,
      portionUnits: [portionUnit],
    );
  }

  PortionUnit get portionUnit => PortionUnit(
        id: id ?? 0,
        foodId: foodId,
        unitName: unitName,
        gramWeight: servingQuantity > 0 ? gramWeight / servingQuantity : 100,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodLogEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          foodId == other.foodId &&
          mealType == other.mealType &&
          servingQuantity == other.servingQuantity &&
          unitName == other.unitName &&
          oilModifier == other.oilModifier;

  @override
  int get hashCode => Object.hash(
        id,
        date,
        foodId,
        mealType,
        servingQuantity,
        unitName,
        oilModifier,
      );
}

typedef DailyFoodLogEntry = FoodLogEntry;
typedef DailyNutritionAggregate = NutritionalValues;
