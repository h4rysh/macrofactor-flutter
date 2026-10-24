import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 14: Dietary Preference & Lifestyle
class Step14DietType extends StatefulWidget {
  const Step14DietType({
    super.key,
    required this.initialDietType,
    required this.onNext,
  });

  final String initialDietType;
  final ValueChanged<String> onNext;

  @override
  State<Step14DietType> createState() => _Step14DietTypeState();
}

class _Step14DietTypeState extends State<Step14DietType> {
  late String _dietType;

  @override
  void initState() {
    super.initState();
    _dietType = widget.initialDietType;
  }

  static const List<Map<String, String>> _options = [
    {
      'id': 'standard',
      'title': 'Standard / Omnivore',
      'subtitle': 'No dietary restrictions. Meats, dairy, plants, and grains.',
      'icon': 'restaurant',
    },
    {
      'id': 'vegetarian',
      'title': 'Vegetarian (Lacto-Ovo)',
      'subtitle':
          'Plant-based with dairy and eggs. Paneer, dal, legumes, and yogurt.',
      'icon': 'egg_alt',
    },
    {
      'id': 'pure_veg',
      'title': 'Lacto-Vegetarian (Indian Pure Veg)',
      'subtitle':
          'Dairy-friendly without eggs. Rich in lentils, paneer, and milk.',
      'icon': 'spa',
    },
    {
      'id': 'vegan',
      'title': 'Vegan (Strict Plant-Based)',
      'subtitle':
          '100% plant foods. Tofu, legumes, soy chunks, grains, and nuts.',
      'icon': 'eco',
    },
    {
      'id': 'pescatarian',
      'title': 'Pescatarian',
      'subtitle': 'Vegetarian baseline plus fish and seafood sources.',
      'icon': 'set_meal',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Dietary Preference',
      subtitle:
          'Tailors macro distribution recommendations and food catalog indexing.',
      icon: Icons.restaurant_menu_rounded,
      continueKey: const Key('step_14_continue_btn'),
      onContinue: () => widget.onNext(_dietType),
      child: Column(
        children: [
          const SizedBox(height: 12),
          for (final opt in _options) ...[
            AppleTactileCard(
              onTap: () => setState(() => _dietType = opt['id']!),
              backgroundColor: _dietType == opt['id']
                  ? AppTheme.activeBlue.withValues(alpha: 0.12)
                  : AppTheme.cardSurface,
              border: Border.all(
                color: _dietType == opt['id']
                    ? AppTheme.activeBlue
                    : AppTheme.cardBorder,
                width: _dietType == opt['id'] ? 2 : 1,
              ),
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opt['title']!,
                          style: TextStyle(
                            fontFamily: 'MacroSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _dietType == opt['id']
                                ? AppTheme.textPrimary
                                : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          opt['subtitle']!,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_dietType == opt['id'])
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.activeBlue, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
