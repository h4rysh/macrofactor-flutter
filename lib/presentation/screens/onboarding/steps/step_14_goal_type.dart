import 'package:flutter/material.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 14: Primary Nutritional Goal Selection (Fat Loss, Maintenance, Muscle Gain)
class Step14GoalType extends StatefulWidget {
  const Step14GoalType({
    super.key,
    required this.initialGoalType,
    required this.onNext,
  });

  final GoalType initialGoalType;
  final ValueChanged<GoalType> onNext;

  @override
  State<Step14GoalType> createState() => _Step14GoalTypeState();
}

class _Step14GoalTypeState extends State<Step14GoalType> {
  late GoalType _selectedGoal;

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.initialGoalType;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'What is your primary goal?',
      subtitle:
          'Caloric recommendations and macronutrient splits will calibrate to your physiological objective.',
      icon: Icons.track_changes_rounded,
      continueKey: const Key('step_14_continue_btn'),
      onContinue: () => widget.onNext(_selectedGoal),
      child: Column(
        children: [
          _GoalTile(
            key: const Key('step_14_goal_fat_loss'),
            title: 'Fat Loss',
            subtitle:
                'Target a controlled caloric deficit to reduce body fat while preserving lean muscle mass.',
            icon: Icons.local_fire_department_rounded,
            iconColor: AppTheme.calories,
            isSelected: _selectedGoal == GoalType.fatLoss,
            onTap: () => setState(() => _selectedGoal = GoalType.fatLoss),
          ),
          const SizedBox(height: 14),
          _GoalTile(
            key: const Key('step_14_goal_maintenance'),
            title: 'Maintenance',
            subtitle:
                'Eat at metabolic equilibrium to stabilize body weight and optimize athletic recovery.',
            icon: Icons.balance_rounded,
            iconColor: AppTheme.activeBlue,
            isSelected: _selectedGoal == GoalType.maintenance,
            onTap: () => setState(() => _selectedGoal = GoalType.maintenance),
          ),
          const SizedBox(height: 14),
          _GoalTile(
            key: const Key('step_14_goal_muscle_gain'),
            title: 'Muscle Gain',
            subtitle:
                'Target a measured caloric surplus to fuel hypertrophy and strength progression.',
            icon: Icons.fitness_center_rounded,
            iconColor: AppTheme.protein,
            isSelected: _selectedGoal == GoalType.muscleGain,
            onTap: () => setState(() => _selectedGoal = GoalType.muscleGain),
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppleTactileCard(
      onTap: onTap,
      backgroundColor:
          isSelected ? iconColor.withValues(alpha: 0.12) : AppTheme.cardSurface,
      border: Border.all(
        color: isSelected ? iconColor : AppTheme.cardBorder,
        width: isSelected ? 2 : 1,
      ),
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 8),
              child:
                  Icon(Icons.check_circle_rounded, color: iconColor, size: 20),
            ),
        ],
      ),
    );
  }
}
