import 'package:flutter_test/flutter_test.dart';
import 'package:macro_factor_app/domain/models/food_models.dart';

void main() {
  group('Issue 9 Regression: Oil Modifier Scaling & Non-negative Clamping', () {
    const food = FoodItem(
      id: 1,
      uuid: 'roti-test',
      name: 'Whole Wheat Roti',
      category: 'Breads',
      region: 'North India',
      caloriesPer100g: 260.0,
      proteinPer100g: 8.0,
      carbsPer100g: 50.0,
      fatPer100g: 3.0,
      fiberPer100g: 4.0,
      iconSvg: 'bread',
      source: 'test',
      aliases: 'roti, chapati',
      portionUnits: [
        PortionUnit(
          foodId: 1,
          unitName: 'roti',
          gramsPerUnit: 35.0,
          isDefault: true,
        ),
      ],
    );

    test(
        'Small portion with lowOil modifier does NOT produce negative calories or fat',
        () {
      // 0.1 roti = 3.5g total weight
      final values = food.calculateNutrition(
        quantity: 0.1,
        unit: food.portionUnits.first,
        oilModifier: OilModifier.lowOil,
      );

      expect(values.calories, greaterThanOrEqualTo(0.0),
          reason: 'Calories should never drop below 0');
      expect(values.fat, greaterThanOrEqualTo(0.0),
          reason: 'Fat should never drop below 0');
      expect(values.protein, greaterThanOrEqualTo(0.0));
      expect(values.carbs, greaterThanOrEqualTo(0.0));
    });

    test('Multiple servings scale oil modifier proportionally', () {
      // 1 roti with extra ghee
      final singleServing = food.calculateNutrition(
        quantity: 1.0,
        unit: food.portionUnits.first,
        oilModifier: OilModifier.extraGheeOrOil,
      );

      // 4 rotis with extra ghee
      final fourServings = food.calculateNutrition(
        quantity: 4.0,
        unit: food.portionUnits.first,
        oilModifier: OilModifier.extraGheeOrOil,
      );

      // Four rotis should have exactly 4x the calories and fat
      expect(fourServings.calories, closeTo(singleServing.calories * 4.0, 0.1),
          reason: 'Oil modifier adjustment must scale with quantity');
      expect(fourServings.fat, closeTo(singleServing.fat * 4.0, 0.1));
    });

    test('OilModifier tiers provide exact expected calorie and fat values', () {
      expect(OilModifier.standard.additionalCalories, equals(0.0));
      expect(OilModifier.standard.additionalFatGrams, equals(0.0));

      expect(OilModifier.lowOil.additionalCalories, equals(-30.0));
      expect(OilModifier.lowOil.additionalFatGrams, equals(-3.3));

      expect(OilModifier.halfTsp.additionalCalories, equals(22.5));
      expect(OilModifier.halfTsp.additionalFatGrams, equals(2.5));

      expect(OilModifier.oneTsp.additionalCalories, equals(45.0));
      expect(OilModifier.oneTsp.additionalFatGrams, equals(5.0));

      expect(OilModifier.oneTbsp.additionalCalories, equals(120.0));
      expect(OilModifier.oneTbsp.additionalFatGrams, equals(13.5));
    });
  });
}
