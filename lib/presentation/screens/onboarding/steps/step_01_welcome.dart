import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Step 1: Welcome & Philosophy Overview
class Step01Welcome extends StatelessWidget {
  const Step01Welcome({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Welcome to Sique',
      subtitle:
          'Adaptive metabolic intelligence with adherence-neutral coaching.',
      icon: Icons.auto_awesome_rounded,
      continueLabel: 'Get Started',
      continueKey: const Key('step_01_continue_btn'),
      onContinue: onNext,
      child: const Column(
        children: [
          _PillarCard(
            icon: Icons.favorite_border_rounded,
            iconColor: AppTheme.calories,
            title: 'Adherence-Neutral',
            description:
                'No guilt, streaks, or judgment. Eat above or below target and Sique mathematically recalculates without penalty.',
          ),
          SizedBox(height: 12),
          _PillarCard(
            icon: Icons.timeline_rounded,
            iconColor: AppTheme.expenditure,
            title: 'Bayesian Energy Filter',
            description:
                'Decodes your true daily metabolic expenditure continuously from scale weights and intake logs.',
          ),
          SizedBox(height: 12),
          _PillarCard(
            icon: Icons.tune_rounded,
            iconColor: AppTheme.carbs,
            title: 'Flexible Day Shifting',
            description:
                'Shift nutrition towards high-demand workout days while keeping weekly energy balance intact.',
          ),
        ],
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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
