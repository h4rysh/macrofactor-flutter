import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_factor_app/domain/models/food_models.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';
import 'package:macro_factor_app/presentation/screens/food_detail_modal.dart';
import 'package:macro_factor_app/presentation/theme/app_theme.dart';
import 'package:macro_factor_app/presentation/widgets/food_svg_icon.dart';

/// Instant FTS5 Food Search screen for Indian and International foods.
class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({
    super.key,
    required this.mealType,
  });

  final MealType mealType;

  static MaterialPageRoute<void> route(MealType mealType) {
    return MaterialPageRoute(
      builder: (_) => FoodSearchScreen(mealType: mealType),
    );
  }

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<FoodItem> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _performSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      _performSearch(text);
    });
  }

  void _performSearch(String query) {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final results = db.searchFoods(query, limit: 40);
    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log ${widget.mealType.displayName}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText:
                    'Search 2,500+ Indian & global foods (e.g. Idli, Paneer, Dosa)...',
                hintStyle: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
                prefixIcon:
                    const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppTheme.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppTheme.calories, width: 1.5),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.calories))
          : _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off,
                          size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'No foods found for "${_searchController.text}"',
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 15,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final food = _searchResults[index];
                    return _FoodSearchResultTile(
                      food: food,
                      onTap: () {
                        FoodDetailModal.show(
                          context,
                          food: food,
                          mealType: widget.mealType,
                        );
                      },
                    );
                  },
                ),
    );
  }
}

class _FoodSearchResultTile extends StatelessWidget {
  const _FoodSearchResultTile({
    required this.food,
    required this.onTap,
  });

  final FoodItem food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder, width: 1),
        ),
        child: Row(
          children: [
            FoodSvgIcon(iconSvg: food.iconSvg, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: AppTheme.cardBorder, width: 1),
                        ),
                        child: Text(
                          food.region,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${food.caloriesPer100g.round()} kcal / 100g',
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          color: AppTheme.calories,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${food.proteinPer100g.toStringAsFixed(1)}g P',
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.protein,
                  ),
                ),
                Text(
                  '${food.carbsPer100g.toStringAsFixed(1)}g C • ${food.fatPer100g.toStringAsFixed(1)}g F',
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                size: 18, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
