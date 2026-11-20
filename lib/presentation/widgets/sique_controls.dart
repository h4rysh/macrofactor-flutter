import 'package:flutter/material.dart';
import 'package:sique/presentation/theme/tokens/app_colors.dart';
import 'package:sique/presentation/theme/tokens/app_haptics.dart';
import 'package:sique/presentation/theme/tokens/app_radii.dart';
import 'package:sique/presentation/theme/tokens/app_typography.dart';
import 'package:sique/presentation/widgets/sique_bouncy.dart';

enum SiqueButtonVariant { primary, secondary, destructive, ghost }

/// Sovereign tactile button for the Sique Design System.
class SiqueButton extends StatelessWidget {
  const SiqueButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = SiqueButtonVariant.primary,
    this.isLoading = false,
    this.height = 52.0,
    this.width,
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final SiqueButtonVariant variant;
  final bool isLoading;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppRadii.button;
    final isEnabled = onPressed != null && !isLoading;

    Color bg;
    Color fg;
    Border? border;

    switch (variant) {
      case SiqueButtonVariant.primary:
        bg = isEnabled ? AppColors.calories : AppColors.calories.withAlpha(80);
        fg = AppColors.buttonForeground;
        break;
      case SiqueButtonVariant.secondary:
        bg = AppColors.cardElevated;
        fg = isEnabled ? AppColors.textPrimary : AppColors.textMuted;
        border = Border.all(color: AppColors.cardBorder);
        break;
      case SiqueButtonVariant.destructive:
        bg = isEnabled ? AppColors.protein : AppColors.protein.withAlpha(80);
        fg = Colors.white;
        break;
      case SiqueButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isEnabled ? AppColors.textPrimary : AppColors.textMuted;
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: fg,
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );

    return SiqueBouncy(
      enabled: isEnabled,
      onTap: () {
        AppHaptics.lightImpact();
        onPressed?.call();
      },
      child: Container(
        height: height,
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: effectiveRadius,
          border: border,
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );
  }
}

/// Sovereign segmented pill selector for switching units, intervals, or modes.
class SiqueSegmentedControl<T> extends StatelessWidget {
  const SiqueSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final Map<T, String> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: AppRadii.pillShape,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: segments.entries.map((entry) {
          final isSelected = entry.key == selected;
          return Expanded(
            child: SiqueBouncy(
              onTap: () {
                if (!isSelected) {
                  AppHaptics.selectionClick();
                  onChanged(entry.key);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.activeBlue : Colors.transparent,
                  borderRadius: AppRadii.pillShape,
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
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

/// Sovereign tactile numeric stepper for logging weights, portions, and targets.
class SiqueStepper extends StatelessWidget {
  const SiqueStepper({
    super.key,
    required this.valueText,
    required this.onIncrement,
    required this.onDecrement,
    this.unitLabel,
    this.canIncrement = true,
    this.canDecrement = true,
  });

  final String valueText;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final String? unitLabel;
  final bool canIncrement;
  final bool canDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SiqueBouncy(
            enabled: canDecrement,
            onTap: () {
              AppHaptics.selectionClick();
              onDecrement();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.remove,
                  size: 18, color: AppColors.textPrimary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valueText,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (unitLabel != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    unitLabel!,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SiqueBouncy(
            enabled: canIncrement,
            onTap: () {
              AppHaptics.selectionClick();
              onIncrement();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.add, size: 18, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
