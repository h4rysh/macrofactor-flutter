import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Step 7: Weight History Max (Highest adult weight)
class Step07WeightHistoryMax extends StatefulWidget {
  const Step07WeightHistoryMax({
    super.key,
    required this.currentWeightKg,
    this.initialMaxWeightKg,
    required this.onNext,
  });

  final double currentWeightKg;
  final double? initialMaxWeightKg;
  final ValueChanged<double> onNext;

  @override
  State<Step07WeightHistoryMax> createState() => _Step07WeightHistoryMaxState();
}

class _Step07WeightHistoryMaxState extends State<Step07WeightHistoryMax> {
  late double _maxWeightKg;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _maxWeightKg = widget.initialMaxWeightKg ?? widget.currentWeightKg;
    _controller = TextEditingController(text: _maxWeightKg.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid => _maxWeightKg >= 30 && _maxWeightKg <= 350;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Highest Weight',
      subtitle:
          'What was your highest body weight achieved as an adult? Helps calibrate metabolic rate history.',
      icon: Icons.history_rounded,
      continueKey: const Key('step_07_continue_btn'),
      isContinueEnabled: _isValid,
      onContinue: _isValid ? () => widget.onNext(_maxWeightKg) : null,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const Key('step_07_decrement_btn'),
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 36),
                color: AppTheme.textSecondary,
                onPressed: () {
                  if (_maxWeightKg > 30) {
                    setState(() {
                      _maxWeightKg -= 0.5;
                      _controller.text = _maxWeightKg.toStringAsFixed(1);
                    });
                  }
                },
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 160,
                child: TextFormField(
                  key: const Key('step_07_max_weight_input'),
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
                      setState(() => _maxWeightKg = parsed);
                    }
                  },
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                key: const Key('step_07_increment_btn'),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 36),
                color: AppTheme.textSecondary,
                onPressed: () {
                  if (_maxWeightKg < 350) {
                    setState(() {
                      _maxWeightKg += 0.5;
                      _controller.text = _maxWeightKg.toStringAsFixed(1);
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
