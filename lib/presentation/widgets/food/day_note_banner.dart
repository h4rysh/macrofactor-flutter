import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sique/data/local/dao/diary_tools_dao.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Compact Diary Strip showing Day Notes & 1-tap Pending Repeat Items for [date].
class DayNoteAndRepeatsBanner extends ConsumerWidget {
  const DayNoteAndRepeatsBanner({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    ref.watch(foodLogsRevisionProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final note = db.diaryToolsDao.getDayNote(dateStr);
    final repeats = db.diaryToolsDao.getPendingRepeatItemsForDate(date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.add_rounded,
                      size: 14, color: AppTheme.textSecondary),
                  label: const Text(
                    'Repeat',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  backgroundColor: AppTheme.cardSurface,
                  side: const BorderSide(color: AppTheme.cardBorder),
                  onPressed: () => _pickRepeatFood(context, ref, date),
                ),
                for (final r in repeats) ...[
                  const SizedBox(width: 8),
                  InputChip(
                    avatar: const Icon(Icons.repeat_rounded,
                        size: 14, color: AppTheme.activeBlue),
                    label: Text(
                      '${r.foodName} (${r.calories.round()})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    backgroundColor: AppTheme.cardSurface,
                    side: BorderSide(
                        color: AppTheme.activeBlue.withValues(alpha: 0.4)),
                    onDeleted: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppTheme.cardSurface,
                          title: const Text('Remove repeat item?'),
                          content: Text(
                            'Stop showing "${r.foodName}" as a daily repeat suggestion?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        db.diaryToolsDao.deleteRepeatItem(r.id);
                        ref.read(foodLogsRevisionProvider.notifier).state++;
                      }
                    },
                    onPressed: () {
                      final meal = MealType.values.firstWhere(
                        (m) => m.name == r.mealType,
                        orElse: () => MealType.breakfast,
                      );
                      final g = r.gramWeight > 0 ? r.gramWeight : 100.0;
                      final factor = 100.0 / g;
                      final virtualFood = FoodItem(
                        id: r.foodId,
                        uuid: 'repeat_${r.id}',
                        name: r.foodName,
                        category: 'Repeat',
                        region: 'Custom',
                        caloriesPer100g: r.calories * factor,
                        proteinPer100g: r.protein * factor,
                        carbsPer100g: r.carbs * factor,
                        fatPer100g: r.fat * factor,
                        fiberPer100g: r.fiber * factor,
                        iconSvg: 'i2.svg',
                        source: 'REPEAT',
                        aliases: r.foodName,
                      );
                      final unit = PortionUnit(
                        id: 0,
                        foodId: r.foodId,
                        unitName: r.unitName,
                        gramsPerUnit: g /
                            (r.servingQuantity > 0 ? r.servingQuantity : 1.0),
                        isDefault: true,
                      );
                      ref.read(dailyFoodLogsProvider.notifier).addEntry(
                            food: virtualFood,
                            portionUnit: unit,
                            quantity: r.servingQuantity,
                            mealType: meal,
                            oilModifier: OilModifier.none,
                            loggedAt: DateTime(
                                date.year, date.month, date.day, r.hour, 0),
                          );
                      db.diaryToolsDao.markRepeatItemLogged(r.id, dateStr);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _editNote(context, ref, dateStr, note ?? ''),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    size: 16,
                    color: note != null && note.isNotEmpty
                        ? AppTheme.calories
                        : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note != null && note.isNotEmpty
                          ? note
                          : 'Add day note (digestion, sleep, social event...)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: note != null && note.isNotEmpty
                            ? AppTheme.textPrimary
                            : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editNote(
    BuildContext context,
    WidgetRef ref,
    String dateStr,
    String initial,
  ) async {
    final savedText = await showDialog<String>(
      context: context,
      builder: (_) => _DayNoteDialog(dateStr: dateStr, initial: initial),
    );
    if (savedText != null && context.mounted) {
      ref.read(databaseProvider).diaryToolsDao.saveDayNote(dateStr, savedText);
      ref.read(foodLogsRevisionProvider.notifier).state++;
    }
  }

  void _pickRepeatFood(BuildContext context, WidgetRef ref, DateTime date) {
    final recent = ref.read(recentLoggedFoodsProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text(
            'Pin Daily Repeat Item',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          for (final food in recent.take(8))
            ListTile(
              title: Text(food.name,
                  style: const TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text('${food.caloriesPer100g.round()} kcal / 100g',
                  style: const TextStyle(color: AppTheme.textSecondary)),
              trailing:
                  const Icon(Icons.repeat_rounded, color: AppTheme.activeBlue),
              onTap: () {
                final now = DateTime.now();
                ref.read(databaseProvider).diaryToolsDao.upsertRepeatItem(
                      RepeatItemRecord(
                        id: 'rep_${food.id}_${now.millisecondsSinceEpoch}',
                        foodId: food.id,
                        foodName: food.name,
                        mealType: MealType.breakfast.name,
                        hour: 8,
                        servingQuantity: 1.0,
                        unitName: '100g',
                        gramWeight: 100.0,
                        calories: food.caloriesPer100g,
                        protein: food.proteinPer100g,
                        carbs: food.carbsPer100g,
                        fat: food.fatPer100g,
                        fiber: food.fiberPer100g,
                        createdAt: now.toIso8601String(),
                      ),
                    );
                ref.read(foodLogsRevisionProvider.notifier).state++;
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }
}

class _DayNoteDialog extends StatefulWidget {
  const _DayNoteDialog({
    required this.dateStr,
    required this.initial,
  });

  final String dateStr;
  final String initial;

  @override
  State<_DayNoteDialog> createState() => _DayNoteDialogState();
}

class _DayNoteDialogState extends State<_DayNoteDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardSurface,
      title: Text(
        'Note for ${widget.dateStr}',
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
      ),
      content: SingleChildScrollView(
        child: TextField(
          controller: _ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'High-sodium dinner, travel, GI notes...',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
