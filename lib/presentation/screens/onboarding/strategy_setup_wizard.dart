import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/algorithms/coaching_engine.dart';
import '../../../domain/models/macro_program.dart';
import '../../../domain/models/user_profile.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_tactile_card.dart';
import '../../widgets/onboarding/wizard_input_tiles.dart';
import '../../widgets/onboarding/wizard_preview_step.dart';
import 'auth_gate_screen.dart';

/// Interactive Strategy Setup Questionnaire Wizard configuring the user's 7-day program.
class StrategySetupWizard extends ConsumerStatefulWidget {
  const StrategySetupWizard({super.key});

  @override
  ConsumerState<StrategySetupWizard> createState() =>
      _StrategySetupWizardState();
}

class _StrategySetupWizardState extends ConsumerState<StrategySetupWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 6;

  // Step 0: Body Metrics
  double _currentWeightKg = 75.0;
  double _heightCm = 175.0;
  int _age = 28;
  bool _isMale = true;

  // Step 1: Goal & Rate
  GoalType _goalType = GoalType.fatLoss;
  double _targetRatePct = -0.5;

  // Step 2: Coaching Mode
  ProgramMode _programMode = ProgramMode.coached;

  // Step 3: Macro Program Style & Dietary Preferences
  MacroProgramStyle _programStyle = MacroProgramStyle.balanced;
  ProteinPreference _proteinPref = ProteinPreference.high;
  String _dietaryPref = 'pure_veg';

  // Step 4: Day Allocation & Workout Days
  DayAllocationType _allocationType = DayAllocationType.shiftedWorkout;
  final Set<int> _workoutDays = {1, 3, 5}; // Mon, Wed, Fri

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _currentWeightKg = profile.currentWeightKg;
    _heightCm = profile.heightCm;
    _age = profile.age;
    _isMale = profile.isMale;
    _goalType = profile.goalType;
    _targetRatePct = profile.weeklyRateOfChangePct;
    _programMode = profile.programMode;
    _proteinPref = profile.proteinPreference;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finalizeStrategy();
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  double _calculateBaselineTDEE() {
    // Mifflin-St Jeor formula + 1.35x activity multiplier
    final bmr = (10.0 * _currentWeightKg) +
        (6.25 * _heightCm) -
        (5.0 * _age) +
        (_isMale ? 5.0 : -161.0);
    return (bmr * 1.35).roundToDouble();
  }

  WeeklyMacroProgram _computePreviewProgram() {
    final tdee = _calculateBaselineTDEE();
    final targetWeight = _goalType == GoalType.fatLoss
        ? (_currentWeightKg * 0.92).roundToDouble()
        : _goalType == GoalType.muscleGain
            ? (_currentWeightKg * 1.08).roundToDouble()
            : _currentWeightKg;

    final tempProfile = UserProfile(
      id: 'usr_me',
      name: 'Athlete',
      currentWeightKg: _currentWeightKg,
      targetWeightKg: targetWeight,
      heightCm: _heightCm,
      age: _age,
      isMale: _isMale,
      goalType: _goalType,
      programMode: _programMode,
      weeklyRateOfChangePct: _targetRatePct,
      proteinPreference: _proteinPref,
      calorieFloor: 1200.0,
      baselineExpenditureKcal: tdee,
    );

    return CoachingEngine.buildWeeklyProgram(
      profile: tempProfile,
      expenditureKcal: tdee,
      style: _programStyle,
      allocationType: _allocationType,
      workoutDays: _workoutDays,
    );
  }

  void _finalizeStrategy() {
    final tdee = _calculateBaselineTDEE();
    final targetWeight = _goalType == GoalType.fatLoss
        ? (_currentWeightKg * 0.92).roundToDouble()
        : _goalType == GoalType.muscleGain
            ? (_currentWeightKg * 1.08).roundToDouble()
            : _currentWeightKg;

    final finalProfile = UserProfile(
      id: 'usr_me',
      name: 'Athlete',
      currentWeightKg: _currentWeightKg,
      targetWeightKg: targetWeight,
      heightCm: _heightCm,
      age: _age,
      isMale: _isMale,
      goalType: _goalType,
      programMode: _programMode,
      weeklyRateOfChangePct: _targetRatePct,
      proteinPreference: _proteinPref,
      calorieFloor: 1200.0,
      baselineExpenditureKcal: tdee,
    );

    final finalProgram = CoachingEngine.buildWeeklyProgram(
      profile: finalProfile,
      expenditureKcal: tdee,
      style: _programStyle,
      allocationType: _allocationType,
      workoutDays: _workoutDays,
    );

    // Persist to Riverpod & SQLite
    ref.read(userProfileProvider.notifier).updateProfile(finalProfile);
    ref.read(weeklyMacroProgramProvider.notifier).updateProgram(finalProgram);

    final db = ref.read(databaseProvider);
    db.setSetting('dietary_preference', _dietaryPref);

    // Navigate to Auth Gate
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AuthGateScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: _previousPage,
        ),
        title: Text(
          'Step ${_currentStep + 1} of $_totalSteps',
          style: const TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: AppTheme.cardBorder,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.calories),
              minHeight: 3,
            ),
            const SizedBox(height: 8),

            // Questionnaire PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentStep = idx),
                children: [
                  _buildStep0BodyMetrics(),
                  _buildStep1GoalAndRate(),
                  _buildStep2CoachingMode(),
                  _buildStep3MacroStyle(),
                  _buildStep4DayShifting(),
                  _buildStep5ProgramPreview(),
                ],
              ),
            ),

            // Navigation Bottom CTA Bar
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                bottomPadding > 0 ? bottomPadding : 16,
              ),
              child: AppleTactileCard(
                onTap: _nextPage,
                backgroundColor: AppTheme.calories,
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentStep == _totalSteps - 1
                          ? 'Confirm Strategy & Continue'
                          : 'Continue',
                      style: const TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 0: Body Metrics ---
  Widget _buildStep0BodyMetrics() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Tell us about yourself',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Used to compute your initial metabolic expenditure baseline.',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 28),

        // Sex Selector
        Row(
          children: [
            Expanded(
              child: WizardChoiceChip(
                label: 'Male',
                icon: Icons.male_rounded,
                selected: _isMale,
                onTap: () => setState(() => _isMale = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: WizardChoiceChip(
                label: 'Female',
                icon: Icons.female_rounded,
                selected: !_isMale,
                onTap: () => setState(() => _isMale = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Weight Slider
        WizardSliderTile(
          title: 'Current Weight',
          valueText: '${_currentWeightKg.toStringAsFixed(1)} kg',
          value: _currentWeightKg,
          min: 40.0,
          max: 160.0,
          onChanged: (v) => setState(() => _currentWeightKg = v),
        ),
        const SizedBox(height: 20),

        // Height Slider
        WizardSliderTile(
          title: 'Height',
          valueText: '${_heightCm.toStringAsFixed(0)} cm',
          value: _heightCm,
          min: 130.0,
          max: 220.0,
          onChanged: (v) => setState(() => _heightCm = v),
        ),
        const SizedBox(height: 20),

        // Age Slider
        WizardSliderTile(
          title: 'Age',
          valueText: '$_age yrs',
          value: _age.toDouble(),
          min: 16.0,
          max: 80.0,
          onChanged: (v) => setState(() => _age = v.toInt()),
        ),
      ],
    );
  }

  // --- Step 1: Goal & Rate ---
  Widget _buildStep1GoalAndRate() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'What is your primary goal?',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'MacroFactor recommends an adherence-neutral pacing strategy.',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        WizardSelectionCard(
          title: 'Fat Loss',
          subtitle: 'Sustainable deficit protecting lean muscle tissue.',
          icon: Icons.local_fire_department_rounded,
          accentColor: AppTheme.calories,
          selected: _goalType == GoalType.fatLoss,
          onTap: () => setState(() {
            _goalType = GoalType.fatLoss;
            _targetRatePct = -0.5;
          }),
        ),
        const SizedBox(height: 12),
        WizardSelectionCard(
          title: 'Maintenance',
          subtitle:
              'Eat at your true dynamic expenditure without weight change.',
          icon: Icons.balance_rounded,
          accentColor: AppTheme.expenditure,
          selected: _goalType == GoalType.maintenance,
          onTap: () => setState(() {
            _goalType = GoalType.maintenance;
            _targetRatePct = 0.0;
          }),
        ),
        const SizedBox(height: 12),
        WizardSelectionCard(
          title: 'Muscle Gain',
          subtitle: 'Lean mass accrual with controlled energetic surplus.',
          icon: Icons.fitness_center_rounded,
          accentColor: AppTheme.carbs,
          selected: _goalType == GoalType.muscleGain,
          onTap: () => setState(() {
            _goalType = GoalType.muscleGain;
            _targetRatePct = 0.25;
          }),
        ),
        const SizedBox(height: 28),
        if (_goalType != GoalType.maintenance) ...[
          WizardSliderTile(
            title: 'Target Weekly Rate',
            valueText: '${_targetRatePct.abs().toStringAsFixed(2)}% / week',
            value: _targetRatePct.abs(),
            min: 0.1,
            max: 1.0,
            onChanged: (v) => setState(() {
              _targetRatePct = _goalType == GoalType.fatLoss ? -v : v;
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _targetRatePct.abs() <= 0.6
                ? '✓ Optimal Recommended Zone (Muscle Sparing)'
                : '⚠ Aggressive Pacing (Higher metabolic adaptation)',
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _targetRatePct.abs() <= 0.6
                  ? AppTheme.expenditure
                  : AppTheme.fat,
            ),
          ),
        ],
      ],
    );
  }

  // --- Step 2: Coaching Philosophy ---
  Widget _buildStep2CoachingMode() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Choose your coaching mode',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'How much algorithmic automation do you want in your weekly check-ins?',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        WizardSelectionCard(
          title: 'Coached (Recommended)',
          subtitle:
              'Full algorithmic guidance. Calories & macros automatically adjust weekly based on your Bayesian metabolic expenditure.',
          icon: Icons.auto_awesome_rounded,
          accentColor: AppTheme.calories,
          selected: _programMode == ProgramMode.coached,
          onTap: () => setState(() => _programMode = ProgramMode.coached),
        ),
        const SizedBox(height: 12),
        WizardSelectionCard(
          title: 'Collaborative',
          subtitle:
              'The algorithm recommends calorie adjustments, but you choose macro split and day-to-day distributions.',
          icon: Icons.handshake_outlined,
          accentColor: AppTheme.carbs,
          selected: _programMode == ProgramMode.collaborative,
          onTap: () => setState(() => _programMode = ProgramMode.collaborative),
        ),
        const SizedBox(height: 12),
        WizardSelectionCard(
          title: 'Manual',
          subtitle:
              'You set all calorie and macro targets manually. The Bayesian expenditure engine continues tracking your burn in the background.',
          icon: Icons.edit_note_rounded,
          accentColor: AppTheme.textSecondary,
          selected: _programMode == ProgramMode.manual,
          onTap: () => setState(() => _programMode = ProgramMode.manual),
        ),
      ],
    );
  }

  // --- Step 3: Macro Distribution Style & Diet ---
  Widget _buildStep3MacroStyle() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Macro Program Style',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select how your non-protein calories are divided between carbs and fats.',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        for (final style in MacroProgramStyle.values) ...[
          WizardSelectionCard(
            title: style.displayName,
            subtitle: style.description,
            icon: Icons.pie_chart_outline_rounded,
            accentColor: AppTheme.calories,
            selected: _programStyle == style,
            onTap: () => setState(() => _programStyle = style),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 20),
        const Text(
          'Dietary Habit (Indian Nutrition)',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            WizardSmallChoiceChip(
              label: 'Pure Vegetarian',
              selected: _dietaryPref == 'pure_veg',
              onTap: () => setState(() => _dietaryPref = 'pure_veg'),
            ),
            WizardSmallChoiceChip(
              label: 'Eggetarian',
              selected: _dietaryPref == 'eggetarian',
              onTap: () => setState(() => _dietaryPref = 'eggetarian'),
            ),
            WizardSmallChoiceChip(
              label: 'Non-Vegetarian',
              selected: _dietaryPref == 'non_veg',
              onTap: () => setState(() => _dietaryPref = 'non_veg'),
            ),
          ],
        ),
      ],
    );
  }

  // --- Step 4: Day Calorie Shifting & Workout Schedule ---
  Widget _buildStep4DayShifting() {
    const daysOfWeek = [
      {'id': 1, 'name': 'Mon'},
      {'id': 2, 'name': 'Tue'},
      {'id': 3, 'name': 'Wed'},
      {'id': 4, 'name': 'Thu'},
      {'id': 5, 'name': 'Fri'},
      {'id': 6, 'name': 'Sat'},
      {'id': 7, 'name': 'Sun'},
    ];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Day Calorie Shifting',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Allocate higher energy to workout or weekend days without changing your weekly calorie total.',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        for (final alloc in DayAllocationType.values) ...[
          WizardSelectionCard(
            title: alloc.displayName,
            subtitle: alloc.description,
            icon: Icons.calendar_today_rounded,
            accentColor: AppTheme.carbs,
            selected: _allocationType == alloc,
            onTap: () => setState(() => _allocationType = alloc),
          ),
          const SizedBox(height: 10),
        ],
        if (_allocationType == DayAllocationType.shiftedWorkout) ...[
          const SizedBox(height: 20),
          const Text(
            'Select Workout Days (Energy Surplus)',
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: daysOfWeek.map((day) {
              final id = day['id'] as int;
              final isWorkout = _workoutDays.contains(id);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isWorkout) {
                      if (_workoutDays.length > 1) _workoutDays.remove(id);
                    } else {
                      _workoutDays.add(id);
                    }
                  });
                },
                child: Container(
                  width: 42,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isWorkout ? AppTheme.calories : AppTheme.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isWorkout ? AppTheme.calories : AppTheme.cardBorder,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    day['name'] as String,
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isWorkout ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // --- Step 5: Program Preview & Confirmation ---
  Widget _buildStep5ProgramPreview() {
    return WizardPreviewStep(
      previewProgram: _computePreviewProgram(),
      tdee: _calculateBaselineTDEE(),
      programStyle: _programStyle,
      programMode: _programMode,
      dietaryPref: _dietaryPref,
    );
  }
}
