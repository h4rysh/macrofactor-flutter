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

import 'steps/step_01_health_connect.dart';
import 'steps/step_02_sex.dart';
import 'steps/step_03_dob.dart';
import 'steps/step_04_height.dart';
import 'steps/step_05_weight.dart';
import 'steps/step_06_weight_history.dart';
import 'steps/step_07_weight_trend.dart';
import 'steps/step_08_body_fat.dart';
import 'steps/step_09_exercise_frequency.dart';
import 'steps/step_10_daily_activity.dart';
import 'steps/step_11_lifting_experience.dart';
import 'steps/step_12_cardio_experience.dart';
import 'steps/step_13_tdee_reveal.dart';
import 'steps/step_14_goal_type.dart';
import 'steps/step_15_target_weight.dart';
import 'steps/step_16_goal_rate.dart';
import 'steps/step_17_goal_summary.dart';
import 'steps/step_18_diet_type.dart';
import 'steps/step_19_calorie_floor.dart';
import 'steps/step_20_training.dart';
import 'steps/step_21_distribution_mode.dart';
import 'steps/step_22_protein_preference.dart';
import 'steps/step_23_medical_disclaimer.dart';
import 'steps/step_24_program_ready.dart';

/// Master 24-Step Onboarding Flow Screen
/// Manages honest progress indicator, step persistence in app_settings,
/// and profile/program synthesis into SQLite.
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
  static const int _totalSteps = 24;

  // Onboarding Profile State
  String _name = 'Athlete';
  bool _isMale = true;
  int _age = 28;
  double _heightCm = 175.0;
  double _currentWeightKg = 75.0;
  double _weightHistoryMax = 80.0;
  String _recentWeightTrend = 'stable';
  String _bodyFatRange = '15 – 19%';
  String _exerciseFrequency = '1-3';
  String _dailyActivity = 'moderate';
  String _liftingExperience = 'beginner';
  String _cardioExperience = 'beginner';
  double? _customTdeeOverride;

  GoalType _goalType = GoalType.fatLoss;
  double _targetWeightKg = 70.0;
  double _ratePct = -0.50;

  String _dietType = 'standard';
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
    _exerciseFrequency = profile.exerciseFrequency;
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

    _dietType = profile.dietType;
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
    if (_dailyActivity == 'very_active') activityMult = 1.55;

    double exerciseBoost = 0.0;
    if (_exerciseFrequency == '1-3') exerciseBoost = 100.0;
    if (_exerciseFrequency == '4-6') exerciseBoost = 220.0;
    if (_exerciseFrequency == '7+') exerciseBoost = 350.0;

    return (bmr * activityMult + exerciseBoost).roundToDouble();
  }

  void _persistCurrentProfile() {
    double floorCalories;
    if (_calorieFloorType == 'aggressive') {
      floorCalories = _isMale ? 1300.0 : 1000.0;
    } else if (_calorieFloorType == 'disabled') {
      floorCalories = 800.0;
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
      exerciseFrequency: _exerciseFrequency,
      dailyActivity: _dailyActivity,
    );

    ref.read(userProfileProvider.notifier).updateProfile(updatedProfile);
    final db = ref.read(databaseProvider);
    db.setSetting('onboarding_workout_days', _workoutDays.join(','));
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

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / _totalSteps;

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
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.cardBorder,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.activeBlue),
            minHeight: 3,
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
          // Step 1: Health Connect (Optional)
          Step01HealthConnect(onNext: _nextStep),
          // Step 2: Sex
          Step02Sex(
            initialIsMale: _isMale,
            onNext: (isMale) {
              _isMale = isMale;
              _nextStep();
            },
          ),
          // Step 3: Date of Birth (Age 18+ Lock)
          Step03Dob(
            initialAge: _age,
            onNext: (age) {
              _age = age;
              _nextStep();
            },
          ),
          // Step 4: Height (cm / ft-in toggle)
          Step04Height(
            initialHeightCm: _heightCm,
            onNext: (h) {
              _heightCm = h;
              _nextStep();
            },
          ),
          // Step 5: Current Weight (kg / lb toggle, slider + numeric)
          Step05Weight(
            initialWeightKg: _currentWeightKg,
            onNext: (w) {
              _currentWeightKg = w;
              _nextStep();
            },
          ),
          // Step 6: Weight History
          Step06WeightHistory(
            currentWeightKg: _currentWeightKg,
            initialMaxWeightKg: _weightHistoryMax,
            onNext: (maxW) {
              _weightHistoryMax = maxW;
              _nextStep();
            },
          ),
          // Step 7: Recent Weight Trend (seeds Kalman prior)
          Step07WeightTrend(
            initialTrend: _recentWeightTrend,
            onNext: (trend) {
              _recentWeightTrend = trend;
              _nextStep();
            },
          ),
          // Step 8: Body Fat (Optional)
          Step08BodyFat(
            initialBodyFatRange: _bodyFatRange,
            isMale: _isMale,
            onNext: (range) {
              _bodyFatRange = range;
              _nextStep();
            },
          ),
          // Step 9: Exercise Frequency
          Step09ExerciseFrequency(
            initialFrequency: _exerciseFrequency,
            onNext: (freq) {
              _exerciseFrequency = freq;
              _nextStep();
            },
          ),
          // Step 10: Daily Activity
          Step10DailyActivity(
            initialActivity: _dailyActivity,
            onNext: (activity) {
              _dailyActivity = activity;
              _nextStep();
            },
          ),
          // Step 11: Lifting Experience
          Step11LiftingExperience(
            initialExperience: _liftingExperience,
            onNext: (exp) {
              _liftingExperience = exp;
              _nextStep();
            },
          ),
          // Step 12: Cardio Experience
          Step12CardioExperience(
            initialExperience: _cardioExperience,
            onNext: (cardio) {
              _cardioExperience = cardio;
              _nextStep();
            },
          ),
          // Step 13: TDEE Reveal (Mifflin-St Jeor + Activity/Exercise + Override)
          Step13TdeeReveal(
            weightKg: _currentWeightKg,
            heightCm: _heightCm,
            age: _age,
            isMale: _isMale,
            activityLevel: _dailyActivity,
            exerciseFrequency: _exerciseFrequency,
            initialOverrideKcal: _customTdeeOverride,
            onNext: (tdee) {
              _customTdeeOverride = tdee;
              _nextStep();
            },
          ),
          // Step 14: Goal Type
          Step14GoalType(
            initialGoalType: _goalType,
            onNext: (g) {
              _goalType = g;
              _nextStep();
            },
          ),
          // Step 15: Target Weight (BMI >= 18.5 guardrail)
          Step15TargetWeight(
            goalType: _goalType,
            currentWeightKg: _currentWeightKg,
            heightCm: _heightCm,
            initialTargetWeightKg: _targetWeightKg,
            onNext: (targetW) {
              _targetWeightKg = targetW;
              _nextStep();
            },
          ),
          // Step 16: Goal Rate
          Step16GoalRate(
            goalType: _goalType,
            currentWeightKg: _currentWeightKg,
            initialRatePct: _ratePct,
            onNext: (rate) {
              _ratePct = rate;
              _nextStep();
            },
          ),
          // Step 17: Goal Summary
          Step17GoalSummary(
            goalType: _goalType,
            currentWeightKg: _currentWeightKg,
            targetWeightKg: _targetWeightKg,
            ratePct: _ratePct,
            onNext: _nextStep,
          ),
          // Step 18: Diet Type
          Step18DietType(
            initialDietType: _dietType,
            onNext: (diet) {
              _dietType = diet;
              _nextStep();
            },
          ),
          // Step 19: Calorie Floor
          Step19CalorieFloor(
            isMale: _isMale,
            initialFloorType: _calorieFloorType,
            onNext: (floor) {
              _calorieFloorType = floor;
              _nextStep();
            },
          ),
          // Step 20: Training Schedule
          Step20Training(
            initialWorkoutDays: _workoutDays,
            onNext: (days) {
              _workoutDays = days;
              _nextStep();
            },
          ),
          // Step 21: Distribution Mode (Even vs Shifted)
          Step21DistributionMode(
            initialMode: _distributionMode,
            initialWorkoutDays: _workoutDays,
            onNext: (mode, days) {
              _distributionMode = mode;
              _workoutDays = days;
              _nextStep();
            },
          ),
          // Step 22: Protein Preference
          Step22ProteinPreference(
            currentWeightKg: _currentWeightKg,
            initialPreference: _proteinPref,
            onNext: (pref) {
              _proteinPref = pref;
              _nextStep();
            },
          ),
          // Step 23: Medical Disclaimer
          Step23MedicalDisclaimer(
            onNext: _buildAndActivateProgram,
          ),
          // Step 24: Program Ready Screen
          Step24ProgramReady(
            program: _ensureProgram(),
            onCompleted: () {
              final db = ref.read(databaseProvider);
              db.setSetting('onboarding_completed', 'true');
              db.setSetting('onboarding_step', '0');
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const ScaffoldWithNavBar()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
