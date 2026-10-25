import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 9: Exercise Frequency (0, 1-3, 4-6, 7+ workouts per week)
class Step09ExerciseFrequency extends StatefulWidget {
  const Step09ExerciseFrequency({
    super.key,
    required this.initialFrequency,
    required this.onNext,
  });

  final String initialFrequency;
  final ValueChanged<String> onNext;

  @override
  State<Step09ExerciseFrequency> createState() =>
      _Step09ExerciseFrequencyState();
}

class _Step09ExerciseFrequencyState extends State<Step09ExerciseFrequency> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialFrequency;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Exercise Frequency',
      subtitle:
          'How many structured workouts (lifting, cardio, sports) do you complete in a typical week?',
      icon: Icons.fitness_center_rounded,
      continueKey: const Key('step_09_continue_btn'),
      onContinue: () => widget.onNext(_selected),
      child: Column(
        children: [
          _FreqTile(
            key: const Key('step_09_freq_0'),
            title: '0 workouts / week',
            subtitle: 'No planned exercise routine currently.',
            isSelected: _selected == '0',
            onTap: () => setState(() => _selected = '0'),
          ),
          const SizedBox(height: 12),
          _FreqTile(
            key: const Key('step_09_freq_1_3'),
            title: '1 – 3 workouts / week',
            subtitle: 'Moderate gym sessions, weekend sports, or yoga.',
            isSelected: _selected == '1-3',
            onTap: () => setState(() => _selected = '1-3'),
          ),
          const SizedBox(height: 12),
          _FreqTile(
            key: const Key('step_09_freq_4_6'),
            title: '4 – 6 workouts / week',
            subtitle: 'Dedicated resistance training or athletic conditioning.',
            isSelected: _selected == '4-6',
            onTap: () => setState(() => _selected = '4-6'),
          ),
          const SizedBox(height: 12),
          _FreqTile(
            key: const Key('step_09_freq_7_plus'),
            title: '7+ workouts / week',
            subtitle:
                'Two-a-day sessions, high-volume endurance or competition prep.',
            isSelected: _selected == '7+',
            onTap: () => setState(() => _selected = '7+'),
          ),
        ],
      ),
    );
  }
}

class _FreqTile extends StatelessWidget {
  const _FreqTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
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
        children: [
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
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.activeBlue, size: 20),
        ],
      ),
    );
  }
}
