import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 12: Cardiovascular Activity / Conditioning Experience
class Step12CardioExperience extends StatefulWidget {
  const Step12CardioExperience({
    super.key,
    required this.initialExperience,
    required this.onNext,
  });

  final String initialExperience;
  final ValueChanged<String> onNext;

  @override
  State<Step12CardioExperience> createState() => _Step12CardioExperienceState();
}

class _Step12CardioExperienceState extends State<Step12CardioExperience> {
  late String _cardio;

  @override
  void initState() {
    super.initState();
    _cardio = widget.initialExperience;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Cardio & Aerobic Habit',
      subtitle:
          'How much aerobic conditioning or structured endurance activity do you perform weekly?',
      icon: Icons.directions_run_rounded,
      continueKey: const Key('step_12_continue_btn'),
      onContinue: () => widget.onNext(_cardio),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _CardioTile(
            key: const Key('step_12_none_tile'),
            title: 'Low / Sedentary',
            description: '< 3,000 steps/day. Minimal structured cardio.',
            isSelected: _cardio == 'none' || _cardio == 'beginner',
            onTap: () => setState(() => _cardio = 'beginner'),
          ),
          const SizedBox(height: 12),
          _CardioTile(
            key: const Key('step_12_light_tile'),
            title: 'Light (1 – 2 sessions/wk)',
            description:
                '5,000 – 7,500 daily steps. Occasional brisk walking or light cycling.',
            isSelected: _cardio == 'light',
            onTap: () => setState(() => _cardio = 'light'),
          ),
          const SizedBox(height: 12),
          _CardioTile(
            key: const Key('step_12_moderate_tile'),
            title: 'Moderate (3 – 4 sessions/wk)',
            description:
                '8,000 – 12,000 steps/day. Regular Zone 2 runs, HIIT, or rowing.',
            isSelected: _cardio == 'moderate',
            onTap: () => setState(() => _cardio = 'moderate'),
          ),
          const SizedBox(height: 12),
          _CardioTile(
            key: const Key('step_12_high_tile'),
            title: 'High / Endurance Athlete (5+ sessions)',
            description:
                '12,000+ steps/day. Competitive endurance training or two-a-days.',
            isSelected: _cardio == 'high' || _cardio == 'advanced',
            onTap: () => setState(() => _cardio = 'high'),
          ),
        ],
      ),
    );
  }
}

class _CardioTile extends StatelessWidget {
  const _CardioTile({
    super.key,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppleTactileCard(
      onTap: onTap,
      backgroundColor: isSelected
          ? AppTheme.activeBlue.withValues(alpha: 0.12)
          : AppTheme.cardSurface,
      border: Border.all(
        color: isSelected ? AppTheme.activeBlue : AppTheme.cardBorder,
        width: isSelected ? 2 : 1,
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
                  title,
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.activeBlue, size: 20),
        ],
      ),
    );
  }
}
