import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_factor_app/domain/models/user_profile.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';
import 'package:macro_factor_app/presentation/theme/app_theme.dart';

/// Strategy & Coaching configuration screen with live macro recalculation.
class StrategyScreen extends ConsumerStatefulWidget {
  const StrategyScreen({super.key});

  @override
  ConsumerState<StrategyScreen> createState() => _StrategyScreenState();
}

class _StrategyScreenState extends ConsumerState<StrategyScreen> {
  late GoalType _goalType;
  late ProgramMode _programMode;
  late double _weeklyRate;
  late ProteinPreference _proteinPreference;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _goalType = profile.goalType;
    _programMode = profile.programMode;
    _weeklyRate = profile.weeklyRateOfChangePct;
    _proteinPreference = profile.proteinPreference;
  }

  void _saveStrategy() {
    final current = ref.read(userProfileProvider);
    final updated = current.copyWith(
      goalType: _goalType,
      programMode: _programMode,
      weeklyRateOfChangePct: _weeklyRate,
      proteinPreference: _proteinPreference,
    );
    ref.read(userProfileProvider.notifier).updateProfile(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Strategy updated successfully',
          style: TextStyle(fontFamily: 'DMSans'),
        ),
        backgroundColor: AppTheme.cardSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final expenditureState = ref.watch(expenditureStateProvider);

    // Calculate simulated preview target
    final previewProfile = profile.copyWith(
      goalType: _goalType,
      programMode: _programMode,
      weeklyRateOfChangePct: _weeklyRate,
      proteinPreference: _proteinPreference,
    );
    final previewMacros =
        previewProfile.calculateTargetMacros(expenditureState.expenditureKcal);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Coaching & Strategy'),
        actions: [
          TextButton(
            onPressed: _saveStrategy,
            child: const Text(
              'Save',
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontWeight: FontWeight.w700,
                color: AppTheme.calories,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Adherence-Neutral Guarantee Banner
            _buildAdherenceNeutralCard(),
            const SizedBox(height: 16),

            // Live Target Preview Card
            _buildPreviewCard(previewMacros, expenditureState.expenditureKcal),
            const SizedBox(height: 16),

            // Program Mode Selector
            _buildProgramModeCard(),
            const SizedBox(height: 16),

            // Goal Type Selector
            _buildGoalTypeCard(),
            const SizedBox(height: 16),

            // Weekly Rate of Change Slider (only if not maintenance)
            if (_goalType != GoalType.maintenance) ...[
              _buildRateOfChangeCard(profile.currentWeightKg),
              const SizedBox(height: 16),
            ],

            // Protein Preference Selector
            _buildProteinPreferenceCard(),
            const SizedBox(height: 24),

            // Save Strategy Action Button
            ElevatedButton(
              onPressed: _saveStrategy,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.calories,
                foregroundColor: AppTheme.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'APPLY PROGRAM TARGETS',
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceNeutralCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.expenditure.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.expenditure.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.psychology,
              size: 20,
              color: AppTheme.expenditure,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADHERENCE-NEUTRAL COACHING',
                  style: TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.expenditure,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Our Bayesian expenditure engine does not judge or assign guilt. Eat what you enjoy: your metabolism is estimated from biological intake vs weight flux, with zero behavioral penalties.',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(MacroTarget target, double expenditure) {
    final deficitSurplus = target.calories - expenditure;
    final deficitText = deficitSurplus < -10
        ? '${deficitSurplus.round()} kcal deficit'
        : deficitSurplus > 10
            ? '+${deficitSurplus.round()} kcal surplus'
            : 'Energy balance (0 kcal)';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PROJECTED DAILY TARGETS',
                  style: TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  deficitText,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.calories,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${target.calories.round()}',
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.calories,
                  ),
                ),
                const Text(
                  'kcal / day',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMacroPreviewPill('PROTEIN',
                    '${target.proteinGrams.round()}g', AppTheme.protein),
                const SizedBox(width: 8),
                _buildMacroPreviewPill(
                    'FAT', '${target.fatGrams.round()}g', AppTheme.fat),
                const SizedBox(width: 8),
                _buildMacroPreviewPill(
                    'CARBS', '${target.carbsGrams.round()}g', AppTheme.carbs),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroPreviewPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
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

  Widget _buildProgramModeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PROGRAM MODE',
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSelectableChip<ProgramMode>(
                  label: 'Coached',
                  value: ProgramMode.coached,
                  groupValue: _programMode,
                  onSelected: (val) => setState(() => _programMode = val),
                ),
                const SizedBox(width: 8),
                _buildSelectableChip<ProgramMode>(
                  label: 'Collaborative',
                  value: ProgramMode.collaborative,
                  groupValue: _programMode,
                  onSelected: (val) => setState(() => _programMode = val),
                ),
                const SizedBox(width: 8),
                _buildSelectableChip<ProgramMode>(
                  label: 'Manual',
                  value: ProgramMode.manual,
                  groupValue: _programMode,
                  onSelected: (val) => setState(() => _programMode = val),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTypeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GOAL TYPE',
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSelectableChip<GoalType>(
                  label: 'Fat Loss',
                  value: GoalType.fatLoss,
                  groupValue: _goalType,
                  onSelected: (val) {
                    setState(() {
                      _goalType = val;
                      _weeklyRate = -0.5;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildSelectableChip<GoalType>(
                  label: 'Maintain',
                  value: GoalType.maintenance,
                  groupValue: _goalType,
                  onSelected: (val) {
                    setState(() {
                      _goalType = val;
                      _weeklyRate = 0.0;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildSelectableChip<GoalType>(
                  label: 'Gain Muscle',
                  value: GoalType.muscleGain,
                  groupValue: _goalType,
                  onSelected: (val) {
                    setState(() {
                      _goalType = val;
                      _weeklyRate = 0.25;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateOfChangeCard(double currentWeight) {
    final isLoss = _goalType == GoalType.fatLoss;
    final minRate = isLoss ? -1.0 : 0.1;
    final maxRate = isLoss ? -0.2 : 0.5;
    final deltaKgPerWeek = (currentWeight * (_weeklyRate.abs() / 100.0));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'WEEKLY RATE OF CHANGE',
                  style: TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${_weeklyRate > 0 ? '+' : ''}${_weeklyRate.toStringAsFixed(2)}% / week',
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.calories,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${deltaKgPerWeek.toStringAsFixed(2)} kg / week',
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.calories,
                thumbColor: AppTheme.calories,
                inactiveTrackColor: AppTheme.cardElevated,
                overlayColor: AppTheme.calories.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: _weeklyRate.clamp(minRate, maxRate),
                min: minRate,
                max: maxRate,
                divisions: isLoss ? 16 : 8,
                onChanged: (val) {
                  setState(
                      () => _weeklyRate = double.parse(val.toStringAsFixed(2)));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProteinPreferenceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PROTEIN INTAKE PREFERENCE',
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSelectableChip<ProteinPreference>(
                  label: 'Moderate\n(1.6 g/kg)',
                  value: ProteinPreference.moderate,
                  groupValue: _proteinPreference,
                  onSelected: (val) => setState(() => _proteinPreference = val),
                ),
                const SizedBox(width: 8),
                _buildSelectableChip<ProteinPreference>(
                  label: 'High\n(2.0 g/kg)',
                  value: ProteinPreference.high,
                  groupValue: _proteinPreference,
                  onSelected: (val) => setState(() => _proteinPreference = val),
                ),
                const SizedBox(width: 8),
                _buildSelectableChip<ProteinPreference>(
                  label: 'Extra High\n(2.4 g/kg)',
                  value: ProteinPreference.extraHigh,
                  groupValue: _proteinPreference,
                  onSelected: (val) => setState(() => _proteinPreference = val),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableChip<T>({
    required String label,
    required T value,
    required T groupValue,
    required ValueChanged<T> onSelected,
  }) {
    final isSelected = value == groupValue;
    return Expanded(
      child: InkWell(
        onTap: () => onSelected(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.calories.withValues(alpha: 0.15)
                : AppTheme.cardElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.calories : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.calories : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
