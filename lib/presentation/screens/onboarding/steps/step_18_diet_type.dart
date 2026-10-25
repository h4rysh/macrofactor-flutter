import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 18: Dietary Philosophy (Standard, Vegetarian, Vegan, Jain, Pescatarian)
class Step18DietType extends StatefulWidget {
  const Step18DietType({
    super.key,
    required this.initialDietType,
    required this.onNext,
  });

  final String initialDietType;
  final ValueChanged<String> onNext;

  @override
  State<Step18DietType> createState() => _Step18DietTypeState();
}

class _Step18DietTypeState extends State<Step18DietType> {
  late String _selectedDiet;

  final List<Map<String, dynamic>> _diets = [
    {
      'id': 'standard',
      'title': 'Standard (Omnivore)',
      'desc':
          'All Indian foods including poultry, eggs, seafood, dairy, and grains.',
      'icon': Icons.restaurant_rounded,
    },
    {
      'id': 'vegetarian',
      'title': 'Vegetarian (Lacto-Veg)',
      'desc': 'Dairy, paneer, dals, rotis, rice, and produce. No meat or eggs.',
      'icon': Icons.eco_rounded,
    },
    {
      'id': 'pescatarian',
      'title': 'Pescatarian / Eggetarian',
      'desc':
          'Vegetarian diet augmented with whole eggs and regional fish/seafood.',
      'icon': Icons.set_meal_rounded,
    },
    {
      'id': 'vegan',
      'title': 'Plant-Based (Vegan)',
      'desc':
          'Zero animal products. Soya chunks, tofu, lentils, grains, and nuts.',
      'icon': Icons.spa_rounded,
    },
    {
      'id': 'jain',
      'title': 'Jain Vegetarian',
      'desc':
          'Lacto-vegetarian strictly excluding root vegetables (potato, onion, garlic).',
      'icon': Icons.brightness_high_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedDiet = widget.initialDietType;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Dietary Preference',
      subtitle:
          'Calibrates food search defaults and ICMR-NIN recipe recommendation suggestions.',
      icon: Icons.dining_rounded,
      continueKey: const Key('step_18_continue_btn'),
      onContinue: () => widget.onNext(_selectedDiet),
      child: Column(
        children: _diets.map((diet) {
          final isSelected = _selectedDiet == diet['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppleTactileCard(
              key: Key('step_18_diet_${diet['id']}'),
              onTap: () => setState(() => _selectedDiet = diet['id'] as String),
              backgroundColor: isSelected
                  ? AppTheme.activeBlue.withValues(alpha: 0.14)
                  : AppTheme.cardSurface,
              border: Border.all(
                color: isSelected ? AppTheme.activeBlue : AppTheme.cardBorder,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    diet['icon'] as IconData,
                    size: 24,
                    color: isSelected
                        ? AppTheme.activeBlue
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diet['title'] as String,
                          style: TextStyle(
                            fontFamily: 'MacroSans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          diet['desc'] as String,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.activeBlue, size: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
