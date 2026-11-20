import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../scaffold_with_nav_bar.dart';
import 'onboarding_flow_screen.dart';
import 'welcome_screen.dart';

/// Top-level router determining whether to display the first-launch onboarding flow
/// or navigate straight into the main authenticated dashboard.
class OnboardingCoordinator extends ConsumerWidget {
  const OnboardingCoordinator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final isCompleted =
        db.getSetting('onboarding_completed', 'false').toLowerCase() == 'true';

    if (isCompleted) {
      return const ScaffoldWithNavBar();
    }

    final savedStep = int.tryParse(db.getSetting('onboarding_step', '0')) ?? 0;
    if (savedStep >= 24) {
      return const ScaffoldWithNavBar();
    }
    if (savedStep > 0) {
      return OnboardingFlowScreen(initialStep: savedStep);
    }

    return const WelcomeScreen();
  }
}
