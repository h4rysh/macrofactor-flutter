import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../screens/onboarding/strategy_setup_wizard.dart';
import '../../theme/app_theme.dart';
import '../apple_tactile_card.dart';

/// Hero card showcasing the user's active weekly macro program and target dials.
class MacroProgramHeroCard extends ConsumerWidget {
  const MacroProgramHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(weeklyMacroProgramProvider);
    final expenditure = ref.watch(expenditureStateProvider);
    final avgTarget = program.days.first; // representative macro split

    final deficitSurplus =
        program.dailyAverageCalories - expenditure.expenditureKcal;
    final isDeficit = deficitSurplus < -15;
    final isSurplus = deficitSurplus > 15;

    final deficitText = isDeficit
        ? '${deficitSurplus.abs().round()} kcal deficit'
        : isSurplus
            ? '+${deficitSurplus.round()} kcal surplus'
            : 'Energy balance (0 kcal)';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Badges & Edit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _Badge(
                    label: program.mode.displayName.toUpperCase(),
                    color: AppTheme.calories,
                  ),
                  _Badge(
                    label: program.style.displayName.toUpperCase(),
                    color: AppTheme.activeBlue,
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StrategySetupWizard(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.edit_note_rounded,
                  color: AppTheme.textSecondary,
                  size: 24,
                ),
                tooltip: 'Edit Strategy Program',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Average Calories
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${program.dailyAverageCalories.round()}',
                style: const TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.calories,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'kcal / day avg',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDeficit
                      ? AppTheme.calories.withValues(alpha: 0.12)
                      : isSurplus
                          ? AppTheme.carbs.withValues(alpha: 0.12)
                          : AppTheme.cardElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  deficitText,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDeficit
                        ? AppTheme.calories
                        : isSurplus
                            ? AppTheme.carbs
                            : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Macro Split Pills
          Row(
            children: [
              _MacroSplitPill(
                label: 'PROTEIN',
                grams: '${avgTarget.proteinGrams.round()}g',
                color: AppTheme.protein,
              ),
              const SizedBox(width: 8),
              _MacroSplitPill(
                label: 'FAT',
                grams: '${avgTarget.fatGrams.round()}g',
                color: AppTheme.fat,
              ),
              const SizedBox(width: 8),
              _MacroSplitPill(
                label: 'CARBS',
                grams: '${avgTarget.carbsGrams.round()}g',
                color: AppTheme.carbs,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Action to re-run setup wizard
          AppleTactileCard(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StrategySetupWizard(),
                ),
              );
            },
            backgroundColor: AppTheme.cardElevated,
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: AppTheme.calories,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Change Strategy or Preferences',
                  style: TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'MacroSans',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MacroSplitPill extends StatelessWidget {
  const _MacroSplitPill({
    required this.label,
    required this.grams,
    required this.color,
  });

  final String label;
  final String grams;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
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
            const SizedBox(height: 4),
            Text(
              grams,
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
