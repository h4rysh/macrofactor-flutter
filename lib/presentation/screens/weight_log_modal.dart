import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sique/domain/algorithms/weight_trend_v2.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_sheet_grabber.dart';

/// Modal bottom sheet for logging scale weight with instant trend weight preview.
class WeightLogModal extends ConsumerStatefulWidget {
  const WeightLogModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
  bool _isSubmitting = false; // Button submission debouncing (ISS-8-08)

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

  void _handleSave(double parsedWeight) {
    if (_isSubmitting) return; // Debounce guard (ISS-8-08)
    setState(() => _isSubmitting = true);

    try {
      HapticFeedback.mediumImpact();
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _handleDelete(ScaleWeightEntry entry) {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      HapticFeedback.mediumImpact();
      final dateStr = DateFormat('yyyy-MM-dd').format(entry.date);
      ref.read(weightLogsProvider.notifier).deleteWeight(dateStr);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted weight log for $dateStr'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppTheme.activeBlue,
            onPressed: () {
              ref.read(weightLogsProvider.notifier).logWeight(
                    dateStr,
                    entry.weightKg,
                    entry.note,
                  );
            },
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double? parsedWeight = double.tryParse(_weightController.text);
    final existingWeights = ref.watch(weightLogsProvider);
    final mediaQuery = MediaQuery.of(context);
    final existingEntryForDate = existingWeights
        .where(
          (e) => DateFormat('yyyy-MM-dd').format(e.date) == _selectedDate,
        )
        .firstOrNull;

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

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface.withValues(alpha: 0.88),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: SafeArea(
            top: false,
            bottom: true, // Bottom SafeArea padding (ISS-7-08)
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: mediaQuery.viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Apple Sheet Grabber
                    const AppleSheetGrabber(
                        margin: EdgeInsets.only(bottom: 12)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'LOG SCALE WEIGHT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (existingEntryForDate != null) ...[
                          IconButton(
                            key: const Key('weight_log_delete_btn'),
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 20, color: AppTheme.calories),
                            tooltip: 'Delete weight log',
                            onPressed: () =>
                                _handleDelete(existingEntryForDate),
                          ),
                          const SizedBox(width: 4),
                        ],
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.parse(_selectedDate),
                              firstDate: DateTime(2020),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 1)),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDate =
                                    DateFormat('yyyy-MM-dd').format(picked);
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today,
                              size: 14, color: AppTheme.calories),
                          label: Text(
                            _selectedDate,
                            style: const TextStyle(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: AppTheme.cardBorder, width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _weightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*')),
                              ],
                              autofocus: true,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                              decoration: const InputDecoration(
                                hintText: '0.0',
                                hintStyle: TextStyle(
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.trendWeight.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  AppTheme.trendWeight.withValues(alpha: 0.4),
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                  fontFeatures: [FontFeature.tabularFigures()],
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
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(
                          fontSize: 14, color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText:
                            'Note (optional, e.g. morning fasted, post walk)...',
                        hintStyle: const TextStyle(
                            fontSize: 13, color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppTheme.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppTheme.cardBorder),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button with debouncing (ISS-8-08)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (parsedWeight != null &&
                                parsedWeight > 0 &&
                                !_isSubmitting)
                            ? () => _handleSave(parsedWeight)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.calories,
                          foregroundColor: AppTheme.background,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(_isSubmitting
                              ? 'SAVING...'
                              : 'SAVE SCALE WEIGHT'),
                        ),
                      ),
                    ),
                    if (existingEntryForDate != null) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          key: const Key('weight_log_delete_text_btn'),
                          onPressed: () => _handleDelete(existingEntryForDate),
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 16, color: AppTheme.calories),
                          label: const Text(
                            'Delete Weight Log for This Date',
                            style: TextStyle(
                              color: AppTheme.calories,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
