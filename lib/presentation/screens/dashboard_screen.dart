import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_tactile_card.dart';
import '../widgets/expenditure_card.dart';
import '../widgets/macro_gauge_ring.dart';
import '../widgets/profile_avatar_button.dart';
import '../widgets/weight_trend_card.dart';
import 'account_profile_screen.dart';
import 'food_search_screen.dart';
import 'goal_questionnaire_sheet.dart';
import 'quick_actions_sheet.dart';
import 'weight_log_modal.dart';

/// Authentic MacroFactor Dashboard Screen (Insights & Analytics Hub).
/// Matches `package:macrofactor/src/ui/dashboard/dashboard_view.dart`.
/// Displays Focus Tile (Macro Gauge Ring), Live Bayesian Expenditure V3,
/// Smoothed Weight Trend V2, and Energy Balance cards.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({
    super.key,
    this.onNavigateToStrategy,
    this.onNavigateToFoodLog,
  });

  final VoidCallback? onNavigateToStrategy;
  final VoidCallback? onNavigateToFoodLog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDateStr = ref.watch(selectedDateProvider);
    final selectedDate = DateTime.tryParse(selectedDateStr) ?? DateTime.now();

    final dailyNutrition = ref.watch(dailyNutritionSummaryProvider);
    final macroTarget = ref.watch(dailyMacroTargetProvider);
    final expenditureState = ref.watch(expenditureStateProvider);
    final latestTrendPoint = ref.watch(latestTrendWeightProvider);
    final currentUser = ref.watch(currentUserProvider);

    final energyBalanceKcal =
        (dailyNutrition.calories - expenditureState.expenditureKcal).round();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. Sleek Dashboard Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d')
                              .format(selectedDate)
                              .toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'MacroSans',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Dashboard',
                          style: TextStyle(
                            fontFamily: 'MacroSans',
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Scale Weight Log Action
                        IconButton(
                          tooltip: 'Log Scale Weight',
                          icon: const Icon(
                            Icons.monitor_weight_outlined,
                            color: AppTheme.trendWeight,
                            size: 24,
                          ),
                          onPressed: () => WeightLogModal.show(context),
                        ),
                        // Adaptive Goal Questionnaire Action
                        IconButton(
                          key: const Key('dashboard_goal_setup_btn'),
                          tooltip: 'Personalize Program',
                          icon: const Icon(
                            Icons.tune_rounded,
                            color: AppTheme.activeBlue,
                            size: 22,
                          ),
                          onPressed: () => GoalQuestionnaireSheet.show(context),
                        ),
                        // Strategy Action
                        if (onNavigateToStrategy != null)
                          IconButton(
                            tooltip: 'Strategy',
                            icon: const Icon(
                              Icons.hub_outlined,
                              color: AppTheme.textSecondary,
                              size: 22,
                            ),
                            onPressed: onNavigateToStrategy,
                          ),
                        const SizedBox(width: 6),
                        // Profile Avatar Action (36x36 Circular AppleBouncy)
                        ProfileAvatarButton(
                          key: const Key('dashboard_profile_avatar_btn'),
                          user: currentUser,
                          size: 36,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const AccountProfileScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. Dashboard Body Cards
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    // Top Interactive Direction Banner (Apple Tactile)
                    AppleBouncy(
                      onTap: () => GoalQuestionnaireSheet.show(context),
                      child: Container(
                        key: const Key('dashboard_goal_banner'),
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.activeBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.activeBlue.withValues(alpha: 0.25),
                            width: 0.9,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.activeBlue.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: AppTheme.activeBlue,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'ADAPTIVE SETUP',
                                        style: TextStyle(
                                          fontFamily: 'MacroSans',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.activeBlue,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Personalize Your Goal & Diet',
                                    style: TextStyle(
                                      fontFamily: 'MacroSans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Tailor rate, Indian staples, and protein strategy in 6 steps',
                                    style: TextStyle(
                                      fontFamily: 'DMSans',
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: AppTheme.activeBlue,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // A. Nutrition Focus Tile: Macro Gauge Ring (Calories + P/F/C breakdown)
                    MacroGaugeRing(
                      consumed: dailyNutrition,
                      targets: macroTarget,
                    ),
                    const SizedBox(height: 14),

                    // Quick Action Strip
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionPill(
                            icon: Icons.add_rounded,
                            label: 'Log Food',
                            color: AppTheme.activeBlue,
                            onTap: () {
                              if (onNavigateToFoodLog != null) {
                                onNavigateToFoodLog!();
                              } else {
                                Navigator.push(
                                  context,
                                  FoodSearchScreen.route(),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionPill(
                            icon: Icons.monitor_weight_outlined,
                            label: 'Log Weight',
                            color: AppTheme.trendWeight,
                            onTap: () => WeightLogModal.show(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionPill(
                            icon: Icons.bolt_rounded,
                            label: 'Quick Add',
                            color: AppTheme.calories,
                            onTap: () => QuickActionsSheet.show(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // B. Dynamic Bayesian Energy Expenditure V3
                    DynamicExpenditureCard(
                      expenditureState: expenditureState,
                    ),
                    const SizedBox(height: 14),

                    // C. Smoothed Weight Trend V2 Card
                    WeightTrendCard(
                      latestTrendPoint: latestTrendPoint,
                      onLogWeightTap: () => WeightLogModal.show(context),
                    ),
                    const SizedBox(height: 14),

                    // D. Energy Balance Tile
                    _buildEnergyBalanceCard(energyBalanceKcal),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppleBouncy(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergyBalanceCard(int energyBalanceKcal) {
    final isDeficit = energyBalanceKcal <= 0;
    final absBalance = energyBalanceKcal.abs();
    final badgeColor = isDeficit ? AppTheme.activeBlue : AppTheme.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ENERGY BALANCE',
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDeficit ? 'DEFICIT' : 'SURPLUS',
                  style: TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${isDeficit ? '-' : '+'}$absBalance',
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDeficit ? AppTheme.activeBlue : AppTheme.warning,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'kcal / day',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isDeficit
                ? 'Your daily net caloric deficit is driving body fat loss according to your plan.'
                : 'Your daily intake exceeds expenditure for lean tissue accrual.',
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
