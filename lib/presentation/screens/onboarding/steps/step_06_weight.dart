import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Step 6: Current Body Weight (kg)
class Step06Weight extends StatefulWidget {
  const Step06Weight({
    super.key,
    required this.initialWeightKg,
    required this.onNext,
  });

  final double initialWeightKg;
  final ValueChanged<double> onNext;

  @override
  State<Step06Weight> createState() => _Step06WeightState();
}

class _Step06WeightState extends State<Step06Weight> {
  late double _weightKg;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _weightKg = widget.initialWeightKg;
    _controller = TextEditingController(text: _weightKg.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid => _weightKg >= 30 && _weightKg <= 350;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Current Weight',
      subtitle: 'Your starting benchmark for Kalman trend weight estimation.',
      icon: Icons.monitor_weight_outlined,
      continueKey: const Key('step_06_continue_btn'),
      isContinueEnabled: _isValid,
      onContinue: _isValid ? () => widget.onNext(_weightKg) : null,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const Key('step_06_decrement_btn'),
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 36),
                color: AppTheme.textSecondary,
                onPressed: () {
                  if (_weightKg > 30) {
                    setState(() {
                      _weightKg -= 0.5;
                      _controller.text = _weightKg.toStringAsFixed(1);
                    });
                  }
                },
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 160,
                child: TextFormField(
                  key: const Key('step_06_weight_input'),
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
                      setState(() => _weightKg = parsed);
                    }
                  },
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                key: const Key('step_06_increment_btn'),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 36),
                color: AppTheme.textSecondary,
                onPressed: () {
                  if (_weightKg < 350) {
                    setState(() {
                      _weightKg += 0.5;
                      _controller.text = _weightKg.toStringAsFixed(1);
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
