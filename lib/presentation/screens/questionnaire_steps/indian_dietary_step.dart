import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_tactile_card.dart';

/// Step 3: Indian Nutrition & Dietary Habits
class IndianDietaryStep extends StatelessWidget {
  const IndianDietaryStep({
    super.key,
    required this.dietSlug,
    required this.stapleSlug,
    required this.oilSlug,
    required this.onDietSelected,
    required this.onStapleSelected,
    required this.onOilSelected,
  });

  final String dietSlug;
  final String stapleSlug;
  final String oilSlug;
  final ValueChanged<String> onDietSelected;
  final ValueChanged<String> onStapleSelected;
  final ValueChanged<String> onOilSelected;

  @override
  Widget build(BuildContext context) {
    const diets = [
      {'title': 'Pure Vegetarian', 'slug': 'pure_veg'},
      {'title': 'Eggetarian', 'slug': 'eggetarian'},
      {'title': 'Non-Vegetarian', 'slug': 'non_veg'},
      {'title': 'Vegan / Plant-based', 'slug': 'vegan'},
    ];

    const staples = [
      {'title': 'Balanced Roti & Rice', 'slug': 'balanced'},
      {'title': 'Roti dominant', 'slug': 'roti'},
      {'title': 'Rice & Katori Dominant', 'slug': 'rice'},
    ];

    const oilHabits = [
      {'title': 'Light spray (~0.5 tbsp)', 'slug': 'light'},
      {'title': 'Standard (1 tbsp oil/ghee)', 'slug': 'standard'},
      {'title': 'Generous (2 tbsp restaurant/heavy tadka)', 'slug': 'generous'},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        const Text(
          'INDIAN NUTRITION & DIET',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.activeBlue,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Indian Nutrition & Habits',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tailor search ranking, default logging portions, and cooking oil modifiers (ICMR-NIN IFCT).',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // Section A: Diet Type
        const Text(
          'DIETARY PATTERN',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final diet in diets) ...[
              _buildDietChip(
                title: diet['title'] as String,
                slug: diet['slug'] as String,
                isSelected: dietSlug == diet['slug'],
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),

        // Section B: Staple Habit
        const Text(
          'DAILY STAPLE PREFERENCE',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        for (final staple in staples) ...[
          _buildStapleTile(
            title: staple['title'] as String,
            slug: staple['slug'] as String,
            isSelected: stapleSlug == staple['slug'],
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),

        // Section C: Cooking Oil Habit
        const Text(
          'TYPICAL COOKING OIL / GHEE HABIT',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        for (final oil in oilHabits) ...[
          _buildOilTile(
            title: oil['title'] as String,
            slug: oil['slug'] as String,
            isSelected: oilSlug == oil['slug'],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildDietChip({
    required String title,
    required String slug,
    required bool isSelected,
  }) {
    return AppleBouncy(
      onTap: () => onDietSelected(slug),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.calories.withValues(alpha: 0.18)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.calories : AppTheme.cardBorder,
            width: isSelected ? 1.4 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded,
                  size: 14, color: AppTheme.calories),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStapleTile({
    required String title,
    required String slug,
    required bool isSelected,
  }) {
    return AppleBouncy(
      onTap: () => onStapleSelected(slug),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.carbs.withValues(alpha: 0.12)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.carbs : AppTheme.cardBorder,
            width: isSelected ? 1.4 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.carbs, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildOilTile({
    required String title,
    required String slug,
    required bool isSelected,
  }) {
    return AppleBouncy(
      onTap: () => onOilSelected(slug),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.fat.withValues(alpha: 0.12)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.fat : AppTheme.cardBorder,
            width: isSelected ? 1.4 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.fat, size: 18),
          ],
        ),
      ),
    );
  }
}
