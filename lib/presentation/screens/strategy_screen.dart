import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_profile.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_primitives.dart';
import '../widgets/strategy/checkin_history_sheet.dart';
import '../widgets/strategy/collaborative_macro_editor_sheet.dart';
import '../widgets/strategy/lifestyle_telemetry_strip.dart';
import '../widgets/strategy/macro_program_hero_card.dart';
import '../widgets/strategy/metabolic_command_header.dart';
import '../widgets/strategy/seven_day_distribution_chart.dart';
import '../widgets/body_measurements_sheet.dart';
import '../widgets/weekly_challenge_card.dart';
import 'goal_questionnaire_sheet.dart';
import 'onboarding/strategy_setup_wizard.dart';

/// Strategy & Coaching Screen reconstructed with Sique's clean-room
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

  void _openQuestionnaire(BuildContext context) {
    GoalQuestionnaireSheet.show(context);
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
    final profile = ref.watch(userProfileProvider);

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
            key: const Key('strategy_goal_questionnaire_btn'),
            onPressed: () => _openQuestionnaire(context),
            icon: const Icon(Icons.tune_rounded, color: AppTheme.activeBlue),
            tooltip: 'Personalize Goal & Strategy',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: SingleChildScrollView(
            key: const PageStorageKey('strategy_scroll_view'),
            physics: const BouncingScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TIER 1: Above-the-Fold Metabolic Command & Active Macro Program
                const AppleStaggeredEntrance(
                  index: 0,
                  child: MetabolicCommandHeader(),
                ),
                const SizedBox(height: 16),
                const AppleStaggeredEntrance(
                  index: 1,
                  child: MacroProgramHeroCard(),
                ),
                const SizedBox(height: 16),
                const AppleStaggeredEntrance(
                  index: 2,
                  child: SevenDayDistributionChart(),
                ),
                const SizedBox(height: 16),

                // TIER 2: Closed-Loop Coaching (Personalized Challenges & Recomp Radar)
                const AppleStaggeredEntrance(
                  index: 3,
                  child: WeeklyChallengesSection(),
                ),
                const SizedBox(height: 16),
                const AppleStaggeredEntrance(
                  index: 4,
                  child: AnthropometricsCard(),
                ),
                const SizedBox(height: 16),

                // TIER 3: Configuration & Lifestyle Telemetry Strip
                AppleStaggeredEntrance(
                  index: 5,
                  child: _buildProgramModeCard(
                    context,
                    ref,
                    program.mode,
                    profile,
                  ),
                ),
                const SizedBox(height: 16),
                const AppleStaggeredEntrance(
                  index: 6,
                  child: LifestyleTelemetryStrip(),
                ),
                const SizedBox(height: 16),

                // Refined Adjust Strategy & Program Personalization Card
                AppleStaggeredEntrance(
                  index: 7,
                  child: Container(
                    key: const Key('strategy_adjust_program_card'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardSurface,
                      borderRadius: AppRadii.xlBorderRadius,
                      border: Border.all(
                        color: AppTheme.activeBlue.withValues(alpha: 0.25),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: AppTheme.activeBlue,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'ADJUST STRATEGY & GOALS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Personalize your target rate of change, Indian diet staples, or refigure the entire macro split.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: AppleBouncy(
                                scaleDown: 0.96,
                                onTap: () {
                                  AppHaptics.lightImpact();
                                  _openQuestionnaire(context);
                                },
                                child: Container(
                                  key: const Key(
                                      'strategy_personalize_goal_btn'),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.activeBlue
                                        .withValues(alpha: 0.12),
                                    borderRadius: AppRadii.mdBorderRadius,
                                    border: Border.all(
                                      color: AppTheme.activeBlue
                                          .withValues(alpha: 0.35),
                                      width: 1,
                                    ),
                                  ),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.edit_note_rounded,
                                            size: 16,
                                            color: AppTheme.activeBlue),
                                        SizedBox(width: 4),
                                        Text(
                                          'Edit Goal & Diet',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.activeBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppleBouncy(
                                scaleDown: 0.96,
                                onTap: () {
                                  AppHaptics.lightImpact();
                                  _openSetupWizard(context);
                                },
                                child: Container(
                                  key: const Key(
                                      'strategy_refigure_program_btn'),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 4),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.calories,
                                    borderRadius: AppRadii.mdBorderRadius,
                                  ),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.auto_fix_high_rounded,
                                            size: 16,
                                            color: AppTheme.buttonForeground),
                                        SizedBox(width: 4),
                                        Text(
                                          'Refigure Split',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.buttonForeground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgramModeCard(
    BuildContext context,
    WidgetRef ref,
    ProgramMode activeMode,
    UserProfile profile,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: AppRadii.xlBorderRadius,
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COACHING MODE',
            style: TextStyle(
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
          if (activeMode != ProgramMode.coached) ...[
            const SizedBox(height: 12),
            AppleBouncy(
              scaleDown: 0.96,
              onTap: () => CollaborativeMacroEditorSheet.show(
                context,
                mode: activeMode,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.activeBlue.withValues(alpha: 0.14),
                  borderRadius: AppRadii.mdBorderRadius,
                  border: Border.all(
                    color: AppTheme.activeBlue.withValues(alpha: 0.35),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  activeMode == ProgramMode.manual
                      ? 'Configure Manual Targets ->'
                      : 'Customize Carb/Fat & Refeed Split ->',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.activeBlue,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Divider(color: AppTheme.cardBorder.withValues(alpha: 0.6), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DIET BREAK WEEK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pause deficit temporarily at 1.0x estimated expenditure.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: profile.isInDietBreak,
                activeThumbColor: AppTheme.expenditure,
                onChanged: (enabled) {
                  AppHaptics.selectionClick();
                  ref.read(userProfileProvider.notifier).updateProfile(
                        profile.copyWith(isInDietBreak: enabled),
                      );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'REVERSE DIET PACING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (final opt in const [
                ('none', 'Off'),
                ('conservative', '+2.5%/wk'),
                ('moderate', '+5%/wk'),
                ('aggressive', '+8%/wk'),
              ])
                ChoiceChip(
                  label: Text(
                    opt.$2,
                    style: const TextStyle(fontSize: 11),
                  ),
                  selected: profile.reverseDietPacing == opt.$1,
                  selectedColor: AppTheme.expenditure.withValues(alpha: 0.22),
                  onSelected: (_) {
                    AppHaptics.selectionClick();
                    ref.read(userProfileProvider.notifier).updateProfile(
                          profile.copyWith(reverseDietPacing: opt.$1),
                        );
                  },
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
        return 'Fully automated check-ins. Sique optimizes your calories and macro split based on your Bayesian expenditure.';
      case ProgramMode.collaborative:
        return 'Guided partnership. Sique sets the weekly energy budget, and you customize day distribution and macro ratios.';
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
          AppHaptics.selectionClick();
          final program = ref.read(weeklyMacroProgramProvider);
          final updatedProgram = program.copyWith(
            mode: mode,
            clearCarbShareOverride: mode != ProgramMode.collaborative,
          );
          ref
              .read(weeklyMacroProgramProvider.notifier)
              .updateProgram(updatedProgram);

          final profile = ref.read(userProfileProvider);
          ref.read(userProfileProvider.notifier).updateProfile(
                profile.copyWith(
                  programMode: mode,
                  clearCustom: mode != ProgramMode.manual,
                ),
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
            borderRadius: AppRadii.mdBorderRadius,
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
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppTheme.calories : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
