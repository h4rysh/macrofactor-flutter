import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';
import 'package:sique/presentation/widgets/sique_frosted_chrome.dart';

/// Card 1: Primary Goal Selection (Fat Loss, Maintenance, Muscle Gain).
class Card01Goal extends StatelessWidget {
  const Card01Goal({
    super.key,
    required this.selectedGoal,
    required this.onGoalSelected,
    required this.onNext,
  });

  final GoalType selectedGoal;
  final ValueChanged<GoalType> onGoalSelected;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              const Text(
                'GOAL SELECTION',
                style: TextStyle(
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
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sique calibrates your nutritional targets, metabolic pacing, and protein distributions to your goal.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              _buildGoalTile(
                goal: GoalType.fatLoss,
                title: 'Fat Loss',
                subtitle:
                    'Burn body fat while preserving lean tissue via calibrated, adherence-neutral caloric deficit.',
                icon: Icons.local_fire_department_rounded,
                color: AppTheme.calories,
              ),
              const SizedBox(height: 12),
              _buildGoalTile(
                goal: GoalType.maintenance,
                title: 'Maintenance',
                subtitle:
                    'Maintain body weight, track baseline expenditure, and fuel optimal performance.',
                icon: Icons.balance_rounded,
                color: AppTheme.expenditure,
              ),
              const SizedBox(height: 12),
              _buildGoalTile(
                goal: GoalType.muscleGain,
                title: 'Muscle Gain',
                subtitle:
                    'Build lean muscle mass with progressive caloric surplus and elevated protein synthesis.',
                icon: Icons.fitness_center_rounded,
                color: AppTheme.trendWeight,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        // Pinned sticky bottom CTA bar: guaranteed visible without scrolling
        SiqueFrostedChrome(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: SizedBox(
                width: double.infinity,
                child: AppleTactileCard(
                  key: const Key('onboarding_card_1_continue_btn'),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onNext();
                  },
                  backgroundColor: const Color(0xFFFAFAFA),
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Center(
                    child: Text(
                      'Continue to biometrics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF09090B),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalTile({
    required GoalType goal,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedGoal == goal;

    return AppleBouncy(
      onTap: () {
        HapticFeedback.selectionClick();
        onGoalSelected(goal);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : AppTheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.25)
                    : AppTheme.cardElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
