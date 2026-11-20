import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/domain/validation/domain_validator.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Card 3: Weight Goal & Dynamic Rate Pacing (live kcal/day preview + BMI guardrail).
class Card03WeightPacing extends StatefulWidget {
  const Card03WeightPacing({
    super.key,
    required this.goalType,
    required this.currentWeightKg,
    required this.heightCm,
    required this.initialTargetWeightKg,
    required this.initialRatePct,
    required this.onPacingChanged,
    required this.onNext,
  });

  final GoalType goalType;
  final double currentWeightKg;
  final double heightCm;
  final double initialTargetWeightKg;
  final double initialRatePct;
  final void Function({
    required double targetWeightKg,
    required double ratePct,
  }) onPacingChanged;
  final VoidCallback onNext;

  @override
  State<Card03WeightPacing> createState() => _Card03WeightPacingState();
}

class _Card03WeightPacingState extends State<Card03WeightPacing> {
  late double _targetWeightKg;
  late double _ratePct;
  late TextEditingController _targetWeightController;

  @override
  void initState() {
    super.initState();
    if (widget.goalType == GoalType.maintenance) {
      _targetWeightKg = widget.currentWeightKg;
      _ratePct = 0.0;
    } else {
      _targetWeightKg = widget.initialTargetWeightKg;
      _ratePct = widget.initialRatePct;
    }
    _targetWeightController =
        TextEditingController(text: _targetWeightKg.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(Card03WeightPacing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.goalType == GoalType.maintenance &&
        oldWidget.goalType != GoalType.maintenance) {
      setState(() {
        _targetWeightKg = widget.currentWeightKg;
        _ratePct = 0.0;
        _targetWeightController.text = _targetWeightKg.toStringAsFixed(1);
      });
    }
  }

  @override
  void dispose() {
    _targetWeightController.dispose();
    super.dispose();
  }

  void _notifyUpdate() {
    widget.onPacingChanged(
      targetWeightKg: _targetWeightKg,
      ratePct: _ratePct,
    );
  }

  bool get _isUnderweightWarning {
    if (widget.goalType != GoalType.fatLoss) return false;
    return DomainValidator.isUnderweightBmi(_targetWeightKg, widget.heightCm);
  }

  bool get _isValid {
    if (_isUnderweightWarning) return false;
    if (_targetWeightKg < DomainValidator.minWeightKg ||
        _targetWeightKg > DomainValidator.maxWeightKg) {
      return false;
    }
    return true;
  }

  int get _dailyKcalDelta {
    if (widget.goalType == GoalType.maintenance) return 0;
    // Dynamic formula: (currentWeightKg * (|ratePct| / 100) * 7700 / 7).round()
    return (widget.currentWeightKg * (_ratePct.abs() / 100.0) * 7700 / 7)
        .round();
  }

  @override
  Widget build(BuildContext context) {
    final isMaintenance = widget.goalType == GoalType.maintenance;
    final isFatLoss = widget.goalType == GoalType.fatLoss;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        const Text(
          'TARGET & PACING',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.activeBlue,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Weight Goal & Dynamic Rate',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Calibrated rate of change ensures sustainable adherence and metabolic stability.',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 18),

        // Current vs Target Weight Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Weight',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.currentWeightKg.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward_rounded,
                  color: AppTheme.textMuted, size: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Target Weight',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    '${_targetWeightKg.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isFatLoss
                          ? AppTheme.calories
                          : (isMaintenance
                              ? AppTheme.expenditure
                              : AppTheme.trendWeight),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Target Weight Input
        if (!isMaintenance) ...[
          const Text('Target Weight (kg)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isUnderweightWarning
                    ? AppTheme.calories
                    : AppTheme.cardBorder,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('step_15_target_weight_input'),
                    controller: _targetWeightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()]),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '70.0',
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        setState(() => _targetWeightKg = parsed);
                        _notifyUpdate();
                      }
                    },
                  ),
                ),
                const Text('KG',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],

        // BMI Underweight Clinical Guardrail Banner
        if (_isUnderweightWarning) ...[
          const SizedBox(height: 10),
          Container(
            key: const Key('step_15_bmi_guardrail_banner'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.calories.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.calories.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppTheme.calories, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Target weight ${_targetWeightKg.toStringAsFixed(1)} kg places BMI in the clinical underweight range (< 18.5). Safe minimum target is ${DomainValidator.minSafeWeightKg(widget.heightCm).toStringAsFixed(1)} kg.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.calories,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),

        // Dynamic Rate Pacing Slider & Live Kcal Preview
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Weekly Rate of Change',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary)),
            Text(
              isMaintenance
                  ? '0.0% / wk (Maintenance)'
                  : '${_ratePct > 0 ? "+" : ""}${_ratePct.toStringAsFixed(2)}% / wk',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isFatLoss
                    ? AppTheme.calories
                    : (isMaintenance
                        ? AppTheme.expenditure
                        : AppTheme.trendWeight),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            children: [
              if (!isMaintenance)
                Slider(
                  key: const Key('step_16_rate_slider'),
                  value: _ratePct.clamp(
                    isFatLoss ? -1.50 : 0.10,
                    isFatLoss ? -0.20 : 0.80,
                  ),
                  min: isFatLoss ? -1.50 : 0.10,
                  max: isFatLoss ? -0.20 : 0.80,
                  divisions: isFatLoss ? 26 : 14,
                  activeColor:
                      isFatLoss ? AppTheme.calories : AppTheme.trendWeight,
                  inactiveColor: AppTheme.cardBorder,
                  onChanged: (val) {
                    setState(() => _ratePct = val);
                    _notifyUpdate();
                  },
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Energy intake dynamically balances expenditure with 0.0% weekly deviation.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              const Divider(color: AppTheme.cardBorder, height: 20),

              // Live kcal/day Delta Preview Pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.cardElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isFatLoss
                          ? Icons.local_fire_department_rounded
                          : (isMaintenance
                              ? Icons.balance_rounded
                              : Icons.trending_up_rounded),
                      size: 18,
                      color: isFatLoss
                          ? AppTheme.calories
                          : (isMaintenance
                              ? AppTheme.expenditure
                              : AppTheme.trendWeight),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isMaintenance
                            ? 'Equilibrium Pace: 0 kcal deviation'
                            : (isFatLoss
                                ? 'Estimated Caloric Deficit: ~$_dailyKcalDelta kcal/day'
                                : 'Estimated Caloric Surplus: ~$_dailyKcalDelta kcal/day'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
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
          key: const Key('step_15_continue_btn'),
          onTap: _isValid
              ? () {
                  HapticFeedback.lightImpact();
                  _notifyUpdate();
                  widget.onNext();
                }
              : null,
          backgroundColor:
              _isValid ? AppTheme.activeBlue : AppTheme.cardElevated,
          borderRadius: 14,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              _isValid
                  ? 'Continue to Activity & Training'
                  : 'Resolve Guardrail',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _isValid ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
