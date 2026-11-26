import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/algorithms/coaching_engine.dart';
import '../../../domain/models/macro_program.dart';
import '../../../domain/models/user_profile.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../animated_primitives.dart';
import '../apple_sheet_grabber.dart';

/// Interactive MacroFactor-grade customization sheet supporting both:
/// - Collaborative Mode: Locks Bayesian calorie budget while customizing Carb/Fat ratio,
///   day allocation pattern, and training days.
/// - Manual Mode: Direct full-control customization of calories, protein, carbs, and fat.
class CollaborativeMacroEditorSheet extends ConsumerStatefulWidget {
  const CollaborativeMacroEditorSheet({
    super.key,
    required this.mode,
  });

  final ProgramMode mode;

  static Future<void> show(BuildContext context, {required ProgramMode mode}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CollaborativeMacroEditorSheet(mode: mode),
    );
  }

  @override
  ConsumerState<CollaborativeMacroEditorSheet> createState() =>
      _CollaborativeMacroEditorSheetState();
}

class _CollaborativeMacroEditorSheetState
    extends ConsumerState<CollaborativeMacroEditorSheet> {
  // Collaborative state
  late double _carbSharePct;
  late DayAllocationType _allocationType;
  late Set<int> _workoutDays;

  // Manual state
  late TextEditingController _calCtrl;
  late TextEditingController _proteinCtrl;
  late TextEditingController _carbsCtrl;
  late TextEditingController _fatCtrl;

  @override
  void initState() {
    super.initState();
    final program = ref.read(weeklyMacroProgramProvider);
    final profile = ref.read(userProfileProvider);
    final rep = program.days.first;

    final nonProt = (rep.carbsGrams * 4.0) + (rep.fatGrams * 9.0);
    _carbSharePct = nonProt > 0
        ? ((rep.carbsGrams * 4.0) / nonProt).clamp(0.20, 0.80)
        : 0.55;
    _allocationType = program.allocationType;
    _workoutDays = Set<int>.from(program.workoutDays);

    _calCtrl = TextEditingController(
      text: (profile.customCalories ?? program.dailyAverageCalories)
          .round()
          .toString(),
    );
    _proteinCtrl = TextEditingController(
      text: (profile.customProteinGrams ?? rep.proteinGrams).round().toString(),
    );
    _carbsCtrl = TextEditingController(
      text: (profile.customCarbsGrams ?? rep.carbsGrams).round().toString(),
    );
    _fatCtrl = TextEditingController(
      text: (profile.customFatGrams ?? rep.fatGrams).round().toString(),
    );
  }

  @override
  void dispose() {
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  void _reconcileManualCaloriesFromMacros() {
    final p = double.tryParse(_proteinCtrl.text) ?? 0;
    final c = double.tryParse(_carbsCtrl.text) ?? 0;
    final f = double.tryParse(_fatCtrl.text) ?? 0;
    final kcals = (p * 4.0) + (c * 4.0) + (f * 9.0);
    if (kcals > 0) {
      setState(() => _calCtrl.text = kcals.round().toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isManual = widget.mode == ProgramMode.manual;
    final profile = ref.watch(userProfileProvider);
    final expenditure = ref.watch(expenditureStateProvider);
    final program = ref.watch(weeklyMacroProgramProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    final avgCals = CoachingEngine.calculateDailyAverageCalories(
      profile: profile.copyWith(clearCustom: true),
      expenditureKcal: expenditure.expenditureKcal,
      previousAvgCalories: program.dailyAverageCalories,
    );

    final previewMacros = CoachingEngine.computeDayMacros(
      calories: avgCals,
      weightKg: profile.currentWeightKg,
      style: program.style,
      proteinPref: profile.proteinPreference,
      carbShareOverride: _carbSharePct,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppTheme.cardBorder, width: 0.8),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            bottomInset > 0 ? bottomInset : 18,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppleSheetGrabber(margin: EdgeInsets.only(bottom: 10)),
                Row(
                  children: [
                    Icon(
                      isManual ? Icons.edit_rounded : Icons.handshake_rounded,
                      color: AppTheme.activeBlue,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isManual
                            ? 'Manual Macro & Calorie Override'
                            : 'Collaborative Budget Designer',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded,
                          color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isManual
                      ? 'Set your exact daily macro targets. Sique continues tracking your daily burn in the background.'
                      : 'Your energy budget (${avgCals.round()} kcal/day) is optimized by the expenditure engine. Fine-tune your carb-to-fat balance and high-day schedule below.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                if (isManual)
                  _buildManualFields(profile.calorieFloor)
                else
                  _buildCollaborativeControls(previewMacros),
                const SizedBox(height: 18),
                AppleBouncy(
                  scaleDown: 0.96,
                  onTap: () {
                    AppHaptics.successFeedback();
                    if (isManual) {
                      final cal = double.tryParse(_calCtrl.text) ??
                          program.dailyAverageCalories;
                      final p = double.tryParse(_proteinCtrl.text) ?? 150.0;
                      final c = double.tryParse(_carbsCtrl.text) ?? 200.0;
                      final f = double.tryParse(_fatCtrl.text) ?? 60.0;
                      ref
                          .read(weeklyMacroProgramProvider.notifier)
                          .applyManualTargets(
                            calories: cal.clamp(800.0, 6500.0),
                            proteinGrams: p.clamp(30.0, 600.0),
                            carbsGrams: c.clamp(0.0, 1200.0),
                            fatGrams: f.clamp(15.0, 400.0),
                          );
                    } else {
                      ref
                          .read(weeklyMacroProgramProvider.notifier)
                          .applyCollaborativeCustomization(
                            carbSharePct: _carbSharePct,
                            allocationType: _allocationType,
                            workoutDays: _workoutDays,
                          );
                    }
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                      color: AppTheme.calories,
                      borderRadius: AppRadii.lgBorderRadius,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isManual
                          ? 'Lock Manual Targets'
                          : 'Apply Collaborative Split',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollaborativeControls(MacroTarget preview) {
    final fatSharePct = ((1.0 - _carbSharePct) * 100).round();
    final carbPct = (_carbSharePct * 100).round();
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroMini(
                  label: 'Protein',
                  value: '${preview.proteinGrams.round()}g',
                  color: AppTheme.protein),
              _MacroMini(
                  label: 'Carbs',
                  value: '${preview.carbsGrams.round()}g',
                  color: AppTheme.carbs),
              _MacroMini(
                  label: 'Fat',
                  value: '${preview.fatGrams.round()}g',
                  color: AppTheme.fat),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ENERGY FUEL SPLIT (CARB vs FAT)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
                letterSpacing: 0.7,
              ),
            ),
            Text(
              '$carbPct% Carbs / $fatSharePct% Fat',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.carbs,
              ),
            ),
          ],
        ),
        Slider(
          value: _carbSharePct,
          min: 0.20,
          max: 0.80,
          divisions: 12,
          activeColor: AppTheme.carbs,
          inactiveColor: AppTheme.fat.withValues(alpha: 0.35),
          onChanged: (v) {
            AppHaptics.selectionClick();
            setState(() => _carbSharePct = v);
          },
        ),
        const SizedBox(height: 10),
        const Text(
          'WEEKLY DAY SHIFTING',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.textSecondary,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final type in [
              DayAllocationType.even,
              DayAllocationType.shiftedWorkout,
              DayAllocationType.weekendShift,
            ])
              ChoiceChip(
                label: Text(type.displayName),
                selected: _allocationType == type,
                selectedColor: AppTheme.calories.withValues(alpha: 0.22),
                onSelected: (_) {
                  AppHaptics.selectionClick();
                  setState(() => _allocationType = type);
                },
              ),
          ],
        ),
        if (_allocationType == DayAllocationType.shiftedWorkout) ...[
          const SizedBox(height: 12),
          const Text(
            'HIGH-ENERGY TRAINING DAYS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textSecondary,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (idx) {
              final day = idx + 1;
              final active = _workoutDays.contains(day);
              return GestureDetector(
                onTap: () {
                  AppHaptics.selectionClick();
                  setState(() {
                    if (active && _workoutDays.length > 1) {
                      _workoutDays.remove(day);
                    } else {
                      _workoutDays.add(day);
                    }
                  });
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      active ? AppTheme.calories : AppTheme.cardElevated,
                  child: Text(
                    dayLabels[idx],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: active ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildManualFields(double calorieFloor) {
    final cal = double.tryParse(_calCtrl.text) ?? 0;
    final belowFloor = cal > 0 && cal < calorieFloor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ManualField(
          controller: _calCtrl,
          label: 'Daily Calories (kcal)',
          color: AppTheme.calories,
        ),
        if (belowFloor)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Note: Below your configured safety floor (${calorieFloor.round()} kcal).',
              style: const TextStyle(fontSize: 11, color: AppTheme.warning),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ManualField(
                controller: _proteinCtrl,
                label: 'Protein (g)',
                color: AppTheme.protein,
                onChanged: (_) => _reconcileManualCaloriesFromMacros(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ManualField(
                controller: _carbsCtrl,
                label: 'Carbs (g)',
                color: AppTheme.carbs,
                onChanged: (_) => _reconcileManualCaloriesFromMacros(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ManualField(
                controller: _fatCtrl,
                label: 'Fat (g)',
                color: AppTheme.fat,
                onChanged: (_) => _reconcileManualCaloriesFromMacros(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MacroMini extends StatelessWidget {
  const _MacroMini({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _ManualField extends StatelessWidget {
  const _ManualField({
    required this.controller,
    required this.label,
    required this.color,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final Color color;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 11, color: color),
        filled: true,
        fillColor: AppTheme.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}
