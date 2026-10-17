import 'package:flutter/material.dart';
import '../../domain/models/food_models.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_tactile_card.dart';
import 'food_search_screen.dart';
import 'goal_questionnaire_sheet.dart';
import 'weight_log_modal.dart';

/// Quick actions bottom sheet triggered by the center '+' navigation button.
class QuickActionsSheet extends StatelessWidget {
  const QuickActionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const QuickActionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildTile(
                context: context,
                icon: Icons.tune_rounded,
                title: 'Personalize Goals & Preferences',
                color: AppTheme.activeBlue,
                onTap: () {
                  Navigator.pop(context);
                  GoalQuestionnaireSheet.show(context);
                },
              ),
              _buildTile(
                context: context,
                icon: Icons.search_rounded,
                title: 'Search Food / Add to Plate',
                color: AppTheme.calories,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    FoodSearchScreen.route(mealType: MealType.lunch),
                  );
                },
              ),
              _buildTile(
                context: context,
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scan Barcode',
                color: AppTheme.carbs,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Barcode scanner active'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildTile(
                context: context,
                icon: Icons.monitor_weight_outlined,
                title: 'Log Scale Weight',
                color: AppTheme.trendWeight,
                onTap: () {
                  Navigator.pop(context);
                  WeightLogModal.show(context);
                },
              ),
              _buildTile(
                context: context,
                icon: Icons.flash_on_rounded,
                title: 'Quick Add Calories / Macros',
                color: AppTheme.fat,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    FoodSearchScreen.route(mealType: MealType.snacks),
                  );
                },
              ),
              _buildTile(
                context: context,
                icon: Icons.note_alt_outlined,
                title: 'Add Day Note',
                color: AppTheme.protein,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Day Note recorded'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppleBouncy(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder.withAlpha(80)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withAlpha(35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
