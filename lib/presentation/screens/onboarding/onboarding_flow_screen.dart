import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/data/local/app_database_coaching.dart';
import 'package:sique/domain/algorithms/coaching_engine.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/scaffold_with_nav_bar.dart';
import 'package:sique/presentation/theme/app_theme.dart';

import 'cards/card_01_goal.dart';
import 'cards/card_02_biometrics.dart';
import 'cards/card_03_weight_pacing.dart';
import 'cards/card_04_activity_training.dart';
import 'cards/card_05_diet_preferences.dart';
import 'cards/card_06_tdee_blueprint.dart';
import 'cards/card_07_save_strategy.dart';

/// Master 7-Card Streamlined Onboarding Flow Screen (AUD-37, AUD-38).
/// Replaces legacy 24-step marathon with 7 cohesive, high-craft Apple HIG cards.
/// Card 1: Goal Selection
/// Card 2: Biometrics
/// Card 3: Weight Goal & Dynamic Rate Pacing
/// Card 4: Activity & Training
/// Card 5: Diet & Nutrition Preferences
/// Card 6: Personalized TDEE & Macro Blueprint Reveal
/// Card 7: 'Save Your Strategy' (Optional Google/Email Auth + Health Connect sync)
class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key, this.initialStep});

  final int? initialStep;

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  late final PageController _pageController;
  int _currentStep = 0;
  static const int _totalSteps = 7;

  // Onboarding Profile State
  String _name = 'Athlete';
  bool _isMale = true;
  int _age = 28;
  double _heightCm = 175.0;
  double _currentWeightKg = 75.0;
  double _weightHistoryMax = 80.0;
  String _recentWeightTrend = 'stable';
  String _bodyFatRange = '15 – 19%';
  String _dailyActivity = 'moderate';
  String _liftingExperience = 'beginner';
  String _cardioExperience = 'beginner';
  double? _customTdeeOverride;

  GoalType _goalType = GoalType.fatLoss;
  double _targetWeightKg = 70.0;
  double _ratePct = -0.50;

  String _dietType = 'pure_veg';
  String _staplePreference = 'balanced';
  String _oilDefault = 'standard';
  String _calorieFloorType = 'standard';
  Set<int> _workoutDays = {1, 3, 5};
  String _distributionMode = 'even';
  ProteinPreference _proteinPref = ProteinPreference.high;

  MacroProgramStyle get _programStyle {
    if (_proteinPref == ProteinPreference.extraHigh) {
      return MacroProgramStyle.highProtein;
    }
    if (_dietType == 'keto') {
      return MacroProgramStyle.keto;
    }
    if (_dietType == 'low_carb') {
      return MacroProgramStyle.lowCarb;
    }
    if (_dietType == 'low_fat') {
      return MacroProgramStyle.lowFat;
    }
    return MacroProgramStyle.balanced;
  }

  WeeklyMacroProgram? _generatedProgram;

  WeeklyMacroProgram _computeFallbackProgram() {
    final profile = ref.read(userProfileProvider);
    final baselineTdee = _calculateBaselineTDEE();
    return CoachingEngine.buildWeeklyProgram(
      profile: profile,
      expenditureKcal: baselineTdee,
      style: _programStyle,
      allocationType: _distributionMode == 'shifted'
          ? DayAllocationType.shiftedWorkout
          : DayAllocationType.even,
      workoutDays: _workoutDays,
    );
  }

  WeeklyMacroProgram _ensureProgram() {
    if (_generatedProgram != null) return _generatedProgram!;
    final db = ref.read(databaseProvider);
    final saved = db.getCoachingProgram();
    if (saved != null) {
      _generatedProgram = saved;
      return saved;
    }
    final fallback = _computeFallbackProgram();
    _generatedProgram = fallback;
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _name = profile.name.isNotEmpty ? profile.name : 'Athlete';
    _isMale = profile.isMale;
    _age = profile.age >= 18 ? profile.age : 28;
    _heightCm = profile.heightCm > 0 ? profile.heightCm : 175.0;
    _currentWeightKg =
        profile.currentWeightKg > 0 ? profile.currentWeightKg : 75.0;
    _weightHistoryMax = profile.weightHistoryMax ?? _currentWeightKg;
    _recentWeightTrend = profile.recentWeightTrend;
    _bodyFatRange = profile.bodyFatRange ?? (_isMale ? '15 – 19%' : '22 – 26%');
    _dailyActivity = profile.dailyActivity;
    _liftingExperience = profile.liftingExperience;
    _cardioExperience = profile.cardioExperience;
    _customTdeeOverride = profile.baselineExpenditureKcal > 0
        ? profile.baselineExpenditureKcal
        : null;

    _goalType = profile.goalType;
    _targetWeightKg =
        profile.targetWeightKg > 0 ? profile.targetWeightKg : 70.0;
    _ratePct = profile.weeklyRateOfChangePct;

    _dietType = profile.dietType.isNotEmpty ? profile.dietType : 'pure_veg';
    _calorieFloorType = profile.calorieFloorType;
    _distributionMode = profile.distributionMode;
    _proteinPref = profile.proteinPreference;

    // Load persisted step and workout days
    final db = ref.read(databaseProvider);
    final savedWorkoutDays = db.getSetting('onboarding_workout_days', '');
    if (savedWorkoutDays.isNotEmpty) {
      final parsedDays = savedWorkoutDays
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toSet();
      if (parsedDays.isNotEmpty) {
        _workoutDays = parsedDays;
      }
    }

    final savedStaple = db.getSetting('staple_preference', 'balanced');
    _staplePreference = savedStaple;
    final savedOil = db.getSetting('default_oil_modifier', 'standard');
    _oilDefault = savedOil;

    final savedStepStr = db.getSetting('onboarding_step', '0');
    final savedStep = int.tryParse(savedStepStr) ?? 0;
    _currentStep = (widget.initialStep ?? savedStep).clamp(0, _totalSteps - 1);

    if (_currentStep == _totalSteps - 1) {
      _generatedProgram = db.getCoachingProgram();
      if (_generatedProgram == null) {
        _ensureProgram();
      }
    }

    _pageController = PageController(initialPage: _currentStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _persistStepProgress(int step) {
    final db = ref.read(databaseProvider);
    db.setSetting('onboarding_step', step.toString());
  }

  void _goToStep(int step) {
    if (step >= 0 && step < _totalSteps) {
      setState(() => _currentStep = step);
      _persistStepProgress(step);
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _nextStep() {
    _persistCurrentProfile();
    if (_currentStep < _totalSteps - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  double _calculateBaselineTDEE() {
    if (_customTdeeOverride != null && _customTdeeOverride! > 0) {
      return _customTdeeOverride!;
    }
    final bmr = (10.0 * _currentWeightKg) +
        (6.25 * _heightCm) -
        (5.0 * _age) +
        (_isMale ? 5.0 : -161.0);

    double activityMult = 1.35;
    if (_dailyActivity == 'sedentary') activityMult = 1.20;
    if (_dailyActivity == 'light') activityMult = 1.35;
    if (_dailyActivity == 'moderate') activityMult = 1.50;
    if (_dailyActivity == 'very_active') activityMult = 1.70;

    double exerciseBoost = 0.0;
    if (_workoutDays.isNotEmpty && _workoutDays.length <= 3) {
      exerciseBoost = 100.0;
    } else if (_workoutDays.length >= 4 && _workoutDays.length <= 6) {
      exerciseBoost = 220.0;
    } else if (_workoutDays.length >= 7) {
      exerciseBoost = 350.0;
    }

    return (bmr * activityMult + exerciseBoost).roundToDouble();
  }

  double _calculateBmr() {
    return (10.0 * _currentWeightKg) +
        (6.25 * _heightCm) -
        (5.0 * _age) +
        (_isMale ? 5.0 : -161.0);
  }

  void _persistCurrentProfile() {
    double floorCalories;
    if (_calorieFloorType == 'aggressive') {
      floorCalories = _isMale ? 1300.0 : 1000.0;
    } else {
      floorCalories = _isMale ? 1500.0 : 1200.0;
    }

    final currentProfile = ref.read(userProfileProvider);
    final profileName = _name.isNotEmpty && _name != 'Athlete'
        ? _name
        : (currentProfile.name.isNotEmpty ? currentProfile.name : 'Athlete');

    final updatedProfile = UserProfile(
      id: 'active_user',
      name: profileName,
      currentWeightKg: _currentWeightKg,
      targetWeightKg: _targetWeightKg,
      heightCm: _heightCm,
      age: _age,
      isMale: _isMale,
      goalType: _goalType,
      programMode: ProgramMode.coached,
      weeklyRateOfChangePct: _ratePct,
      proteinPreference: _proteinPref,
      calorieFloor: floorCalories,
      baselineExpenditureKcal: _calculateBaselineTDEE(),
      dietType: _dietType,
      calorieFloorType: _calorieFloorType,
      liftingExperience: _liftingExperience,
      cardioExperience: _cardioExperience,
      bodyFatRange: _bodyFatRange,
      weightHistoryMax: _weightHistoryMax,
      distributionMode: _distributionMode,
      recentWeightTrend: _recentWeightTrend,
      exerciseFrequency: '${_workoutDays.length}',
      dailyActivity: _dailyActivity,
    );

    ref.read(userProfileProvider.notifier).updateProfile(updatedProfile);
    final db = ref.read(databaseProvider);
    db.setSetting('onboarding_workout_days', _workoutDays.join(','));
    db.setSetting('dietary_preference', _dietType);
    db.setSetting('staple_preference', _staplePreference);
    db.setSetting('default_oil_modifier', _oilDefault);
  }

  void _buildAndActivateProgram() {
    _persistCurrentProfile();
    final profile = ref.read(userProfileProvider);
    final baselineTdee = _calculateBaselineTDEE();

    final program = CoachingEngine.buildWeeklyProgram(
      profile: profile,
      expenditureKcal: baselineTdee,
      style: _programStyle,
      allocationType: _distributionMode == 'shifted'
          ? DayAllocationType.shiftedWorkout
          : DayAllocationType.even,
      workoutDays: _workoutDays,
    );

    final db = ref.read(databaseProvider);
    db.saveCoachingProgram(program);

    setState(() {
      _generatedProgram = program;
    });

    _nextStep();
  }

  void _finishOnboarding() {
    _persistCurrentProfile();
    final program = _ensureProgram();
    final db = ref.read(databaseProvider);
    db.saveCoachingProgram(program);
    db.setSetting('onboarding_completed', 'true');
    db.setSetting('onboarding_step', '0');

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ScaffoldWithNavBar()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = 0.22 + (_currentStep / (_totalSteps - 1)) * 0.78;
    final tdee = _calculateBaselineTDEE();
    final bmr = _calculateBmr();

    // Compute live macro targets for preview
    final targetCals = _goalType == GoalType.maintenance
        ? tdee
        : (_goalType == GoalType.fatLoss
            ? tdee - (_currentWeightKg * (_ratePct.abs() / 100.0) * 7700 / 7)
            : tdee + (_currentWeightKg * (_ratePct.abs() / 100.0) * 7700 / 7));
    final proteinGrams = _currentWeightKg * _proteinPref.gramsPerKg;
    final fatGrams = (targetCals * 0.25 / 9.0).clamp(30.0, 150.0);
    final carbsGrams =
        ((targetCals - (proteinGrams * 4.0) - (fatGrams * 9.0)) / 4.0)
            .clamp(50.0, 800.0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          key: const Key('onboarding_back_btn'),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppTheme.textPrimary),
          onPressed: _previousStep,
        ),
        title: Text(
          'Step ${_currentStep + 1} of $_totalSteps',
          key: const Key('onboarding_step_title'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.22, end: progress),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            builder: (context, val, _) => LinearProgressIndicator(
              value: val,
              backgroundColor: AppTheme.cardBorder,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.activeBlue),
              minHeight: 3,
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (idx) {
          setState(() => _currentStep = idx);
          _persistStepProgress(idx);
        },
        children: [
          // Card 1: Goal Selection
          Card01Goal(
            selectedGoal: _goalType,
            onGoalSelected: (goal) {
              setState(() {
                _goalType = goal;
                if (goal == GoalType.maintenance) {
                  _targetWeightKg = _currentWeightKg;
                  _ratePct = 0.0;
                } else if (goal == GoalType.fatLoss) {
                  _ratePct = -0.50;
                  if (_targetWeightKg >= _currentWeightKg) {
                    _targetWeightKg =
                        (_currentWeightKg - 5.0).clamp(40.0, 300.0);
                  }
                } else if (goal == GoalType.muscleGain) {
                  _ratePct = 0.25;
                  if (_targetWeightKg <= _currentWeightKg) {
                    _targetWeightKg =
                        (_currentWeightKg + 3.0).clamp(40.0, 300.0);
                  }
                }
              });
            },
            onNext: _nextStep,
          ),

          // Card 2: Biometrics
          Card02Biometrics(
            initialIsMale: _isMale,
            initialAge: _age,
            initialHeightCm: _heightCm,
            initialWeightKg: _currentWeightKg,
            onBiometricsChanged: ({
              required isMale,
              required age,
              required heightCm,
              required weightKg,
            }) {
              setState(() {
                _isMale = isMale;
                _age = age;
                _heightCm = heightCm;
                _currentWeightKg = weightKg;
              });
            },
            onNext: _nextStep,
          ),

          // Card 3: Weight Goal & Dynamic Rate Pacing
          Card03WeightPacing(
            goalType: _goalType,
            currentWeightKg: _currentWeightKg,
            heightCm: _heightCm,
            initialTargetWeightKg: _targetWeightKg,
            initialRatePct: _ratePct,
            onPacingChanged: ({
              required targetWeightKg,
              required ratePct,
            }) {
              setState(() {
                _targetWeightKg = targetWeightKg;
                _ratePct = ratePct;
              });
            },
            onNext: _nextStep,
          ),

          // Card 4: Activity & Training
          Card04ActivityTraining(
            initialActivity: _dailyActivity,
            initialWorkoutDays: _workoutDays,
            onActivityTrainingChanged: ({
              required dailyActivity,
              required workoutDays,
            }) {
              setState(() {
                _dailyActivity = dailyActivity;
                _workoutDays = workoutDays;
              });
            },
            onNext: _nextStep,
          ),

          // Card 5: Diet & Nutrition Preferences
          Card05DietPreferences(
            initialDietType: _dietType,
            initialStaple: _staplePreference,
            initialProteinPref: _proteinPref,
            initialOilDefault: _oilDefault,
            onPreferencesChanged: ({
              required dietType,
              required staplePreference,
              required proteinPreference,
              required oilDefault,
            }) {
              setState(() {
                _dietType = dietType;
                _staplePreference = staplePreference;
                _proteinPref = proteinPreference;
                _oilDefault = oilDefault;
              });
            },
            onNext: _nextStep,
          ),

          // Card 6: Personalized TDEE & Macro Blueprint Reveal
          Card06TdeeBlueprint(
            tdeeKcal: tdee,
            bmrKcal: bmr,
            targetCalories: targetCals,
            proteinGrams: proteinGrams,
            carbsGrams: carbsGrams,
            fatGrams: fatGrams,
            initialOverrideKcal: _customTdeeOverride,
            initialDistributionMode: _distributionMode,
            workoutDays: _workoutDays,
            onBlueprintChanged: ({
              required customTdeeOverride,
              required distributionMode,
            }) {
              setState(() {
                _customTdeeOverride = customTdeeOverride;
                _distributionMode = distributionMode;
              });
            },
            onNext: _buildAndActivateProgram,
          ),

          // Card 7: Save Your Strategy (Optional Google/Email Auth + Health Connect sync)
          Card07SaveStrategy(
            program: _ensureProgram(),
            onFinish: _finishOnboarding,
          ),
        ],
      ),
    );
  }
}
