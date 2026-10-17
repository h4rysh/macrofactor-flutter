import 'package:flutter/foundation.dart';

/// Portion unit for a food item (e.g. "Standard Piece (40g)", "Katori (150g)", "Grams").
@immutable
class PortionUnit {
  const PortionUnit({
    required this.id,
    required this.foodId,
    required this.unitName,
    required this.gramWeight,
    this.isDefault = false,
  });

  final int id;
  final int foodId;
  final String unitName;
  final double gramWeight;
  final bool isDefault;

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

/// Food item model matching ICMR-NIN IFCT + MacroFactor master catalog.
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
  }) {
    final totalGrams = quantity * unit.gramWeight;
    final ratio = totalGrams / 100.0;

    double baseCalories = caloriesPer100g * ratio;
    double baseProtein = proteinPer100g * ratio;
    double baseCarbs = carbsPer100g * ratio;
    double baseFat = fatPer100g * ratio;
    double baseFiber = fiberPer100g * ratio;

    // Apply oil modifier
    switch (oilModifier) {
      case OilModifier.lowOil:
        // Homestyle: -15% fat, minimum 0
        final fatDeduction = baseFat * 0.15;
        baseFat = (baseFat - fatDeduction).clamp(0.0, double.infinity);
        baseCalories =
            (baseCalories - (fatDeduction * 9.0)).clamp(0.0, double.infinity);
        break;
      case OilModifier.standard:
        // Standard recipe
        break;
      case OilModifier.extraGheeOrOil:
        // Restaurant / Desi Ghee tadka: +5g fat per serving (+45 kcal)
        final fatAddition = 5.0 * quantity;
        baseFat += fatAddition;
        baseCalories += fatAddition * 9.0;
        break;
    }

    return NutritionalValues(
      calories: baseCalories,
      protein: baseProtein,
      carbs: baseCarbs,
      fat: baseFat,
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
  lowOil('Homestyle (Low Oil)', -30.0),
  standard('Standard Recipe', 0.0),
  extraGheeOrOil('Desi Ghee / Restaurant', 45.0);

  const OilModifier(this.label, this.approxCalorieDelta);
  final String label;
  final double approxCalorieDelta;
}

/// Calculated nutritional values.
@immutable
class NutritionalValues {
  const NutritionalValues({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.totalGrams,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double totalGrams;

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
  snacks('Snacks & Extras', '17:00');

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
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      oilModifier: oilModifier ?? this.oilModifier,
      loggedAt: loggedAt ?? this.loggedAt,
      iconSvg: iconSvg ?? this.iconSvg,
    );
  }

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
