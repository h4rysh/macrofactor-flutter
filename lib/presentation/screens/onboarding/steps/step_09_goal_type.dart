import 'package:flutter/material.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 9: Goal Selection (Fat Loss, Maintenance, Muscle Gain)
class Step09GoalType extends StatefulWidget {
  const Step09GoalType({
    super.key,
    required this.initialGoalType,
    required this.onNext,
  });

  final GoalType initialGoalType;
  final ValueChanged<GoalType> onNext;

  @override
  State<Step09GoalType> createState() => _Step09GoalTypeState();
}

class _Step09GoalTypeState extends State<Step09GoalType> {
  late GoalType _goalType;

  @override
  void initState() {
    super.initState();
    _goalType = widget.initialGoalType;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'What is your primary goal?',
      subtitle:
          'Sique calibrates your energy deficit or surplus based on your selection.',
      icon: Icons.track_changes_rounded,
      continueKey: const Key('step_09_continue_btn'),
      onContinue: () => widget.onNext(_goalType),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _GoalOptionCard(
            key: const Key('step_09_fat_loss_tile'),
            title: 'Fat Loss',
            subtitle:
                'Targeted caloric deficit optimized to shed body fat while sparing lean mass.',
            icon: Icons.local_fire_department_rounded,
            accentColor: AppTheme.calories,
            isSelected: _goalType == GoalType.fatLoss,
            onTap: () => setState(() => _goalType = GoalType.fatLoss),
          ),
          const SizedBox(height: 14),
          _GoalOptionCard(
            key: const Key('step_09_maintenance_tile'),
            title: 'Maintenance',
            subtitle:
                'Calibrated isocaloric balance to sustain weight and enhance metabolic stability.',
            icon: Icons.balance_rounded,
            accentColor: AppTheme.activeBlue,
            isSelected: _goalType == GoalType.maintenance,
            onTap: () => setState(() => _goalType = GoalType.maintenance),
          ),
          const SizedBox(height: 14),
          _GoalOptionCard(
            key: const Key('step_09_muscle_gain_tile'),
            title: 'Muscle Gain',
            subtitle:
                'Hypertrophy-focused energy surplus supporting progressive overload and recovery.',
            icon: Icons.fitness_center_rounded,
            accentColor: AppTheme.expenditure,
            isSelected: _goalType == GoalType.muscleGain,
            onTap: () => setState(() => _goalType = GoalType.muscleGain),
          ),
        ],
      ),
    );
  }
}

class _GoalOptionCard extends StatelessWidget {
  const _GoalOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppleTactileCard(
      onTap: onTap,
      backgroundColor: isSelected
          ? accentColor.withValues(alpha: 0.12)
          : AppTheme.cardSurface,
      border: Border.all(
        color: isSelected ? accentColor : AppTheme.cardBorder,
        width: isSelected ? 2 : 1,
      ),
      borderRadius: 16,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppTheme.textPrimary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded,
                          color: accentColor, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
