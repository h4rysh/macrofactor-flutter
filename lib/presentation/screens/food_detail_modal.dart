import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_sheet_grabber.dart';
import 'package:sique/presentation/widgets/food_svg_icon.dart';

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
      backgroundColor: Colors.transparent,
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
  late TextEditingController _quantityController;
  late FocusNode _quantityFocusNode;
  bool _isSubmitting = false; // Button submission debouncing (ISS-8-08)

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.food.defaultPortionUnit;
    _quantityController = TextEditingController(
      text: _formatQuantity(_quantity),
    );
    _quantityFocusNode = FocusNode();
    _quantityFocusNode.addListener(() {
      if (!_quantityFocusNode.hasFocus) {
        final parsed = double.tryParse(_quantityController.text);
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

  String _formatQuantity(double q) {
    return q.truncateToDouble() == q
        ? q.toInt().toString()
        : q.toStringAsFixed(1);
  }

  void _setQuantity(double newQ) {
    if (newQ > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _quantity = (newQ * 100).roundToDouble() / 100.0;
        _quantityController.text = _formatQuantity(_quantity);
      });
    }
  }

  void _handleLogFood() {
    if (_isSubmitting) return; // Debounce guard (ISS-8-08)
    setState(() => _isSubmitting = true);

    try {
      HapticFeedback.mediumImpact();
      final dateStr = ref.read(selectedDateProvider);
      final now = DateTime.now();
      final parsedDate = DateTime.tryParse(dateStr);
      final loggedAt = parsedDate != null
          ? DateTime(parsedDate.year, parsedDate.month, parsedDate.day,
              now.hour, now.minute, now.second)
          : now;

      ref.read(dailyFoodLogsProvider.notifier).addEntry(
            food: widget.food,
            portionUnit: _selectedUnit,
            quantity: _quantity,
            mealType: widget.mealType,
            oilModifier: _oilModifier,
            loggedAt: loggedAt,
          );
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nutrition = widget.food.calculateNutrition(
      quantity: _quantity,
      unit: _selectedUnit,
      oilModifier: _oilModifier,
    );
    final mediaQuery = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface.withValues(alpha: 0.88),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: SafeArea(
            top: false,
            bottom: true, // Bottom SafeArea padding (ISS-7-08)
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: mediaQuery.viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Apple Sheet Grabber
                    const AppleSheetGrabber(
                        margin: EdgeInsets.only(bottom: 12)),
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
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
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    widget.food.category,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (widget.food.isVerified)
                                Container(
                                  key: const Key('food_verified_badge'),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.activeBlue
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: AppTheme.activeBlue
                                            .withValues(alpha: 0.35)),
                                  ),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_outlined,
                                            size: 11,
                                            color: AppTheme.activeBlue),
                                        SizedBox(width: 4),
                                        Text(
                                          'ICMR-NIN IFCT Verified',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.activeBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  key: const Key('food_approximate_badge'),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.expenditure
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: AppTheme.expenditure
                                            .withValues(alpha: 0.35)),
                                  ),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.info_outline,
                                            size: 11,
                                            color: AppTheme.expenditure),
                                        SizedBox(width: 4),
                                        Text(
                                          'Approximate values (Recipe Estimate)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.expenditure,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                        border:
                            Border.all(color: AppTheme.cardBorder, width: 1),
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
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newUnit) {
                            if (newUnit != null) {
                              HapticFeedback.selectionClick();
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
                        const Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'NUMBER OF SERVINGS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            IconButton.filledTonal(
                              onPressed: () {
                                final current =
                                    double.tryParse(_quantityController.text) ??
                                        _quantity;
                                if (current > 0.5) {
                                  _setQuantity(current - 0.5);
                                }
                              },
                              icon: const Icon(Icons.remove, size: 16),
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.surface,
                                foregroundColor: AppTheme.textPrimary,
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 54),
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: 54,
                                child: TextFormField(
                                  focusNode: _quantityFocusNode,
                                  controller: _quantityController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*')),
                                  ],
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 2),
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val);
                                    if (parsed != null && parsed > 0) {
                                      setState(() => _quantity = parsed);
                                    }
                                  },
                                ),
                              ),
                            ),
                            IconButton.filledTonal(
                              onPressed: () {
                                final current =
                                    double.tryParse(_quantityController.text) ??
                                        _quantity;
                                _setQuantity(current + 0.5);
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
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  mod == OilModifier.lowOil
                                      ? 'Homestyle\n(-15% Fat)'
                                      : mod == OilModifier.standard
                                          ? 'Standard\nRecipe'
                                          : 'Desi Ghee\n(+5g Fat)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppTheme.background
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() => _oilModifier = mod);
                              },
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
                        border:
                            Border.all(color: AppTheme.cardBorder, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: _NutrientTile(
                              title: 'CALORIES',
                              value: '${nutrition.calories.round()}',
                              unit: 'kcal',
                              color: AppTheme.calories,
                            ),
                          ),
                          Expanded(
                            child: _NutrientTile(
                              title: 'PROTEIN',
                              value: nutrition.protein.toStringAsFixed(1),
                              unit: 'g',
                              color: AppTheme.protein,
                            ),
                          ),
                          Expanded(
                            child: _NutrientTile(
                              title: 'CARBS',
                              value: nutrition.carbs.toStringAsFixed(1),
                              unit: 'g',
                              color: AppTheme.carbs,
                            ),
                          ),
                          Expanded(
                            child: _NutrientTile(
                              title: 'FAT',
                              value: nutrition.fat.toStringAsFixed(1),
                              unit: 'g',
                              color: AppTheme.fat,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Log Button with submission debouncing (ISS-8-08)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: !_isSubmitting ? _handleLogFood : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.calories,
                          foregroundColor: AppTheme.background,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _isSubmitting
                                ? 'Logging...'
                                : 'Log to ${widget.mealType.displayName}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
