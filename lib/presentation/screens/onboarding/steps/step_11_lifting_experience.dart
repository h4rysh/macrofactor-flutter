import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 11: Resistance Training Experience Level
class Step11LiftingExperience extends StatefulWidget {
  const Step11LiftingExperience({
    super.key,
    required this.initialExperience,
    required this.onNext,
  });

  final String initialExperience;
  final ValueChanged<String> onNext;

  @override
  State<Step11LiftingExperience> createState() =>
      _Step11LiftingExperienceState();
}

class _Step11LiftingExperienceState extends State<Step11LiftingExperience> {
  late String _experience;

  @override
  void initState() {
    super.initState();
    _experience = widget.initialExperience;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Lifting Experience',
      subtitle:
          'Your training age influences muscle protein synthesis rates and muscle gain potential.',
      icon: Icons.fitness_center_rounded,
      continueKey: const Key('step_11_continue_btn'),
      onContinue: () => widget.onNext(_experience),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _ExperienceCard(
            key: const Key('step_11_beginner_tile'),
            title: 'Beginner (< 1 year)',
            description:
                'New to structured resistance training. High capacity for rapid neuromuscular adaptations and body recomposition.',
            isSelected: _experience == 'beginner',
            onTap: () => setState(() => _experience = 'beginner'),
          ),
          const SizedBox(height: 14),
          _ExperienceCard(
            key: const Key('step_11_intermediate_tile'),
            title: 'Intermediate (1 – 3 years)',
            description:
                'Consistent lifting with steady strength progression. Requires structured periodization and higher recovery attention.',
            isSelected: _experience == 'intermediate',
            onTap: () => setState(() => _experience = 'intermediate'),
          ),
          const SizedBox(height: 14),
          _ExperienceCard(
            key: const Key('step_11_advanced_tile'),
            title: 'Advanced (3+ years)',
            description:
                'Close to genetic ceiling. Requires precise surplus control and elevated protein intake to stimulate hypertrophy.',
            isSelected: _experience == 'advanced',
            onTap: () => setState(() => _experience = 'advanced'),
          ),
        ],
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              if (isSelected)
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.activeBlue, size: 20),
            ],
          ),
          const SizedBox(height: 6),
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
    );
  }
}
