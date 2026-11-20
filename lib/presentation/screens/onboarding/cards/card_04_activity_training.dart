import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';
import 'package:sique/presentation/widgets/sique_frosted_chrome.dart';

/// Card 4: Activity & Training (Daily activity + weekly workouts; reveals training days inline only if workouts > 0).
class Card04ActivityTraining extends StatefulWidget {
  const Card04ActivityTraining({
    super.key,
    required this.initialActivity,
    required this.initialWorkoutDays,
    required this.onActivityTrainingChanged,
    required this.onNext,
  });

  final String initialActivity;
  final Set<int> initialWorkoutDays;
  final void Function({
    required String dailyActivity,
    required Set<int> workoutDays,
  }) onActivityTrainingChanged;
  final VoidCallback onNext;

  @override
  State<Card04ActivityTraining> createState() => _Card04ActivityTrainingState();
}

class _Card04ActivityTrainingState extends State<Card04ActivityTraining> {
  late String _dailyActivity;
  late int _workoutCount;
  late Set<int> _workoutDays;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _dailyActivity = widget.initialActivity;
    _workoutDays = Set<int>.from(widget.initialWorkoutDays);
    _workoutCount = _workoutDays.length;
  }

  void _notifyUpdate() {
    widget.onActivityTrainingChanged(
      dailyActivity: _dailyActivity,
      workoutDays: _workoutCount > 0 ? _workoutDays : <int>{},
    );
  }

  void _setWorkoutCount(int count) {
    setState(() {
      _workoutCount = count;
      if (count == 0) {
        _workoutDays.clear();
      } else {
        // Preset canonical days if empty
        if (_workoutDays.isEmpty) {
          if (count == 3) {
            _workoutDays = {1, 3, 5}; // Mon, Wed, Fri
          } else if (count == 4) {
            _workoutDays = {1, 2, 4, 5};
          } else if (count == 5) {
            _workoutDays = {1, 2, 3, 4, 5};
          } else {
            _workoutDays = List.generate(count, (i) => i + 1).toSet();
          }
        } else if (_workoutDays.length > count) {
          _workoutDays = _workoutDays.take(count).toSet();
        } else if (_workoutDays.length < count) {
          for (var i = 1; i <= 7; i++) {
            if (!_workoutDays.contains(i)) {
              _workoutDays.add(i);
              if (_workoutDays.length == count) break;
            }
          }
        }
      }
    });
    _notifyUpdate();
  }

  void _toggleDay(int day) {
    setState(() {
      if (_workoutDays.contains(day)) {
        if (_workoutDays.length > 1) {
          _workoutDays.remove(day);
          _workoutCount = _workoutDays.length;
        }
      } else {
        _workoutDays.add(day);
        _workoutCount = _workoutDays.length;
      }
    });
    _notifyUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              const Text(
                'EXPENDITURE PRIORS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.activeBlue,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Activity & Training Schedule',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your baseline movement and resistance workouts seed the Bayesian expenditure filter.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Section 1: Daily Activity (NEAT)
              const Text('Daily Baseline Activity (Non-Exercise)',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              _buildActivityOption(
                slug: 'sedentary',
                title: 'Sedentary',
                subtitle:
                    'Desk work, seated commute, minimal daily step count (~1.20x BMR)',
                icon: Icons.chair_rounded,
              ),
              const SizedBox(height: 8),
              _buildActivityOption(
                slug: 'light',
                title: 'Lightly Active',
                subtitle:
                    'Light walking, casual movement, 5,000–7,000 steps (~1.35x BMR)',
                icon: Icons.directions_walk_rounded,
              ),
              const SizedBox(height: 8),
              _buildActivityOption(
                slug: 'moderate',
                title: 'Moderately Active',
                subtitle:
                    'On your feet regularly, active job, 8,000–12,000 steps (~1.50x BMR)',
                icon: Icons.directions_run_rounded,
              ),
              const SizedBox(height: 8),
              _buildActivityOption(
                slug: 'very_active',
                title: 'Very Active',
                subtitle:
                    'Physically demanding labor, high daily volume (>12,000 steps, ~1.70x BMR)',
                icon: Icons.bolt_rounded,
              ),
              const SizedBox(height: 22),

              // Section 2: Weekly Workouts
              const Text('Weekly Training Frequency',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Weekly Workouts',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary)),
                        Flexible(
                          child: Text(
                            _workoutCount == 0
                                ? '0 days (Rest only)'
                                : '$_workoutCount ${_workoutCount == 1 ? "day" : "days"} / week',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.activeBlue,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Quick count selector 0..7
                    Row(
                      children: List.generate(8, (i) {
                        final isSelected = _workoutCount == i;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: i == 0 ? 0 : 2,
                              right: i == 7 ? 0 : 2,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _setWorkoutCount(i);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.activeBlue
                                      : AppTheme.cardElevated,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.activeBlue
                                        : AppTheme.cardBorder,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$i',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    // Inline Training Days Selector: ONLY REVEALED IF WORKOUTS > 0
                    if (_workoutCount > 0) ...[
                      const SizedBox(height: 16),
                      const Divider(color: AppTheme.cardBorder, height: 1),
                      const SizedBox(height: 14),
                      const Text(
                        'Select Training Days',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(7, (idx) {
                          final dayNum = idx + 1; // 1 = Mon, 7 = Sun
                          final isTraining = _workoutDays.contains(dayNum);
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: idx == 0 ? 0 : 2,
                                right: idx == 6 ? 0 : 2,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  _toggleDay(dayNum);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isTraining
                                        ? AppTheme.activeBlue
                                            .withValues(alpha: 0.18)
                                        : AppTheme.cardElevated,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isTraining
                                          ? AppTheme.activeBlue
                                          : AppTheme.cardBorder,
                                      width: isTraining ? 1.5 : 1.0,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _dayNames[idx],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isTraining
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isTraining
                                          ? AppTheme.activeBlue
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
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
                  key: const Key('onboarding_card_4_continue_btn'),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _notifyUpdate();
                    widget.onNext();
                  },
                  backgroundColor: const Color(0xFFFAFAFA),
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Center(
                    child: Text(
                      'Continue to nutrition preferences',
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

  Widget _buildActivityOption({
    required String slug,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _dailyActivity == slug;

    return AppleBouncy(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _dailyActivity = slug);
        _notifyUpdate();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.activeBlue.withValues(alpha: 0.12)
              : AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.activeBlue : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.activeBlue.withValues(alpha: 0.25)
                    : AppTheme.cardElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color:
                    isSelected ? AppTheme.activeBlue : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
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
                          ? AppTheme.activeBlue
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.25,
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
      ),
    );
  }
}
