import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/recipe_models.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/providers/recipes_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_sheet_grabber.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Bottom sheet for browsing, creating, and logging Custom Recipes
/// with MacroFactor-style "Explode Ingredients to Timeline" decomposition.
class RecipeBuilderSheet extends ConsumerStatefulWidget {
  const RecipeBuilderSheet({
    super.key,
    required this.mealType,
    required this.loggedAt,
    this.onLogged,
  });

  final MealType mealType;
  final DateTime loggedAt;
  final ValueChanged<String>? onLogged;

  static Future<void> show(
    BuildContext context, {
    required MealType mealType,
    required DateTime loggedAt,
    ValueChanged<String>? onLogged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecipeBuilderSheet(
        mealType: mealType,
        loggedAt: loggedAt,
        onLogged: onLogged,
      ),
    );
  }

  @override
  ConsumerState<RecipeBuilderSheet> createState() => _RecipeBuilderSheetState();
}

class _RecipeBuilderSheetState extends ConsumerState<RecipeBuilderSheet> {
  Future<void> _openCreateRecipeDialog() async {
    final nameCtrl = TextEditingController();
    final servingsCtrl = TextEditingController(text: '2');
    final kcalCtrl = TextEditingController(text: '450');
    final pCtrl = TextEditingController(text: '35');
    final cCtrl = TextEditingController(text: '45');
    final fCtrl = TextEditingController(text: '12');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: const Text(
          'Create Quick Custom Recipe',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 17),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Recipe Name',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: servingsCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Total Servings',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: kcalCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Batch kcal',
                        labelStyle: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: pCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Protein (g)',
                        labelStyle: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Carbs (g)',
                        labelStyle: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Fat (g)',
                        labelStyle: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && nameCtrl.text.trim().isNotEmpty && mounted) {
      final db = ref.read(databaseProvider);
      final now = DateTime.now();
      final id = 'rec_${now.millisecondsSinceEpoch}';
      final servings = math.max(1, int.tryParse(servingsCtrl.text.trim()) ?? 1);
      final kcal = double.tryParse(kcalCtrl.text.trim()) ?? 300.0;
      final p = double.tryParse(pCtrl.text.trim()) ?? 20.0;
      final c = double.tryParse(cCtrl.text.trim()) ?? 30.0;
      final f = double.tryParse(fCtrl.text.trim()) ?? 8.0;

      final recipe = CustomRecipe(
        id: id,
        userId: db.currentUserId,
        name: nameCtrl.text.trim(),
        servings: servings,
        totalWeightG: 250.0 * servings,
        createdAt: now,
        updatedAt: now,
        ingredients: [
          RecipeIngredient(
            id: '${id}_base',
            recipeId: id,
            foodId: -999,
            foodName: '${nameCtrl.text.trim()} Base Mix',
            servingQuantity: servings.toDouble(),
            unitName: '1 Batch Unit',
            gramWeight: 250.0 * servings,
            calories: kcal,
            protein: p,
            carbs: c,
            fat: f,
            fiber: 2.0,
          ),
        ],
      );
      ref.read(customRecipesProvider.notifier).saveRecipe(recipe);
      AppHaptics.successFeedback();
    }

    nameCtrl.dispose();
    servingsCtrl.dispose();
    kcalCtrl.dispose();
    pCtrl.dispose();
    cCtrl.dispose();
    fCtrl.dispose();
  }

  Future<void> _showLogRecipeOptions(CustomRecipe recipe) async {
    var servings = 1.0;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final kcal = (recipe.caloriesPerServing * servings).round();
          final protein = (recipe.proteinPerServing * servings);
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$kcal kcal · ${protein.toStringAsFixed(1)}g P for $servings serving(s)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        onPressed: () {
                          if (servings > 0.5) {
                            setSheetState(() => servings -= 0.5);
                          }
                        },
                      ),
                      Text(
                        '${servings.toStringAsFixed(servings == servings.roundToDouble() ? 0 : 1)} servings',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        onPressed: () => setSheetState(() => servings += 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        AppHaptics.successFeedback();
                        ref.read(customRecipesProvider.notifier).logRecipe(
                              recipe: recipe,
                              servings: servings,
                              mealType: widget.mealType,
                              loggedAt: widget.loggedAt,
                              explodeIngredients: false,
                            );
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                        widget.onLogged?.call(
                          'Logged $servings× ${recipe.name}',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.buttonBackground,
                        foregroundColor: AppTheme.buttonText,
                      ),
                      child: const Text('Log as Single Recipe Entry'),
                    ),
                  ),
                  if (recipe.ingredients.length > 1) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          AppHaptics.successFeedback();
                          final count = ref
                              .read(customRecipesProvider.notifier)
                              .logRecipe(
                                recipe: recipe,
                                servings: servings,
                                mealType: widget.mealType,
                                loggedAt: widget.loggedAt,
                                explodeIngredients: true,
                              );
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pop();
                          widget.onLogged?.call(
                            'Exploded ${recipe.name} into $count ingredients',
                          );
                        },
                        icon: const Icon(Icons.call_split_rounded, size: 18),
                        label: Text(
                          'Explode ${recipe.ingredients.length} Ingredients to Timeline',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipes = ref.watch(customRecipesProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
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
                      'Custom Recipes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openCreateRecipeDialog,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New Recipe'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (recipes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  child: Text(
                    'No custom recipes yet. Stage items on your plate and tap "Save Recipe", or tap "+ New Recipe".',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: recipes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final recipe = recipes[idx];
                      return AppleBouncy(
                        onTap: () => _showLogRecipeOptions(recipe),
                        child: Container(
                          padding: const EdgeInsets.all(12),
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
                                      recipe.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${recipe.caloriesPerServing.round()} kcal / serving · ${recipe.proteinPerServing.toStringAsFixed(1)}g P · ${recipe.ingredients.length} items',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Edit recipe & cooked weight',
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: AppTheme.activeBlue,
                                ),
                                onPressed: () => _openEditRecipeDialog(recipe),
                              ),
                              IconButton(
                                tooltip: 'Delete recipe',
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () => ref
                                    .read(customRecipesProvider.notifier)
                                    .deleteRecipe(recipe.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditRecipeDialog(CustomRecipe recipe) async {
    final nameCtrl = TextEditingController(text: recipe.name);
    final servingsCtrl =
        TextEditingController(text: recipe.servings.toString());
    final cookedCtrl = TextEditingController(
      text: recipe.cookedWeightG?.toStringAsFixed(0) ?? '',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: const Text('Edit Recipe',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Recipe Name'),
            ),
            TextField(
              controller: servingsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Servings'),
            ),
            TextField(
              controller: cookedCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Total Cooked Weight (g, optional)',
                hintText: 'Overrides raw ingredient weight',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final updated = recipe.copyWith(
        name: nameCtrl.text.trim().isEmpty ? recipe.name : nameCtrl.text.trim(),
        servings: int.tryParse(servingsCtrl.text) ?? recipe.servings,
        cookedWeightG: double.tryParse(cookedCtrl.text),
        updatedAt: DateTime.now(),
      );
      ref.read(customRecipesProvider.notifier).saveRecipe(updated);
    }
    nameCtrl.dispose();
    servingsCtrl.dispose();
    cookedCtrl.dispose();
  }
}
