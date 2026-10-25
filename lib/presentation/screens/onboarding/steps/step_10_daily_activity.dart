import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 10: Daily Non-Exercise Activity (NEAT) Level
class Step10DailyActivity extends StatefulWidget {
  const Step10DailyActivity({
    super.key,
    required this.initialActivity,
    required this.onNext,
  });

  final String initialActivity;
  final ValueChanged<String> onNext;

  @override
  State<Step10DailyActivity> createState() => _Step10DailyActivityState();
}

class _Step10DailyActivityState extends State<Step10DailyActivity> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialActivity;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Daily Activity Level',
      subtitle:
          'Outside of planned gym workouts, how active is your daily work and lifestyle routine?',
      icon: Icons.directions_walk_rounded,
      continueKey: const Key('step_10_continue_btn'),
      onContinue: () => widget.onNext(_selected),
      child: Column(
        children: [
          _ActivityTile(
            key: const Key('step_10_activity_sedentary'),
            title: 'Sedentary',
            subtitle:
                'Desk job, seated work, driving, minimal daily steps (< 5,000 steps/day).',
            icon: Icons.chair_rounded,
            isSelected: _selected == 'sedentary',
            onTap: () => setState(() => _selected = 'sedentary'),
          ),
          const SizedBox(height: 12),
          _ActivityTile(
            key: const Key('step_10_activity_moderate'),
            title: 'Moderate Activity',
            subtitle:
                'Walking during commute, standing, household chores (5,000 – 10,000 steps/day).',
            icon: Icons.directions_walk_rounded,
            isSelected: _selected == 'moderate',
            onTap: () => setState(() => _selected = 'moderate'),
          ),
          const SizedBox(height: 12),
          _ActivityTile(
            key: const Key('step_10_activity_very_active'),
            title: 'Very Active',
            subtitle:
                'On your feet all day, physical trade/labor, high NEAT (> 10,000 steps/day).',
            icon: Icons.directions_run_rounded,
            isSelected: _selected == 'very_active',
            onTap: () => setState(() => _selected = 'very_active'),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppleTactileCard(
      onTap: onTap,
      backgroundColor: isSelected
          ? AppTheme.activeBlue.withValues(alpha: 0.14)
          : AppTheme.cardSurface,
      border: Border.all(
        color: isSelected ? AppTheme.activeBlue : AppTheme.cardBorder,
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
              color: isSelected
                  ? AppTheme.activeBlue.withValues(alpha: 0.2)
                  : AppTheme.cardElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isSelected ? AppTheme.activeBlue : AppTheme.textSecondary,
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
                    fontFamily: 'MacroSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
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
          if (isSelected)
            const Padding(
              padding: EdgeInsets.only(top: 2, left: 8),
              child: Icon(Icons.check_circle_rounded,
                  color: AppTheme.activeBlue, size: 20),
            ),
        ],
      ),
    );
  }
}
