import 'package:flutter/material.dart';
import '../../../domain/models/macro_program.dart';
import '../../../domain/models/user_profile.dart';
import '../../theme/app_theme.dart';
import 'wizard_input_tiles.dart';

/// Step 5: Live Algorithmic Program Preview & Confirmation.
class WizardPreviewStep extends StatelessWidget {
  const WizardPreviewStep({
    super.key,
    required this.previewProgram,
    required this.tdee,
    required this.programStyle,
    required this.programMode,
    required this.dietaryPref,
  });

  final WeeklyMacroProgram previewProgram;
  final double tdee;
  final MacroProgramStyle programStyle;
  final ProgramMode programMode;
  final String dietaryPref;

  @override
  Widget build(BuildContext context) {
    final workoutDay = previewProgram.days.firstWhere(
      (d) => d.isWorkoutDay,
      orElse: () => previewProgram.days.first,
    );
    final restDay = previewProgram.days.firstWhere(
      (d) => !d.isWorkoutDay,
      orElse: () => previewProgram.days.first,
    );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Your Custom Strategy',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Algorithmic targets calibrated to your physiology and preferences.',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Hero Metric Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.cardBorder, width: 1),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Estimated Burn (TDEE)',
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '${tdee.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.expenditure,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daily Average Target',
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '${previewProgram.dailyAverageCalories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.calories,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Workout vs Rest Day Breakdown
        const Text(
          'Day-to-Day Distribution',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDayTargetCard(
                title: 'Workout Days',
                target: workoutDay,
                isWorkout: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDayTargetCard(
                title: 'Rest Days',
                target: restDay,
                isWorkout: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Program Metadata Badges
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            WizardMacroBadge(text: 'Style: ${programStyle.displayName}'),
            WizardMacroBadge(text: 'Mode: ${programMode.displayName}'),
            WizardMacroBadge(
                text: 'Diet: ${dietaryPref.replaceAll('_', ' ').toUpperCase()}'),
          ],
        ),
      ],
    );
  }

  Widget _buildDayTargetCard({
    required String title,
    required DayMacroTarget target,
    required bool isWorkout,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWorkout
              ? AppTheme.calories.withValues(alpha: 0.35)
              : AppTheme.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isWorkout
                    ? Icons.fitness_center_rounded
                    : Icons.bedtime_outlined,
                size: 16,
                color: isWorkout ? AppTheme.calories : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isWorkout ? AppTheme.calories : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${target.calories.toStringAsFixed(0)} kcal',
            style: const TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'P: ${target.proteinGrams.toStringAsFixed(0)}g | C: ${target.carbsGrams.toStringAsFixed(0)}g | F: ${target.fatGrams.toStringAsFixed(0)}g',
            style: const TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
