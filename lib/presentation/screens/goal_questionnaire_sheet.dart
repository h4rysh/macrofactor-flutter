import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_profile.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_tactile_card.dart';
import 'questionnaire_steps/activity_expenditure_step.dart';
import 'questionnaire_steps/adaptive_pacing_step.dart';
import 'questionnaire_steps/goal_selection_step.dart';
import 'questionnaire_steps/indian_dietary_step.dart';
import 'questionnaire_steps/protein_strategy_step.dart';
import 'questionnaire_steps/summary_activation_step.dart';

/// Interactive Apple HIG Questionnaire & Direction Sheet for Goals & Preferences.
/// Features dynamic branching based on primary goal, real-time target preview,
/// spring micro-interactions, Indian nutritional personalization, and instant persistence.
class GoalQuestionnaireSheet extends ConsumerStatefulWidget {
  const GoalQuestionnaireSheet({super.key});

  /// Opens the interactive goal & preferences direction sheet as a modal bottom sheet.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => const GoalQuestionnaireSheet(),
    );
  }

  @override
  ConsumerState<GoalQuestionnaireSheet> createState() =>
      _GoalQuestionnaireSheetState();
}

class _GoalQuestionnaireSheetState
    extends ConsumerState<GoalQuestionnaireSheet> {
  int _currentStep = 0;
  final int _totalSteps = 6;
  bool _isSubmitting = false;

  // Working state initialized from userProfileProvider
  late GoalType _selectedGoal;
  late double _weeklyRate;
  late ProteinPreference _proteinPref;
  late double _baselineExpenditure;

  // Activity baseline multiplier
  double _activityMultiplier = 1.375; // Default: Lightly Active

  // Indian Dietary Preferences
  String _dietSlug = 'pure_veg';
  String _stapleSlug = 'balanced';
  String _oilSlug = 'standard';

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _selectedGoal = profile.goalType;
    _weeklyRate = profile.weeklyRateOfChangePct;
    _proteinPref = profile.proteinPreference;
    _baselineExpenditure = profile.baselineExpenditureKcal;

    // Load initial dietary habits from database settings if available
    final db = ref.read(databaseProvider);
    final savedDiet =
        db.getSetting('dietary_preference', 'pure_veg').toLowerCase();
    if (savedDiet.contains('egg')) {
      _dietSlug = 'eggetarian';
    } else if (savedDiet.contains('non')) {
      _dietSlug = 'non_veg';
    } else if (savedDiet.contains('vegan')) {
      _dietSlug = 'vegan';
    } else {
      _dietSlug = 'pure_veg';
    }

    final savedStaple =
        db.getSetting('staple_preference', 'balanced').toLowerCase();
    if (savedStaple.contains('roti')) {
      _stapleSlug = 'roti';
    } else if (savedStaple.contains('rice')) {
      _stapleSlug = 'rice';
    } else {
      _stapleSlug = 'balanced';
    }

    final savedOil =
        db.getSetting('default_oil_modifier', 'standard').toLowerCase();
    if (savedOil.contains('light') ||
        savedOil.contains('low') ||
        savedOil.contains('spray')) {
      _oilSlug = 'light';
    } else if (savedOil.contains('heavy') ||
        savedOil.contains('generous') ||
        savedOil.contains('extra')) {
      _oilSlug = 'generous';
    } else {
      _oilSlug = 'standard';
    }
  }

  void _nextStep() {
    _autoSaveCurrentState();
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    _autoSaveCurrentState();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  /// Calculates dynamic baseline expenditure using Mifflin-St Jeor formula + activity multiplier.
  void _recalculateExpenditure(UserProfile profile) {
    final s = profile.isMale ? 5.0 : -161.0;
    final bmr = (10.0 * profile.currentWeightKg) +
        (6.25 * profile.heightCm) -
        (5.0 * profile.age) +
        s;
    _baselineExpenditure = (bmr * _activityMultiplier).roundToDouble();
  }

  /// Persists the user's progress across steps so interim answers are never lost.
  void _autoSaveCurrentState() {
    final currentProfile = ref.read(userProfileProvider);
    final db = ref.read(databaseProvider);

    final updatedProfile = currentProfile.copyWith(
      goalType: _selectedGoal,
      weeklyRateOfChangePct: _weeklyRate,
      proteinPreference: _proteinPref,
      baselineExpenditureKcal: _baselineExpenditure,
      clearCustom: true,
    );

    ref.read(userProfileProvider.notifier).updateProfile(updatedProfile);
    db.setSetting('dietary_preference', _dietSlug);
    db.setSetting('staple_preference', _stapleSlug);
    db.setSetting('default_oil_modifier', _oilSlug);
  }

  /// Final saves all choices and dismisses the questionnaire modal safely.
  void _saveAndApply() {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    _autoSaveCurrentState();

    if (!mounted) return;
    Navigator.of(context).pop(true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.expenditure, width: 0.8),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.expenditure, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Program calibrated for ${_selectedGoal.displayName}!',
                style: const TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final simulatedProfile = profile.copyWith(
      goalType: _selectedGoal,
      weeklyRateOfChangePct: _weeklyRate,
      proteinPreference: _proteinPref,
      baselineExpenditureKcal: _baselineExpenditure,
      clearCustom: true,
    );
    final previewMacros =
        simulatedProfile.calculateTargetMacros(_baselineExpenditure);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AppTheme.cardBorder,
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Apple Sheet Grabber Pill
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0x4DFFFFFF),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Header with Apple-Style Step Indicator & Back Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      IconButton(
                        key: const Key('questionnaire_back_btn'),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: AppTheme.textSecondary),
                        onPressed: _prevStep,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    else
                      const SizedBox(width: 18),
                    const Spacer(),
                    Text(
                      'Step ${_currentStep + 1} of $_totalSteps',
                      style: const TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: AppTheme.textSecondary),
                      onPressed: () {
                        _autoSaveCurrentState();
                        Navigator.of(context).pop(false);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // 3. Smooth Animated Progress Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 4,
                    child: Row(
                      children: List.generate(_totalSteps, (index) {
                        final isCompleted = index <= _currentStep;
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppTheme.calories
                                  : const Color(0x1FFFFFFF),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),

              const Divider(height: 12, color: AppTheme.cardBorder),

              // 4. Interactive Page Content with Spring Slide Transition
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.06, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: _buildCurrentStepView(
                    context,
                    profile,
                    previewMacros,
                  ),
                ),
              ),

              // 5. Bottom Navigation Action Bar
              _buildBottomActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepView(
    BuildContext context,
    UserProfile profile,
    MacroTarget previewMacros,
  ) {
    switch (_currentStep) {
      case 0:
        return GoalSelectionStep(
          key: const ValueKey('step_0_goal'),
          selectedGoal: _selectedGoal,
          onGoalSelected: (goal) {
            setState(() {
              _selectedGoal = goal;
              if (goal == GoalType.fatLoss) {
                _weeklyRate = -0.75;
              } else if (goal == GoalType.muscleGain) {
                _weeklyRate = 0.25;
              } else {
                _weeklyRate = 0.0;
              }
            });
          },
        );
      case 1:
        return AdaptivePacingStep(
          key: const ValueKey('step_1_pacing'),
          selectedGoal: _selectedGoal,
          weeklyRate: _weeklyRate,
          currentWeightKg: profile.currentWeightKg,
          onRateSelected: (rate) {
            setState(() => _weeklyRate = rate);
          },
        );
      case 2:
        return ActivityExpenditureStep(
          key: const ValueKey('step_2_activity'),
          activityMultiplier: _activityMultiplier,
          baselineExpenditure: _baselineExpenditure,
          onActivitySelected: (mult) {
            setState(() {
              _activityMultiplier = mult;
              _recalculateExpenditure(profile);
            });
          },
        );
      case 3:
        return IndianDietaryStep(
          key: const ValueKey('step_3_diet'),
          dietSlug: _dietSlug,
          stapleSlug: _stapleSlug,
          oilSlug: _oilSlug,
          onDietSelected: (diet) => setState(() => _dietSlug = diet),
          onStapleSelected: (staple) => setState(() => _stapleSlug = staple),
          onOilSelected: (oil) => setState(() => _oilSlug = oil),
        );
      case 4:
        return ProteinStrategyStep(
          key: const ValueKey('step_4_protein'),
          selectedGoal: _selectedGoal,
          currentWeightKg: profile.currentWeightKg,
          proteinPref: _proteinPref,
          onProteinSelected: (pref) => setState(() => _proteinPref = pref),
        );
      case 5:
        return SummaryActivationStep(
          key: const ValueKey('step_5_summary'),
          macros: previewMacros,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomActionBar() {
    final isFinalStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 0.8)),
      ),
      child: AppleBouncy(
        key: const Key('questionnaire_next_btn'),
        onTap: _isSubmitting ? null : (isFinalStep ? _saveAndApply : _nextStep),
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: isFinalStep ? AppTheme.calories : AppTheme.activeBlue,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isFinalStep ? AppTheme.calories : AppTheme.activeBlue)
                    .withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isFinalStep ? 'Activate Custom Program' : 'Continue',
                style: const TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isFinalStep
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
