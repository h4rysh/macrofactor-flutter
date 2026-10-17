import 'package:flutter/material.dart';
import '../../../domain/models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_tactile_card.dart';

/// Step 1: Dynamic Adaptive Pacing
class AdaptivePacingStep extends StatelessWidget {
  const AdaptivePacingStep({
    super.key,
    required this.selectedGoal,
    required this.weeklyRate,
    required this.currentWeightKg,
    required this.onRateSelected,
  });

  final GoalType selectedGoal;
  final double weeklyRate;
  final double currentWeightKg;
  final ValueChanged<double> onRateSelected;

  @override
  Widget build(BuildContext context) {
    final isFatLoss = selectedGoal == GoalType.fatLoss;
    final isMuscleGain = selectedGoal == GoalType.muscleGain;

    String heading;
    String description;
    List<Map<String, dynamic>> rateOptions;

    if (isFatLoss) {
      heading = 'Select Your Desired Pace';
      description = 'Select your desired pace of fat loss:';
      rateOptions = [
        {
          'rate': -0.50,
          'title': 'Conservative Loss',
          'desc': 'Mild deficit (~250 kcal/day). Highest satiety and energy.',
          'badge': '-0.50%/wk',
        },
        {
          'rate': -0.75,
          'title': 'Recommended Standard',
          'desc':
              'Optimal pace (~500 kcal deficit). Preserves lean muscle mass.',
          'badge': '-0.75%/wk',
        },
        {
          'rate': -1.00,
          'title': 'Aggressive Deficit',
          'desc': 'Steeper deficit (~750 kcal). Fast results for short cuts.',
          'badge': '-1.00%/wk',
        },
      ];
    } else if (isMuscleGain) {
      heading = 'Select Your Hypertrophy Rate';
      description =
          'A controlled surplus maximizes muscle accretion while minimizing unwanted fat storage.';
      rateOptions = [
        {
          'rate': 0.25,
          'title': 'Lean Bulk (Conservative)',
          'desc': 'Minimal fat gain (~190 kcal surplus). Best for lean builds.',
          'badge': '+0.25%/wk',
        },
        {
          'rate': 0.50,
          'title': 'Standard Muscle Gain',
          'desc':
              'Optimal muscle growth (~380 kcal surplus). Balanced accretion.',
          'badge': '+0.50%/wk',
        },
        {
          'rate': 0.75,
          'title': 'Hypertrophy Surplus',
          'desc':
              'Maximum strength support (~570 kcal surplus). High volume training.',
          'badge': '+0.75%/wk',
        },
      ];
    } else {
      heading = 'Caloric Maintenance Settings';
      description =
          'Targeting body weight stability while adapting to daily metabolic expenditure changes.';
      rateOptions = [
        {
          'rate': 0.0,
          'title': 'Caloric Equilibrium / Recomp',
          'desc':
              '1:1 match with Bayesian daily energy expenditure. Zero planned weight delta.',
          'badge': 'True Balance',
        },
      ];
    }

    final weeklyDeltaKg =
        (currentWeightKg * (weeklyRate.abs() / 100.0)).toStringAsFixed(2);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        const Text(
          'RATE OF CHANGE',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.activeBlue,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          heading,
          style: const TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // Live Rate Preview Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WEEKLY RATE OF CHANGE',
                      style: TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${weeklyRate >= 0 ? "+" : ""}${weeklyRate.toStringAsFixed(2)}% / week',
                      style: const TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.cardElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  weeklyRate == 0
                      ? 'Stable 0.0 kg/wk'
                      : '${weeklyRate < 0 ? "-" : "+"}$weeklyDeltaKg kg/wk',
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.activeBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ...rateOptions.map((opt) {
          final rateVal = (opt['rate'] as num).toDouble();
          final isSelected = (weeklyRate - rateVal).abs() < 0.01;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppleBouncy(
              onTap: () => onRateSelected(rateVal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.activeBlue.withValues(alpha: 0.12)
                      : AppTheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isSelected ? AppTheme.activeBlue : AppTheme.cardBorder,
                    width: isSelected ? 1.5 : 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  opt['title'] as String,
                                  style: const TextStyle(
                                    fontFamily: 'MacroSans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              AppleBadge(
                                label: opt['badge'] as String,
                                color: isSelected
                                    ? AppTheme.activeBlue
                                    : AppTheme.textMuted,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            opt['desc'] as String,
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          color: AppTheme.activeBlue, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
