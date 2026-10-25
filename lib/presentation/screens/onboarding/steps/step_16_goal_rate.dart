import 'package:flutter/material.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 16: Goal Rate Pacing (% Bodyweight / week, kg / week, per month)
class Step16GoalRate extends StatefulWidget {
  const Step16GoalRate({
    super.key,
    required this.goalType,
    required this.currentWeightKg,
    required this.initialRatePct,
    required this.onNext,
  });

  final GoalType goalType;
  final double currentWeightKg;
  final double initialRatePct;
  final ValueChanged<double> onNext;

  @override
  State<Step16GoalRate> createState() => _Step16GoalRateState();
}

class _Step16GoalRateState extends State<Step16GoalRate> {
  late double _ratePct;

  @override
  void initState() {
    super.initState();
    _ratePct = widget.initialRatePct;
    if (widget.goalType == GoalType.maintenance) {
      _ratePct = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoss = widget.goalType == GoalType.fatLoss;
    final isMaint = widget.goalType == GoalType.maintenance;

    final weeklyKg = (widget.currentWeightKg * (_ratePct.abs() / 100.0));
    final monthlyKg = weeklyKg * 4.33;

    return OnboardingStepScaffold(
      title: isMaint ? 'Weight Maintenance' : 'Rate of Progress',
      subtitle: isMaint
          ? 'Targets are locked to metabolic equilibrium (0.0% weekly change).'
          : 'Select your preferred weekly rate of weight change (% of bodyweight per week).',
      icon: Icons.speed_rounded,
      continueKey: const Key('step_16_continue_btn'),
      onContinue: () => widget.onNext(_ratePct),
      child: Column(
        children: [
          if (!isMaint) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                children: [
                  Text(
                    '${_ratePct.abs().toStringAsFixed(2)}% / week',
                    style: const TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${weeklyKg.toStringAsFixed(2)} kg/week • ${monthlyKg.toStringAsFixed(1)} kg/month',
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.activeBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    key: const Key('step_16_rate_slider'),
                    value: _ratePct.abs(),
                    min: isLoss ? 0.20 : 0.10,
                    max: isLoss ? 1.50 : 0.60,
                    divisions: isLoss ? 13 : 10,
                    activeColor: AppTheme.activeBlue,
                    inactiveColor: AppTheme.cardBorder,
                    onChanged: (val) {
                      setState(() {
                        _ratePct = isLoss ? -val : val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _PresetRateCard(
                    title: 'Conservative',
                    rateText: isLoss ? '-0.25% / wk' : '+0.15% / wk',
                    isSelected:
                        (_ratePct.abs() - (isLoss ? 0.25 : 0.15)).abs() < 0.05,
                    onTap: () =>
                        setState(() => _ratePct = isLoss ? -0.25 : 0.15),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PresetRateCard(
                    title: 'Standard',
                    rateText: isLoss ? '-0.50% / wk' : '+0.25% / wk',
                    isSelected:
                        (_ratePct.abs() - (isLoss ? 0.50 : 0.25)).abs() < 0.05,
                    onTap: () =>
                        setState(() => _ratePct = isLoss ? -0.50 : 0.25),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PresetRateCard(
                    title: 'Aggressive',
                    rateText: isLoss ? '-0.75% / wk' : '+0.40% / wk',
                    isSelected:
                        (_ratePct.abs() - (isLoss ? 0.75 : 0.40)).abs() < 0.05,
                    onTap: () =>
                        setState(() => _ratePct = isLoss ? -0.75 : 0.40),
                  ),
                ),
              ],
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Text(
                'Energy intake will match your Kalman expenditure calculation to maintain body composition.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PresetRateCard extends StatelessWidget {
  const _PresetRateCard({
    required this.title,
    required this.rateText,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String rateText;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppleTactileCard(
      onTap: onTap,
      backgroundColor: isSelected
          ? AppTheme.activeBlue.withValues(alpha: 0.14)
          : AppTheme.cardSurface,
      border: Border.all(
        color: isSelected ? AppTheme.activeBlue : AppTheme.cardBorder,
        width: isSelected ? 2 : 1,
      ),
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppTheme.activeBlue : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            rateText,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 11,
              color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
