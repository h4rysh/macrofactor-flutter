import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/data/local/app_database_coaching.dart';
import 'package:sique/domain/algorithms/coaching_engine.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/app_providers.dart';

export 'lifestyle_providers.dart';

/// Notifier managing active 7-day WeeklyMacroProgram and persistence.
class WeeklyMacroProgramNotifier extends StateNotifier<WeeklyMacroProgram> {
  WeeklyMacroProgramNotifier(this._ref) : super(_loadInitial(_ref));

  final Ref _ref;

  static WeeklyMacroProgram _loadInitial(Ref ref) {
    final db = ref.read(databaseProvider);
    final saved = db.getCoachingProgram();
    if (saved != null) return saved;

    final profile = ref.read(userProfileProvider);
    final expenditure = ref.read(expenditureStateProvider);

    final defaultProgram = CoachingEngine.buildWeeklyProgram(
      profile: profile,
      expenditureKcal: expenditure.expenditureKcal,
      style: MacroProgramStyle.balanced,
      allocationType: DayAllocationType.shiftedWorkout,
      workoutDays: const {1, 3, 5}, // Mon, Wed, Fri
    );

    db.saveCoachingProgram(defaultProgram);
    return defaultProgram;
  }

  void updateProgram(WeeklyMacroProgram newProgram) {
    final db = _ref.read(databaseProvider);
    db.saveCoachingProgram(newProgram);
    state = newProgram;
  }

  /// Immediately regenerates and persists weekly program when driving profile attributes change.
  void regenerateFromProfile(
    UserProfile profile, {
    bool applyReverseRamp = false,
  }) {
    final expenditure = _ref.read(expenditureStateProvider);
    final currentProgram = state;
    final updatedProgram = CoachingEngine.buildWeeklyProgram(
      profile: profile,
      expenditureKcal: expenditure.expenditureKcal,
      style: currentProgram.style,
      allocationType: currentProgram.allocationType,
      workoutDays: currentProgram.workoutDays,
      checkInDayOfWeek: currentProgram.checkInDayOfWeek,
      lastCheckInDate: currentProgram.lastCheckInDate,
      programStartDate: currentProgram.createdAt,
      carbShareOverride: profile.programMode == ProgramMode.collaborative
          ? currentProgram.carbShareOverride
          : null,
      previousAvgCalories: currentProgram.dailyAverageCalories,
      applyReverseRamp: applyReverseRamp,
    );
    updateProgram(updatedProgram);
  }

  /// Rebuilds the active weekly program with custom Collaborative carb-to-fat ratio & day allocation.
  void applyCollaborativeCustomization({
    required double carbSharePct,
    required DayAllocationType allocationType,
    required Set<int> workoutDays,
  }) {
    final profile = _ref.read(userProfileProvider);
    if (profile.programMode != ProgramMode.collaborative) {
      _ref.read(userProfileProvider.notifier).updateProfile(
            profile.copyWith(programMode: ProgramMode.collaborative),
          );
    }
    final latestProfile = _ref.read(userProfileProvider);
    final expenditure = _ref.read(expenditureStateProvider);
    final updated = CoachingEngine.buildWeeklyProgram(
      profile: latestProfile.copyWith(programMode: ProgramMode.collaborative),
      expenditureKcal: expenditure.expenditureKcal,
      style: state.style,
      allocationType: allocationType,
      workoutDays: workoutDays,
      checkInDayOfWeek: state.checkInDayOfWeek,
      lastCheckInDate: state.lastCheckInDate,
      programStartDate: state.createdAt,
      carbShareOverride: carbSharePct,
      previousAvgCalories: state.dailyAverageCalories,
      applyReverseRamp: false,
    );
    updateProgram(updated);
  }

  /// Locks exact Manual custom targets onto the profile & weekly schedule.
  void applyManualTargets({
    required double calories,
    required double proteinGrams,
    required double carbsGrams,
    required double fatGrams,
  }) {
    final profile = _ref.read(userProfileProvider).copyWith(
          programMode: ProgramMode.manual,
          customCalories: calories,
          customProteinGrams: proteinGrams,
          customCarbsGrams: carbsGrams,
          customFatGrams: fatGrams,
        );
    _ref.read(userProfileProvider.notifier).updateProfile(profile);
  }

  void applyCheckIn(CheckInRecommendation recommendation) {
    final db = _ref.read(databaseProvider);
    final checkIn = CoachingCheckIn(
      id: 'chk_${DateTime.now().millisecondsSinceEpoch}',
      checkInDate: DateTime.now(),
      previousCalories: recommendation.previousAverageCalories,
      recommendedCalories: recommendation.recommendedAverageCalories,
      expenditureKcal: recommendation.currentExpenditureKcal,
      weightTrendKg: _ref.read(latestTrendWeightProvider)?.trendWeightKg ??
          _ref.read(userProfileProvider).currentWeightKg,
      isAccepted: true,
      statusNote: recommendation.metabolicInsight,
      createdAt: DateTime.now(),
      rawCalorieDelta: recommendation.rawCalorieDelta,
      dampedCalorieDelta: recommendation.dampedCalorieDelta,
      wasClamped: recommendation.wasClamped,
      silentRecompDetected: recommendation.silentRecompDetected,
    );

    db.insertCoachingCheckIn(checkIn);
    updateProgram(recommendation.suggestedProgram);
    _ref.invalidate(coachingCheckInHistoryProvider);
  }

  void declineCheckIn(CheckInRecommendation recommendation) {
    final db = _ref.read(databaseProvider);
    final checkIn = CoachingCheckIn(
      id: 'chk_${DateTime.now().millisecondsSinceEpoch}',
      checkInDate: DateTime.now(),
      previousCalories: recommendation.previousAverageCalories,
      recommendedCalories: recommendation.recommendedAverageCalories,
      expenditureKcal: recommendation.currentExpenditureKcal,
      weightTrendKg: _ref.read(latestTrendWeightProvider)?.trendWeightKg ??
          _ref.read(userProfileProvider).currentWeightKg,
      isAccepted: false,
      statusNote: 'Program retained without changes.',
      createdAt: DateTime.now(),
      rawCalorieDelta: recommendation.rawCalorieDelta,
      dampedCalorieDelta: recommendation.dampedCalorieDelta,
      wasClamped: recommendation.wasClamped,
      silentRecompDetected: recommendation.silentRecompDetected,
    );

    db.insertCoachingCheckIn(checkIn);
    // Defer check-in by updating lastCheckInDate to today
    final updated = state.copyWith(lastCheckInDate: DateTime.now());
    updateProgram(updated);
    _ref.invalidate(coachingCheckInHistoryProvider);
  }

  /// Rebalances the remaining days of the current week around actual logged intake.
  void applyMidWeekRebalance({
    required double consumedCaloriesSoFar,
    required int completedDaysCount,
  }) {
    final profile = _ref.read(userProfileProvider);
    final rebalanced = CoachingEngine.rebalanceRemainingWeek(
      currentProgram: state,
      profile: profile,
      consumedCaloriesSoFar: consumedCaloriesSoFar,
      completedDaysCount: completedDaysCount,
    );
    updateProgram(rebalanced);
  }
}

/// Provider for active 7-day WeeklyMacroProgram.
final weeklyMacroProgramProvider =
    StateNotifierProvider<WeeklyMacroProgramNotifier, WeeklyMacroProgram>(
        (ref) {
  ref.watch(userDataEpochProvider);
  return WeeklyMacroProgramNotifier(ref);
});

/// Evaluates whether a weekly metabolic check-in is due and recommends adjustments.
final coachingCheckInStatusProvider = Provider<CheckInRecommendation>((ref) {
  final program = ref.watch(weeklyMacroProgramProvider);
  final profile = ref.watch(userProfileProvider);
  final expenditure = ref.watch(expenditureStateProvider);
  final silentRecomp = ref.watch(recompositionStatusProvider);

  return CoachingEngine.evaluateWeeklyCheckIn(
    currentProgram: program,
    profile: profile,
    currentExpenditureKcal: expenditure.expenditureKcal,
    currentDate: DateTime.now(),
    kalmanConfidence: expenditure.confidence,
    silentRecompActive: silentRecomp,
  );
});

/// List of historical coaching check-in entries from SQLite.
final coachingCheckInHistoryProvider = Provider<List<CoachingCheckIn>>((ref) {
  ref.watch(userDataEpochProvider);
  final db = ref.watch(databaseProvider);
  return db.getCoachingCheckIns();
});

/// Day-specific macro target matching the date currently selected in the UI.
final dayMacroTargetForSelectedDateProvider = Provider<MacroTarget>((ref) {
  final program = ref.watch(weeklyMacroProgramProvider);
  final selectedDateStr = ref.watch(selectedDateProvider);

  try {
    final date = DateTime.parse(selectedDateStr);
    return program.targetForDate(date).toMacroTarget();
  } on FormatException catch (e, st) {
    developer.log(
      'Invalid selectedDateStr "$selectedDateStr", defaulting to day 1 target',
      name: 'StrategyProviders',
      error: e,
      stackTrace: st,
    );
    return program.days.first.toMacroTarget();
  }
});
