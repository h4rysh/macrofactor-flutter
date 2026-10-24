import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/data/local/app_database_coaching.dart';
import 'package:sique/domain/algorithms/coaching_engine.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';

import 'steps/step_01_welcome.dart';
import 'steps/step_02_name.dart';
import 'steps/step_03_sex.dart';
import 'steps/step_04_age.dart';
import 'steps/step_05_height.dart';
import 'steps/step_06_weight.dart';
import 'steps/step_07_weight_history_max.dart';
import 'steps/step_08_target_weight.dart';
import 'steps/step_09_goal_type.dart';
import 'steps/step_10_pacing.dart';
import 'steps/step_11_lifting_experience.dart';
import 'steps/step_12_cardio_experience.dart';
import 'steps/step_13_body_fat.dart';
import 'steps/step_14_diet_type.dart';
import 'steps/step_15_distribution_mode.dart';
import 'steps/step_16_protein_preference.dart';
import 'steps/step_17_calorie_floor.dart';
import 'steps/step_18_program_style.dart';
import 'steps/step_19_summary_review.dart';
import 'steps/step_20_target_activation.dart';
import 'steps/step_21_auth_gate.dart';
import 'steps/step_22_health_connect.dart';
import 'steps/step_23_completion.dart';

/// Master 23-Step Onboarding Coordinator managing sequential progression,
/// animated progress bar, and SQLite auto-save.
class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 23;

  // Onboarding Working State
  String _name = 'Athlete';
  bool _isMale = true;
  int _age = 28;
  double _heightCm = 175.0;
  double _currentWeightKg = 75.0;
  double _weightHistoryMax = 80.0;
  double _targetWeightKg = 70.0;
  GoalType _goalType = GoalType.fatLoss;
  double _ratePct = -0.50;
  String _liftingExperience = 'beginner';
  String _cardioExperience = 'beginner';
  String _bodyFatRange = '15 – 19%';
  String _dietType = 'standard';
  String _distributionMode = 'even';
  Set<int> _workoutDays = {1, 3, 5};
  ProteinPreference _proteinPref = ProteinPreference.high;
  String _calorieFloorType = 'standard';
  MacroProgramStyle _programStyle = MacroProgramStyle.balanced;
  WeeklyMacroProgram? _generatedProgram;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _name = profile.name.isNotEmpty ? profile.name : 'Athlete';
    _isMale = profile.isMale;
    _age = profile.age;
    _heightCm = profile.heightCm;
    _currentWeightKg = profile.currentWeightKg;
    _weightHistoryMax = profile.weightHistoryMax ?? profile.currentWeightKg;
    _targetWeightKg = profile.targetWeightKg;
    _goalType = profile.goalType;
    _ratePct = profile.weeklyRateOfChangePct;
    _liftingExperience = profile.liftingExperience;
    _cardioExperience = profile.cardioExperience;
    _bodyFatRange = profile.bodyFatRange ?? (_isMale ? '15 – 19%' : '22 – 26%');
    _dietType = profile.dietType;
    _distributionMode = profile.distributionMode;
    _proteinPref = profile.proteinPreference;
    _calorieFloorType = profile.calorieFloorType;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step >= 0 && step < _totalSteps) {
      setState(() => _currentStep = step);
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
    final bmr = (10.0 * _currentWeightKg) +
        (6.25 * _heightCm) -
        (5.0 * _age) +
        (_isMale ? 5.0 : -161.0);
    return (bmr * 1.35).roundToDouble();
  }

  void _persistCurrentProfile() {
    final floorCalories = _isMale ? 1500.0 : 1200.0;
    final updatedProfile = UserProfile(
      id: 'active_user',
      name: _name,
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
    );

    ref.read(userProfileProvider.notifier).updateProfile(updatedProfile);
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppTheme.textPrimary),
          onPressed: _previousStep,
        ),
        title: Text(
          'Step ${_currentStep + 1} of $_totalSteps',
          style: const TextStyle(
            fontFamily: 'MacroSans',
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
        onPageChanged: (idx) => setState(() => _currentStep = idx),
        children: [
          // Step 1: Welcome
          Step01Welcome(onNext: _nextStep),
          // Step 2: Name
          Step02Name(
            initialName: _name,
            onNext: (name) {
              _name = name;
              _nextStep();
            },
          ),
          // Step 3: Sex
          Step03Sex(
            initialIsMale: _isMale,
            onNext: (isMale) {
              _isMale = isMale;
              _nextStep();
            },
          ),
          // Step 4: Age (Guardrail >= 18)
          Step04Age(
            initialAge: _age,
            onNext: (age) {
              _age = age;
              _nextStep();
            },
          ),
          // Step 5: Height
          Step05Height(
            initialHeightCm: _heightCm,
            onNext: (h) {
              _heightCm = h;
              _nextStep();
            },
          ),
          // Step 6: Current Weight
          Step06Weight(
            initialWeightKg: _currentWeightKg,
            onNext: (w) {
              _currentWeightKg = w;
              _nextStep();
            },
          ),
          // Step 7: Weight History Max
          Step07WeightHistoryMax(
            currentWeightKg: _currentWeightKg,
            initialMaxWeightKg: _weightHistoryMax,
            onNext: (maxW) {
              _weightHistoryMax = maxW;
              _nextStep();
            },
          ),
          // Step 8: Target Weight
          Step08TargetWeight(
            initialTargetWeightKg: _targetWeightKg,
            onNext: (targetW) {
              _targetWeightKg = targetW;
              _nextStep();
            },
          ),
          // Step 9: Goal Type
          Step09GoalType(
            initialGoalType: _goalType,
            onNext: (g) {
              _goalType = g;
              _nextStep();
            },
          ),
          // Step 10: Pacing (Guardrail BMI >= 18.5)
          Step10Pacing(
            goalType: _goalType,
            currentWeightKg: _currentWeightKg,
            heightCm: _heightCm,
            initialRatePct: _ratePct,
            onNext: (rate) {
              _ratePct = rate;
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
          // Step 13: Body Fat Estimate
          Step13BodyFat(
            initialBodyFatRange: _bodyFatRange,
            isMale: _isMale,
            onNext: (range) {
              _bodyFatRange = range;
              _nextStep();
            },
          ),
          // Step 14: Diet Type
          Step14DietType(
            initialDietType: _dietType,
            onNext: (diet) {
              _dietType = diet;
              _nextStep();
            },
          ),
          // Step 15: Distribution Mode
          Step15DistributionMode(
            initialMode: _distributionMode,
            initialWorkoutDays: _workoutDays,
            onNext: (mode, days) {
              _distributionMode = mode;
              _workoutDays = days;
              _nextStep();
            },
          ),
          // Step 16: Protein Preference
          Step16ProteinPreference(
            currentWeightKg: _currentWeightKg,
            initialPreference: _proteinPref,
            onNext: (pref) {
              _proteinPref = pref;
              _nextStep();
            },
          ),
          // Step 17: Calorie Floor
          Step17CalorieFloor(
            isMale: _isMale,
            initialFloorType: _calorieFloorType,
            onNext: (floor) {
              _calorieFloorType = floor;
              _nextStep();
            },
          ),
          // Step 18: Program Style
          Step18ProgramStyle(
            initialStyle: _programStyle,
            onNext: (style) {
              _programStyle = style;
              _nextStep();
            },
          ),
          // Step 19: Summary Review
          Step19SummaryReview(
            name: _name,
            isMale: _isMale,
            age: _age,
            heightCm: _heightCm,
            currentWeightKg: _currentWeightKg,
            targetWeightKg: _targetWeightKg,
            goalType: _goalType,
            ratePct: _ratePct,
            proteinPref: _proteinPref,
            distributionMode: _distributionMode,
            dietType: _dietType,
            programStyle: _programStyle,
            onNext: _buildAndActivateProgram,
          ),
          // Step 20: Target Activation
          if (_generatedProgram != null)
            Step20TargetActivation(
              program: _generatedProgram!,
              onActivate: _nextStep,
            )
          else
            const Center(child: CircularProgressIndicator()),
          // Step 21: Auth Gate
          Step21AuthGate(onNext: _nextStep),
          // Step 22: Health Connect Sync
          Step22HealthConnect(onNext: _nextStep),
          // Step 23: Completion
          const Step23Completion(),
        ],
      ),
    );
  }
}
