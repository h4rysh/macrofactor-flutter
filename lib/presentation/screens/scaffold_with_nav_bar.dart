import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_lifecycle_sync_observer.dart';
import '../widgets/apple_tactile_card.dart';
import 'dashboard_screen.dart';
import 'food_log_screen.dart';
import 'more_screen.dart';
import 'quick_actions_sheet.dart';
import 'strategy_screen.dart';

/// Authentic MacroFactor 5-destination Scaffold with Center Action Button.
/// Matches `src/ui/scaffold_with_nav_bar/scaffold_with_nav_bar_view.dart`.
class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({super.key});

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  // Index 0: Dashboard (Insights & Focus Tile)
  // Index 1: Food Log (Hourly timeline & Date carousel - Authentic Default)
  // Index 2: Strategy
  // Index 3: More
  int _currentIndex = 1;

  final List<Widget> _screens = const [
    DashboardScreen(),
    FoodLogScreen(),
    StrategyScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AppLifecycleSyncObserver(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.92),
            border: const Border(
              top: BorderSide(color: AppTheme.cardBorder, width: 0.8),
            ),
          ),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: SafeArea(
                child: SizedBox(
                  height: 64,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 1. Dashboard Tab
                      _buildNavItem(
                        index: 0,
                        icon: Icons.grid_view_rounded,
                        label: 'Dashboard',
                      ),

                      // 2. Food Log Tab (Iconic Apple)
                      _buildNavItem(
                        index: 1,
                        icon: Icons.apple,
                        label: 'Food Log',
                      ),

                      // 3. Center Floating Action Button (+) Matching log_revamp.png
                      AppleBouncy(
                        child: GestureDetector(
                          key: const Key('center_action_fab'),
                          onTap: () => QuickActionsSheet.show(context),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Color(0xFF141418),
                              size: 28,
                            ),
                          ),
                        ),
                      ),

                      // 4. Strategy Tab (3 interconnected nodes)
                      _buildNavItem(
                        index: 2,
                        icon: Icons.hub_outlined,
                        label: 'Strategy',
                      ),

                      // 5. More Tab
                      _buildNavItem(
                        index: 3,
                        icon: Icons.more_horiz_rounded,
                        label: 'More',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.activeBlue : AppTheme.textSecondary;

    return Expanded(
      child: AppleBouncy(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
