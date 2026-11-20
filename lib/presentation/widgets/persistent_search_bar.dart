import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'apple_tactile_card.dart';

/// Persistent quick search bar docked above the bottom nav bar.
/// Styled with Apple Liquid Glass frosted obsidian blur and tactile response.
class PersistentSearchBar extends StatelessWidget {
  const PersistentSearchBar({
    super.key,
    required this.onSearchTap,
    required this.onBarcodeTap,
    required this.onCustomFoodTap,
  });

  final VoidCallback onSearchTap;
  final VoidCallback onBarcodeTap;
  final VoidCallback onCustomFoodTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Search Icon & Prompt with tactile bounce
                Expanded(
                  child: AppleBouncy(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onSearchTap();
                    },
                    scaleDown: 0.98,
                    child: Container(
                      color: Colors.transparent,
                      child: const Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Search for a food',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Barcode scanner shortcut
                Semantics(
                  button: true,
                  label: 'Scan food barcode',
                  child: AppleBouncy(
                    scaleDown: 0.90,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onBarcodeTap();
                    },
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 20,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Custom Food / Plate shortcut
                Semantics(
                  button: true,
                  label: 'Quick custom food log',
                  child: AppleBouncy(
                    scaleDown: 0.90,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onCustomFoodTap();
                    },
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                        ),
                        child: const Icon(
                          Icons.restaurant_menu_rounded,
                          size: 20,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
