import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/food_models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_primitives.dart';
import '../widgets/expenditure_card.dart';
import '../widgets/food/quick_add_macros_sheet.dart';
import '../widgets/macro_gauge_ring.dart';
import '../widgets/profile_avatar_button.dart';
import '../widgets/weight_trend_card.dart';
import 'account_profile_screen.dart';
import 'food_search_screen.dart';
import 'weight_log_modal.dart';

/// Authentic Sique Dashboard Screen (Insights & Analytics Hub).
/// Displays Focus Tile (Macro Gauge Ring), Adaptive Expenditure,
/// Smoothed Weight Trend V2, and Energy Balance cards.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({
    super.key,
    this.onNavigateToStrategy,
    this.onNavigateToFoodLog,
  });

  final VoidCallback? onNavigateToStrategy;
  final VoidCallback? onNavigateToFoodLog;

  MealType _mealTypeForHour(int hour) {
    if (hour < 11) return MealType.breakfast;
    if (hour < 16) return MealType.lunch;
    if (hour < 21) return MealType.dinner;
    return MealType.snacks;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final selectedDateStr = ref.watch(selectedDateProvider);
    final selectedDate = DateTime.tryParse(selectedDateStr) ?? now;
    final selectedDateWithTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    final dailyNutrition = ref.watch(dailyNutritionSummaryProvider);
    final macroTarget = ref.watch(dailyMacroTargetProvider);
    final expenditureState = ref.watch(expenditureStateProvider);
    final expenditureSeries = ref.watch(expenditureHistorySeriesProvider);
    final weightSeries = ref.watch(weightTrendSeriesProvider);
    final latestTrendPoint = ref.watch(latestTrendWeightProvider);
    final profile = ref.watch(userProfileProvider);
    final useLbs = ref.watch(useImperialUnitsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final syncState = ref.watch(healthConnectSyncProvider);

    final energyBalanceKcal =
        (dailyNutrition.calories - expenditureState.expenditureKcal).round();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.activeBlue,
          backgroundColor: AppTheme.cardElevated,
          onRefresh: () async {
            AppHaptics.lightImpact();
            final messenger = ScaffoldMessenger.of(context);
            await ref.read(healthConnectSyncProvider.notifier).syncNow();
            if (!context.mounted) return;
            final after = ref.read(healthConnectSyncProvider);
            if (after.errorMessage != null) {
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(after.errorMessage!),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Sleek Dashboard Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DateFormat('EEEE, MMM d')
                                        .format(selectedDate),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Tooltip(
                                    message: syncState.isSyncing
                                        ? 'Health Connect syncing'
                                        : (syncState.hasPermissions
                                            ? 'Health Connect synced'
                                            : 'Health Connect not connected'),
                                    child: Semantics(
                                      label: syncState.isSyncing
                                          ? 'Health Connect syncing'
                                          : (syncState.hasPermissions
                                              ? 'Health Connect synced'
                                              : 'Health Connect not connected'),
                                      child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: syncState.isSyncing
                                              ? AppTheme.activeBlue
                                              : (syncState.hasPermissions
                                                  ? AppTheme.expenditure
                                                  : AppTheme.cardBorder),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            const FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Dashboard',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                ),
              ),

              // 2. Dashboard Body Cards
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      // A. Nutrition Focus Tile: Macro Gauge Ring (Calories + P/F/C breakdown)
                      AppleStaggeredEntrance(
                        index: 0,
                        child: MacroGaugeRing(
                          consumed: dailyNutrition,
                          targets: macroTarget,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Quick Action Strip
                      AppleStaggeredEntrance(
                        index: 1,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildActionPill(
                                icon: Icons.add_rounded,
                                label: 'Log Food',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    FoodSearchScreen.route(
                                      mealType: _mealTypeForHour(now.hour),
                                      initialLoggedAt: selectedDateWithTime,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildActionPill(
                                icon: Icons.monitor_weight_outlined,
                                label: 'Log Weight',
                                onTap: () => WeightLogModal.show(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildActionPill(
                                icon: Icons.bolt_rounded,
                                label: 'Quick Add',
                                onTap: () => QuickAddMacrosSheet.show(
                                  context,
                                  date: selectedDate,
                                  mealType: _mealTypeForHour(now.hour),
                                  loggedAt: selectedDateWithTime,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // B. Adaptive Energy Expenditure + Chart
                      AppleStaggeredEntrance(
                        index: 2,
                        child: DynamicExpenditureCard(
                          expenditureState: expenditureState,
                          historySeries: expenditureSeries,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // C. Smoothed Weight Trend V2 Card + Chart
                      AppleStaggeredEntrance(
                        index: 3,
                        child: WeightTrendCard(
                          latestTrendPoint: latestTrendPoint,
                          trendSeries: weightSeries,
                          targetWeightKg: profile.targetWeightKg,
                          weeklyRatePct: profile.weeklyRateOfChangePct,
                          useLbs: useLbs,
                          onLogWeightTap: () => WeightLogModal.show(context),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // D. Energy Balance Tile
                      AppleStaggeredEntrance(
                        index: 4,
                        child: _buildEnergyBalanceCard(
                          energyBalanceKcal,
                          hasLoggedFood: dailyNutrition.calories > 0,
                        ),
                      ),
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return AppleBouncy(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.cardBorder,
            width: 0.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 15),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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

  Widget _buildEnergyBalanceCard(
    int energyBalanceKcal, {
    required bool hasLoggedFood,
  }) {
    final bool isBalanced = energyBalanceKcal == 0;
    final bool isDeficit = energyBalanceKcal < 0;
    final absBalance = energyBalanceKcal.abs();
    final Color badgeColor;
    final String badgeText;
    final String helperText;
    if (!hasLoggedFood) {
      badgeColor = AppTheme.textMuted;
      badgeText = 'UNLOGGED';
      helperText =
          'No meals logged yet for this day. Log food to track your net energy balance.';
    } else if (isBalanced) {
      badgeColor = AppTheme.textSecondary;
      badgeText = 'BALANCED';
      helperText = 'Daily intake matches your estimated daily expenditure.';
    } else if (isDeficit) {
      badgeColor = AppTheme.activeBlueText;
      badgeText = 'DEFICIT';
      helperText =
          'Your daily net caloric deficit is supporting steady weight reduction.';
    } else {
      badgeColor = AppTheme.warning;
      badgeText = 'SURPLUS';
      helperText =
          'Your daily intake exceeds expenditure for lean tissue accrual.';
    }

    return AppleTactileCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 18,
      backgroundColor: AppTheme.cardSurface.withValues(alpha: 0.85),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ENERGY BALANCE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedCountText(
                value: !hasLoggedFood ? 0.0 : absBalance.toDouble(),
                prefix:
                    !hasLoggedFood || isBalanced ? '' : (isDeficit ? '-' : '+'),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: badgeColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'kcal / day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            helperText,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
