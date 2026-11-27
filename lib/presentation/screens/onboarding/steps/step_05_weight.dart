import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 5: Current Weight with kg/lb Unit Toggle, Slider & Numeric Input
class Step05Weight extends StatefulWidget {
  const Step05Weight({
    super.key,
    required this.initialWeightKg,
    required this.onNext,
  });

  final double initialWeightKg;
  final ValueChanged<double> onNext;

  @override
  State<Step05Weight> createState() => _Step05WeightState();
}

class _Step05WeightState extends State<Step05Weight> {
  late double _weightKg;
  bool _isLbs = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _weightKg = widget.initialWeightKg;
    _controller =
        TextEditingController(text: _displayWeight.toStringAsFixed(1));
  }

  double get _displayWeight => _isLbs ? _weightKg * 2.20462 : _weightKg;

  void _updateFromDisplay(double val) {
    setState(() {
      _weightKg = (_isLbs ? val / 2.20462 : val).clamp(30.0, 350.0);
      _controller.text = _displayWeight.toStringAsFixed(1);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid => _weightKg >= 30 && _weightKg <= 350;

  @override
  Widget build(BuildContext context) {
    final minVal = _isLbs ? 66.0 : 30.0;
    final maxVal = _isLbs ? 770.0 : 350.0;

    return OnboardingStepScaffold(
      title: 'Current Weight',
      subtitle: 'Your initial benchmark to start smooth trend weight tracking.',
      icon: Icons.monitor_weight_outlined,
      continueKey: const Key('step_05_continue_btn'),
      isContinueEnabled: _isValid,
      onContinue: _isValid ? () => widget.onNext(_weightKg) : null,
      child: Column(
        children: [
          // Unit Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _UnitChip(
                key: const Key('step_05_unit_toggle_kg'),
                label: 'Kilograms (kg)',
                isSelected: !_isLbs,
                onTap: () {
                  if (_isLbs) {
                    setState(() {
                      _isLbs = false;
                      _controller.text = _displayWeight.toStringAsFixed(1);
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              _UnitChip(
                key: const Key('step_05_unit_toggle_lb'),
                label: 'Pounds (lbs)',
                isSelected: _isLbs,
                onTap: () {
                  if (!_isLbs) {
                    setState(() {
                      _isLbs = true;
                      _controller.text = _displayWeight.toStringAsFixed(1);
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const Key('step_05_decrement_btn'),
                tooltip: 'Decrease weight',
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 36),
                color: AppTheme.textSecondary,
                onPressed: () {
                  if (_weightKg > 30) {
                    setState(() {
                      _weightKg = (_weightKg - 0.5).clamp(30.0, 350.0);
                      _controller.text = _displayWeight.toStringAsFixed(1);
                    });
                  }
                },
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 160,
                child: TextFormField(
                  key: const Key('step_05_weight_input'),
                  controller: _controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
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
                      setState(() {
                        _weightKg = (_isLbs ? parsed / 2.20462 : parsed)
                            .clamp(30.0, 350.0);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                key: const Key('step_05_increment_btn'),
                tooltip: 'Increase weight',
                icon: const Icon(Icons.add_circle_outline_rounded, size: 36),
                color: AppTheme.textSecondary,
                onPressed: () {
                  if (_weightKg < 350) {
                    setState(() {
                      _weightKg = (_weightKg + 0.5).clamp(30.0, 350.0);
                      _controller.text = _displayWeight.toStringAsFixed(1);
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isLbs ? 'Pounds (lbs)' : 'Kilograms (kg)',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          // Interactive Slider
          Slider(
            key: const Key('step_05_weight_slider'),
            value: _displayWeight.clamp(minVal, maxVal),
            min: minVal,
            max: maxVal,
            activeColor: AppTheme.activeBlue,
            inactiveColor: AppTheme.cardBorder,
            onChanged: (val) => _updateFromDisplay(val),
          ),
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppleTactileCard(
      onTap: onTap,
      backgroundColor: isSelected
          ? AppTheme.activeBlue.withValues(alpha: 0.15)
          : AppTheme.cardSurface,
      border: Border.all(
        color: isSelected ? AppTheme.activeBlue : AppTheme.cardBorder,
        width: 1,
      ),
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppTheme.activeBlue : AppTheme.textSecondary,
        ),
      ),
    );
  }
}
