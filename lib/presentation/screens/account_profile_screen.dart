import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/presentation/providers/auth_providers.dart';
import 'package:sique/presentation/providers/health_sync_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/google_account_card.dart';
import 'package:sique/presentation/widgets/health_connect_sync_card.dart';
import 'package:sique/presentation/widgets/physical_stats_summary_card.dart';
import 'package:sique/presentation/widgets/recent_workout_card.dart';
import 'package:sique/presentation/widgets/workout_consistency_tracker.dart';
import 'package:sique/presentation/widgets/workout_stats_hero_grid.dart';

/// Complete Account & Hevy Training Profile Screen.
/// Composes 6 modular widgets into an Apple Obsidian Dark scroll view.
class AccountProfileScreen extends ConsumerWidget {
  const AccountProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for transient auth errors to show feedback
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppTheme.calories,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    // Listen for health sync error feedback
    ref.listen<HealthSyncState>(healthConnectSyncProvider, (previous, next) {
      if (next.isError && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.calories,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Account & Profile'),
        leading: IconButton(
          key: const Key('profile_back_btn'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: const [
          GoogleAccountCard(),
          SizedBox(height: 16),
          WorkoutStatsHeroGrid(),
          SizedBox(height: 16),
          WorkoutConsistencyTracker(),
          SizedBox(height: 16),
          RecentWorkoutsFeed(),
          SizedBox(height: 16),
          PhysicalStatsSummaryCard(),
          SizedBox(height: 16),
          HealthConnectSyncCard(),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}
