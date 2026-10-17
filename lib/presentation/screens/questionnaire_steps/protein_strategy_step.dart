import 'package:flutter/material.dart';
import '../../../domain/models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_tactile_card.dart';

/// Step 4: Protein Strategy & Macro Distribution
class ProteinStrategyStep extends StatelessWidget {
  const ProteinStrategyStep({
    super.key,
    required this.selectedGoal,
    required this.currentWeightKg,
    required this.proteinPref,
    required this.onProteinSelected,
  });

  final GoalType selectedGoal;
  final double currentWeightKg;
  final ProteinPreference proteinPref;
  final ValueChanged<ProteinPreference> onProteinSelected;

  @override
  Widget build(BuildContext context) {
    final proteinOptions = [
      {
        'pref': ProteinPreference.moderate,
        'title': 'Moderate (1.6 g/kg)',
        'grams': (currentWeightKg * 1.6).round(),
        'desc': 'Healthy baseline for endurance or general active lifestyle.',
      },
      {
        'pref': ProteinPreference.high,
        'title': 'High Protein (Recommended)',
        'grams': (currentWeightKg * 2.0).round(),
        'desc':
            'Ideal for resistance training, fat loss satiety, and lean muscle retention.',
      },
      {
        'pref': ProteinPreference.extraHigh,
        'title': 'Extra High (2.4 g/kg)',
        'grams': (currentWeightKg * 2.4).round(),
        'desc': 'For aggressive fat loss cuts or dedicated strength athletes.',
      },
    ];

    String goalContextHint;
    if (selectedGoal == GoalType.fatLoss) {
      goalContextHint =
          '💡 High Protein (2.0 g/kg) is recommended during Fat Loss to protect contractile tissue against muscle catabolism in a caloric deficit.';
    } else if (selectedGoal == GoalType.muscleGain) {
      goalContextHint =
          '💡 In a caloric surplus, 1.8–2.0 g/kg protein is plenty to maximize muscle protein synthesis alongside high carbohydrate replenishment.';
    } else {
      goalContextHint =
          '💡 At maintenance calories, protein stabilizes recovery and satiety throughout the week.';
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        const Text(
          'PROTEIN STRATEGY',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.protein,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Protein Intake Target',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Calculated proportionally to your current scale weight (${currentWeightKg.toStringAsFixed(1)} kg).',
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 14),

        // Contextual Hint Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.protein.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: Text(
            goalContextHint,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              color: AppTheme.protein,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 16),

        ...proteinOptions.map((opt) {
          final pref = opt['pref'] as ProteinPreference;
          final isSelected = proteinPref == pref;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppleBouncy(
              onTap: () => onProteinSelected(pref),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.protein.withValues(alpha: 0.12)
                      : AppTheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? AppTheme.protein : AppTheme.cardBorder,
                    width: isSelected ? 1.5 : 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt['title'] as String,
                            style: const TextStyle(
                              fontFamily: 'MacroSans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            opt['desc'] as String,
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.cardElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${opt['grams']}g/day',
                        style: const TextStyle(
                          fontFamily: 'MacroSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.protein,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
