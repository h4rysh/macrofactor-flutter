import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'animated_primitives.dart';
import 'sique_entrance.dart';
import 'sique_frosted_chrome.dart';
import 'sique_shimmer.dart';

/// Regional Indian food transliteration dictionary mapping Hindi, Tamil, Telugu,
/// and regional vernacular names to standard English/IFCT searchable terms.
class IndianFoodAliases {
  const IndianFoodAliases._();

  static const Map<String, String> _aliases = {
    // Grains & Breads
    'chawal': 'rice',
    'bhat': 'rice',
    'sadham': 'rice',
    'annam': 'rice',
    'roti': 'chapati',
    'phulka': 'chapati',
    'paratha': 'paratha',
    'poha': 'flattened rice',
    'aval': 'flattened rice',
    'upma': 'upma',
    'idli': 'idli',
    'dosa': 'dosa',
    'rava': 'semolina',
    'suji': 'semolina',

    // Dairy
    'dahi': 'curd',
    'thayir': 'curd',
    'perugu': 'curd',
    'yogurt': 'curd',
    'paneer': 'paneer',
    'doodh': 'milk',
    'paal': 'milk',
    'paalu': 'milk',
    'makhan': 'butter',
    'vennai': 'butter',
    'ghee': 'ghee',
    'chaas': 'buttermilk',
    'mor': 'buttermilk',

    // Pulses & Lentils
    'dal': 'dal',
    'paruppu': 'dal',
    'pappu': 'dal',
    'rajma': 'kidney beans',
    'chole': 'chickpeas',
    'chana': 'chickpeas',
    'moong': 'green gram',
    'urad': 'black gram',
    'masoor': 'lentil',
    'sambar': 'sambar',
    'rasam': 'rasam',

    // Vegetables
    'sabzi': 'vegetables',
    'aloo': 'potato',
    'urulaikizhangu': 'potato',
    'bangaladumpa': 'potato',
    'pyaz': 'onion',
    'vengayam': 'onion',
    'ulli': 'onion',
    'tamatar': 'tomato',
    'thakkali': 'tomato',
    'palak': 'spinach',
    'keerai': 'spinach',
    'gobi': 'cauliflower',
    'phoolgobi': 'cauliflower',
    'patta gobi': 'cabbage',
    'mutter': 'peas',
    'matar': 'peas',
    'pattani': 'peas',
    'bhindi': 'okra',
    'vendakkai': 'okra',
    'baingan': 'eggplant',
    'brinjal': 'eggplant',

    // Protein & Eggs
    'anda': 'egg',
    'muttai': 'egg',
    'guddu': 'egg',
    'murgh': 'chicken',
    'koli': 'chicken',
    'kozhi': 'chicken',
    'machli': 'fish',
    'meen': 'fish',
    'chepa': 'fish',
    'gosht': 'mutton',
    'mamsam': 'mutton',
  };

  /// Returns canonical search term if an alias exists, or null.
  static String? resolveAlias(String query) {
    final cleaned = query.trim().toLowerCase();
    if (cleaned.isEmpty) return null;
    return _aliases[cleaned];
  }
}

/// Popular Indian staples quick-add chips shown on empty search state.
class IndianStapleChips extends StatelessWidget {
  const IndianStapleChips({
    super.key,
    required this.onStapleSelected,
  });

  final ValueChanged<String> onStapleSelected;

  static const List<String> staples = [
    'Roti',
    'Dal Tadka',
    'Paneer',
    'Basmati Rice',
    'Egg Boiled',
    'Curd / Dahi',
    'Idli',
    'Dosa',
    'Chicken Curry',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_dining_rounded,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              SizedBox(width: 6),
              Text(
                'POPULAR INDIAN STAPLES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: staples.map((staple) {
              return AppleBouncy(
                scaleDown: 0.94,
                onTap: () {
                  AppHaptics.lightImpact();
                  onStapleSelected(staple);
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    borderRadius: AppRadii.mdBorderRadius,
                    border: Border.all(
                      color: AppTheme.cardBorder,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    staple,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton loader rendering 4 card placeholders while searching.
class FoodSearchSkeletonList extends StatelessWidget {
  const FoodSearchSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: AppRadii.lgBorderRadius,
            border: Border.all(color: AppTheme.cardBorder, width: 0.8),
          ),
          child: const Row(
            children: [
              SiqueShimmer(
                width: 44,
                height: 44,
                borderRadius: AppRadii.mdBorderRadius,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SiqueShimmer(
                      width: 140,
                      height: 16,
                      borderRadius: AppRadii.smBorderRadius,
                    ),
                    SizedBox(height: 8),
                    SiqueShimmer(
                      width: 90,
                      height: 12,
                      borderRadius: AppRadii.smBorderRadius,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              SiqueShimmer(
                width: 50,
                height: 24,
                borderRadius: AppRadii.smBorderRadius,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Floating glassmorphic plate review bottom action bar.
class PlateReviewBar extends StatelessWidget {
  const PlateReviewBar({
    super.key,
    required this.itemCount,
    required this.totalCalories,
    required this.onDone,
    this.onExpand,
    this.buttonLabel = 'Done',
  });

  final int itemCount;
  final int totalCalories;
  final VoidCallback onDone;
  final VoidCallback? onExpand;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 16,
      child: SiqueEntrance(
        child: Semantics(
          button: true,
          label:
              'Review Plate: $itemCount items, $totalCalories calories total',
          child: SiqueFrostedChrome(
            borderRadius: AppRadii.xlBorderRadius,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: InkWell(
              onTap: onExpand,
              borderRadius: AppRadii.xlBorderRadius,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.cardElevated,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      size: 18,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$itemCount ${itemCount == 1 ? 'item' : 'items'} staged · Tap to edit',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '$totalCalories kcal total',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppleBouncy(
                    scaleDown: 0.94,
                    onTap: onDone,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: AppTheme.buttonBackground,
                        borderRadius: AppRadii.lgBorderRadius,
                      ),
                      child: Text(
                        buttonLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.buttonText,
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
    );
  }
}
