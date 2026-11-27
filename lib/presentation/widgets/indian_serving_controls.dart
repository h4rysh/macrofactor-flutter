import 'package:flutter/material.dart';
import '../../domain/models/food_models.dart';
import '../theme/app_theme.dart';
import 'animated_primitives.dart';
import 'food_svg_icon.dart';

/// Household measure chip options for Indian foods.
class IndianServingChips extends StatelessWidget {
  const IndianServingChips({
    super.key,
    required this.selectedUnit,
    required this.availableUnits,
    required this.onUnitSelected,
  });

  final PortionUnit selectedUnit;
  final List<PortionUnit> availableUnits;
  final ValueChanged<PortionUnit> onUnitSelected;

  @override
  Widget build(BuildContext context) {
    // Filter to standard household units
    final displayUnits = availableUnits.where((u) {
      final name = u.unitName.toLowerCase();
      return name.contains('gram') ||
          name.contains('katori') ||
          name.contains('ladle') ||
          name.contains('roti') ||
          name.contains('piece') ||
          name.contains('cup');
    }).toList();

    if (displayUnits.length <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: displayUnits.map((unit) {
            final isSelected = selectedUnit.unitName == unit.unitName;
            final label = '${unit.unitName} (${unit.gramsPerUnit.round()}g)';

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Semantics(
                button: true,
                selected: isSelected,
                label: 'Unit: $label',
                child: AppleBouncy(
                  scaleDown: 0.94,
                  onTap: () {
                    AppHaptics.selectionClick();
                    onUnitSelected(unit);
                  },
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : AppMotion.normal,
                    curve: Curves.easeOutCubic,
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.activeBlue.withValues(alpha: 0.18)
                          : AppTheme.cardElevated,
                      borderRadius: AppRadii.mdBorderRadius,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.activeBlue
                            : AppTheme.cardBorder,
                        width: isSelected ? 1.2 : 0.8,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppTheme.activeBlueText
                            : AppTheme.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Preparation state toggle (Cooked / Boiled vs Raw Uncooked) for grains, lentils & sabzis.
class PreparationStateSelector extends StatelessWidget {
  const PreparationStateSelector({
    super.key,
    required this.isRaw,
    required this.onChanged,
  });

  final bool isRaw;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardElevated,
          borderRadius: AppRadii.mdBorderRadius,
          border: Border.all(color: AppTheme.cardBorder, width: 0.8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.soup_kitchen_rounded,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Preparation State',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Values reflect cooked preparation by default',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              toggled: isRaw,
              label:
                  'Preparation state: ${isRaw ? 'Raw Uncooked' : 'Cooked / Boiled'}',
              child: AppleBouncy(
                scaleDown: 0.94,
                onTap: () {
                  AppHaptics.selectionClick();
                  onChanged(!isRaw);
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isRaw
                        ? AppTheme.calories.withValues(alpha: 0.2)
                        : AppTheme.activeBlue.withValues(alpha: 0.16),
                    borderRadius: AppRadii.smBorderRadius,
                    border: Border.all(
                      color: isRaw ? AppTheme.calories : AppTheme.activeBlue,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isRaw ? 'Raw Uncooked' : 'Cooked / Boiled',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isRaw
                          ? AppTheme.caloriesSecondary
                          : AppTheme.activeBlueText,
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
}

/// Food header banner with icon, name, regional tag, and big calorie readout.
class PlateHeaderSummary extends StatelessWidget {
  const PlateHeaderSummary({
    super.key,
    required this.food,
    required this.effectiveCalories,
    required this.budgetText,
    required this.budgetColor,
  });

  final FoodItem food;
  final double effectiveCalories;
  final String budgetText;
  final Color budgetColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Food Icon & Title
        Row(
          children: [
            FoodSvgIcon(iconName: food.iconName, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (food.region.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.activeBlue.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        food.region,
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
                '${effectiveCalories.round()}',
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
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
