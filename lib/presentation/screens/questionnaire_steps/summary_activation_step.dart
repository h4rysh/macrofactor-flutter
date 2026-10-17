import 'package:flutter/material.dart';
import '../../../domain/models/user_profile.dart';
import '../../theme/app_theme.dart';

/// Step 5: Program Target Summary & Activation
class SummaryActivationStep extends StatelessWidget {
  const SummaryActivationStep({
    super.key,
    required this.macros,
  });

  final MacroTarget macros;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        const Text(
          'TARGET PREVIEW & CONFIRMATION',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.calories,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your Calibrated Program',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Review your personalized targets. All parameters update the live dashboard seamlessly.',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // Big Calorie Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.calories.withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33FF5722),
                blurRadius: 18,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'DAILY CALORIC TARGET',
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${macros.calories.round()}',
                style: const TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.calories,
                  letterSpacing: -1.0,
                ),
              ),
              const Text(
                'kcal / day',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroSummaryPill(
                    label: 'PROTEIN',
                    value: '${macros.proteinGrams.round()}g',
                    color: AppTheme.protein,
                  ),
                  _buildMacroSummaryPill(
                    label: 'CARBS',
                    value: '${macros.carbsGrams.round()}g',
                    color: AppTheme.carbs,
                  ),
                  _buildMacroSummaryPill(
                    label: 'FAT',
                    value: '${macros.fatGrams.round()}g',
                    color: AppTheme.fat,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Adherence-Neutral Guarantee Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined,
                  color: AppTheme.expenditure, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ADHERENCE-NEUTRAL GUARANTEE',
                      style: TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Eat more or less than this target without guilt. The Bayesian algorithm continuously calculates expenditure from real weight trends, adapting seamlessly.',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacroSummaryPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
