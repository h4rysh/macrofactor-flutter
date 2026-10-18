import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';
import 'package:macro_factor_app/presentation/screens/profile_targets_screen.dart';
import 'package:macro_factor_app/presentation/theme/app_theme.dart';
import 'package:macro_factor_app/presentation/widgets/apple_tactile_card.dart';

/// Section 5: Physical Stats & Targets overview card.
class PhysicalStatsSummaryCard extends ConsumerWidget {
  const PhysicalStatsSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final macroTarget = ref.watch(dailyMacroTargetProvider);

    return AppleGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.accessibility_new_rounded,
                    size: 18,
                    color: AppTheme.trendWeight,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Physical Stats & Targets',
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              AppleBouncy(
                key: const Key('physical_stats_edit_btn'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileTargetsScreen(),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      'Edit',
                      style: TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.activeBlue,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: AppTheme.activeBlue,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricCol(
                  'Current Weight',
                  '${profile.currentWeightKg.toStringAsFixed(1)} kg',
                ),
              ),
              Expanded(
                child: _buildMetricCol(
                  'Target Weight',
                  '${profile.targetWeightKg.toStringAsFixed(1)} kg',
                ),
              ),
              Expanded(
                child: _buildMetricCol(
                  'Height',
                  '${profile.heightCm.toStringAsFixed(0)} cm',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              AppleBadge(
                label: profile.goalType.displayName,
                color: AppTheme.activeBlue,
              ),
              AppleBadge(
                label:
                    '${profile.weeklyRateOfChangePct >= 0 ? "+" : ""}${profile.weeklyRateOfChangePct.toStringAsFixed(2)}% / wk',
                color: AppTheme.trendWeight,
              ),
              AppleBadge(
                label: profile.proteinPreference.displayName,
                color: AppTheme.protein,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMacroText(
                  'Calories',
                  '${macroTarget.calories.round()} kcal',
                  AppTheme.calories,
                ),
                _buildMacroText(
                  'Protein',
                  '${macroTarget.proteinGrams.round()}g',
                  AppTheme.protein,
                ),
                _buildMacroText(
                  'Fat',
                  '${macroTarget.fatGrams.round()}g',
                  AppTheme.fat,
                ),
                _buildMacroText(
                  'Carbs',
                  '${macroTarget.carbsGrams.round()}g',
                  AppTheme.carbs,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroText(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
