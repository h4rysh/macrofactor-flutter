import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 20: Training Days Selection
class Step20Training extends StatefulWidget {
  const Step20Training({
    super.key,
    required this.initialWorkoutDays,
    required this.onNext,
  });

  final Set<int> initialWorkoutDays;
  final ValueChanged<Set<int>> onNext;

  @override
  State<Step20Training> createState() => _Step20TrainingState();
}

class _Step20TrainingState extends State<Step20Training> {
  late Set<int> _workoutDays;

  static const List<Map<String, dynamic>> _daysOfWeek = [
    {'iso': 1, 'name': 'Monday', 'short': 'Mon'},
    {'iso': 2, 'name': 'Tuesday', 'short': 'Tue'},
    {'iso': 3, 'name': 'Wednesday', 'short': 'Wed'},
    {'iso': 4, 'name': 'Thursday', 'short': 'Thu'},
    {'iso': 5, 'name': 'Friday', 'short': 'Fri'},
    {'iso': 6, 'name': 'Saturday', 'short': 'Sat'},
    {'iso': 7, 'name': 'Sunday', 'short': 'Sun'},
  ];

  @override
  void initState() {
    super.initState();
    _workoutDays = Set<int>.from(widget.initialWorkoutDays);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Training Schedule',
      subtitle:
          'On which days of the week do you train? In Shifted mode, calorie targets will peak on these days.',
      icon: Icons.calendar_month_rounded,
      continueKey: const Key('step_20_continue_btn'),
      onContinue: () => widget.onNext(_workoutDays),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _daysOfWeek.map((day) {
              final iso = day['iso'] as int;
              final isSelected = _workoutDays.contains(iso);
              return AppleTactileCard(
                key: Key('step_20_day_$iso'),
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
                  color: isSelected ? AppTheme.activeBlue : AppTheme.cardBorder,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: 14,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  day['short'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? AppTheme.activeBlue
                        : AppTheme.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppTheme.activeBlue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_workoutDays.length} training days selected. You can shift extra carbohydrate energy to workout days in the next step.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
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
