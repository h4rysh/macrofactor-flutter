import 'package:flutter/material.dart';
import '../../../domain/models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_tactile_card.dart';

/// Step 0: Goal Selection
class GoalSelectionStep extends StatelessWidget {
  const GoalSelectionStep({
    super.key,
    required this.selectedGoal,
    required this.onGoalSelected,
  });

  final GoalType selectedGoal;
  final ValueChanged<GoalType> onGoalSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        const Text(
          'GOAL SELECTION',
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
          'What is your primary goal?',
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
          'Sique tailors caloric targets and protein distributions to your metabolic objective.',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        _buildGoalOptionCard(
          goal: GoalType.fatLoss,
          title: 'Fat Loss',
          subtitle:
              'Burn body fat while preserving lean tissue with an adherence-neutral smart deficit.',
          icon: Icons.local_fire_department_rounded,
          color: AppTheme.calories,
        ),
        const SizedBox(height: 12),
        _buildGoalOptionCard(
          goal: GoalType.maintenance,
          title: 'Maintenance & Recomposition',
          subtitle:
              'Maintain weight while tracking expenditure and optimizing energy for training.',
          icon: Icons.balance_rounded,
          color: AppTheme.expenditure,
        ),
        const SizedBox(height: 12),
        _buildGoalOptionCard(
          goal: GoalType.muscleGain,
          title: 'Muscle Gain (Hypertrophy)',
          subtitle:
              'Support maximum muscle protein synthesis with a measured, steady caloric surplus.',
          icon: Icons.fitness_center_rounded,
          color: AppTheme.trendWeight,
        ),
      ],
    );
  }

  Widget _buildGoalOptionCard({
    required GoalType goal,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedGoal == goal;

    return AppleBouncy(
      onTap: () => onGoalSelected(goal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : AppTheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : AppTheme.cardBorder,
            width: isSelected ? 1.6 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'MacroSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.check_circle_rounded,
                            color: color, size: 20),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
