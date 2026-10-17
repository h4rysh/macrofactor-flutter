import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Persistent quick search bar docked above the bottom nav bar.
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardElevated,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Icon & Prompt
          Expanded(
            child: GestureDetector(
              onTap: onSearchTap,
              behavior: HitTestBehavior.opaque,
              child: const Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Search for a food',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barcode scanner shortcut
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
            color: AppTheme.textSecondary,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onBarcodeTap,
          ),
          const SizedBox(width: 12),

          // Custom Food / Plate shortcut
          IconButton(
            icon: const Icon(Icons.restaurant_menu_rounded, size: 20),
            color: AppTheme.textSecondary,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onCustomFoodTap,
          ),
        ],
      ),
    );
  }
}
