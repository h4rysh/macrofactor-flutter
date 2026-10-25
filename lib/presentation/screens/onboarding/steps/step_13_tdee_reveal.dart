import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 13: TDEE Reveal with Mifflin-St Jeor Breakdown & Athlete Override Control
class Step13TdeeReveal extends StatefulWidget {
  const Step13TdeeReveal({
    super.key,
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.isMale,
    required this.activityLevel,
    required this.exerciseFrequency,
    this.initialOverrideKcal,
    required this.onNext,
  });

  final double weightKg;
  final double heightCm;
  final int age;
  final bool isMale;
  final String activityLevel;
  final String exerciseFrequency;
  final double? initialOverrideKcal;
  final ValueChanged<double> onNext;

  @override
  State<Step13TdeeReveal> createState() => _Step13TdeeRevealState();
}

class _Step13TdeeRevealState extends State<Step13TdeeReveal> {
  bool _isExpanded = false;
  bool _isOverrideEnabled = false;
  late double _calculatedTdee;
  late double _currentTdee;
  late final TextEditingController _overrideController;

  @override
  void initState() {
    super.initState();
    _calculatedTdee = _computeTdee();
    if (widget.initialOverrideKcal != null &&
        widget.initialOverrideKcal! > 0 &&
        widget.initialOverrideKcal != _calculatedTdee) {
      _isOverrideEnabled = true;
      _currentTdee = widget.initialOverrideKcal!;
    } else {
      _currentTdee = _calculatedTdee;
    }
    _overrideController =
        TextEditingController(text: _currentTdee.round().toString());
  }

  double _computeTdee() {
    // 1. Mifflin-St Jeor Resting Metabolic Rate (BMR)
    final bmr = (10.0 * widget.weightKg) +
        (6.25 * widget.heightCm) -
        (5.0 * widget.age) +
        (widget.isMale ? 5.0 : -161.0);

    // 2. Daily NEAT activity multiplier
    double activityMult = 1.35;
    if (widget.activityLevel == 'sedentary') {
      activityMult = 1.20;
    } else if (widget.activityLevel == 'very_active') {
      activityMult = 1.55;
    }

    // 3. Exercise frequency adjustment
    double exerciseBoost = 0.0;
    if (widget.exerciseFrequency == '1-3') {
      exerciseBoost = 100.0;
    } else if (widget.exerciseFrequency == '4-6') {
      exerciseBoost = 220.0;
    } else if (widget.exerciseFrequency == '7+') {
      exerciseBoost = 350.0;
    }

    return (bmr * activityMult + exerciseBoost).roundToDouble();
  }

  @override
  void dispose() {
    _overrideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bmr = ((10.0 * widget.weightKg) +
            (6.25 * widget.heightCm) -
            (5.0 * widget.age) +
            (widget.isMale ? 5.0 : -161.0))
        .round();

    return OnboardingStepScaffold(
      title: 'Estimated Expenditure',
      subtitle:
          'Your initial Total Daily Energy Expenditure (TDEE). Sique will dynamically adapt this over time.',
      icon: Icons.local_fire_department_rounded,
      continueKey: const Key('step_13_continue_btn'),
      onContinue: () => widget.onNext(_currentTdee),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Hero Calories Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.calories.withValues(alpha: 0.15),
                  AppTheme.cardSurface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.calories.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'INITIAL DAILY TDEE',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.calories,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_currentTdee.round()}',
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'kcal / day',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Expandable "How this was calculated"
          AppleTactileCard(
            key: const Key('step_13_calculation_expandable'),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            backgroundColor: AppTheme.cardSurface,
            border: Border.all(color: AppTheme.cardBorder, width: 1),
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.calculate_outlined,
                        size: 20, color: AppTheme.activeBlue),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'How this was calculated',
                        style: TextStyle(
                          fontFamily: 'MacroSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppTheme.cardBorder),
                  const SizedBox(height: 12),
                  _CalcRow(
                    label: 'Resting BMR (Mifflin-St Jeor):',
                    value: '$bmr kcal',
                  ),
                  const SizedBox(height: 8),
                  _CalcRow(
                    label: 'Daily Activity Level:',
                    value: widget.activityLevel.toUpperCase(),
                  ),
                  const SizedBox(height: 8),
                  _CalcRow(
                    label: 'Weekly Workouts:',
                    value: '${widget.exerciseFrequency} / week',
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Note: This baseline serves only as the Kalman filter prior. As you log foods and weights, Sique mathematically discovers your true expenditure.',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Override Control Card
          AppleTactileCard(
            backgroundColor: AppTheme.cardSurface,
            border: Border.all(color: AppTheme.cardBorder, width: 1),
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune_rounded,
                        size: 20, color: AppTheme.expenditure),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Override Baseline TDEE',
                        style: TextStyle(
                          fontFamily: 'MacroSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      key: const Key('step_13_override_toggle'),
                      value: _isOverrideEnabled,
                      activeTrackColor: AppTheme.expenditure,
                      onChanged: (val) {
                        setState(() {
                          _isOverrideEnabled = val;
                          if (!val) {
                            _currentTdee = _calculatedTdee;
                            _overrideController.text =
                                _calculatedTdee.round().toString();
                          }
                        });
                      },
                    ),
                  ],
                ),
                if (_isOverrideEnabled) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('step_13_override_input'),
                    controller: _overrideController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Known Maintenance Calories (kcal)',
                      suffixText: 'kcal/day',
                      filled: true,
                      fillColor: AppTheme.cardElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed >= 800 && parsed <= 6000) {
                        setState(() => _currentTdee = parsed);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalcRow extends StatelessWidget {
  const _CalcRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
