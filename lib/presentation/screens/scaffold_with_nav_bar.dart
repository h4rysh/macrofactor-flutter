import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'food_log_screen.dart';
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
    _MorePlaceholderScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 0.8)),
        ),
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
                GestureDetector(
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
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
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
    );
  }
}

class _MorePlaceholderScreen extends StatelessWidget {
  const _MorePlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsTile(
            icon: Icons.account_circle_outlined,
            title: 'Profile & Targets',
            subtitle: 'Caloric balance, height, weight',
          ),
          _buildSettingsTile(
            icon: Icons.restaurant_outlined,
            title: 'Food Log Settings',
            subtitle: 'Timeline display, portion preferences',
          ),
          _buildSettingsTile(
            icon: Icons.monitor_weight_outlined,
            title: 'Expenditure & Weight Settings',
            subtitle: 'Algorithm sensitivity, noise envelope scale',
          ),
          _buildSettingsTile(
            icon: Icons.download_rounded,
            title: 'Data Export',
            subtitle: 'Export logs to CSV/JSON',
          ),
          _buildSettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'About MacroFactor (Indian Edition)',
            subtitle: 'v1.1.0 • Clean-Room Adherence-Neutral',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder.withAlpha(80)),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(icon, color: AppTheme.activeBlue),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppTheme.textMuted,
          ),
          onTap: () {},
        ),
      ),
    );
  }
}
