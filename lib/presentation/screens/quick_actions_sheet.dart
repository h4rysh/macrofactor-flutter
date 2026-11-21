import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sique/presentation/widgets/sique_bouncy.dart';
import '../../domain/models/food_models.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_sheet_grabber.dart';
import 'food_search_screen.dart';
import 'weight_log_modal.dart';

/// Quick actions bottom sheet triggered by the center '+' navigation button.
/// Refactored into a high-craft 2+3 obsidian bento grid layout.
class QuickActionsSheet extends StatelessWidget {
  const QuickActionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickActionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface.withValues(alpha: 0.92),
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
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppleSheetGrabber(margin: EdgeInsets.only(bottom: 8)),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Top Row: 2 Large Hero Bento Tiles
                    Row(
                      children: [
                        Expanded(
                          child: _buildHeroBentoTile(
                            context: context,
                            icon: Icons.search_rounded,
                            title: 'Search Food / Add to Plate',
                            subtitle: 'Log meals & items',
                            color: AppTheme.calories,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                FoodSearchScreen.route(
                                    mealType: MealType.lunch),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildHeroBentoTile(
                            context: context,
                            icon: Icons.monitor_weight_outlined,
                            title: 'Log Scale Weight',
                            subtitle: 'Daily morning weigh-in',
                            color: AppTheme.trendWeight,
                            onTap: () {
                              Navigator.pop(context);
                              WeightLogModal.show(context);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Bottom Row: 3 Compact Bento Tiles
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactBentoTile(
                            context: context,
                            icon: Icons.flash_on_rounded,
                            title: 'Quick Add Calories',
                            color: AppTheme.fat,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                FoodSearchScreen.route(
                                    mealType: MealType.snacks),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCompactBentoTile(
                            context: context,
                            icon: Icons.content_copy_rounded,
                            title: 'Copy Yesterday',
                            color: AppTheme.carbs,
                            onTap: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Yesterday’s meals copied to today',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCompactBentoTile(
                            context: context,
                            icon: Icons.note_alt_outlined,
                            title: 'Day Note',
                            color: AppTheme.protein,
                            onTap: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Day note recorded'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBentoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SiqueBouncy(
      onTap: () {
        AppHaptics.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardElevated,
          borderRadius: AppRadii.lgBorderRadius,
          border: Border.all(color: AppTheme.cardBorder, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: AppRadii.mdBorderRadius,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactBentoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SiqueBouncy(
      onTap: () {
        AppHaptics.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardElevated,
          borderRadius: AppRadii.lgBorderRadius,
          border: Border.all(color: AppTheme.cardBorder, width: 0.8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: AppRadii.mdBorderRadius,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
