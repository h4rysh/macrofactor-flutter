import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:macro_factor_app/domain/algorithms/weight_trend_v2.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';
import 'package:macro_factor_app/presentation/theme/app_theme.dart';

/// Modal bottom sheet for logging scale weight with instant trend weight preview.
class WeightLogModal extends ConsumerStatefulWidget {
  const WeightLogModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const WeightLogModal(),
    );
  }

  @override
  ConsumerState<WeightLogModal> createState() => _WeightLogModalState();
}

class _WeightLogModalState extends ConsumerState<WeightLogModal> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  late String _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Pre-populate with previous weight if available
    final latestWeight = ref.read(weightLogsProvider);
    if (latestWeight.isNotEmpty) {
      _weightController.text = latestWeight.last.weightKg.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double? parsedWeight = double.tryParse(_weightController.text);
    final existingWeights = ref.watch(weightLogsProvider);

    // Compute preview trend weight if weight is entered
    double? previewTrendWeight;
    if (parsedWeight != null && parsedWeight > 30.0 && parsedWeight < 300.0) {
      final simulatedList = List<ScaleWeightEntry>.from(existingWeights)
        ..removeWhere(
            (e) => DateFormat('yyyy-MM-dd').format(e.date) == _selectedDate)
        ..add(ScaleWeightEntry(
          date: DateTime.parse(_selectedDate),
          weightKg: parsedWeight,
        ));

      final series = WeightTrendV2Series.compute(
          entries: simulatedList, bidirectional: true);
      if (series.points.isNotEmpty) {
        previewTrendWeight = series.points.last.trendWeightKg;
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LOG SCALE WEIGHT',
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.parse(_selectedDate),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today,
                    size: 14, color: AppTheme.calories),
                label: Text(
                  _selectedDate,
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 13,
                    color: AppTheme.calories,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Numeric Weight Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0.0',
                      hintStyle: TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textMuted,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const Text(
                  'KG',
                  style: TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Trend Weight Preview Pill
          if (previewTrendWeight != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.trendWeight.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.trendWeight.withValues(alpha: 0.4),
                    width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_graph,
                      size: 18, color: AppTheme.trendWeight),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Preview: Resulting Trend Weight will be ${previewTrendWeight.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),

          // Note Input
          TextField(
            controller: _noteController,
            style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 14,
                color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Note (optional, e.g. morning fasted, post walk)...',
              hintStyle: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.cardBorder),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: parsedWeight != null && parsedWeight > 0
                  ? () {
                      final note = _noteController.text.trim();
                      ref.read(weightLogsProvider.notifier).logWeight(
                            _selectedDate,
                            parsedWeight,
                            note.isNotEmpty ? note : null,
                          );
                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Logged ${parsedWeight.toStringAsFixed(1)} kg for $_selectedDate'),
                          backgroundColor: AppTheme.cardSurface,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.calories,
                foregroundColor: AppTheme.background,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('SAVE SCALE WEIGHT'),
            ),
          ),
        ],
      ),
    );
  }
}
