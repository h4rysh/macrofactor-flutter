import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Step 15: Target Body Weight with BMI >= 18.5 Clinical Guardrail
class Step15TargetWeight extends StatefulWidget {
  const Step15TargetWeight({
    super.key,
    required this.goalType,
    required this.currentWeightKg,
    required this.heightCm,
    required this.initialTargetWeightKg,
    required this.onNext,
  });

  final GoalType goalType;
  final double currentWeightKg;
  final double heightCm;
  final double initialTargetWeightKg;
  final ValueChanged<double> onNext;

  @override
  State<Step15TargetWeight> createState() => _Step15TargetWeightState();
}

class _Step15TargetWeightState extends State<Step15TargetWeight> {
  late double _targetWeightKg;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _targetWeightKg = widget.initialTargetWeightKg;
    _controller =
        TextEditingController(text: _targetWeightKg.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _targetBmi {
    final heightM = widget.heightCm / 100.0;
    if (heightM <= 0) return 22.0;
    return _targetWeightKg / (heightM * heightM);
  }

  double get _minSafeWeightKg {
    final heightM = widget.heightCm / 100.0;
    return 18.5 * (heightM * heightM);
  }

  bool get _isBmiViolation =>
      widget.goalType == GoalType.fatLoss && _targetBmi < 18.5;

  bool get _isValid =>
      _targetWeightKg >= 30 && _targetWeightKg <= 350 && !_isBmiViolation;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Target Weight',
      subtitle:
          'Set your desired goal weight to establish your milestone pacing timeline.',
      icon: Icons.flag_rounded,
      continueKey: const Key('step_15_continue_btn'),
      isContinueEnabled: _isValid,
      onContinue: _isValid ? () => widget.onNext(_targetWeightKg) : null,
      banner: _isBmiViolation
          ? Container(
              key: const Key('step_15_bmi_guardrail_banner'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.calories.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.calories.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: AppTheme.calories, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Target weight ${_targetWeightKg.toStringAsFixed(1)} kg places BMI (${_targetBmi.toStringAsFixed(1)}) in the clinical underweight range (< 18.5). Safe minimum target is ${_minSafeWeightKg.toStringAsFixed(1)} kg.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.calories,
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
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const Key('step_15_decrement_btn'),
                tooltip: 'Decrease target weight',
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 36),
                color: AppTheme.textSecondary,
                onPressed: () {
                  if (_targetWeightKg > 30) {
                    setState(() {
                      _targetWeightKg -= 0.5;
                      _controller.text = _targetWeightKg.toStringAsFixed(1);
                    });
                  }
                },
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 160,
                child: TextFormField(
                  key: const Key('step_15_target_weight_input'),
                  controller: _controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: _isBmiViolation
                        ? AppTheme.calories
                        : AppTheme.textPrimary,
                  ),
                  decoration: const InputDecoration(border: InputBorder.none),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null) {
                      setState(() => _targetWeightKg = parsed);
                    }
                  },
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                key: const Key('step_15_increment_btn'),
                tooltip: 'Increase target weight',
                icon: const Icon(Icons.add_circle_outline_rounded, size: 36),
                color: AppTheme.textSecondary,
                onPressed: () {
                  if (_targetWeightKg < 350) {
                    setState(() {
                      _targetWeightKg += 0.5;
                      _controller.text = _targetWeightKg.toStringAsFixed(1);
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Target BMI: ${_targetBmi.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 14,
              color: _isBmiViolation ? AppTheme.calories : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
