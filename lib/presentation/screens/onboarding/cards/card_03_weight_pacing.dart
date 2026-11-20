import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/domain/validation/domain_validator.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';
import 'package:sique/presentation/widgets/sique_frosted_chrome.dart';
import 'package:sique/utils/unit_formatter.dart';

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

  String get _projectedFinishDate {
    if (widget.goalType == GoalType.maintenance) return 'Ongoing equilibrium';
    final deltaKg = (_targetWeightKg - widget.currentWeightKg).abs();
    final weeklyChangeKg = widget.currentWeightKg * (_ratePct.abs() / 100.0);
    if (weeklyChangeKg <= 0.01) return 'Ongoing pace';
    final weeks = (deltaKg / weeklyChangeKg).clamp(0.0, 520.0);
    final finishDate = DateTime.now().add(Duration(days: (weeks * 7).round()));
    return 'Est. finish: ${DateFormat('MMM yyyy').format(finishDate)} (~${weeks.round()} wks)';
  }

  @override
  Widget build(BuildContext context) {
    final isMaintenance = widget.goalType == GoalType.maintenance;
    final isFatLoss = widget.goalType == GoalType.fatLoss;

    return Column(
      children: [
        Expanded(
          child: ListView(
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
                Text(UnitFormatter.targetWeightLabel(),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          final minSafe =
                              DomainValidator.minSafeWeightKg(widget.heightCm);
                          setState(() {
                            _targetWeightKg = minSafe;
                            _targetWeightController.text =
                                minSafe.toStringAsFixed(1);
                          });
                          _notifyUpdate();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.calories.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppTheme.calories, width: 0.8),
                          ),
                          child: Text(
                            'Set to safe minimum (${DomainValidator.minSafeWeightKg(widget.heightCm).toStringAsFixed(1)} kg)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // 3 Pacing Preset Pills
              if (!isMaintenance) ...[
                Row(
                  children: [
                    _buildPacingPill(
                      label: 'Steady',
                      rate: isFatLoss ? -0.25 : 0.15,
                      subtitle: isFatLoss ? '-0.25%/wk' : '+0.15%/wk',
                    ),
                    const SizedBox(width: 8),
                    _buildPacingPill(
                      label: 'Recommended',
                      rate: isFatLoss ? -0.50 : 0.25,
                      subtitle: isFatLoss ? '-0.50%/wk' : '+0.25%/wk',
                    ),
                    const SizedBox(width: 8),
                    _buildPacingPill(
                      label: 'Focused',
                      rate: isFatLoss ? -0.75 : 0.40,
                      subtitle: isFatLoss ? '-0.75%/wk' : '+0.40%/wk',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

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
                        activeColor: isFatLoss
                            ? AppTheme.calories
                            : AppTheme.trendWeight,
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
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                    const Divider(color: AppTheme.cardBorder, height: 20),

                    // Live kcal/day Delta Preview Pill & Finish Date
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardElevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
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
                                          ? 'Estimated Deficit: ~$_dailyKcalDelta kcal/day'
                                          : 'Estimated Surplus: ~$_dailyKcalDelta kcal/day'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.flag_outlined,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _projectedFinishDate,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
                  key: const Key('step_15_continue_btn'),
                  onTap: _isValid
                      ? () {
                          HapticFeedback.lightImpact();
                          _notifyUpdate();
                          widget.onNext();
                        }
                      : null,
                  backgroundColor: _isValid
                      ? const Color(0xFFFAFAFA)
                      : AppTheme.cardElevated,
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      _isValid
                          ? 'Continue to activity & training'
                          : 'Resolve guardrail',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _isValid
                            ? const Color(0xFF09090B)
                            : AppTheme.textMuted,
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

  Widget _buildPacingPill({
    required String label,
    required double rate,
    required String subtitle,
  }) {
    final isSelected = (_ratePct - rate).abs() < 0.05;

    return Expanded(
      child: AppleBouncy(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _ratePct = rate);
          _notifyUpdate();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.calories.withValues(alpha: 0.15)
                : AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.calories : AppTheme.cardBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppTheme.calories : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
