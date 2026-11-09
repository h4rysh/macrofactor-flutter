import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 21: Calorie & Macro Distribution Mode (Even vs Shifted Workout Days)
class Step21DistributionMode extends StatefulWidget {
  const Step21DistributionMode({
    super.key,
    required this.initialMode,
    required this.initialWorkoutDays,
    required this.onNext,
  });

  final String initialMode;
  final Set<int> initialWorkoutDays;
  final void Function(String mode, Set<int> workoutDays) onNext;

  @override
  State<Step21DistributionMode> createState() => _Step21DistributionModeState();
}

class _Step21DistributionModeState extends State<Step21DistributionMode> {
  late String _mode;
  late Set<int> _workoutDays;

  static const List<Map<String, dynamic>> _daysOfWeek = [
    {'iso': 1, 'name': 'Mon'},
    {'iso': 2, 'name': 'Tue'},
    {'iso': 3, 'name': 'Wed'},
    {'iso': 4, 'name': 'Thu'},
    {'iso': 5, 'name': 'Fri'},
    {'iso': 6, 'name': 'Sat'},
    {'iso': 7, 'name': 'Sun'},
  ];

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _workoutDays = Set<int>.from(widget.initialWorkoutDays);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Target Distribution',
      subtitle:
          'Distribute daily calories equally across the week, or shift higher calories to your training days.',
      icon: Icons.calendar_view_week_rounded,
      continueKey: const Key('step_21_continue_btn'),
      onContinue: () => widget.onNext(_mode, _workoutDays),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DistributionCard(
            key: const Key('step_21_even_tile'),
            title: 'Even Allocation',
            desc:
                'Equal calorie and macro targets every single day of the week.',
            isSelected: _mode == 'even',
            onTap: () => setState(() => _mode = 'even'),
          ),
          const SizedBox(height: 12),
          _DistributionCard(
            key: const Key('step_21_shifted_tile'),
            title: 'Shifted Workout Days',
            desc:
                'Higher calories & carbohydrates on training days, lower on rest days.',
            isSelected: _mode == 'shifted',
            onTap: () => setState(() => _mode = 'shifted'),
          ),
          if (_mode == 'shifted') ...[
            const SizedBox(height: 20),
            const Text(
              'Select Your Training Days:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _daysOfWeek.map((day) {
                final iso = day['iso'] as int;
                final isSelected = _workoutDays.contains(iso);
                return AppleTactileCard(
                  key: Key('step_21_day_$iso'),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _workoutDays.remove(iso);
                      } else {
                        _workoutDays.add(iso);
                      }
                    });
                  },
                  backgroundColor: isSelected
                      ? AppTheme.activeBlue.withValues(alpha: 0.16)
                      : AppTheme.cardSurface,
                  border: Border.all(
                    color:
                        isSelected ? AppTheme.activeBlue : AppTheme.cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: 12,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    day['name'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? AppTheme.activeBlue
                          : AppTheme.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({
    super.key,
    required this.title,
    required this.desc,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String desc;
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
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
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
