import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';
import 'package:sique/presentation/widgets/sique_frosted_chrome.dart';

/// Card 2: Biometrics (Sex, DOB via date picker, Height, Weight with metric/imperial toggle).
class Card02Biometrics extends StatefulWidget {
  const Card02Biometrics({
    super.key,
    required this.initialIsMale,
    required this.initialAge,
    required this.initialHeightCm,
    required this.initialWeightKg,
    required this.onBiometricsChanged,
    required this.onNext,
  });

  final bool initialIsMale;
  final int initialAge;
  final double initialHeightCm;
  final double initialWeightKg;
  final void Function({
    required bool isMale,
    required int age,
    required double heightCm,
    required double weightKg,
  }) onBiometricsChanged;
  final VoidCallback onNext;

  @override
  State<Card02Biometrics> createState() => _Card02BiometricsState();
}

class _Card02BiometricsState extends State<Card02Biometrics> {
  late bool _isMale;
  late int _age;
  late double _heightCm;
  late double _weightKg;

  late DateTime _dob;
  bool _heightInCm = true;
  bool _weightInKg = true;

  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _feetController;
  late TextEditingController _inchesController;

  @override
  void initState() {
    super.initState();
    _isMale = widget.initialIsMale;
    _age = widget.initialAge;
    _heightCm = widget.initialHeightCm;
    _weightKg = widget.initialWeightKg;

    final now = DateTime.now();
    _dob = DateTime(now.year - _age, now.month, now.day);

    _heightController =
        TextEditingController(text: _heightCm.toStringAsFixed(0));
    _weightController =
        TextEditingController(text: _weightKg.toStringAsFixed(1));

    final totalInches = _heightCm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();
    _feetController = TextEditingController(text: feet.toString());
    _inchesController = TextEditingController(text: inches.toString());
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  int _calculateAgeFromDob(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  void _notifyUpdate() {
    widget.onBiometricsChanged(
      isMale: _isMale,
      age: _age,
      heightCm: _heightCm,
      weightKg: _weightKg,
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob,
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.activeBlue,
              surface: AppTheme.cardSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dob = picked;
        _age = _calculateAgeFromDob(picked);
      });
      _notifyUpdate();
    }
  }

  bool get _isAdult => _age >= 18;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              const Text(
                'BIOMETRIC PROFILE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.activeBlue,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your Physical Foundation',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Used to compute your resting metabolic baseline (Mifflin-St Jeor).',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Section A: Biological Sex
              const Text('Biological Sex',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSexChip(
                      label: 'Male',
                      isMaleOption: true,
                      key: const Key('card_02_sex_male'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSexChip(
                      label: 'Female',
                      isMaleOption: false,
                      key: const Key('card_02_sex_female'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Section B: Date of Birth & Age (with 18+ guardrail)
              const Text('Date of Birth & Age',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: AppRadii.lgBorderRadius,
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_age years old',
                          key: const Key('step_03_age_display'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_dob),
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      key: const Key('card_02_dob_picker_btn'),
                      onPressed: _pickDob,
                      icon: const Icon(Icons.calendar_today_rounded, size: 14),
                      label: const Text('Change Date'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.activeBlue,
                        side: const BorderSide(color: AppTheme.cardBorder),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadii.mdBorderRadius),
                      ),
                    ),
                  ],
                ),
              ),

              // Adult 18+ Lock Banner
              if (!_isAdult) ...[
                const SizedBox(height: 10),
                Container(
                  key: const Key('step_03_age_guardrail_banner'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.calories.withValues(alpha: 0.12),
                    borderRadius: AppRadii.mdBorderRadius,
                    border: Border.all(
                      color: AppTheme.calories.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          color: AppTheme.calories, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sique is designed for adults 18 and older. Metabolic algorithms require adult physiological baseline.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.calories,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // Section C: Height (Metric / Imperial Toggle)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Height',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary)),
                  _buildUnitToggle(
                    isFirst: _heightInCm,
                    firstLabel: 'cm',
                    secondLabel: 'ft/in',
                    firstKey: const Key('step_04_unit_toggle_cm'),
                    secondKey: const Key('step_04_unit_toggle_ft'),
                    onToggle: (first) => setState(() => _heightInCm = first),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildHeightInput(),
              const SizedBox(height: 18),

              // Section D: Current Weight (Metric / Imperial Toggle)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Current Weight',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary)),
                  _buildUnitToggle(
                    isFirst: _weightInKg,
                    firstLabel: 'kg',
                    secondLabel: 'lb',
                    firstKey: const Key('step_05_unit_toggle_kg'),
                    secondKey: const Key('step_05_unit_toggle_lb'),
                    onToggle: (first) => setState(() => _weightInKg = first),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildWeightInput(),
              const SizedBox(height: 16),
            ],
          ),
        ),
        // Pinned sticky bottom CTA bar: guaranteed visible without scrolling
        SiqueFrostedChrome(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: SizedBox(
                width: double.infinity,
                child: AppleTactileCard(
                  key: const Key('onboarding_card_2_continue_btn'),
                  onTap: _isAdult
                      ? () {
                          AppHaptics.lightImpact();
                          _notifyUpdate();
                          widget.onNext();
                        }
                      : null,
                  backgroundColor: _isAdult
                      ? AppTheme.buttonBackground
                      : AppTheme.cardElevated,
                  borderRadius: AppRadii.lg,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      _isAdult ? 'Continue to pacing' : 'Age 18+ Required',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color:
                            _isAdult ? AppTheme.buttonText : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSexChip({
    required String label,
    required bool isMaleOption,
    required Key key,
  }) {
    final isSelected = _isMale == isMaleOption;
    return GestureDetector(
      key: key,
      onTap: () {
        AppHaptics.selectionClick();
        setState(() => _isMale = isMaleOption);
        _notifyUpdate();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.activeBlue.withValues(alpha: 0.15)
              : AppTheme.cardSurface,
          borderRadius: AppRadii.lgBorderRadius,
          border: Border.all(
            color: isSelected ? AppTheme.activeBlue : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isMaleOption ? Icons.male_rounded : Icons.female_rounded,
              size: 20,
              color: isSelected ? AppTheme.activeBlue : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.activeBlue : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitToggle({
    required bool isFirst,
    required String firstLabel,
    required String secondLabel,
    required Key firstKey,
    required Key secondKey,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            key: firstKey,
            onTap: () {
              AppHaptics.selectionClick();
              onToggle(true);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isFirst ? AppTheme.activeBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(firstLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isFirst ? Colors.white : AppTheme.textSecondary)),
            ),
          ),
          GestureDetector(
            key: secondKey,
            onTap: () {
              AppHaptics.selectionClick();
              onToggle(false);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: !isFirst ? AppTheme.activeBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(secondLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: !isFirst ? Colors.white : AppTheme.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: AppRadii.lgBorderRadius,
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: _heightInCm
          ? Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('step_04_height_input'),
                    controller: _heightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: false),
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()]),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '175',
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed >= 100 && parsed <= 250) {
                        _heightCm = parsed;
                        _notifyUpdate();
                      }
                    },
                  ),
                ),
                const Text('cm',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary)),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('step_04_feet_input'),
                    controller: _feetController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()]),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '5',
                    ),
                    onChanged: (val) => _updateHeightFromFtIn(),
                  ),
                ),
                const Text('ft',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary)),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    key: const Key('step_04_inches_input'),
                    controller: _inchesController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()]),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '9',
                    ),
                    onChanged: (val) => _updateHeightFromFtIn(),
                  ),
                ),
                const Text('in',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary)),
              ],
            ),
    );
  }

  void _updateHeightFromFtIn() {
    final ft = double.tryParse(_feetController.text) ?? 5.0;
    final inch = double.tryParse(_inchesController.text) ?? 0.0;
    final totalInches = (ft * 12.0) + inch;
    final cm = (totalInches * 2.54).clamp(100.0, 250.0);
    setState(() => _heightCm = cm);
    _notifyUpdate();
  }

  Widget _buildWeightInput() {
    final displayWeight =
        _weightInKg ? _weightKg : (_weightKg * 2.20462).roundToDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: AppRadii.lgBorderRadius,
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('step_05_weight_input'),
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*[\.,]?\d{0,1}'),
                    ),
                  ],
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()]),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '75.0',
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val.replaceAll(',', '.'));
                    if (parsed != null && parsed >= 30.0 && parsed <= 300.0) {
                      setState(() {
                        _weightKg = _weightInKg ? parsed : parsed / 2.20462;
                      });
                      _notifyUpdate();
                    }
                  },
                ),
              ),
              Text(_weightInKg ? 'kg' : 'lb',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary)),
            ],
          ),
          Slider(
            key: const Key('step_05_weight_slider'),
            value: displayWeight.clamp(
                _weightInKg ? 35.0 : 80.0, _weightInKg ? 180.0 : 400.0),
            min: _weightInKg ? 35.0 : 80.0,
            max: _weightInKg ? 180.0 : 400.0,
            activeColor: AppTheme.activeBlue,
            inactiveColor: AppTheme.cardBorder,
            onChanged: (newVal) {
              setState(() {
                _weightKg = _weightInKg ? newVal : newVal / 2.20462;
                _weightController.text = _weightKg.toStringAsFixed(1);
              });
              _notifyUpdate();
            },
          ),
        ],
      ),
    );
  }
}
