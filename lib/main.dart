import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_factor_app/data/local/app_database.dart';
import 'package:macro_factor_app/domain/models/food_models.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';
import 'package:macro_factor_app/presentation/screens/dashboard_screen.dart';
import 'package:macro_factor_app/presentation/screens/food_search_screen.dart';
import 'package:macro_factor_app/presentation/screens/strategy_screen.dart';
import 'package:macro_factor_app/presentation/screens/weight_log_modal.dart';
import 'package:macro_factor_app/presentation/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.open();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const MacroFactorApp(),
    ),
  );
}

/// MacroFactor Root Application.
class MacroFactorApp extends StatelessWidget {
  const MacroFactorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MacroFactor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigationShell(),
    );
  }
}

/// Root Navigation Shell with BottomNavigationBar & Centered Action Button.
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  void _showQuickLogSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                    'Quick Log',
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActionTile(
                    icon: Icons.wb_twilight,
                    title: 'Breakfast',
                    color: AppTheme.calories,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        FoodSearchScreen.route(MealType.breakfast),
                      );
                    },
                  ),
                  _buildQuickActionTile(
                    icon: Icons.wb_sunny_outlined,
                    title: 'Lunch',
                    color: AppTheme.fat,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        FoodSearchScreen.route(MealType.lunch),
                      );
                    },
                  ),
                  _buildQuickActionTile(
                    icon: Icons.nightlight_outlined,
                    title: 'Dinner',
                    color: AppTheme.carbs,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        FoodSearchScreen.route(MealType.dinner),
                      );
                    },
                  ),
                  _buildQuickActionTile(
                    icon: Icons.cookie_outlined,
                    title: 'Snacks',
                    color: AppTheme.protein,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        FoodSearchScreen.route(MealType.snacks),
                      );
                    },
                  ),
                  const Divider(height: 24),
                  _buildQuickActionTile(
                    icon: Icons.monitor_weight_outlined,
                    title: 'Scale Weight',
                    color: AppTheme.trendWeight,
                    onTap: () {
                      Navigator.pop(ctx);
                      WeightLogModal.show(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'MacroSans',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right,
          color: AppTheme.textSecondary, size: 20),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(
            onNavigateToStrategy: () => _onTabSelected(1),
          ),
          const StrategyScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickLogSheet(context),
        backgroundColor: AppTheme.calories,
        foregroundColor: AppTheme.background,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppTheme.cardSurface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  _currentIndex == 0
                      ? Icons.pie_chart
                      : Icons.pie_chart_outline,
                  color: _currentIndex == 0
                      ? AppTheme.calories
                      : AppTheme.textSecondary,
                  size: 26,
                ),
                tooltip: 'Dashboard',
                onPressed: () => _onTabSelected(0),
              ),
              const SizedBox(width: 48), // Spacing for centered notch FAB
              IconButton(
                icon: Icon(
                  _currentIndex == 1 ? Icons.tune : Icons.tune_outlined,
                  color: _currentIndex == 1
                      ? AppTheme.calories
                      : AppTheme.textSecondary,
                  size: 26,
                ),
                tooltip: 'Strategy',
                onPressed: () => _onTabSelected(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
