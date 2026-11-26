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
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null || !context.mounted) return;
    final notifier = ref.read(dailyFoodLogsProvider.notifier);
    for (final entry in _selectedEntries) {
      notifier.addEntry(
        food: entry.food,
        portionUnit: entry.portionUnit,
        quantity: entry.quantity,
        mealType: entry.mealType,
        oilModifier: entry.oilModifier,
        loggedAt: DateTime(
          picked.year,
          picked.month,
          picked.day,
          entry.loggedAt.hour,
          entry.loggedAt.minute,
        ),
      );
    }
    final count = _selectedEntries.length;
    onClear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied $count item(s) to ${DateFormat('MMM d').format(picked)}',
        ),
      ),
    );
  }

  Future<void> _batchMoveToDate(BuildContext context, WidgetRef ref) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null || !context.mounted) return;
    final notifier = ref.read(dailyFoodLogsProvider.notifier);
    for (final entry in _selectedEntries) {
      notifier.addEntry(
        food: entry.food,
        portionUnit: entry.portionUnit,
        quantity: entry.quantity,
        mealType: entry.mealType,
        oilModifier: entry.oilModifier,
        loggedAt: DateTime(
          picked.year,
          picked.month,
          picked.day,
          entry.loggedAt.hour,
          entry.loggedAt.minute,
        ),
      );
      notifier.removeEntry(entry.id);
    }
    final count = _selectedEntries.length;
    onClear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Moved $count item(s) to ${DateFormat('MMM d').format(picked)}',
        ),
      ),
    );
  }

  void _batchDelete(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(dailyFoodLogsProvider.notifier);
    final count = _selectedEntries.length;
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
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: Colors.redAccent),
            onPressed:
                selectedIds.isEmpty ? null : () => _batchDelete(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppTheme.textSecondary),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
