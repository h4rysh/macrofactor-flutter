import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Floating multi-select action bar for Batch Copy, Batch Move, and Batch Delete.
class BatchDiaryToolbar extends ConsumerWidget {
  const BatchDiaryToolbar({
    super.key,
    required this.selectedIds,
    required this.dayLogs,
    required this.onClear,
  });

  final Set<int> selectedIds;
  final List<DailyFoodLogEntry> dayLogs;
  final VoidCallback onClear;

  List<DailyFoodLogEntry> get _selectedEntries =>
      dayLogs.where((e) => selectedIds.contains(e.id)).toList();

  Future<void> _batchCopyToDate(BuildContext context, WidgetRef ref) async {
    final now = ref.read(clockProvider)();
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null || !context.mounted) return;
    final notifier = ref.read(dailyFoodLogsProvider.notifier);
    final dateStr = DateFormat('yyyy-MM-dd').format(picked);
    final selected = _selectedEntries;
    final entries = selected.map((entry) {
      final n = entry.food.calculateNutrition(
        quantity: entry.quantity,
        unit: entry.portionUnit,
        oilModifier: entry.oilModifier,
      );
      return FoodLogEntry(
        id: 0,
        date: dateStr,
        mealType: entry.mealType,
        foodId: entry.food.id,
        foodName: entry.food.name,
        servingQuantity: entry.quantity,
        unitName: entry.portionUnit.unitName,
        gramWeight: n.totalGrams,
        calories: n.calories,
        protein: n.protein,
        carbs: n.carbs,
        fat: n.fat,
        fiber: n.fiber,
        oilModifier: entry.oilModifier,
        loggedAt: DateTime(
          picked.year,
          picked.month,
          picked.day,
          entry.loggedAt.hour,
          entry.loggedAt.minute,
        ),
        iconSvg: entry.iconSvg,
      );
    }).toList();
    notifier.addEntries(entries);
    final count = entries.length;
    onClear();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Copied $count item(s) to ${DateFormat('MMM d').format(picked)}',
        ),
      ),
    );
  }

  Future<void> _batchMoveToDate(BuildContext context, WidgetRef ref) async {
    final now = ref.read(clockProvider)();
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null || !context.mounted) return;
    final notifier = ref.read(dailyFoodLogsProvider.notifier);
    final dateStr = DateFormat('yyyy-MM-dd').format(picked);
    final selected = _selectedEntries;
    final entries = selected.map((entry) {
      final n = entry.food.calculateNutrition(
        quantity: entry.quantity,
        unit: entry.portionUnit,
        oilModifier: entry.oilModifier,
      );
      return FoodLogEntry(
        id: 0,
        date: dateStr,
        mealType: entry.mealType,
        foodId: entry.food.id,
        foodName: entry.food.name,
        servingQuantity: entry.quantity,
        unitName: entry.portionUnit.unitName,
        gramWeight: n.totalGrams,
        calories: n.calories,
        protein: n.protein,
        carbs: n.carbs,
        fat: n.fat,
        fiber: n.fiber,
        oilModifier: entry.oilModifier,
        loggedAt: DateTime(
          picked.year,
          picked.month,
          picked.day,
          entry.loggedAt.hour,
          entry.loggedAt.minute,
        ),
        iconSvg: entry.iconSvg,
      );
    }).toList();
    notifier.addEntries(entries);
    for (final entry in selected) {
      notifier.removeEntry(entry.id);
    }
    final count = entries.length;
    onClear();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Moved $count item(s) to ${DateFormat('MMM d').format(picked)}',
        ),
      ),
    );
  }

  Future<void> _batchDelete(BuildContext context, WidgetRef ref) async {
    final count = _selectedEntries.length;
    if (count == 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: Text('Delete $count selected item${count == 1 ? '' : 's'}?'),
        content: const Text(
          'This removes the selected food log entries from this day.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final notifier = ref.read(dailyFoodLogsProvider.notifier);
    for (final entry in _selectedEntries) {
      notifier.removeEntry(entry.id);
    }
    onClear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted $count item(s)')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.activeBlue.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Text(
            '${selectedIds.length} selected',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: selectedIds.isEmpty
                ? null
                : () => _batchCopyToDate(context, ref),
            icon: const Icon(Icons.copy_rounded, size: 15),
            label: const Text('Copy', style: TextStyle(fontSize: 12)),
          ),
          TextButton.icon(
            onPressed: selectedIds.isEmpty
                ? null
                : () => _batchMoveToDate(context, ref),
            icon: const Icon(Icons.drive_file_move_outline, size: 15),
            label: const Text('Move', style: TextStyle(fontSize: 12)),
          ),
          IconButton(
            tooltip: 'Delete selected',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppTheme.errorText),
            onPressed:
                selectedIds.isEmpty ? null : () => _batchDelete(context, ref),
          ),
          IconButton(
            tooltip: 'Clear selection',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppTheme.textSecondary),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
