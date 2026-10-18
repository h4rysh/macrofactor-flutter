import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_profile.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_primitives.dart';
import '../widgets/strategy/checkin_history_sheet.dart';
import '../widgets/strategy/coaching_checkin_card.dart';
import '../widgets/strategy/macro_program_hero_card.dart';
import '../widgets/strategy/seven_day_distribution_chart.dart';
import 'onboarding/strategy_setup_wizard.dart';

/// Strategy & Coaching Screen reconstructed with MacroFactor's clean-room
/// adherence-neutral algorithm, 7-day shifting, and Bayesian check-in engine.
class StrategyScreen extends ConsumerWidget {
  const StrategyScreen({super.key});

  void _openSetupWizard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const StrategySetupWizard(),
      ),
    );
  }

  void _openHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CheckinHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(weeklyMacroProgramProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Coaching & Strategy'),
        actions: [
          IconButton(
            onPressed: () => _openHistorySheet(context),
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Check-In History',
          ),
          IconButton(
            onPressed: () => _openSetupWizard(context),
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Customize Program',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Adherence-Neutral Guarantee Banner
            AppleStaggeredEntrance(
              index: 0,
              child: _buildAdherenceNeutralCard(),
            ),
            const SizedBox(height: 16),

            // 2. Coaching Check-In Status Card
            const AppleStaggeredEntrance(
              index: 1,
              child: CoachingCheckinCard(),
            ),
            const SizedBox(height: 16),

            // 3. Active Program Hero Card
            const AppleStaggeredEntrance(
              index: 2,
              child: MacroProgramHeroCard(),
            ),
            const SizedBox(height: 16),

            // 4. 7-Day Day Shifting Distribution Chart
            const AppleStaggeredEntrance(
              index: 3,
              child: SevenDayDistributionChart(),
            ),
            const SizedBox(height: 16),

            // 5. Program Mode Quick Switch Card
            AppleStaggeredEntrance(
              index: 4,
              child: _buildProgramModeCard(context, ref, program.mode),
            ),
            const SizedBox(height: 16),

            // 6. Strategy Action Buttons
            AppleStaggeredEntrance(
              index: 5,
              child: AppleTactileCard(
                onTap: () => _openSetupWizard(context),
                backgroundColor: AppTheme.calories,
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_fix_high_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'REFIGURE PROGRAM STRATEGY',
                      style: TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceNeutralCard() {
    return AppleTactileCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      backgroundColor: AppTheme.cardSurface,
      borderColor: AppTheme.expenditure.withValues(alpha: 0.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.expenditure.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              size: 22,
              color: AppTheme.expenditure,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADHERENCE-NEUTRAL COACHING',
                  style: TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.expenditure,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Our Bayesian expenditure engine does not judge or assign guilt. Eat what you enjoy: your targets adapt to biological intake and weight flux, with zero behavioral penalties.',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
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

  Widget _buildProgramModeCard(
    BuildContext context,
    WidgetRef ref,
    ProgramMode activeMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COACHING MODE',
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _modeDescription(activeMode),
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildModeChip(
                context: context,
                ref: ref,
                label: 'Coached',
                mode: ProgramMode.coached,
                isSelected: activeMode == ProgramMode.coached,
              ),
              const SizedBox(width: 8),
              _buildModeChip(
                context: context,
                ref: ref,
                label: 'Collaborative',
                mode: ProgramMode.collaborative,
                isSelected: activeMode == ProgramMode.collaborative,
              ),
              const SizedBox(width: 8),
              _buildModeChip(
                context: context,
                ref: ref,
                label: 'Manual',
                mode: ProgramMode.manual,
                isSelected: activeMode == ProgramMode.manual,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _modeDescription(ProgramMode mode) {
    switch (mode) {
      case ProgramMode.coached:
        return 'Fully automated check-ins. MacroFactor optimizes your calories and macro split based on your Bayesian expenditure.';
      case ProgramMode.collaborative:
        return 'Guided partnership. MacroFactor sets the weekly energy budget, and you customize day distribution and macro ratios.';
      case ProgramMode.manual:
        return 'Total freedom. You set your exact targets while the expenditure engine quietly computes your true metabolic burn.';
    }
  }

  Widget _buildModeChip({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required ProgramMode mode,
    required bool isSelected,
  }) {
    return Expanded(
      child: AppleBouncy(
        scaleDown: 0.94,
        onTap: () {
          HapticFeedback.selectionClick();
          final program = ref.read(weeklyMacroProgramProvider);
          final updatedProgram = program.copyWith(mode: mode);
          ref
              .read(weeklyMacroProgramProvider.notifier)
              .updateProgram(updatedProgram);

          final profile = ref.read(userProfileProvider);
          ref.read(userProfileProvider.notifier).updateProfile(
                profile.copyWith(programMode: mode),
              );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.calories.withValues(alpha: 0.16)
                : AppTheme.cardElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.calories : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.calories.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppTheme.calories : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
