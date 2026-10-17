import 'package:flutter/material.dart';
import '../../domain/models/food_models.dart';
import '../../domain/models/user_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_tactile_card.dart';
import '../widgets/food_svg_icon.dart';

/// Authentic MacroFactor Plate Serving Selector Bottom Sheet.
/// Matches `plate_serving_selector_sheet.dart` & `log_revamp.png` specifications.
class PlateServingSheet extends StatefulWidget {
  const PlateServingSheet({
    super.key,
    required this.food,
    required this.portionUnits,
    required this.macroTargets,
    required this.initialLoggedAt,
    required this.onLogConfirmed,
  });

  final FoodItem food;
  final List<PortionUnit> portionUnits;
  final MacroTargets macroTargets;
  final DateTime initialLoggedAt;
  final void Function({
    required PortionUnit unit,
    required double quantity,
    required OilModifier oilModifier,
    required DateTime loggedAt,
  }) onLogConfirmed;

  static Future<void> show({
    required BuildContext context,
    required FoodItem food,
    required List<PortionUnit> portionUnits,
    required MacroTargets macroTargets,
    DateTime? initialLoggedAt,
    required void Function({
      required PortionUnit unit,
      required double quantity,
      required OilModifier oilModifier,
      required DateTime loggedAt,
    }) onLogConfirmed,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => PlateServingSheet(
        food: food,
        portionUnits: portionUnits,
        macroTargets: macroTargets,
        initialLoggedAt: initialLoggedAt ?? DateTime.now(),
        onLogConfirmed: onLogConfirmed,
      ),
    );
  }

  @override
  State<PlateServingSheet> createState() => _PlateServingSheetState();
}

class _PlateServingSheetState extends State<PlateServingSheet> {
  late PortionUnit _selectedUnit;
  double _quantity = 1.0;
  OilModifier _selectedOil = OilModifier.none;
  late DateTime _loggedAt;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.portionUnits.isNotEmpty
        ? widget.portionUnits.first
        : PortionUnit(
            id: 0,
            foodId: widget.food.id,
            unitName: 'Grams',
            gramsPerUnit: 1.0,
          );
    _loggedAt = widget.initialLoggedAt;
  }

  double get _effectiveCalories {
    final base = (widget.food.caloriesPer100g *
            (_selectedUnit.gramsPerUnit * _quantity)) /
        100.0;
    return base + _selectedOil.additionalCalories;
  }

  double get _effectiveProtein {
    return (widget.food.proteinPer100g *
            (_selectedUnit.gramsPerUnit * _quantity)) /
        100.0;
  }

  double get _effectiveFat {
    final base =
        (widget.food.fatPer100g * (_selectedUnit.gramsPerUnit * _quantity)) /
            100.0;
    return base + _selectedOil.additionalFatGrams;
  }

  double get _effectiveCarbs {
    return (widget.food.carbsPer100g *
            (_selectedUnit.gramsPerUnit * _quantity)) /
        100.0;
  }

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

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Drag Pill, Close X, Timestamp, Edit
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 24),
                  color: AppTheme.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.cardElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    timeStr,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.activeBlue,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Food Icon & Title
            Row(
              children: [
                FoodSvgIcon(iconName: widget.food.iconName, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.food.name,
                        style: const TextStyle(
                          fontFamily: 'MacroSans',
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
                            color: AppTheme.activeBlue.withAlpha(40),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.food.region,
                            style: const TextStyle(
                              fontFamily: 'MacroSans',
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

            const SizedBox(height: 20),

            // Big Calories Display & Macro Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_effectiveCalories.round()}',
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
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
                      fontFamily: 'MacroSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Macro Percentage Badges
            Row(
              children: [
                _buildMacroPill(
                  label: 'Protein',
                  grams: _effectiveProtein,
                  percentage: proteinPct,
                  color: AppTheme.protein,
                ),
                const SizedBox(width: 8),
                _buildMacroPill(
                  label: 'Fat',
                  grams: _effectiveFat,
                  percentage: fatPct,
                  color: AppTheme.fat,
                ),
                const SizedBox(width: 8),
                _buildMacroPill(
                  label: 'Carbs',
                  grams: _effectiveCarbs,
                  percentage: carbsPct,
                  color: AppTheme.carbs,
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(color: AppTheme.cardBorder),
            const SizedBox(height: 16),

            // Quantity & Portion Unit Selector
            const Text(
              'SERVING SIZE',
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
                letterSpacing: 0.8,
              ),
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
                    children: [
                      AppleBouncy(
                        scaleDown: 0.88,
                        onTap: () {
                          if (_quantity > 0.5) {
                            setState(() => _quantity -= 0.5);
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 18,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _quantity.toStringAsFixed(1),
                        style: const TextStyle(
                          fontFamily: 'MacroSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      AppleBouncy(
                        scaleDown: 0.88,
                        onTap: () {
                          setState(() => _quantity += 0.5);
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
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
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<PortionUnit>(
                        value: _selectedUnit,
                        dropdownColor: AppTheme.cardSurface,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: AppTheme.textSecondary,
                        ),
                        items: widget.portionUnits.map((u) {
                          return DropdownMenuItem(
                            value: u,
                            child: Text(
                              '${u.unitName} (${u.gramsPerUnit.round()}g)',
                              style: const TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (u) {
                          if (u != null) setState(() => _selectedUnit = u);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 1-Tap Oil Modifier
            const Text(
              '1-TAP OIL / GHEE MODIFIER',
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: OilModifier.values.map((oil) {
                  final isSelected = _selectedOil == oil;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppleBouncy(
                      scaleDown: 0.94,
                      onTap: () => setState(() => _selectedOil = oil),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.activeBlue.withValues(alpha: 0.18)
                              : AppTheme.cardElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.activeBlue
                                : AppTheme.cardBorder,
                            width: isSelected ? 1.4 : 1.0,
                          ),
                        ),
                        child: Text(
                          oil.displayName,
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(color: AppTheme.cardBorder),
            const SizedBox(height: 16),

            // Impact on Targets Dial Badges (matching log_revamp.png)
            const Text(
              'IMPACT ON TARGETS',
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTargetDial(
                  label: 'Calories',
                  pct: targetCalPct,
                  color: AppTheme.calories,
                ),
                _buildTargetDial(
                  label: 'Protein',
                  pct: targetProteinPct,
                  color: AppTheme.protein,
                ),
                _buildTargetDial(
                  label: 'Fat',
                  pct: targetFatPct,
                  color: AppTheme.fat,
                ),
                _buildTargetDial(
                  label: 'Carbs',
                  pct: targetCarbsPct,
                  color: AppTheme.carbs,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action Buttons: Remove / To Custom & Add to Plate
            SizedBox(
              width: double.infinity,
              height: 52,
              child: AppleBouncy(
                scaleDown: 0.96,
                onTap: () {
                  widget.onLogConfirmed(
                    unit: _selectedUnit,
                    quantity: _quantity,
                    oilModifier: _selectedOil,
                    loggedAt: _loggedAt,
                  );
                  Navigator.pop(context);
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.activeBlue,
                        Color(0xFF0056B3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.activeBlue.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Add to Plate',
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroPill({
    required String label,
    required double grams,
    required int percentage,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(50),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$percentage%',
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${grams.toStringAsFixed(1)}g',
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetDial({
    required String label,
    required int pct,
    required Color color,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                strokeWidth: 4,
                backgroundColor: AppTheme.cardBorder,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '$pct%',
              style: const TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
