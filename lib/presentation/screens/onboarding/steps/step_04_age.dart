import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Step 4: Age Input with 18+ Guardrail
class Step04Age extends StatefulWidget {
  const Step04Age({
    super.key,
    required this.initialAge,
    required this.onNext,
  });

  final int initialAge;
  final ValueChanged<int> onNext;

  @override
  State<Step04Age> createState() => _Step04AgeState();
}

class _Step04AgeState extends State<Step04Age> {
  late int _age;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _age = widget.initialAge;
    _controller = TextEditingController(text: _age.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isAdult => _age >= 18;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'How old are you?',
      subtitle: 'Metabolic expenditure shifts predictably with biological age.',
      icon: Icons.cake_outlined,
      continueKey: const Key('step_04_continue_btn'),
      isContinueEnabled: _isAdult,
      onContinue: _isAdult ? () => widget.onNext(_age) : null,
      banner: !_isAdult
          ? Container(
              key: const Key('step_04_age_guardrail_banner'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.calories.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.calories.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: AppTheme.calories, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sique algorithms and nutritional coaching are designed for adults 18 and older.',
                      style: TextStyle(
                        fontFamily: 'DMSans',
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
                key: const Key('step_04_decrement_btn'),
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 36),
                color: AppTheme.textSecondary,
                onPressed: () {
                  if (_age > 10) {
                    setState(() {
                      _age--;
                      _controller.text = _age.toString();
                    });
                  }
                },
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 100,
                child: TextFormField(
                  key: const Key('step_04_age_input'),
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: const InputDecoration(border: InputBorder.none),
                  onChanged: (val) {
                    final parsed = int.tryParse(val);
                    if (parsed != null) {
                      setState(() => _age = parsed);
                    }
                  },
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                key: const Key('step_04_increment_btn'),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 36),
                color: AppTheme.textSecondary,
                onPressed: () {
                  if (_age < 120) {
                    setState(() {
                      _age++;
                      _controller.text = _age.toString();
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'years old',
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
