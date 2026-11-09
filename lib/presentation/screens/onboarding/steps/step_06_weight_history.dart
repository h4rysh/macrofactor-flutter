import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Step 6: Highest Historical Weight (Weight History)
class Step06WeightHistory extends StatefulWidget {
  const Step06WeightHistory({
    super.key,
    required this.currentWeightKg,
    required this.initialMaxWeightKg,
    required this.onNext,
  });

  final double currentWeightKg;
  final double initialMaxWeightKg;
  final ValueChanged<double> onNext;

  @override
  State<Step06WeightHistory> createState() => _Step06WeightHistoryState();
}

class _Step06WeightHistoryState extends State<Step06WeightHistory> {
  late double _maxWeightKg;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _maxWeightKg = widget.initialMaxWeightKg >= widget.currentWeightKg
        ? widget.initialMaxWeightKg
        : widget.currentWeightKg;
    _controller = TextEditingController(text: _maxWeightKg.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid => _maxWeightKg >= widget.currentWeightKg;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Highest Adult Weight',
      subtitle:
          'Informs set-point theory models and post-diet metabolic adaptation expectations.',
      icon: Icons.history_rounded,
      continueKey: const Key('step_06_continue_btn'),
      isContinueEnabled: _isValid,
      onContinue: _isValid ? () => widget.onNext(_maxWeightKg) : null,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const Key('step_06_decrement_btn'),
                tooltip: 'Decrease weight',
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 36),
                color: AppTheme.textSecondary,
                onPressed: () {
                  if (_maxWeightKg > widget.currentWeightKg) {
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
                  key: const Key('step_06_max_weight_input'),
                  controller: _controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
                key: const Key('step_06_increment_btn'),
                tooltip: 'Increase weight',
                icon: const Icon(Icons.add_circle_outline_rounded, size: 36),
                color: AppTheme.textSecondary,
                onPressed: () {
                  if (_maxWeightKg < 400) {
                    setState(() {
                      _maxWeightKg += 0.5;
                      _controller.text = _maxWeightKg.toStringAsFixed(1);
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Kilograms (kg)',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
