import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/profile_targets/calorie_target_card.dart';
import 'package:sique/presentation/screens/profile_targets/goal_selection_card.dart';
import 'package:sique/presentation/screens/profile_targets/macro_distribution_card.dart';
import 'package:sique/presentation/screens/profile_targets/physical_stats_card.dart';
import 'package:sique/presentation/screens/profile_targets/protein_preference_card.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Screen for viewing and configuring user profile, caloric targets, and macro distribution.
/// Implements Instant Auto-Save: all slider/toggle changes immediately persist to SQLite.
class ProfileTargetsScreen extends ConsumerWidget {
  const ProfileTargetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final expenditureState = ref.watch(expenditureStateProvider);
    final macroTarget = ref.watch(dailyMacroTargetProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profile & Targets'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          PhysicalStatsCard(ref: ref, profile: profile),
          const SizedBox(height: 16),
          GoalSelectionCard(ref: ref, profile: profile),
          const SizedBox(height: 16),
          CalorieTargetCard(
            ref: ref,
            profile: profile,
            expenditureKcal: expenditureState.expenditureKcal,
            target: macroTarget,
          ),
          const SizedBox(height: 16),
          ProteinPreferenceCard(ref: ref, profile: profile),
          const SizedBox(height: 16),
          MacroDistributionCard(target: macroTarget),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
