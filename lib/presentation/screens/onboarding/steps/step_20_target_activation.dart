import 'package:flutter/material.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Step 20: Algorithmic Target Activation & 7-Day Program Reveal
class Step20TargetActivation extends StatelessWidget {
  const Step20TargetActivation({
    super.key,
    required this.program,
    required this.onActivate,
  });

  final WeeklyMacroProgram program;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final monday = program.days.first;

    return OnboardingStepScaffold(
      title: 'Your Sique Strategy',
      subtitle:
          'Algorithmic energy and macro targets dynamically computed for your metabolism.',
      icon: Icons.electric_bolt_rounded,
      continueLabel: 'Activate Targets',
      continueKey: const Key('step_20_activate_btn'),
      onContinue: onActivate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.activeBlue.withValues(alpha: 0.15),
                  AppTheme.expenditure.withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.activeBlue.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Daily Average Budget',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${program.dailyAverageCalories.round()}',
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.calories,
                    letterSpacing: -1.0,
                  ),
                ),
                const Text(
                  'kcal / day',
                  style: TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MacroItem(
                      label: 'Protein',
                      grams: monday.proteinGrams.round(),
                      color: AppTheme.protein,
                    ),
                    _MacroItem(
                      label: 'Carbs',
                      grams: monday.carbsGrams.round(),
                      color: AppTheme.carbs,
                    ),
                    _MacroItem(
                      label: 'Fats',
                      grams: monday.fatGrams.round(),
                      color: AppTheme.fat,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '7-Day Caloric Trajectory',
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in program.days) ...[
                _DayCard(day: day),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  const _MacroItem({
    required this.label,
    required this.grams,
    required this.color,
  });

  final String label;
  final int grams;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$grams g',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final DayMacroTarget day;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: day.isWorkoutDay
            ? AppTheme.carbs.withValues(alpha: 0.12)
            : AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: day.isWorkoutDay ? AppTheme.carbs : AppTheme.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Text(
            day.dayName,
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: day.isWorkoutDay ? AppTheme.carbs : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${day.calories.round()}',
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
