import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sique/domain/legal/legal_copy.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Card 6: Personalized TDEE & Macro Blueprint Reveal (Value delivery).
class Card06TdeeBlueprint extends StatefulWidget {
  const Card06TdeeBlueprint({
    super.key,
    required this.tdeeKcal,
    required this.bmrKcal,
    required this.targetCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.initialOverrideKcal,
    required this.initialDistributionMode,
    required this.workoutDays,
    required this.onBlueprintChanged,
    required this.onNext,
  });

  final double tdeeKcal;
  final double bmrKcal;
  final double targetCalories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double? initialOverrideKcal;
  final String initialDistributionMode;
  final Set<int> workoutDays;
  final void Function({
    required double? customTdeeOverride,
    required String distributionMode,
  }) onBlueprintChanged;
  final VoidCallback onNext;

  @override
  State<Card06TdeeBlueprint> createState() => _Card06TdeeBlueprintState();
}

class _Card06TdeeBlueprintState extends State<Card06TdeeBlueprint> {
  late bool _hasOverride;
  late double? _customTdee;
  late String _distributionMode;
  bool _disclaimerAccepted = false;
  late TextEditingController _overrideController;

  @override
  void initState() {
    super.initState();
    _customTdee = widget.initialOverrideKcal;
    _hasOverride = _customTdee != null && _customTdee! > 0;
    _distributionMode = widget.initialDistributionMode;
    _overrideController = TextEditingController(
      text: _customTdee != null ? _customTdee!.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _overrideController.dispose();
    super.dispose();
  }

  void _notifyUpdate() {
    widget.onBlueprintChanged(
      customTdeeOverride: _hasOverride ? _customTdee : null,
      distributionMode: _distributionMode,
    );
  }

  double get _effectiveTdee =>
      (_hasOverride && _customTdee != null && _customTdee! > 0)
          ? _customTdee!
          : widget.tdeeKcal;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        const Text(
          'YOUR BLUEPRINT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.activeBlue,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Personalized Metabolic Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Calculated from your resting metabolic rate and activity priors.',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 18),

        // Section A: TDEE & Target Calories Hero Container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.calories.withValues(alpha: 0.15),
                AppTheme.cardSurface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.calories.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            children: [
              const Text(
                'DAILY TARGET CALORIES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.calories,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.targetCalories.round()}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              const Text('kcal / day',
                  style:
                      TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.cardBorder, height: 1),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSubMetric(
                    label: 'Resting BMR',
                    value: '${widget.bmrKcal.round()} kcal',
                    color: AppTheme.textSecondary,
                  ),
                  Container(width: 1, height: 28, color: AppTheme.cardBorder),
                  _buildSubMetric(
                    label: 'Calculated TDEE',
                    value: '${_effectiveTdee.round()} kcal',
                    color: AppTheme.expenditure,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section B: Optional TDEE Override Toggle
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Known TDEE Override',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Enable if you already know your accurate daily maintenance burn.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    key: const Key('step_13_override_toggle'),
                    value: _hasOverride,
                    activeTrackColor: AppTheme.activeBlue,
                    onChanged: (val) {
                      setState(() {
                        _hasOverride = val;
                        if (!val) _customTdee = null;
                      });
                      _notifyUpdate();
                    },
                  ),
                ],
              ),
              if (_hasOverride) ...[
                const SizedBox(height: 12),
                TextField(
                  key: const Key('step_13_override_input'),
                  controller: _overrideController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()]),
                  decoration: InputDecoration(
                    labelText: 'Enter known expenditure (kcal/day)',
                    labelStyle: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.cardElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.cardBorder),
                    ),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null && parsed >= 1000 && parsed <= 6000) {
                      _customTdee = parsed;
                      _notifyUpdate();
                    }
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section C: Macronutrient Breakdown
        const Text('Target Macronutrients',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMacroCard(
                label: 'Protein',
                grams: widget.proteinGrams,
                color: AppTheme.protein,
                icon: Icons.egg_alt_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMacroCard(
                label: 'Carbs',
                grams: widget.carbsGrams,
                color: AppTheme.carbs,
                icon: Icons.grain_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMacroCard(
                label: 'Fat',
                grams: widget.fatGrams,
                color: AppTheme.fat,
                icon: Icons.opacity_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Section D: Calorie Distribution Mode (Even vs Shifted)
        const Text('Calorie Distribution',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDistributionOption(
                key: const Key('step_21_mode_even'),
                title: 'Even Daily',
                subtitle: 'Identical calories & macros every day',
                mode: 'even',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDistributionOption(
                key: const Key('step_21_mode_shifted'),
                title: 'Workout Shifted',
                subtitle: 'More carbs & cals on training days',
                mode: 'shifted',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Section E: Medical Disclaimer Gate Checkbox
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.health_and_safety_rounded,
                      color: AppTheme.activeBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    LegalCopy.onboardingNoticeTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                LegalCopy.onboardingNoticeSubtitle,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                key: const Key('step_23_checkbox'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _disclaimerAccepted = !_disclaimerAccepted);
                },
                child: Row(
                  children: [
                    Checkbox(
                      value: _disclaimerAccepted,
                      activeColor: AppTheme.activeBlue,
                      onChanged: (val) {
                        setState(() => _disclaimerAccepted = val ?? false);
                      },
                    ),
                    const Expanded(
                      child: Text(
                        LegalCopy.onboardingDisclaimerAgreement,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Continue Button
        AppleTactileCard(
          key: const Key('onboarding_card_6_continue_btn'),
          onTap: _disclaimerAccepted
              ? () {
                  HapticFeedback.lightImpact();
                  _notifyUpdate();
                  widget.onNext();
                }
              : null,
          backgroundColor:
              _disclaimerAccepted ? AppTheme.activeBlue : AppTheme.cardElevated,
          borderRadius: 14,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              _disclaimerAccepted
                  ? 'Continue to Save Strategy'
                  : 'Acknowledge Disclaimer to Proceed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _disclaimerAccepted ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildMacroCard({
    required String label,
    required double grams,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${grams.round()}g',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionOption({
    required Key key,
    required String title,
    required String subtitle,
    required String mode,
  }) {
    final isSelected = _distributionMode == mode;
    return GestureDetector(
      key: key,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _distributionMode = mode);
        _notifyUpdate();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.activeBlue.withValues(alpha: 0.15)
              : AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.activeBlue : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: isSelected ? AppTheme.activeBlue : AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppTheme.activeBlue
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
