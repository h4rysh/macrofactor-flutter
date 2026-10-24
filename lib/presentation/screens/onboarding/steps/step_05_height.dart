import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Step 5: Height Input (cm)
class Step05Height extends StatefulWidget {
  const Step05Height({
    super.key,
    required this.initialHeightCm,
    required this.onNext,
  });

  final double initialHeightCm;
  final ValueChanged<double> onNext;

  @override
  State<Step05Height> createState() => _Step05HeightState();
}

class _Step05HeightState extends State<Step05Height> {
  late double _heightCm;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _heightCm = widget.initialHeightCm;
    _controller = TextEditingController(text: _heightCm.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid => _heightCm >= 90 && _heightCm <= 250;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'How tall are you?',
      subtitle:
          'Height is factored into BMI, body surface area, and baseline expenditure.',
      icon: Icons.height_rounded,
      continueKey: const Key('step_05_continue_btn'),
      isContinueEnabled: _isValid,
      onContinue: _isValid ? () => widget.onNext(_heightCm) : null,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const Key('step_05_decrement_btn'),
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 36),
                color: AppTheme.textSecondary,
                onPressed: () {
                  if (_heightCm > 90) {
                    setState(() {
                      _heightCm -= 1;
                      _controller.text = _heightCm.toStringAsFixed(0);
                    });
                  }
                },
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 140,
                child: TextFormField(
                  key: const Key('step_05_height_input'),
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
                      setState(() => _heightCm = parsed);
                    }
                  },
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                key: const Key('step_05_increment_btn'),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 36),
                color: AppTheme.textSecondary,
                onPressed: () {
                  if (_heightCm < 250) {
                    setState(() {
                      _heightCm += 1;
                      _controller.text = _heightCm.toStringAsFixed(0);
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'centimeters (cm)',
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
