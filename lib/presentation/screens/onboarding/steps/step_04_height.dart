import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 4: Height Input with Metric (cm) and Imperial (ft-in) Toggle
class Step04Height extends StatefulWidget {
  const Step04Height({
    super.key,
    required this.initialHeightCm,
    required this.onNext,
  });

  final double initialHeightCm;
  final ValueChanged<double> onNext;

  @override
  State<Step04Height> createState() => _Step04HeightState();
}

class _Step04HeightState extends State<Step04Height> {
  late double _heightCm;
  bool _isImperial = false; // false = cm, true = ft-in
  late final TextEditingController _cmController;
  late final TextEditingController _ftController;
  late final TextEditingController _inController;

  @override
  void initState() {
    super.initState();
    _heightCm = widget.initialHeightCm;
    _cmController = TextEditingController(text: _heightCm.toStringAsFixed(0));
    final totalInches = (_heightCm / 2.54).round();
    _ftController = TextEditingController(text: (totalInches ~/ 12).toString());
    _inController = TextEditingController(text: (totalInches % 12).toString());
  }

  void _syncImperialFromCm() {
    final totalInches = (_heightCm / 2.54).round();
    final ft = totalInches ~/ 12;
    final inches = totalInches % 12;
    _ftController.text = ft.toString();
    _inController.text = inches.toString();
  }

  void _updateFromImperial() {
    final ft = int.tryParse(_ftController.text) ?? 5;
    final inches = int.tryParse(_inController.text) ?? 9;
    final totalInches = (ft * 12) + inches;
    setState(() {
      _heightCm = (totalInches * 2.54).clamp(90.0, 250.0);
      _cmController.text = _heightCm.toStringAsFixed(0);
    });
  }

  @override
  void dispose() {
    _cmController.dispose();
    _ftController.dispose();
    _inController.dispose();
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
      continueKey: const Key('step_04_continue_btn'),
      isContinueEnabled: _isValid,
      onContinue: _isValid ? () => widget.onNext(_heightCm) : null,
      child: Column(
        children: [
          // Unit Toggle
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _UnitToggleChip(
                key: const Key('step_04_unit_toggle_cm'),
                label: 'Centimeters (cm)',
                isSelected: !_isImperial,
                onTap: () {
                  setState(() {
                    _isImperial = false;
                    _cmController.text = _heightCm.toStringAsFixed(0);
                  });
                },
              ),
              _UnitToggleChip(
                key: const Key('step_04_unit_toggle_ft'),
                label: 'Feet & Inches (ft/in)',
                isSelected: _isImperial,
                onTap: () {
                  setState(() {
                    _isImperial = true;
                    _syncImperialFromCm();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (!_isImperial)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  key: const Key('step_04_decrement_btn'),
                  icon:
                      const Icon(Icons.remove_circle_outline_rounded, size: 36),
                  color: AppTheme.textSecondary,
                  onPressed: () {
                    if (_heightCm > 90) {
                      setState(() {
                        _heightCm -= 1;
                        _cmController.text = _heightCm.toStringAsFixed(0);
                        _syncImperialFromCm();
                      });
                    }
                  },
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    key: const Key('step_04_height_input'),
                    controller: _cmController,
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
                        setState(() {
                          _heightCm = parsed;
                          _syncImperialFromCm();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  key: const Key('step_04_increment_btn'),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 36),
                  color: AppTheme.textSecondary,
                  onPressed: () {
                    if (_heightCm < 250) {
                      setState(() {
                        _heightCm += 1;
                        _cmController.text = _heightCm.toStringAsFixed(0);
                        _syncImperialFromCm();
                      });
                    }
                  },
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    key: const Key('step_04_feet_input'),
                    controller: _ftController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      suffixText: 'ft',
                      suffixStyle: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    onChanged: (_) => _updateFromImperial(),
                  ),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    key: const Key('step_04_inches_input'),
                    controller: _inController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      suffixText: 'in',
                      suffixStyle: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    onChanged: (_) => _updateFromImperial(),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 4),
          Text(
            _isImperial ? 'Imperial Height' : 'Centimeters (cm)',
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitToggleChip extends StatelessWidget {
  const _UnitToggleChip({
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
          fontFamily: 'DMSans',
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppTheme.activeBlue : AppTheme.textSecondary,
        ),
      ),
    );
  }
}
