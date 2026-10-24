import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/screens/scaffold_with_nav_bar.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Step 23: Onboarding Completion & Final Launch
class Step23Completion extends ConsumerWidget {
  const Step23Completion({super.key});

  void _finish(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    db.setSetting('onboarding_completed', 'true');

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ScaffoldWithNavBar()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingStepScaffold(
      title: 'You are All Set!',
      subtitle:
          'Your personalized metabolic coaching program is active and ready.',
      icon: Icons.celebration_rounded,
      continueLabel: 'Enter Sique',
      continueKey: const Key('step_23_enter_app_btn'),
      onContinue: () => _finish(context, ref),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppTheme.success, size: 40),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Metabolic Engine Engaged',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Log your meals and daily scale weights. Sique Kalman V4 filter will continuously refine your true daily expenditure in real-time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
