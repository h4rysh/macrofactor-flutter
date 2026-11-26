import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/presentation/providers/plate_staging_provider.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_sheet_grabber.dart';

/// Expandable review & batch-commit modal sheet for the Multi-Add Staging Plate.
class StagingPlateSheet extends ConsumerStatefulWidget {
  const StagingPlateSheet({
    super.key,
    required this.mealType,
    required this.loggedAt,
    this.onCommitted,
  });

  final MealType mealType;
  final DateTime loggedAt;
  final ValueChanged<int>? onCommitted;

  static Future<void> show(
    BuildContext context, {
    required MealType mealType,
    required DateTime loggedAt,
    ValueChanged<int>? onCommitted,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StagingPlateSheet(
        mealType: mealType,
        loggedAt: loggedAt,
        onCommitted: onCommitted,
      ),
    );
  }

  @override
  ConsumerState<StagingPlateSheet> createState() => _StagingPlateSheetState();
}

class _StagingPlateSheetState extends ConsumerState<StagingPlateSheet> {
  Future<void> _promptSaveRecipe() async {
    final nameController = TextEditingController();
    final servingsController = TextEditingController(text: '1');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: const Text(
          'Save Plate as Custom Recipe',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Recipe Name (e.g. Post-Workout Shake)',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: servingsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Total Servings Yielded',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.activeBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Recipe'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final servings = int.tryParse(servingsController.text.trim()) ?? 1;
      final recipe = ref
          .read(plateStagingProvider.notifier)
          .saveAsCustomRecipe(name: nameController.text, servings: servings);
      if (recipe != null && mounted) {
        AppHaptics.successFeedback();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Saved recipe "${recipe.name}" (${recipe.safeServings} servings)'),
            backgroundColor: AppTheme.cardElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    nameController.dispose();
    servingsController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(plateStagingProvider);
    final notifier = ref.read(plateStagingProvider.notifier);

    final totalCals =
        items.fold(0.0, (sum, i) => sum + i.nutrition.calories).round();
    final totalP = items.fold(0.0, (sum, i) => sum + i.nutrition.protein);
    final totalC = items.fold(0.0, (sum, i) => sum + i.nutrition.carbs);
    final totalF = items.fold(0.0, (sum, i) => sum + i.nutrition.fat);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.cardBorder, width: 0.8),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppleSheetGrabber(margin: EdgeInsets.only(bottom: 10)),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Staging Plate',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (items.isNotEmpty)
                    TextButton.icon(
                      onPressed: _promptSaveRecipe,
                      icon: const Icon(Icons.menu_book_rounded, size: 16),
                      label: const Text('Save Recipe'),
                    ),
                  if (items.isNotEmpty)
                    IconButton(
                      tooltip: 'Clear Plate',
                      icon: const Icon(
                        Icons.delete_sweep_outlined,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () {
                        AppHaptics.lightImpact();
                        notifier.clear();
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: AppRadii.mdBorderRadius,
                  border: Border.all(color: AppTheme.cardBorder, width: 0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MacroStat(
                      label: 'Calories',
                      value: '$totalCals',
                      color: AppTheme.calories,
                    ),
                    _MacroStat(
                      label: 'Protein',
                      value: '${totalP.toStringAsFixed(1)}g',
                      color: AppTheme.protein,
                    ),
                    _MacroStat(
                      label: 'Carbs',
                      value: '${totalC.toStringAsFixed(1)}g',
                      color: AppTheme.carbs,
                    ),
                    _MacroStat(
                      label: 'Fat',
                      value: '${totalF.toStringAsFixed(1)}g',
                      color: AppTheme.fat,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Tap + on any food to stage multiple items before logging.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final nutrition = item.nutrition;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: AppRadii.mdBorderRadius,
                          border: Border.all(
                            color: AppTheme.cardBorder,
                            width: 0.7,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.food.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)} × ${item.portionUnit.unitName} · ${nutrition.calories.round()} kcal · ${nutrition.protein.toStringAsFixed(1)}g P',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Decrease quantity',
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                                size: 20,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () {
                                AppHaptics.lightImpact();
                                notifier.updateQuantity(
                                  item.id,
                                  item.quantity - 0.5,
                                );
                              },
                            ),
                            IconButton(
                              tooltip: 'Increase quantity',
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 20,
                                color: AppTheme.activeBlue,
                              ),
                              onPressed: () {
                                AppHaptics.lightImpact();
                                notifier.updateQuantity(
                                  item.id,
                                  item.quantity + 0.5,
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: items.isEmpty
                      ? null
                      : () {
                          AppHaptics.successFeedback();
                          final count = notifier.commitToLog(
                            mealType: widget.mealType,
                            loggedAt: widget.loggedAt,
                          );
                          Navigator.of(context).pop();
                          widget.onCommitted?.call(count);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.buttonBackground,
                    foregroundColor: AppTheme.buttonText,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.lgBorderRadius,
                    ),
                  ),
                  child: Text(
                    'Log ${items.length} ${items.length == 1 ? 'Item' : 'Items'} ($totalCals kcal)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  const _MacroStat({
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
