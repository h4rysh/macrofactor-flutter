import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Step 8: Target Body Weight (kg)
class Step08TargetWeight extends StatefulWidget {
  const Step08TargetWeight({
    super.key,
    required this.initialTargetWeightKg,
    required this.onNext,
  });

  final double initialTargetWeightKg;
  final ValueChanged<double> onNext;

  @override
  State<Step08TargetWeight> createState() => _Step08TargetWeightState();
}

class _Step08TargetWeightState extends State<Step08TargetWeight> {
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

  bool get _isValid => _targetWeightKg >= 30 && _targetWeightKg <= 350;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Target Weight',
      subtitle:
          'What is your ultimate goal weight? We will calculate an optimal, safe pacing trajectory.',
      icon: Icons.flag_outlined,
      continueKey: const Key('step_08_continue_btn'),
      isContinueEnabled: _isValid,
      onContinue: _isValid ? () => widget.onNext(_targetWeightKg) : null,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const Key('step_08_decrement_btn'),
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
                  key: const Key('step_08_target_weight_input'),
                  controller: _controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
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
                key: const Key('step_08_increment_btn'),
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
          const SizedBox(height: 8),
          const Text(
            'kilograms (kg)',
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 16,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
