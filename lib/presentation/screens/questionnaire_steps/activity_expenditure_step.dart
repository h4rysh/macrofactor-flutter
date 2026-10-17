import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_tactile_card.dart';

/// Step 2: Physical Activity & Bayesian Baseline Expenditure
class ActivityExpenditureStep extends StatelessWidget {
  const ActivityExpenditureStep({
    super.key,
    required this.activityMultiplier,
    required this.baselineExpenditure,
    required this.onActivitySelected,
  });

  final double activityMultiplier;
  final double baselineExpenditure;
  final ValueChanged<double> onActivitySelected;

  @override
  Widget build(BuildContext context) {
    final activities = [
      {
        'mult': 1.20,
        'title': 'Sedentary',
        'desc': 'Desk job, mostly sitting, little intentional exercise',
        'icon': Icons.weekend_outlined,
      },
      {
        'mult': 1.375,
        'title': 'Lightly Active',
        'desc': 'Daily walking or light exercise 1–3 days/week',
        'icon': Icons.directions_walk_rounded,
      },
      {
        'mult': 1.55,
        'title': 'Moderately Active',
        'desc': 'Moderate exercise or sports 3–5 days/week',
        'icon': Icons.directions_run_rounded,
      },
      {
        'mult': 1.725,
        'title': 'Very Active',
        'desc': 'Intense training 6–7 days/week or active job',
        'icon': Icons.fitness_center_rounded,
      },
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        const Text(
          'PHYSICAL ACTIVITY & TDEE',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.activeBlue,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Daily Activity Level',
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
          'Used to seed your initial Bayesian expenditure algorithm baseline before observation data.',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // Live Computed Expenditure Banner
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CALIBRATED BASELINE EXPENDITURE',
                      style: TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Bayesian Seed Point',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.expenditure.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.expenditure.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${baselineExpenditure.round()} kcal',
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.expenditure,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ...activities.map((act) {
          final multVal = act['mult'] as double;
          final isSelected = (activityMultiplier - multVal).abs() < 0.01;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppleBouncy(
              onTap: () => onActivitySelected(multVal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.expenditure.withValues(alpha: 0.12)
                      : AppTheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isSelected ? AppTheme.expenditure : AppTheme.cardBorder,
                    width: isSelected ? 1.5 : 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      act['icon'] as IconData,
                      color: isSelected
                          ? AppTheme.expenditure
                          : AppTheme.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act['title'] as String,
                            style: const TextStyle(
                              fontFamily: 'MacroSans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            act['desc'] as String,
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
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.expenditure,
                        size: 20,
                      ),
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
