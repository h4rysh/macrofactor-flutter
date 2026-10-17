import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_factor_app/domain/models/user_profile.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';
import 'package:macro_factor_app/presentation/theme/app_theme.dart';

/// Screen for viewing and configuring user profile, caloric targets, and macro distribution.
/// Implements Instant Auto-Save: all slider/toggle changes immediately persist to SQLite.
class ProfileTargetsScreen extends ConsumerWidget {
  const ProfileTargetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final expenditureState = ref.watch(expenditureStateProvider);
    final macroTarget = ref.watch(dailyMacroTargetProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profile & Targets'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildPhysicalStatsCard(context, ref, profile),
          const SizedBox(height: 16),
          _buildGoalSelectionCard(context, ref, profile),
          const SizedBox(height: 16),
          _buildCalorieTargetCard(context, ref, profile,
              expenditureState.expenditureKcal, macroTarget),
          const SizedBox(height: 16),
          _buildProteinPreferenceCard(context, ref, profile),
          const SizedBox(height: 16),
          _buildMacroDistributionSummary(macroTarget),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPhysicalStatsCard(
      BuildContext context, WidgetRef ref, UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center_rounded,
                  size: 20, color: AppTheme.activeBlue),
              const SizedBox(width: 8),
              const Text(
                'Physical Stats',
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cardElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${profile.age} yrs • ${profile.isMale ? "Male" : "Female"}',
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Current Weight',
                  value: '${profile.currentWeightKg.toStringAsFixed(1)} kg',
                  onTap: () => _showWeightDialog(context, ref, profile),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'Target Weight',
                  value: '${profile.targetWeightKg.toStringAsFixed(1)} kg',
                  onTap: () => _showTargetWeightDialog(context, ref, profile),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'Height',
                  value: '${profile.heightCm.toStringAsFixed(0)} cm',
                  onTap: () => _showHeightDialog(context, ref, profile),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.cardBorder.withAlpha(90)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSelectionCard(
      BuildContext context, WidgetRef ref, UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Goal & Strategy',
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: GoalType.values.map((goal) {
              final isSelected = profile.goalType == goal;
              final name = switch (goal) {
                GoalType.fatLoss => 'Fat Loss',
                GoalType.maintenance => 'Maintain',
                GoalType.muscleGain => 'Muscle Gain',
              };
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color:
                            isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.activeBlue,
                    backgroundColor: AppTheme.cardElevated,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.activeBlue
                          : AppTheme.cardBorder,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(userProfileProvider.notifier).updateProfile(
                              profile.copyWith(goalType: goal),
                            );
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Rate of Change',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '${profile.weeklyRateOfChangePct >= 0 ? "+" : ""}${profile.weeklyRateOfChangePct.toStringAsFixed(2)}% / wk',
                style: const TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.trendWeight,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.trendWeight,
              inactiveTrackColor: AppTheme.cardBorder,
              thumbColor: AppTheme.trendWeight,
              trackHeight: 4,
            ),
            child: Slider(
              value: profile.weeklyRateOfChangePct.clamp(-1.5, 1.0),
              min: -1.5,
              max: 1.0,
              divisions: 50,
              onChanged: (val) {
                ref.read(userProfileProvider.notifier).updateProfile(
                      profile.copyWith(weeklyRateOfChangePct: val),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieTargetCard(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    double expenditureKcal,
    MacroTarget target,
  ) {
    final isCustom = profile.customCalories != null;
    final currentTarget = target.calories;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Caloric Target',
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCustom
                        ? 'Custom Override Active'
                        : 'Calculated by Expenditure Engine',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: isCustom ? AppTheme.warning : AppTheme.expenditure,
                    ),
                  ),
                ],
              ),
              if (isCustom)
                TextButton(
                  onPressed: () {
                    ref.read(userProfileProvider.notifier).updateProfile(
                          profile.copyWith(clearCustom: true),
                        );
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: AppTheme.activeBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  currentTarget.toStringAsFixed(0),
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.calories,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'kcal / day',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.calories,
              inactiveTrackColor: AppTheme.cardBorder,
              thumbColor: AppTheme.calories,
              trackHeight: 4,
            ),
            child: Slider(
              value: currentTarget.clamp(1200.0, 4000.0),
              min: 1200.0,
              max: 4000.0,
              divisions: 112,
              onChanged: (val) {
                ref.read(userProfileProvider.notifier).updateProfile(
                      profile.copyWith(customCalories: val.roundToDouble()),
                    );
              },
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1,200 kcal',
                  style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 11,
                      color: AppTheme.textMuted)),
              Text('4,000 kcal',
                  style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 11,
                      color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProteinPreferenceCard(
      BuildContext context, WidgetRef ref, UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Protein Target Strategy',
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Protein intake protects lean body mass during energy deficits and supports muscle protein synthesis.',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ProteinPreference.values.map((pref) {
              final isSelected = profile.proteinPreference == pref;
              return ChoiceChip(
                label: Text(
                  pref.displayName,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppTheme.protein,
                backgroundColor: AppTheme.cardElevated,
                side: BorderSide(
                  color: isSelected ? AppTheme.protein : AppTheme.cardBorder,
                ),
                onSelected: (selected) {
                  if (selected) {
                    ref.read(userProfileProvider.notifier).updateProfile(
                          profile.copyWith(proteinPreference: pref),
                        );
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroDistributionSummary(MacroTarget target) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target Macro Breakdown',
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMacroPill(
                  label: 'Protein',
                  grams: '${target.proteinGrams.toStringAsFixed(0)}g',
                  color: AppTheme.protein,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroPill(
                  label: 'Fat',
                  grams: '${target.fatGrams.toStringAsFixed(0)}g',
                  color: AppTheme.fat,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroPill(
                  label: 'Carbs',
                  grams: '${target.carbsGrams.toStringAsFixed(0)}g',
                  color: AppTheme.carbs,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill({
    required String label,
    required String grams,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            grams,
            style: const TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showWeightDialog(
      BuildContext context, WidgetRef ref, UserProfile profile) {
    final controller =
        TextEditingController(text: profile.currentWeightKg.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: const Text('Update Current Weight',
            style: TextStyle(
                fontFamily: 'MacroSans', color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            labelStyle: TextStyle(color: AppTheme.textSecondary),
            suffixText: 'kg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 20 && val < 300) {
                ref.read(userProfileProvider.notifier).updateProfile(
                      profile.copyWith(currentWeightKg: val),
                    );
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppTheme.activeBlue)),
          ),
        ],
      ),
    );
  }

  void _showTargetWeightDialog(
      BuildContext context, WidgetRef ref, UserProfile profile) {
    final controller =
        TextEditingController(text: profile.targetWeightKg.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: const Text('Update Target Weight',
            style: TextStyle(
                fontFamily: 'MacroSans', color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Target Weight (kg)',
            labelStyle: TextStyle(color: AppTheme.textSecondary),
            suffixText: 'kg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 20 && val < 300) {
                ref.read(userProfileProvider.notifier).updateProfile(
                      profile.copyWith(targetWeightKg: val),
                    );
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppTheme.activeBlue)),
          ),
        ],
      ),
    );
  }

  void _showHeightDialog(
      BuildContext context, WidgetRef ref, UserProfile profile) {
    final controller =
        TextEditingController(text: profile.heightCm.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: const Text('Update Height',
            style: TextStyle(
                fontFamily: 'MacroSans', color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Height (cm)',
            labelStyle: TextStyle(color: AppTheme.textSecondary),
            suffixText: 'cm',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 80 && val < 260) {
                ref.read(userProfileProvider.notifier).updateProfile(
                      profile.copyWith(heightCm: val),
                    );
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppTheme.activeBlue)),
          ),
        ],
      ),
    );
  }
}
