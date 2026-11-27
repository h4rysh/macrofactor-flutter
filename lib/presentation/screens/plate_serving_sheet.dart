import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/food_models.dart';
import '../../domain/models/user_profile.dart';
import '../theme/app_theme.dart';
import '../utils/quantity_parser.dart';
import '../widgets/apple_sheet_grabber.dart';
import '../widgets/apple_tactile_card.dart';
import '../widgets/food/sique_math_keyboard.dart';
import '../widgets/indian_serving_controls.dart';
import '../widgets/plate_metric_dials.dart';
import '../widgets/sique_frosted_chrome.dart';

typedef PlateLogCallback = void Function({
  required PortionUnit unit,
  required double quantity,
  required OilModifier oilModifier,
  required DateTime loggedAt,
});

typedef PlateDetailedLogCallback = void Function({
  required FoodItem food,
  required PortionUnit unit,
  required double quantity,
  required OilModifier oilModifier,
  required MealType mealType,
  required DateTime loggedAt,
});

/// Authentic Sique Plate Serving Selector Bottom Sheet.
/// Implements portion sizing, weight calculations, and macro target delta preview.
class PlateServingSheet extends StatefulWidget {
  const PlateServingSheet({
    super.key,
    required this.food,
    required this.portionUnits,
    required this.macroTargets,
    required this.initialLoggedAt,
    this.initialMealType = MealType.lunch,
    this.initialQuantity = 1.0,
    this.initialUnit,
    this.initialOilModifier,
    this.defaultPortionPreference,
    this.isVegan = false,
    this.remainingCaloriesToday,
    this.onMealChanged,
    this.onDetailedConfirm,
    required this.onLogConfirmed,
  });

  final FoodItem food;
  final List<PortionUnit> portionUnits;
  final MacroTargets macroTargets;
  final DateTime initialLoggedAt;
  final MealType initialMealType;
  final double initialQuantity;
  final PortionUnit? initialUnit;
  final OilModifier? initialOilModifier;
  final String? defaultPortionPreference;
  final bool isVegan;
  final double? remainingCaloriesToday;
  final ValueChanged<MealType>? onMealChanged;
  final PlateDetailedLogCallback? onDetailedConfirm;
  final PlateLogCallback onLogConfirmed;

  static Future<void> show({
    required BuildContext context,
    required FoodItem food,
    required List<PortionUnit> portionUnits,
    required MacroTargets macroTargets,
    DateTime? initialLoggedAt,
    MealType initialMealType = MealType.lunch,
    double initialQuantity = 1.0,
    PortionUnit? initialUnit,
    OilModifier? initialOilModifier,
    String? defaultPortionPreference,
    bool isVegan = false,
    double? remainingCaloriesToday,
    ValueChanged<MealType>? onMealChanged,
    PlateDetailedLogCallback? onDetailedConfirm,
    required PlateLogCallback onLogConfirmed,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PlateServingSheet(
        food: food,
        portionUnits: portionUnits,
        macroTargets: macroTargets,
        initialLoggedAt: initialLoggedAt ?? DateTime.now(),
        initialMealType: initialMealType,
        initialQuantity: initialQuantity,
        initialUnit: initialUnit,
        initialOilModifier: initialOilModifier,
        defaultPortionPreference: defaultPortionPreference,
        isVegan: isVegan,
        remainingCaloriesToday: remainingCaloriesToday,
        onMealChanged: onMealChanged,
        onDetailedConfirm: onDetailedConfirm,
        onLogConfirmed: onLogConfirmed,
      ),
    );
  }

  @override
  State<PlateServingSheet> createState() => _PlateServingSheetState();
}

class _PlateServingSheetState extends State<PlateServingSheet> {
  late PortionUnit _selectedUnit;
  late MealType _selectedMeal;
  double _quantity = 1.0;
  OilModifier _selectedOil = OilModifier.none;
  late DateTime _loggedAt;
  late TextEditingController _quantityController;
  late FocusNode _quantityFocusNode;
  bool _isSubmitting = false;
  bool _isRaw = false;

  bool get _isGrainOrLentil {
    final name = widget.food.name.toLowerCase();
    return name.contains('rice') ||
        name.contains('dal') ||
        name.contains('khichdi') ||
        name.contains('lentil') ||
        name.contains('chana') ||
        name.contains('rajma') ||
        name.contains('beans') ||
        name.contains('oats');
  }

  List<PortionUnit> get _effectiveUnits {
    final list = List<PortionUnit>.from(widget.portionUnits);
    if (list.isEmpty) {
      list.add(widget.food.defaultPortionUnit);
    }
    if (!list.any((u) => u.unitName.toLowerCase().contains('gram'))) {
      list.add(PortionUnit(
        id: 0,
        foodId: widget.food.id,
        unitName: 'Grams',
        gramWeight: 1.0,
      ));
    }
    if (!list.any((u) => u.unitName.toLowerCase().contains('katori'))) {
      list.add(PortionUnit(
        id: 0,
        foodId: widget.food.id,
        unitName: 'Katori',
        gramWeight: 150.0,
      ));
    }
    if (!list.any((u) => u.unitName.toLowerCase().contains('ladle'))) {
      list.add(PortionUnit(
        id: 0,
        foodId: widget.food.id,
        unitName: 'Ladle',
        gramWeight: 60.0,
      ));
    }
    final nameLower = widget.food.name.toLowerCase();
    if (nameLower.contains('roti') ||
        nameLower.contains('chapati') ||
        nameLower.contains('phulka') ||
        nameLower.contains('paratha')) {
      if (!list.any((u) =>
          u.unitName.toLowerCase().contains('roti') ||
          u.unitName.toLowerCase().contains('piece'))) {
        list.add(PortionUnit(
          id: 0,
          foodId: widget.food.id,
          unitName: 'Roti (Piece)',
          gramWeight: 35.0,
        ));
      }
    }
    return list;
  }

  static double? _parseQuantity(String text) => QuantityParser.parse(text);
  String _formatQuantity(double q) => QuantityParser.format(q);

  FoodItem get _confirmedFood {
    if (!(_isGrainOrLentil && _isRaw)) return widget.food;
    return FoodItem(
      id: widget.food.id,
      uuid: widget.food.uuid,
      name: '${widget.food.name} (Raw)',
      category: widget.food.category,
      region: widget.food.region,
      caloriesPer100g: widget.food.caloriesPer100g * 2.5,
      proteinPer100g: widget.food.proteinPer100g * 2.5,
      carbsPer100g: widget.food.carbsPer100g * 2.5,
      fatPer100g: widget.food.fatPer100g * 2.5,
      fiberPer100g: widget.food.fiberPer100g * 2.5,
      iconSvg: widget.food.iconSvg,
      source: widget.food.source,
      aliases: widget.food.aliases,
      portionUnits: widget.food.portionUnits,
    );
  }

  void _onConfirmLog() {
    if (_isSubmitting) return;
    final latestParsed = _parseQuantity(_quantityController.text);
    if (latestParsed != null && latestParsed > 0) {
      _quantity = latestParsed;
    }
    _isSubmitting = true;
    AppHaptics.mediumImpact();
    Navigator.of(context).pop();
    widget.onMealChanged?.call(_selectedMeal);
    if (widget.onDetailedConfirm != null) {
      widget.onDetailedConfirm!(
        food: _confirmedFood,
        unit: _selectedUnit,
        quantity: _quantity,
        oilModifier: _selectedOil,
        mealType: _selectedMeal,
        loggedAt: _loggedAt,
      );
      return;
    }
    widget.onLogConfirmed(
      unit: _selectedUnit,
      quantity: _quantity,
      oilModifier: _selectedOil,
      loggedAt: _loggedAt,
    );
  }

  PortionUnit _resolveInitialUnit() {
    final units = _effectiveUnits;
    if (widget.initialUnit != null) {
      final match = units.where((u) =>
          u.unitName.toLowerCase() ==
          widget.initialUnit!.unitName.toLowerCase());
      if (match.isNotEmpty) return match.first;
      return widget.initialUnit!;
    }
    final pref = widget.defaultPortionPreference?.toLowerCase() ?? '';
    if (pref.contains('katori')) {
      return units.firstWhere(
        (u) => u.unitName.toLowerCase().contains('katori'),
        orElse: () => units.first,
      );
    }
    if (pref.contains('gram')) {
      return units.firstWhere(
        (u) => u.unitName.toLowerCase().contains('gram'),
        orElse: () => units.first,
      );
    }
    if (pref.contains('roti') || pref.contains('piece')) {
      return units.firstWhere(
        (u) {
          final n = u.unitName.toLowerCase();
          return n.contains('roti') ||
              n.contains('piece') ||
              n.contains('idli');
        },
        orElse: () => units.first,
      );
    }
    return units.first;
  }

  @override
  void initState() {
    super.initState();
    _selectedUnit = _resolveInitialUnit();
    _selectedMeal = widget.initialMealType;
    _quantity = widget.initialQuantity > 0 ? widget.initialQuantity : 1.0;
    _selectedOil = widget.initialOilModifier ?? OilModifier.standard;
    _loggedAt = widget.initialLoggedAt;
    _quantityController = TextEditingController(
      text: _formatQuantity(_quantity),
    );
    _quantityFocusNode = FocusNode();
    _quantityFocusNode.addListener(() {
      if (_quantityFocusNode.hasFocus) {
        _quantityController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _quantityController.text.length,
        );
      } else {
        final parsed = _parseQuantity(_quantityController.text);
        if (parsed == null || parsed <= 0) {
          _quantityController.text = _formatQuantity(_quantity);
        } else {
          _quantity = parsed;
          _quantityController.text = _formatQuantity(_quantity);
        }
      }
    });
  }

  @override
  void dispose() {
    _quantityFocusNode.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _setQuantity(double newQ) {
    if (newQ > 0) {
      AppHaptics.lightImpact();
      setState(() {
        _quantity = (newQ * 100).roundToDouble() / 100.0;
        _quantityController.text = _formatQuantity(_quantity);
      });
    }
  }

  NutritionalValues get _nutrition {
    final base = widget.food.calculateNutrition(
      quantity: _quantity,
      unit: _selectedUnit,
      oilModifier: _selectedOil,
    );
    if (_isGrainOrLentil && _isRaw) {
      return NutritionalValues(
        calories: base.calories * 2.5,
        protein: base.protein * 2.5,
        carbs: base.carbs * 2.5,
        fat: base.fat * 2.5,
        fiber: base.fiber * 2.5,
        totalGrams: base.totalGrams,
      );
    }
    return base;
  }

  double get _effectiveCalories => math.max(0.0, _nutrition.calories);
  double get _effectiveProtein => math.max(0.0, _nutrition.protein);
  double get _effectiveFat => math.max(0.0, _nutrition.fat);
  double get _effectiveCarbs => math.max(0.0, _nutrition.carbs);

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${_loggedAt.hour % 12 == 0 ? 12 : _loggedAt.hour % 12}:${_loggedAt.minute.toString().padLeft(2, '0')} ${_loggedAt.hour >= 12 ? 'PM' : 'AM'}';

    // Calculate percentage macro contribution of this food item
    final totalMacroGrams = _effectiveProtein + _effectiveFat + _effectiveCarbs;
    final proteinPct = totalMacroGrams > 0
        ? ((_effectiveProtein / totalMacroGrams) * 100).round()
        : 0;
    final fatPct = totalMacroGrams > 0
        ? ((_effectiveFat / totalMacroGrams) * 100).round()
        : 0;
    final carbsPct = totalMacroGrams > 0
        ? ((_effectiveCarbs / totalMacroGrams) * 100).round()
        : 0;

    // Target Impact percentages
    final targetCalPct = widget.macroTargets.targetCalories > 0
        ? ((_effectiveCalories / widget.macroTargets.targetCalories) * 100)
            .round()
        : 0;
    final targetProteinPct = widget.macroTargets.targetProteinGrams > 0
        ? ((_effectiveProtein / widget.macroTargets.targetProteinGrams) * 100)
            .round()
        : 0;
    final targetFatPct = widget.macroTargets.targetFatGrams > 0
        ? ((_effectiveFat / widget.macroTargets.targetFatGrams) * 100).round()
        : 0;
    final targetCarbsPct = widget.macroTargets.targetCarbsGrams > 0
        ? ((_effectiveCarbs / widget.macroTargets.targetCarbsGrams) * 100)
            .round()
        : 0;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final remainingKcal = widget.remainingCaloriesToday != null
        ? (widget.remainingCaloriesToday! - _effectiveCalories)
        : (widget.macroTargets.targetCalories - _effectiveCalories);
    final isOverBudget = remainingKcal < 0;
    final budgetText = isOverBudget
        ? 'Remaining today: +${(-remainingKcal).round()} kcal over · Adapts automatically'
        : 'Remaining today: ${remainingKcal.round()} kcal left';
    final budgetColor =
        isOverBudget ? AppTheme.calmOverBudget : AppTheme.textSecondary;

    final isGrams = _selectedUnit.unitName.toLowerCase().contains('gram') ||
        _selectedUnit.gramsPerUnit == 1.0;
    final presets = isGrams
        ? const [50.0, 100.0, 150.0, 200.0]
        : const [0.5, 1.0, 1.5, 2.0];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.cardBorder, width: 0.8),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Bar: Drag Pill, Close X, Timestamp, Meal Selector
                        const AppleSheetGrabber(
                            margin: EdgeInsets.only(bottom: 8)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              tooltip: 'Close',
                              icon: const Icon(Icons.close_rounded, size: 24),
                              color: AppTheme.textSecondary,
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.cardElevated,
                                    borderRadius: AppRadii.mdBorderRadius,
                                  ),
                                  child: Text(
                                    timeStr,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: PopupMenuButton<MealType>(
                                  initialValue: _selectedMeal,
                                  tooltip: 'Select meal',
                                  color: AppTheme.cardElevated,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: AppRadii.lgBorderRadius,
                                    side:
                                        BorderSide(color: AppTheme.cardBorder),
                                  ),
                                  onSelected: (meal) {
                                    AppHaptics.selectionClick();
                                    setState(() => _selectedMeal = meal);
                                  },
                                  itemBuilder: (context) =>
                                      MealType.values.map((meal) {
                                    return PopupMenuItem(
                                      value: meal,
                                      child: Text(
                                        meal.displayName,
                                        style: TextStyle(
                                          color: _selectedMeal == meal
                                              ? AppTheme.textPrimary
                                              : AppTheme.textSecondary,
                                          fontWeight: _selectedMeal == meal
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  child: Semantics(
                                    button: true,
                                    hint:
                                        'Double tap to change meal slot, currently set to ${_selectedMeal.displayName}',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardElevated,
                                        borderRadius: AppRadii.mdBorderRadius,
                                        border: Border.all(
                                            color: AppTheme.cardBorder,
                                            width: 0.8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _selectedMeal.displayName,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_drop_down_rounded,
                                            size: 18,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Food Header Summary
                        PlateHeaderSummary(
                          food: widget.food,
                          effectiveCalories: _effectiveCalories,
                          budgetText: budgetText,
                          budgetColor: budgetColor,
                        ),

                        const SizedBox(height: 12),

                        // Macro Percentage Badges
                        Row(
                          children: [
                            Expanded(
                                child: PlateMacroPill(
                                    label: 'Protein',
                                    grams: _effectiveProtein,
                                    percentage: proteinPct,
                                    color: AppTheme.protein)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: PlateMacroPill(
                                    label: 'Fat',
                                    grams: _effectiveFat,
                                    percentage: fatPct,
                                    color: AppTheme.fat)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: PlateMacroPill(
                                    label: 'Carbs',
                                    grams: _effectiveCarbs,
                                    percentage: carbsPct,
                                    color: AppTheme.carbs)),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Divider(color: AppTheme.cardBorder),
                        const SizedBox(height: 14),

                        // Quantity & Portion Unit Selector
                        const Text(
                          'SERVING SIZE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (_isGrainOrLentil)
                          PreparationStateSelector(
                            isRaw: _isRaw,
                            onChanged: (raw) => setState(() => _isRaw = raw),
                          ),

                        IndianServingChips(
                          selectedUnit: _selectedUnit,
                          availableUnits: _effectiveUnits,
                          onUnitSelected: (unit) {
                            setState(() => _selectedUnit = unit);
                          },
                        ),

                        // 1-Tap Preset Quantity Pills
                        PlatePresetRow(
                          presets: presets,
                          currentQuantity: _quantity,
                          isGrams: isGrams,
                          onSelect: _setQuantity,
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            // Quantity input controls
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.cardElevated,
                                borderRadius: AppRadii.lgBorderRadius,
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Semantics(
                                    button: true,
                                    label: 'Decrease quantity by 0.5',
                                    child: AppleBouncy(
                                      scaleDown: 0.88,
                                      onTap: () {
                                        final current = _parseQuantity(
                                                _quantityController.text) ??
                                            _quantity;
                                        if (current > 0.5) {
                                          _setQuantity(current - 0.5);
                                        }
                                      },
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 48,
                                          minHeight: 48,
                                        ),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.remove,
                                          size: 18,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 58,
                                    child: Semantics(
                                      label: 'Serving quantity',
                                      hint: 'Enter quantity or serving amount',
                                      child: TextFormField(
                                        key: const Key(
                                            'plate_serving_numeric_field'),
                                        focusNode: _quantityFocusNode,
                                        controller: _quantityController,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        textInputAction: TextInputAction.done,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textPrimary,
                                          fontFeatures: [
                                            FontFeature.tabularFigures()
                                          ],
                                        ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'[\d.,+\-*/ ]'))
                                        ],
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          hintText: 'Qty',
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 4, horizontal: 2),
                                          border: InputBorder.none,
                                        ),
                                        onChanged: (val) {
                                          final parsed = _parseQuantity(val) ??
                                              SiqueMathEvaluator.evaluate(val);
                                          if (parsed != null && parsed > 0) {
                                            setState(() => _quantity = parsed);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  Semantics(
                                    button: true,
                                    label: 'Increase quantity by 0.5',
                                    child: AppleBouncy(
                                      scaleDown: 0.88,
                                      onTap: () {
                                        final current = _parseQuantity(
                                                _quantityController.text) ??
                                            _quantity;
                                        _setQuantity(current + 0.5);
                                      },
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 48,
                                          minHeight: 48,
                                        ),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.add,
                                          size: 18,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Portion Unit Dropdown
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardElevated,
                                  borderRadius: AppRadii.lgBorderRadius,
                                  border:
                                      Border.all(color: AppTheme.cardBorder),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<PortionUnit>(
                                    value:
                                        _effectiveUnits.contains(_selectedUnit)
                                            ? _selectedUnit
                                            : _effectiveUnits.first,
                                    dropdownColor: AppTheme.cardSurface,
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: AppTheme.textSecondary,
                                    ),
                                    items: _effectiveUnits.map((u) {
                                      return DropdownMenuItem(
                                        value: u,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            '${u.unitName} (${u.gramsPerUnit.round()}g)',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (u) {
                                      if (u != null) {
                                        AppHaptics.selectionClick();
                                        setState(() => _selectedUnit = u);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SiqueMathKeyboardBar(
                          controller: _quantityController,
                          onEvaluated: (val) => setState(() => _quantity = val),
                        ),
                        const SizedBox(height: 14),

                        // 1-Tap Oil Modifier
                        PlateOilModifierSelector(
                          selectedOil: _selectedOil,
                          isVegan: widget.isVegan,
                          onSelected: (oil) =>
                              setState(() => _selectedOil = oil),
                        ),

                        const SizedBox(height: 20),
                        const Divider(color: AppTheme.cardBorder),
                        const SizedBox(height: 14),

                        // Impact on Targets Dial Badges
                        const Text('IMPACT ON TARGETS',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.8)),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                                child: PlateTargetDial(
                                    label: 'Calories',
                                    percentage: targetCalPct,
                                    color: AppTheme.calories)),
                            Expanded(
                                child: PlateTargetDial(
                                    label: 'Protein',
                                    percentage: targetProteinPct,
                                    color: AppTheme.protein)),
                            Expanded(
                                child: PlateTargetDial(
                                    label: 'Fat',
                                    percentage: targetFatPct,
                                    color: AppTheme.fat)),
                            Expanded(
                                child: PlateTargetDial(
                                    label: 'Carbs',
                                    percentage: targetCarbsPct,
                                    color: AppTheme.carbs)),
                          ],
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Sticky Bottom CTA Bar
                SiqueFrostedChrome(
                  showTopBorder: true,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: AppleBouncy(
                      scaleDown: 0.97,
                      onTap: _onConfirmLog,
                      child: Semantics(
                        button: true,
                        label:
                            'Add to Plate, ${_effectiveCalories.round()} calories to ${_selectedMeal.displayName}',
                        child: Container(
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppTheme.buttonBackground,
                            borderRadius: AppRadii.lgBorderRadius,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Add to Plate',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.buttonText,
                                  ),
                                ),
                                Text(
                                  '${_effectiveCalories.round()} kcal to ${_selectedMeal.displayName}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.buttonText
                                        .withValues(alpha: 0.78),
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }
}
