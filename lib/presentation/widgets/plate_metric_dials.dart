import 'package:flutter/material.dart';
import '../../domain/models/food_models.dart';
import '../../domain/models/oil_modifier_display.dart';
import '../theme/app_theme.dart';
import 'animated_primitives.dart';

/// Micro pill component displaying macro contribution grams and percentage.
class PlateMacroPill extends StatelessWidget {
  const PlateMacroPill({
    super.key,
    required this.label,
    required this.grams,
    required this.percentage,
    required this.color,
  });

  final String label;
  final double grams;
  final int percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardElevated,
        borderRadius: AppRadii.mdBorderRadius,
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${grams.toStringAsFixed(1)}g',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular dial badge indicating a food's percentage impact on daily macro targets.
class PlateTargetDial extends StatelessWidget {
  const PlateTargetDial({
    super.key,
    required this.label,
    required this.percentage,
    required this.color,
  });

  final String label;
  final int percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                strokeWidth: 4,
                backgroundColor: AppTheme.cardBorder,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Horizontal preset quantity selector row for plate serving sheet.
class PlatePresetRow extends StatelessWidget {
  const PlatePresetRow({
    super.key,
    required this.presets,
    required this.currentQuantity,
    required this.isGrams,
    required this.onSelect,
  });

  final List<double> presets;
  final double currentQuantity;
  final bool isGrams;
  final ValueChanged<double> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presets.map((preset) {
          final isSelected = (currentQuantity - preset).abs() < 0.05;
          final label = isGrams
              ? '${preset.toInt()}g'
              : (preset.truncateToDouble() == preset
                  ? preset.toInt().toString()
                  : preset.toString());
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppleBouncy(
              scaleDown: 0.92,
              onTap: () => onSelect(preset),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.buttonBackground
                      : AppTheme.cardElevated,
                  borderRadius: AppRadii.mdBorderRadius,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.buttonBackground
                        : AppTheme.cardBorder,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppTheme.buttonText
                        : AppTheme.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Horizontal cooking oil / ghee modifier selector row.
class PlateOilModifierSelector extends StatelessWidget {
  const PlateOilModifierSelector({
    super.key,
    required this.selectedOil,
    required this.onSelected,
  });

  final OilModifier selectedOil;
  final ValueChanged<OilModifier> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1-TAP OIL / GHEE MODIFIER',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          OilModifierDisplay.getTierSubtitle(selectedOil),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: OilModifierDisplay.canonicalTiers.map((oil) {
              final isSelected = selectedOil == oil;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Semantics(
                  inMutuallyExclusiveGroup: true,
                  selected: isSelected,
                  button: true,
                  label: OilModifierDisplay.getTierLabel(oil),
                  child: AppleBouncy(
                    scaleDown: 0.94,
                    onTap: () {
                      AppHaptics.selectionClick();
                      onSelected(oil);
                    },
                    child: AnimatedContainer(
                      duration: AppMotion.normal,
                      curve: Curves.easeOutCubic,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.activeBlue.withValues(alpha: 0.18)
                            : AppTheme.cardElevated,
                        borderRadius: AppRadii.mdBorderRadius,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.activeBlue
                              : AppTheme.cardBorder,
                          width: isSelected ? 1.4 : 1.0,
                        ),
                      ),
                      child: Text(
                        OilModifierDisplay.getTierLabel(oil),
                        style: TextStyle(
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
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
