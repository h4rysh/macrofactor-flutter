import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/food_models.dart';
import '../../domain/models/user_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_sheet_grabber.dart';
import '../widgets/apple_tactile_card.dart';
import '../widgets/food_svg_icon.dart';
import '../widgets/plate_metric_dials.dart';
import '../widgets/sique_frosted_chrome.dart';

typedef PlateLogCallback = void Function({
  required PortionUnit unit,
  required double quantity,
  required OilModifier oilModifier,
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
    this.remainingCaloriesToday,
    this.onMealChanged,
    required this.onLogConfirmed,
  });

  final FoodItem food;
  final List<PortionUnit> portionUnits;
  final MacroTargets macroTargets;
  final DateTime initialLoggedAt;
  final MealType initialMealType;
  final double? remainingCaloriesToday;
  final ValueChanged<MealType>? onMealChanged;
  final PlateLogCallback onLogConfirmed;

  static Future<void> show({
    required BuildContext context,
    required FoodItem food,
    required List<PortionUnit> portionUnits,
    required MacroTargets macroTargets,
    DateTime? initialLoggedAt,
    MealType initialMealType = MealType.lunch,
    double? remainingCaloriesToday,
    ValueChanged<MealType>? onMealChanged,
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
        remainingCaloriesToday: remainingCaloriesToday,
        onMealChanged: onMealChanged,
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

  List<PortionUnit> get _effectiveUnits => widget.portionUnits.isNotEmpty
      ? widget.portionUnits
      : [
          widget.food.defaultPortionUnit,
          PortionUnit(
              id: 0,
              foodId: widget.food.id,
              unitName: 'Grams',
              gramWeight: 1.0),
        ];

  static double? _parseQuantity(String text) {
    final clean = text.trim().replaceAll(',', '.');
    if (clean.isEmpty) return null;
    if (clean.contains(' ') && clean.contains('/')) {
      final p = clean.split(RegExp(r'\s+'));
      if (p.length == 2) {
        final w = double.tryParse(p[0]), f = _parseQuantity(p[1]);
        if (w != null && f != null) return w + f;
      }
    }
    if (clean.contains('/')) {
      final p = clean.split('/');
      if (p.length == 2) {
        final n = double.tryParse(p[0].trim()),
            d = double.tryParse(p[1].trim());
        if (n != null && d != null && d > 0) return n / d;
      }
      return null;
    }
    return double.tryParse(clean);
  }

  void _onConfirmLog() {
    if (_isSubmitting) return;
    _isSubmitting = true;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    widget.onMealChanged?.call(_selectedMeal);
    widget.onLogConfirmed(
      unit: _selectedUnit,
      quantity: _quantity,
      oilModifier: _selectedOil,
      loggedAt: _loggedAt,
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedUnit = _effectiveUnits.first;
    _selectedMeal = widget.initialMealType;
    _loggedAt = widget.initialLoggedAt;
    _quantityController = TextEditingController(
      text: _formatQuantity(_quantity),
    );
    _quantityFocusNode = FocusNode();
    _quantityFocusNode.addListener(() {
      if (!_quantityFocusNode.hasFocus) {
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

  String _formatQuantity(double q) =>
      q.truncateToDouble() == q ? q.toInt().toString() : q.toStringAsFixed(1);

  void _setQuantity(double newQ) {
    if (newQ > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _quantity = (newQ * 100).roundToDouble() / 100.0;
        _quantityController.text = _formatQuantity(_quantity);
      });
    }
  }

  NutritionalValues get _nutrition => widget.food.calculateNutrition(
        quantity: _quantity,
        unit: _selectedUnit,
        oilModifier: _selectedOil,
      );

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
        isOverBudget ? const Color(0xFF818CF8) : AppTheme.textSecondary;

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
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardElevated,
                                    borderRadius: BorderRadius.circular(12),
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: const BorderSide(
                                        color: AppTheme.cardBorder),
                                  ),
                                  onSelected: (meal) {
                                    HapticFeedback.selectionClick();
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
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardElevated,
                                      borderRadius: BorderRadius.circular(12),
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
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Food Icon & Title
                        Row(
                          children: [
                            FoodSvgIcon(
                                iconName: widget.food.iconName, size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.food.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  if (widget.food.region.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.activeBlue
                                            .withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        widget.food.region,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.activeBlue,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Big Calories Display & Macro Badges
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${_effectiveCalories.round()}',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 6),
                                child: Text(
                                  'Calories',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            budgetText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: budgetColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
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
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppleBouncy(
                                    scaleDown: 0.88,
                                    onTap: () {
                                      final current = _parseQuantity(
                                              _quantityController.text) ??
                                          _quantity;
                                      if (current > 0.5) {
                                        _setQuantity(current - 0.5);
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        size: 18,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 58,
                                    child: TextFormField(
                                      key: const Key(
                                          'plate_serving_numeric_field'),
                                      focusNode: _quantityFocusNode,
                                      controller: _quantityController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
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
                                            RegExp(r'[\d.,/ ]'))
                                      ],
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 4, horizontal: 2),
                                        border: InputBorder.none,
                                      ),
                                      onChanged: (val) {
                                        final parsed = _parseQuantity(val);
                                        if (parsed != null && parsed > 0) {
                                          setState(() => _quantity = parsed);
                                        }
                                      },
                                    ),
                                  ),
                                  AppleBouncy(
                                    scaleDown: 0.88,
                                    onTap: () {
                                      final current = _parseQuantity(
                                              _quantityController.text) ??
                                          _quantity;
                                      _setQuantity(current + 0.5);
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        size: 18,
                                        color: AppTheme.textPrimary,
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
                                  borderRadius: BorderRadius.circular(14),
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
                                        HapticFeedback.selectionClick();
                                        setState(() => _selectedUnit = u);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // 1-Tap Oil Modifier
                        PlateOilModifierSelector(
                          selectedOil: _selectedOil,
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
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(16),
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
                                  color: Color(0xFF09090B),
                                ),
                              ),
                              Text(
                                '${_effectiveCalories.round()} kcal to ${_selectedMeal.displayName}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF52525B),
                                ),
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
          ),
        ),
      ),
    );
  }
}
