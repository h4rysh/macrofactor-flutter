import 'package:flutter/material.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Step 17: Goal Summary Review
class Step17GoalSummary extends StatelessWidget {
  const Step17GoalSummary({
    super.key,
    required this.goalType,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.ratePct,
    required this.onNext,
  });

  final GoalType goalType;
  final double currentWeightKg;
  final double targetWeightKg;
  final double ratePct;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final weightDelta = (targetWeightKg - currentWeightKg).abs();
    final weeklyKg = currentWeightKg * (ratePct.abs() / 100.0);
    final estimatedWeeks =
        (weeklyKg > 0.05 ? (weightDelta / weeklyKg).ceil() : 0);

    return OnboardingStepScaffold(
      title: 'Goal Summary',
      subtitle:
          'Review your target objective before configuring program nutrition & distribution.',
      icon: Icons.checklist_rounded,
      continueKey: const Key('step_17_continue_btn'),
      onContinue: onNext,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              children: [
                _SummaryRow(
                    label: 'Goal Objective', value: goalType.displayName),
                const Divider(height: 24, color: AppTheme.cardBorder),
                _SummaryRow(
                  label: 'Current Weight',
                  value: '${currentWeightKg.toStringAsFixed(1)} kg',
                ),
                const Divider(height: 24, color: AppTheme.cardBorder),
                _SummaryRow(
                  label: 'Target Weight',
                  value: '${targetWeightKg.toStringAsFixed(1)} kg',
                ),
                const Divider(height: 24, color: AppTheme.cardBorder),
                _SummaryRow(
                  label: 'Pacing Rate',
                  value: '${ratePct.abs().toStringAsFixed(2)}% / week',
                ),
                if (estimatedWeeks > 0) ...[
                  const Divider(height: 24, color: AppTheme.cardBorder),
                  _SummaryRow(
                    label: 'Estimated Timeline',
                    value: '~$estimatedWeeks weeks',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
