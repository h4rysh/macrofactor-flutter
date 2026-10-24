import 'package:flutter/material.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 10: Pacing / Weekly Rate of Weight Change (% bodyweight/week) with BMI >= 18.5 Guardrail
class Step10Pacing extends StatefulWidget {
  const Step10Pacing({
    super.key,
    required this.goalType,
    required this.currentWeightKg,
    required this.heightCm,
    required this.initialRatePct,
    required this.onNext,
  });

  final GoalType goalType;
  final double currentWeightKg;
  final double heightCm;
  final double initialRatePct;
  final ValueChanged<double> onNext;

  @override
  State<Step10Pacing> createState() => _Step10PacingState();
}

class _Step10PacingState extends State<Step10Pacing> {
  late double _ratePct;

  @override
  void initState() {
    super.initState();
    _ratePct = widget.initialRatePct;
    if (widget.goalType == GoalType.maintenance) {
      _ratePct = 0.0;
    } else if (widget.goalType == GoalType.fatLoss && _ratePct >= 0) {
      _ratePct = -0.5;
    } else if (widget.goalType == GoalType.muscleGain && _ratePct <= 0) {
      _ratePct = 0.25;
    }
  }

  double get _bmi {
    final heightM = widget.heightCm / 100.0;
    if (heightM <= 0) return 22.0;
    return widget.currentWeightKg / (heightM * heightM);
  }

  bool get _isUnderweight => _bmi < 18.5;

  bool get _isPacingAllowed {
    if (_isUnderweight &&
        widget.goalType == GoalType.fatLoss &&
        _ratePct < -0.25) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final weeklyKg =
        (widget.currentWeightKg * (_ratePct.abs() / 100.0)).toStringAsFixed(2);

    return OnboardingStepScaffold(
      title: 'Target Pacing',
      subtitle: widget.goalType == GoalType.maintenance
          ? 'Maintenance holds your weight stable while refining metabolic health.'
          : 'Choose your weekly rate of change. Moderate rates best protect lean muscle mass.',
      icon: Icons.speed_rounded,
      continueKey: const Key('step_10_continue_btn'),
      isContinueEnabled: _isPacingAllowed,
      onContinue: _isPacingAllowed ? () => widget.onNext(_ratePct) : null,
      banner: _isUnderweight && widget.goalType == GoalType.fatLoss
          ? Container(
              key: const Key('step_10_bmi_guardrail_banner'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: AppTheme.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your calculated BMI (${_bmi.toStringAsFixed(1)}) is in the underweight range (< 18.5). Rapid fat loss deficits are restricted for your safety.',
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 13,
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
      child: Column(
        children: [
          const SizedBox(height: 12),
          if (widget.goalType == GoalType.maintenance) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Text(
                    '0.0%',
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.activeBlue,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Weight Stability / Isocaloric Mode',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                children: [
                  Text(
                    '${_ratePct.abs().toStringAsFixed(2)}% / week',
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: widget.goalType == GoalType.fatLoss
                          ? AppTheme.calories
                          : AppTheme.expenditure,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '~ $weeklyKg kg per week',
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    key: const Key('step_10_pacing_slider'),
                    value: _ratePct.abs(),
                    min: 0.1,
                    max: 1.5,
                    divisions: 28,
                    activeColor: widget.goalType == GoalType.fatLoss
                        ? AppTheme.calories
                        : AppTheme.expenditure,
                    onChanged: (val) {
                      setState(() {
                        _ratePct =
                            widget.goalType == GoalType.fatLoss ? -val : val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _PacingPresetChip(
                  label: 'Conservative (0.25%)',
                  isSelected: (_ratePct.abs() - 0.25).abs() < 0.05,
                  onTap: () => setState(() => _ratePct =
                      widget.goalType == GoalType.fatLoss ? -0.25 : 0.25),
                ),
                const SizedBox(width: 8),
                _PacingPresetChip(
                  label: 'Standard (0.50%)',
                  isSelected: (_ratePct.abs() - 0.50).abs() < 0.05,
                  onTap: () => setState(() => _ratePct =
                      widget.goalType == GoalType.fatLoss ? -0.50 : 0.50),
                ),
                const SizedBox(width: 8),
                _PacingPresetChip(
                  label: 'Aggressive (0.75%)',
                  isSelected: (_ratePct.abs() - 0.75).abs() < 0.05,
                  onTap: () => setState(() => _ratePct =
                      widget.goalType == GoalType.fatLoss ? -0.75 : 0.75),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PacingPresetChip extends StatelessWidget {
  const _PacingPresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppleTactileCard(
        onTap: onTap,
        backgroundColor: isSelected
            ? AppTheme.activeBlue.withValues(alpha: 0.14)
            : AppTheme.cardSurface,
        border: Border.all(
          color: isSelected ? AppTheme.activeBlue : AppTheme.cardBorder,
        ),
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
