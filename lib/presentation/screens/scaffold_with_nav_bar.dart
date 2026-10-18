import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// Elevated with Apple Liquid Glass frosted dock, animated tab indicator pill,
/// and responsive spring micro-interactions.
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

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      setState(() => _currentIndex = index);
    }
  }

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
            color: AppTheme.surface.withValues(alpha: 0.88),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.8,
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: SafeArea(
                child: SizedBox(
                  height: 66,
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

                      // 3. Center Floating Action Button (+) with specular glow
                      Expanded(
                        child: Center(
                          child: Semantics(
                            button: true,
                            label: 'Open quick actions menu',
                            child: AppleBouncy(
                              onTap: () {
                                QuickActionsSheet.show(context);
                              },
                              child: Container(
                                key: const Key('center_action_fab'),
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Color(0xFFE2E4EB),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.white.withValues(alpha: 0.22),
                                      blurRadius: 14,
                                      spreadRadius: 1,
                                    ),
                                    const BoxShadow(
                                      color: Color(0x55000000),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Color(0xFF141418),
                                  size: 30,
                                ),
                              ),
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
        onTap: () => _onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.activeBlue.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppTheme.activeBlue.withValues(alpha: 0.25)
                  : Colors.transparent,
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: color,
                  letterSpacing: isSelected ? 0.2 : 0.0,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
