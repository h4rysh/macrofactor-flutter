import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Renders a vector food SVG from the extracted asset library with graceful fallback.
class FoodSvgIcon extends StatelessWidget {
  const FoodSvgIcon({
    super.key,
    this.iconSvg,
    String? iconName,
    this.size = 40.0,
  }) : resolvedIconSvg = iconSvg ?? iconName ?? 'i10.svg';

  final String? iconSvg;
  final String resolvedIconSvg;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetPath = 'assets/foods/$resolvedIconSvg';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: SvgPicture.asset(
        assetPath,
        width: size * 0.7,
        height: size * 0.7,
        placeholderBuilder: (_) => Icon(
          Icons.restaurant_menu,
          size: size * 0.5,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
