import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_sheet_grabber.dart';

/// MacroFactor-parity Quick-Add Macros sheet (direct P/C/F/kcal entry without creating a food).
class QuickAddMacrosSheet extends ConsumerStatefulWidget {
  const QuickAddMacrosSheet({
    super.key,
    required this.date,
    required this.mealType,
    required this.loggedAt,
  });

  final DateTime date;
  final MealType mealType;
  final DateTime loggedAt;

  static Future<void> show(
    BuildContext context, {
    required DateTime date,
    MealType mealType = MealType.snacks,
    DateTime? loggedAt,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => QuickAddMacrosSheet(
        date: date,
        mealType: mealType,
        loggedAt: loggedAt ?? DateTime.now(),
      ),
    );
  }

  @override
  ConsumerState<QuickAddMacrosSheet> createState() =>
      _QuickAddMacrosSheetState();
}

class _QuickAddMacrosSheetState extends ConsumerState<QuickAddMacrosSheet> {
  final _nameCtrl = TextEditingController(text: 'Quick Add Macros');
  final _kcalCtrl = TextEditingController();
  final _protCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _kcalCtrl.dispose();
    _protCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  void _recalcKcalIfAuto() {
    final p = double.tryParse(_protCtrl.text) ?? 0;
    final c = double.tryParse(_carbCtrl.text) ?? 0;
    final f = double.tryParse(_fatCtrl.text) ?? 0;
    final est = (p * 4) + (c * 4) + (f * 9);
    if (est > 0) {
      _kcalCtrl.text = est.round().toString();
    }
  }

  void _submit() {
    final p = double.tryParse(_protCtrl.text.trim()) ?? 0.0;
    final c = double.tryParse(_carbCtrl.text.trim()) ?? 0.0;
    final f = double.tryParse(_fatCtrl.text.trim()) ?? 0.0;
    final kcal =
        double.tryParse(_kcalCtrl.text.trim()) ?? ((p * 4) + (c * 4) + (f * 9));
    if (kcal <= 0 && p <= 0 && c <= 0 && f <= 0) {
      setState(() {
        _validationError =
            'Enter at least one positive value for calories or macros.';
      });
      return;
    }
    if (_validationError != null) {
      setState(() => _validationError = null);
    }

    final label = _nameCtrl.text.trim().isEmpty
        ? 'Quick Add Macros'
        : _nameCtrl.text.trim();
    final id = -DateTime.now().millisecondsSinceEpoch;
    final virtualFood = FoodItem(
      id: id,
      uuid: 'quick_${DateTime.now().millisecondsSinceEpoch}',
      name: label,
      category: 'Quick Add',
      region: 'Custom',
      caloriesPer100g: kcal,
      proteinPer100g: p,
      carbsPer100g: c,
      fatPer100g: f,
      fiberPer100g: 0.0,
      iconSvg: 'i2.svg',
      source: 'QUICK_ADD',
      aliases: 'quick add',
    );
    final unit = PortionUnit(
      id: 0,
      foodId: id,
      unitName: 'serving',
      gramsPerUnit: 100.0,
      isDefault: true,
    );
    ref.read(dailyFoodLogsProvider.notifier).addEntry(
          food: virtualFood,
          portionUnit: unit,
          quantity: 1.0,
          mealType: widget.mealType,
          oilModifier: OilModifier.none,
          loggedAt: widget.loggedAt,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 10, 20, bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppleSheetGrabber(margin: EdgeInsets.only(bottom: 10)),
            const Text(
              'Quick Add Macros',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            if (_validationError != null) ...[
              const SizedBox(height: 8),
              Text(
                _validationError!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.errorText,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Label (optional)'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _protCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Protein (g)'),
                    onChanged: (_) => _recalcKcalIfAuto(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _carbCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Carbs (g)'),
                    onChanged: (_) => _recalcKcalIfAuto(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fatCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Fat (g)'),
                    onChanged: (_) => _recalcKcalIfAuto(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _kcalCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Calories (kcal)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonBackground,
                foregroundColor: AppTheme.buttonText,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text(
                'Log Macros',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
