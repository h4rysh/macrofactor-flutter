import 'package:sique/domain/models/recipe_models.dart';
import 'package:sqlite3/common.dart';

/// Data Access Object for user-created custom recipes and ingredient rows.
class RecipesDao {
  RecipesDao(
    this._db, {
    this.userId = 'default_user',
    String Function()? userIdProvider,
  }) : _userIdProvider = userIdProvider;

  final CommonDatabase _db;
  String userId;
  String Function()? _userIdProvider;

  set userIdProvider(String Function()? provider) => _userIdProvider = provider;

  /// Active tenant user id for multi-tenant data scoping.
  String get effectiveUserId =>
      _userIdProvider != null ? _userIdProvider!() : userId;

  String _resolveUserId(String? override) {
    if (override != null && override.trim().isNotEmpty) {
      return override.trim();
    }
    return effectiveUserId;
  }

  /// Returns all custom recipes for the active user ordered by most recently updated.
  List<CustomRecipe> getAllRecipes({String? userId}) {
    final uid = _resolveUserId(userId);
    final recipeStmt = _db.prepare('''
      SELECT id, user_id, name, servings, total_weight_g, cooked_weight_g,
             prep_instructions, source_url, created_at, updated_at
      FROM custom_recipes
      WHERE user_id = ?
      ORDER BY updated_at DESC;
    ''');
    try {
      final rows = recipeStmt.select([uid]);
      if (rows.isEmpty) return const [];

      final recipeIds = rows.map((r) => r['id'] as String).toList();
      final ingredientsByRecipe = _loadIngredientsForRecipes(recipeIds);

      return rows
          .map((row) => _mapRecipeRow(
                row,
                ingredientsByRecipe[row['id'] as String] ?? const [],
              ))
          .toList(growable: false);
    } finally {
      recipeStmt.dispose();
    }
  }

  /// Returns a single custom recipe by [id] if owned by the active user.
  CustomRecipe? getRecipeById(String id, {String? userId}) {
    final uid = _resolveUserId(userId);
    final stmt = _db.prepare('''
      SELECT id, user_id, name, servings, total_weight_g, cooked_weight_g,
             prep_instructions, source_url, created_at, updated_at
      FROM custom_recipes
      WHERE id = ? AND user_id = ?
      LIMIT 1;
    ''');
    try {
      final rows = stmt.select([id, uid]);
      if (rows.isEmpty) return null;
      final ingredients = _loadIngredientsForRecipes([id])[id] ?? const [];
      return _mapRecipeRow(rows.first, ingredients);
    } finally {
      stmt.dispose();
    }
  }

  /// Saves or updates a custom recipe and its ingredient breakdown atomically.
  void upsertRecipe(
    CustomRecipe recipe, {
    String? userId,
    bool manageTransaction = true,
  }) {
    final uid = _resolveUserId(userId);
    if (manageTransaction) {
      _db.execute('BEGIN TRANSACTION;');
    }
    try {
      // Prevent cross-tenant overwrite of another user's recipe primary key.
      final ownerStmt = _db.prepare(
        'SELECT user_id FROM custom_recipes WHERE id = ? LIMIT 1;',
      );
      try {
        final ownerRows = ownerStmt.select([recipe.id]);
        if (ownerRows.isNotEmpty && ownerRows.first['user_id'] != uid) {
          throw StateError('Cannot overwrite recipe owned by another user.');
        }
      } finally {
        ownerStmt.dispose();
      }

      final recipeStmt = _db.prepare('''
        INSERT OR REPLACE INTO custom_recipes (
          id, user_id, name, servings, total_weight_g, cooked_weight_g,
          prep_instructions, source_url, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''');
      try {
        recipeStmt.execute([
          recipe.id,
          uid,
          recipe.name.trim(),
          recipe.safeServings,
          recipe.totalWeightG,
          recipe.cookedWeightG,
          recipe.prepInstructions,
          recipe.sourceUrl,
          recipe.createdAt.toIso8601String(),
          recipe.updatedAt.toIso8601String(),
        ]);
      } finally {
        recipeStmt.dispose();
      }

      final deleteStmt = _db.prepare(
        'DELETE FROM recipe_ingredients WHERE recipe_id = ?;',
      );
      try {
        deleteStmt.execute([recipe.id]);
      } finally {
        deleteStmt.dispose();
      }

      if (recipe.ingredients.isNotEmpty) {
        final ingStmt = _db.prepare('''
          INSERT INTO recipe_ingredients (
            id, recipe_id, food_id, food_name, serving_quantity, unit_name,
            gram_weight, calories, protein, carbs, fat, fiber
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        ''');
        try {
          for (final ing in recipe.ingredients) {
            ingStmt.execute([
              ing.id,
              recipe.id,
              ing.foodId,
              ing.foodName,
              ing.servingQuantity,
              ing.unitName,
              ing.gramWeight,
              ing.calories,
              ing.protein,
              ing.carbs,
              ing.fat,
              ing.fiber,
            ]);
          }
        } finally {
          ingStmt.dispose();
        }
      }

      if (manageTransaction) {
        _db.execute('COMMIT;');
      }
    } catch (_) {
      if (manageTransaction) {
        _db.execute('ROLLBACK;');
      }
      rethrow;
    }
  }

  /// Deletes a custom recipe (ingredients cascade via FK).
  void deleteRecipe(String id, {String? userId}) {
    final uid = _resolveUserId(userId);
    _db.execute('BEGIN TRANSACTION;');
    try {
      final delIng = _db.prepare(
        'DELETE FROM recipe_ingredients WHERE recipe_id = ? AND EXISTS (SELECT 1 FROM custom_recipes WHERE id = ? AND user_id = ?);',
      );
      try {
        delIng.execute([id, id, uid]);
      } finally {
        delIng.dispose();
      }

      final delRec = _db.prepare(
        'DELETE FROM custom_recipes WHERE id = ? AND user_id = ?;',
      );
      try {
        delRec.execute([id, uid]);
      } finally {
        delRec.dispose();
      }
      _db.execute('COMMIT;');
    } catch (_) {
      try {
        _db.execute('ROLLBACK;');
      } catch (_) {}
      rethrow;
    }
  }

  Map<String, List<RecipeIngredient>> _loadIngredientsForRecipes(
    List<String> recipeIds,
  ) {
    if (recipeIds.isEmpty) return const {};
    final map = <String, List<RecipeIngredient>>{};
    const chunkSize = 400;
    for (var start = 0; start < recipeIds.length; start += chunkSize) {
      final end = (start + chunkSize < recipeIds.length)
          ? start + chunkSize
          : recipeIds.length;
      final chunk = recipeIds.sublist(start, end);
      final placeholders = List.filled(chunk.length, '?').join(',');
      final stmt = _db.prepare('''
        SELECT id, recipe_id, food_id, food_name, serving_quantity, unit_name,
               gram_weight, calories, protein, carbs, fat, fiber
        FROM recipe_ingredients
        WHERE recipe_id IN ($placeholders);
      ''');
      try {
        final rows = stmt.select(chunk);
        for (final row in rows) {
          final recipeId = row['recipe_id'] as String;
          final list = map.putIfAbsent(recipeId, () => []);
          list.add(
            RecipeIngredient(
              id: row['id'] as String,
              recipeId: recipeId,
              foodId: (row['food_id'] as num).toInt(),
              foodName: row['food_name'] as String,
              servingQuantity: (row['serving_quantity'] as num).toDouble(),
              unitName: row['unit_name'] as String,
              gramWeight: (row['gram_weight'] as num).toDouble(),
              calories: (row['calories'] as num).toDouble(),
              protein: (row['protein'] as num).toDouble(),
              carbs: (row['carbs'] as num).toDouble(),
              fat: (row['fat'] as num).toDouble(),
              fiber: (row['fiber'] as num).toDouble(),
            ),
          );
        }
      } finally {
        stmt.dispose();
      }
    }
    return map;
  }

  CustomRecipe _mapRecipeRow(
    Row row,
    List<RecipeIngredient> ingredients,
  ) {
    return CustomRecipe(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      servings: (row['servings'] as num).toInt(),
      totalWeightG: (row['total_weight_g'] as num?)?.toDouble(),
      cookedWeightG: (row['cooked_weight_g'] as num?)?.toDouble(),
      prepInstructions: row['prep_instructions'] as String?,
      sourceUrl: row['source_url'] as String?,
      createdAt:
          DateTime.tryParse(row['created_at'] as String) ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(row['updated_at'] as String) ?? DateTime.now(),
      ingredients: ingredients,
    );
  }
}
