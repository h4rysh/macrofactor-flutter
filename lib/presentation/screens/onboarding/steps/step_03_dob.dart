import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/domain/validation/domain_validator.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/utils/unit_formatter.dart';

/// Step 3: Date of Birth & Age Input with Dynamic Clock and Strict 18+ Lock
class Step03Dob extends ConsumerStatefulWidget {
  const Step03Dob({
    super.key,
    required this.initialAge,
    required this.onNext,
    this.initialDob,
    this.onDobSelected,
  });

  final int initialAge;
  final ValueChanged<int> onNext;
  final DateTime? initialDob;
  final ValueChanged<DateTime>? onDobSelected;

  @override
  ConsumerState<Step03Dob> createState() => _Step03DobState();
}

class _Step03DobState extends ConsumerState<Step03Dob> {
  late int _age;
  late DateTime _dob;
  late final TextEditingController _controller;
  late final TextEditingController _dobController;

  @override
  void initState() {
    super.initState();
    _age = widget.initialAge;
    final now = DateTime.now();
    _dob = widget.initialDob ??
        DateTime(now.year - widget.initialAge, now.month, now.day);
    _controller = TextEditingController(text: _age.toString());
    _dobController =
        TextEditingController(text: UnitFormatter.formatDateDdMmYyyy(_dob));
  }

  @override
  void dispose() {
    _controller.dispose();
    _dobController.dispose();
    super.dispose();
  }

  DateTime _getCurrentTime() {
    try {
      return ref.read(clockProvider)();
    } catch (_) {
      return DateTime.now();
    }
  }

  bool get _isAdult => DomainValidator.isAdult(_age);

  void _onDobChanged(String text) {
    final parsed = UnitFormatter.parseDateDdMmYyyy(text);
    if (parsed != null) {
      final now = _getCurrentTime();
      final calculatedAge = DomainValidator.calculateAge(parsed, now);
      setState(() {
        _dob = parsed;
        _age = calculatedAge;
        _controller.text = _age.toString();
      });
      widget.onDobSelected?.call(parsed);
    }
  }

  Future<void> _pickDate() async {
    final now = _getCurrentTime();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob.isBefore(now) ? _dob : now,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.activeBlue,
              onPrimary: Colors.white,
              surface: AppTheme.cardSurface,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      final calculatedAge = DomainValidator.calculateAge(picked, now);
      setState(() {
        _dob = picked;
        _age = calculatedAge;
        _dobController.text = UnitFormatter.formatDateDdMmYyyy(picked);
        _controller.text = _age.toString();
      });
      widget.onDobSelected?.call(picked);
    }
  }

  void _updateAge(int newAge) {
    final now = _getCurrentTime();
    setState(() {
      _age = newAge;
      _controller.text = _age.toString();
      _dob = DateTime(now.year - _age, _dob.month, _dob.day);
      _dobController.text = UnitFormatter.formatDateDdMmYyyy(_dob);
    });
    widget.onDobSelected?.call(_dob);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'How old are you?',
      subtitle:
          'Metabolic expenditure and daily calorie targets shift predictably with biological age.',
      icon: Icons.cake_outlined,
      continueKey: const Key('step_03_continue_btn'),
      isContinueEnabled: _isAdult,
      onContinue: _isAdult ? () => widget.onNext(_age) : null,
      banner: !_isAdult
          ? Container(
              key: const Key('step_03_age_guardrail_banner'),
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
          const SizedBox(height: 16),
          // Age increment / decrement and input row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const Key('step_03_decrement_btn'),
                tooltip: 'Decrease age',
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 36),
                color: AppTheme.textSecondary,
                onPressed: () {
                  if (_age > 10) {
                    _updateAge(_age - 1);
                  }
                },
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 100,
                child: TextFormField(
                  key: const Key('step_03_age_input'),
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: _isAdult ? AppTheme.textPrimary : AppTheme.calories,
                  ),
                  decoration: const InputDecoration(border: InputBorder.none),
                  onChanged: (val) {
                    final parsed = int.tryParse(val);
                    if (parsed != null) {
                      _updateAge(parsed);
                    }
                  },
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                key: const Key('step_03_increment_btn'),
                tooltip: 'Increase age',
                icon: const Icon(Icons.add_circle_outline_rounded, size: 36),
                color: AppTheme.textSecondary,
                onPressed: () {
                  if (_age < 110) {
                    _updateAge(_age + 1);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Years Old',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),

          // Date of Birth input (dd/MM/yyyy)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                IconButton(
                  key: const Key('step_03_dob_picker_btn'),
                  tooltip: 'Select date of birth',
                  icon: const Icon(Icons.calendar_month_rounded,
                      color: AppTheme.activeBlue, size: 22),
                  onPressed: _pickDate,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DATE OF BIRTH (DD/MM/YYYY)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TextFormField(
                        key: const Key('step_03_dob_input'),
                        controller: _dobController,
                        keyboardType: TextInputType.datetime,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'DD/MM/YYYY',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: _onDobChanged,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
