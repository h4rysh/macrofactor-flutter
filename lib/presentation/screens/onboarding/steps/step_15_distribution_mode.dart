import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 15: Calorie Distribution Mode (Even Allocation vs Shifted Workout Days)
class Step15DistributionMode extends StatefulWidget {
  const Step15DistributionMode({
    super.key,
    required this.initialMode,
    required this.initialWorkoutDays,
    required this.onNext,
  });

  final String initialMode;
  final Set<int> initialWorkoutDays;
  final void Function(String mode, Set<int> workoutDays) onNext;

  @override
  State<Step15DistributionMode> createState() => _Step15DistributionModeState();
}

class _Step15DistributionModeState extends State<Step15DistributionMode> {
  late String _mode;
  late Set<int> _workoutDays;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _workoutDays = Set<int>.from(widget.initialWorkoutDays);
    if (_workoutDays.isEmpty) {
      _workoutDays = {1, 3, 5}; // Mon, Wed, Fri default
    }
  }

  static const List<Map<String, dynamic>> _days = [
    {'day': 1, 'label': 'Mon'},
    {'day': 2, 'label': 'Tue'},
    {'day': 3, 'label': 'Wed'},
    {'day': 4, 'label': 'Thu'},
    {'day': 5, 'label': 'Fri'},
    {'day': 6, 'label': 'Sat'},
    {'day': 7, 'label': 'Sun'},
  ];

  @override
  Widget build(BuildContext context) {
    final isShifted = _mode == 'shifted';

    return OnboardingStepScaffold(
      title: 'Calorie Distribution',
      subtitle:
          'How would you like your weekly calorie budget distributed across days?',
      icon: Icons.calendar_view_week_rounded,
      continueKey: const Key('step_15_continue_btn'),
      onContinue: () => widget.onNext(_mode, _workoutDays),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          AppleTactileCard(
            key: const Key('step_15_even_tile'),
            onTap: () => setState(() => _mode = 'even'),
            backgroundColor: !isShifted
                ? AppTheme.activeBlue.withValues(alpha: 0.12)
                : AppTheme.cardSurface,
            border: Border.all(
              color: !isShifted ? AppTheme.activeBlue : AppTheme.cardBorder,
              width: !isShifted ? 2 : 1,
            ),
            borderRadius: 16,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Even Allocation',
                        style: TextStyle(
                          fontFamily: 'MacroSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Identical target calories and macros every day of the week.',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isShifted)
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.activeBlue, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppleTactileCard(
            key: const Key('step_15_shifted_tile'),
            onTap: () => setState(() => _mode = 'shifted'),
            backgroundColor: isShifted
                ? AppTheme.carbs.withValues(alpha: 0.12)
                : AppTheme.cardSurface,
            border: Border.all(
              color: isShifted ? AppTheme.carbs : AppTheme.cardBorder,
              width: isShifted ? 2 : 1,
            ),
            borderRadius: 16,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shifted Workout Days',
                        style: TextStyle(
                          fontFamily: 'MacroSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Higher calories & carbohydrates on training days, lower on rest days.',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isShifted)
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.carbs, size: 20),
              ],
            ),
          ),
          if (isShifted) ...[
            const SizedBox(height: 24),
            const Text(
              'Select Your Training Days:',
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final d in _days) ...[
                  _DayChip(
                    label: d['label'] as String,
                    isSelected: _workoutDays.contains(d['day']),
                    onTap: () {
                      setState(() {
                        final dayInt = d['day'] as int;
                        if (_workoutDays.contains(dayInt)) {
                          if (_workoutDays.length > 1) {
                            _workoutDays.remove(dayInt);
                          }
                        } else {
                          _workoutDays.add(dayInt);
                        }
                      });
                    },
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.carbs : AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.carbs : AppTheme.cardBorder,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.black : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
