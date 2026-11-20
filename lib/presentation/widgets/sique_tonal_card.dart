import 'package:flutter/material.dart';
import 'package:sique/presentation/theme/tokens/app_colors.dart';
import 'package:sique/presentation/theme/tokens/app_radii.dart';
import 'package:sique/presentation/widgets/sique_bouncy.dart';

/// Flagship Obsidian tonal card component for the Sique Design System.
///
/// Features:
/// - Deep obsidian surface tones ([AppColors.cardSurface] / [AppColors.cardElevated]).
/// - Hairline border (1px solid rgba(255, 255, 255, 0.065) or custom [borderColor]).
/// - Continuous curvature corner radius (default 16dp).
/// - Optional integrated tactile press bounce via [onTap].
class SiqueTonalCard extends StatelessWidget {
  const SiqueTonalCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.onLongPress,
    this.isElevated = false,
    this.semanticLabel,
  });

  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isElevated;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ??
        (isElevated ? AppColors.cardElevated : AppColors.cardSurface);
    final effectiveBorder = borderColor ?? AppColors.cardBorder;
    final effectiveRadius = borderRadius ?? AppRadii.card;

    Widget cardContent = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: effectiveRadius,
        border: Border.all(color: effectiveBorder, width: 1.0),
      ),
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      return SiqueBouncy(
        onTap: onTap,
        onLongPress: onLongPress,
        semanticLabel: semanticLabel,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
