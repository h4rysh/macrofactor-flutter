import 'package:flutter/material.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Step 19: Summary Review & Pre-Calculation Confirmation
class Step19SummaryReview extends StatelessWidget {
  const Step19SummaryReview({
    super.key,
    required this.name,
    required this.isMale,
    required this.age,
    required this.heightCm,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.goalType,
    required this.ratePct,
    required this.proteinPref,
    required this.distributionMode,
    required this.dietType,
    required this.programStyle,
    required this.onNext,
  });

  final String name;
  final bool isMale;
  final int age;
  final double heightCm;
  final double currentWeightKg;
  final double targetWeightKg;
  final GoalType goalType;
  final double ratePct;
  final ProteinPreference proteinPref;
  final String distributionMode;
  final String dietType;
  final MacroProgramStyle programStyle;
  final VoidCallback onNext;

  double get _baselineTDEE {
    final bmr = (10.0 * currentWeightKg) +
        (6.25 * heightCm) -
        (5.0 * age) +
        (isMale ? 5.0 : -161.0);
    return (bmr * 1.35).roundToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Review Your Program',
      subtitle:
          'Here is your initial physiological baseline before generating your weekly targets.',
      icon: Icons.checklist_rounded,
      continueLabel: 'Calculate Strategy',
      continueKey: const Key('step_19_continue_btn'),
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
                _ReviewRow(label: 'Athlete Name', value: name),
                const Divider(color: AppTheme.cardBorder, height: 20),
                _ReviewRow(
                    label: 'Biological Sex', value: isMale ? 'Male' : 'Female'),
                const Divider(color: AppTheme.cardBorder, height: 20),
                _ReviewRow(
                    label: 'Age / Height',
                    value: '$age yrs • ${heightCm.toStringAsFixed(0)} cm'),
                const Divider(color: AppTheme.cardBorder, height: 20),
                _ReviewRow(
                    label: 'Weight Track',
                    value:
                        '${currentWeightKg.toStringAsFixed(1)} kg → ${targetWeightKg.toStringAsFixed(1)} kg'),
                const Divider(color: AppTheme.cardBorder, height: 20),
                _ReviewRow(label: 'Primary Goal', value: goalType.displayName),
                const Divider(color: AppTheme.cardBorder, height: 20),
                _ReviewRow(
                    label: 'Weekly Pacing',
                    value: '${ratePct.abs().toStringAsFixed(2)}% / week'),
                const Divider(color: AppTheme.cardBorder, height: 20),
                _ReviewRow(
                    label: 'Diet / Style',
                    value:
                        '${dietType.toUpperCase()} • ${programStyle.displayName}'),
                const Divider(color: AppTheme.cardBorder, height: 20),
                _ReviewRow(
                    label: 'Baseline TDEE (Estimated)',
                    value: '${_baselineTDEE.round()} kcal/day'),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

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
            fontFamily: 'DMSans',
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
