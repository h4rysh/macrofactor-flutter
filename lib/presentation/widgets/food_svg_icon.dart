import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Renders a vector food SVG from the bundled asset library with graceful fallback.
class FoodSvgIcon extends StatelessWidget {
  const FoodSvgIcon({
    super.key,
    this.iconSvg,
    this.iconName,
    this.size = 40.0,
  });

  final String? iconSvg;
  final String? iconName;
  final double size;

  String get resolvedIconSvg => _normalizeIcon(iconSvg ?? iconName);

  static String _normalizeIcon(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'i1.svg';
    final clean = raw.trim().toLowerCase();

    // Map common food category tokens to verified bundled SVGs
    switch (clean) {
      case 'veg':
      case 'vegetable':
      case 'vegetarian':
        return 'i740.svg'; // mixed vegetables
      case 'meat':
      case 'non-veg':
      case 'non_veg':
      case 'poultry':
      case 'fish':
      case 'beef':
      case 'chicken':
        return 'i201.svg'; // meat & protein
      case 'dairy':
      case 'milk':
      case 'cheese':
      case 'paneer':
        return 'i101.svg'; // dairy & milk
      case 'grain':
      case 'grains':
      case 'cereal':
      case 'rice':
      case 'roti':
        return 'i549.svg'; // grains & rice
    }

    // Numbered icon format: i123 or i123.svg
    if (RegExp(r'^i\d+\.svg$').hasMatch(clean)) {
      return clean;
    }
    if (RegExp(r'^i\d+$').hasMatch(clean)) {
      return '$clean.svg';
    }

    // Safe general food icon fallback
    return 'i1.svg';
  }

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
