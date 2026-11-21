import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sique/domain/algorithms/weight_trend_v2.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_sheet_grabber.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

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

  Timer? _stepperTimer;

  @override
  void dispose() {
    _stepperTimer?.cancel();
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _startStepperHold(double delta) {
    _stepperTimer?.cancel();
    int ticks = 0;
    _adjustWeight(delta);
    _stepperTimer = Timer.periodic(const Duration(milliseconds: 140), (timer) {
      ticks++;
      final step =
          (ticks > 12) ? (delta * 5) : (ticks > 5 ? (delta * 2) : delta);
      _adjustWeight(step);
    });
  }

  void _stopStepperHold() {
    _stepperTimer?.cancel();
    _stepperTimer = null;
  }

  void _adjustWeight(double delta) {
    AppHaptics.lightImpact();
    final current =
        double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 70.0;
    final updated = (current + delta).clamp(10.0, 500.0);
    setState(() {
      _weightController.text = updated.toStringAsFixed(1);
    });
  }

  void _toggleContextChip(String tag) {
    AppHaptics.selectionClick();
    final current = _noteController.text;
    if (current.contains(tag)) {
      final updated = current
          .replaceAll(tag, '')
          .replaceAll(RegExp(r'\s*,\s*'), ', ')
          .replaceAll(RegExp(r'^,\s*|,\s*$'), '')
          .trim();
      setState(() => _noteController.text = updated);
    } else {
      final updated = current.trim().isEmpty ? tag : '$current, $tag';
      setState(() => _noteController.text = updated);
    }
  }

  void _handleSave(double parsedWeight) {
    if (_isSubmitting) return; // Debounce guard (ISS-8-08)
    setState(() => _isSubmitting = true);

    try {
      AppHaptics.successFeedback();
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
      AppHaptics.mediumImpact();
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
    final double? parsedWeight =
        double.tryParse(_weightController.text.replaceAll(',', '.'));
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
        color: AppTheme.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: AppTheme.cardBorder,
          width: 0.8,
        ),
      ),
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
                const AppleSheetGrabber(margin: EdgeInsets.only(bottom: 12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Log scale weight',
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
                        onPressed: () => _handleDelete(existingEntryForDate),
                      ),
                      const SizedBox(width: 4),
                    ],
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

                // Numeric Weight Input with Flanking Steppers (-0.1 / +0.1)
                Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Decrease weight by 0.1 kilograms',
                      child: GestureDetector(
                        onLongPressStart: (_) => _startStepperHold(-0.1),
                        onLongPressEnd: (_) => _stopStepperHold(),
                        onLongPressCancel: _stopStepperHold,
                        child: AppleBouncy(
                          scaleDown: 0.90,
                          onTap: () => _adjustWeight(-0.1),
                          child: Container(
                            width: 48,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppTheme.cardElevated,
                              borderRadius: AppRadii.lgBorderRadius,
                              border: Border.all(
                                  color: AppTheme.cardBorder, width: 0.8),
                            ),
                            child: const Center(
                              child: Text(
                                '-0.1',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: AppRadii.lgBorderRadius,
                          border:
                              Border.all(color: AppTheme.cardBorder, width: 1),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                label: 'Scale weight in kilograms',
                                child: TextField(
                                  controller: _weightController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: false,
                                  ),
                                  textInputAction: TextInputAction.next,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*[\.,]?\d*'),
                                    ),
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
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      button: true,
                      label: 'Increase weight by 0.1 kilograms',
                      child: GestureDetector(
                        onLongPressStart: (_) => _startStepperHold(0.1),
                        onLongPressEnd: (_) => _stopStepperHold(),
                        onLongPressCancel: _stopStepperHold,
                        child: AppleBouncy(
                          scaleDown: 0.90,
                          onTap: () => _adjustWeight(0.1),
                          child: Container(
                            width: 48,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppTheme.cardElevated,
                              borderRadius: AppRadii.lgBorderRadius,
                              border: Border.all(
                                  color: AppTheme.cardBorder, width: 0.8),
                            ),
                            child: const Center(
                              child: Text(
                                '+0.1',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 13,
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Scale weight fluctuates with hydration and salt. Trend weight smooths the noise.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Trend Weight Preview Pill with Dot
                if (previewTrendWeight != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.trendWeight.withValues(alpha: 0.12),
                      borderRadius: AppRadii.mdBorderRadius,
                      border: Border.all(
                          color: AppTheme.trendWeight.withValues(alpha: 0.4),
                          width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.trendWeight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.auto_graph,
                            size: 16, color: AppTheme.trendWeight),
                        const SizedBox(width: 8),
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

                // 4 Context Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: const ['Fasted', 'Post-meal', 'High salt', 'Travel']
                      .map((chip) {
                    final isSelected = _noteController.text.contains(chip);
                    return Semantics(
                      button: true,
                      selected: isSelected,
                      label: chip,
                      child: AppleBouncy(
                        scaleDown: 0.94,
                        onTap: () => _toggleContextChip(chip),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.buttonBackground
                                : AppTheme.cardElevated,
                            borderRadius: AppRadii.xlBorderRadius,
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.buttonBackground
                                  : AppTheme.cardBorder,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            chip,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.buttonText
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

                // Note Input
                TextField(
                  controller: _noteController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText:
                        'Note (optional, e.g. morning fasted, post walk)...',
                    hintStyle: TextStyle(
                        fontSize: 13, color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.surface,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.mdBorderRadius,
                      borderSide: BorderSide(color: AppTheme.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadii.mdBorderRadius,
                      borderSide: BorderSide(color: AppTheme.cardBorder),
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
                            parsedWeight >= 20.0 &&
                            parsedWeight <= 350.0 &&
                            !_isSubmitting)
                        ? () => _handleSave(parsedWeight)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.buttonBackground,
                      foregroundColor: AppTheme.buttonText,
                      disabledBackgroundColor: AppTheme.cardBorder,
                      disabledForegroundColor: AppTheme.textMuted,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.lgBorderRadius),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                          _isSubmitting ? 'Saving...' : 'Save scale weight'),
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
    );
  }
}
