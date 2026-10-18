import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../scaffold_with_nav_bar.dart';
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

    return const WelcomeScreen();
  }
}
