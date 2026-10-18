import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../apple_tactile_card.dart';

/// Reusable selection card for onboarding wizard.
class WizardSelectionCard extends StatelessWidget {
  const WizardSelectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppleTactileCard(
      onTap: onTap,
      backgroundColor: selected
          ? accentColor.withValues(alpha: 0.12)
          : AppTheme.cardSurface,
      border: Border.all(
        color: selected ? accentColor : AppTheme.cardBorder,
        width: selected ? 1.5 : 1,
      ),
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected
                  ? accentColor.withValues(alpha: 0.25)
                  : AppTheme.cardElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: selected ? accentColor : AppTheme.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: selected ? accentColor : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Icon(Icons.check_circle_rounded, color: accentColor, size: 20),
        ],
      ),
    );
  }
}

/// Slider tile with live value preview for physical metrics and pacing.
class WizardSliderTile extends StatelessWidget {
  const WizardSliderTile({
    super.key,
    required this.title,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                valueText,
                style: const TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.calories,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: AppTheme.calories,
            inactiveColor: AppTheme.cardBorder,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Large choice chip for binary selections like Sex.
class WizardChoiceChip extends StatelessWidget {
  const WizardChoiceChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.calories.withValues(alpha: 0.15)
              : AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.calories : AppTheme.cardBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppTheme.calories : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? AppTheme.calories : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact choice chip for multi-option categories like dietary preference.
class WizardSmallChoiceChip extends StatelessWidget {
  const WizardSmallChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.calories.withValues(alpha: 0.15)
              : AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.calories : AppTheme.cardBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppTheme.calories : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Macro badge tile displaying macro breakdown with subtle border.
class WizardMacroBadge extends StatelessWidget {
  const WizardMacroBadge({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'MacroSans',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
