import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_factor_app/domain/models/food_models.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';
import 'package:macro_factor_app/presentation/theme/app_theme.dart';
import 'package:macro_factor_app/presentation/widgets/food_svg_icon.dart';

/// Modal bottom sheet allowing portion selection, 1-tap oil modifier, and instant food logging.
class FoodDetailModal extends ConsumerStatefulWidget {
  const FoodDetailModal({
    super.key,
    required this.food,
    required this.mealType,
  });

  final FoodItem food;
  final MealType mealType;

  static Future<void> show(
    BuildContext context, {
    required FoodItem food,
    required MealType mealType,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FoodDetailModal(food: food, mealType: mealType),
    );
  }

  @override
  ConsumerState<FoodDetailModal> createState() => _FoodDetailModalState();
}

class _FoodDetailModalState extends ConsumerState<FoodDetailModal> {
  late PortionUnit _selectedUnit;
  double _quantity = 1.0;
  OilModifier _oilModifier = OilModifier.standard;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.food.defaultPortionUnit;
  }

  @override
  Widget build(BuildContext context) {
    final nutrition = widget.food.calculateNutrition(
      quantity: _quantity,
      unit: _selectedUnit,
      oilModifier: _oilModifier,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Food Header
          Row(
            children: [
              FoodSvgIcon(iconSvg: widget.food.iconSvg, size: 50),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.food.name,
                      style: const TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppTheme.cardBorder, width: 1),
                          ),
                          child: Text(
                            widget.food.region,
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.food.category,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppTheme.cardBorder),
          const SizedBox(height: 16),

          // Portion Unit Selector
          const Text(
            'SERVING PORTION',
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PortionUnit>(
                value: _selectedUnit,
                isExpanded: true,
                dropdownColor: AppTheme.surface,
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: AppTheme.textSecondary),
                items: widget.food.portionUnits.map((unit) {
                  return DropdownMenuItem<PortionUnit>(
                    value: unit,
                    child: Text(
                      '${unit.unitName} (${unit.gramWeight.round()}g)',
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newUnit) {
                  if (newUnit != null) {
                    setState(() => _selectedUnit = newUnit);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quantity Stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'NUMBER OF SERVINGS',
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () {
                      if (_quantity > 0.5) {
                        setState(() => _quantity -= 0.5);
                      }
                    },
                    icon: const Icon(Icons.remove, size: 16),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.surface,
                      foregroundColor: AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 48),
                    alignment: Alignment.center,
                    child: Text(
                      _quantity.toStringAsFixed(
                          _quantity.truncateToDouble() == _quantity ? 0 : 1),
                      style: const TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () {
                      setState(() => _quantity += 0.5);
                    },
                    icon: const Icon(Icons.add, size: 16),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.surface,
                      foregroundColor: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1-Tap Oil Modifier
          const Text(
            'COOKING OIL MODIFIER',
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: OilModifier.values.map((mod) {
              final isSelected = _oilModifier == mod;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(
                      mod == OilModifier.lowOil
                          ? 'Homestyle\n(-15% Fat)'
                          : mod == OilModifier.standard
                              ? 'Standard\nRecipe'
                              : 'Desi Ghee\n(+5g Fat)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppTheme.background
                            : AppTheme.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _oilModifier = mod),
                    selectedColor: AppTheme.calories,
                    backgroundColor: AppTheme.surface,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.calories
                            : AppTheme.cardBorder,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Live Nutrition Grid
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cardBorder, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NutrientTile(
                  title: 'CALORIES',
                  value: '${nutrition.calories.round()}',
                  unit: 'kcal',
                  color: AppTheme.calories,
                ),
                _NutrientTile(
                  title: 'PROTEIN',
                  value: nutrition.protein.toStringAsFixed(1),
                  unit: 'g',
                  color: AppTheme.protein,
                ),
                _NutrientTile(
                  title: 'CARBS',
                  value: nutrition.carbs.toStringAsFixed(1),
                  unit: 'g',
                  color: AppTheme.carbs,
                ),
                _NutrientTile(
                  title: 'FAT',
                  value: nutrition.fat.toStringAsFixed(1),
                  unit: 'g',
                  color: AppTheme.fat,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Log Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final date = ref.read(selectedDateProvider);
                final entry = FoodLogEntry(
                  date: date,
                  mealType: widget.mealType,
                  foodId: widget.food.id,
                  foodName: widget.food.name,
                  servingQuantity: _quantity,
                  unitName: _selectedUnit.unitName,
                  gramWeight: nutrition.totalGrams,
                  calories: nutrition.calories,
                  protein: nutrition.protein,
                  carbs: nutrition.carbs,
                  fat: nutrition.fat,
                  fiber: nutrition.fiber,
                  oilModifier: _oilModifier,
                  loggedAt: DateTime.now(),
                  iconSvg: widget.food.iconSvg,
                );

                ref.read(dailyFoodLogsProvider.notifier).addFood(entry);
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Logged ${widget.food.name} to ${widget.mealType.displayName}'),
                    backgroundColor: AppTheme.cardSurface,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.calories,
                foregroundColor: AppTheme.background,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              child:
                  Text('LOG TO ${widget.mealType.displayName.toUpperCase()}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutrientTile extends StatelessWidget {
  const _NutrientTile({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String title;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
