import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/data/local/app_database_coaching.dart';
import 'package:sique/domain/algorithms/coaching_engine.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/app_providers.dart';

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
  void regenerateFromProfile(UserProfile profile) {
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
    );
    updateProgram(updatedProgram);
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
    );

    db.insertCoachingCheckIn(checkIn);
    // Defer check-in by updating lastCheckInDate to today
    final updated = state.copyWith(lastCheckInDate: DateTime.now());
    updateProgram(updated);
    _ref.invalidate(coachingCheckInHistoryProvider);
  }
}

/// Provider for active 7-day WeeklyMacroProgram.
final weeklyMacroProgramProvider =
    StateNotifierProvider<WeeklyMacroProgramNotifier, WeeklyMacroProgram>(
        (ref) {
  return WeeklyMacroProgramNotifier(ref);
});

/// Evaluates whether a weekly metabolic check-in is due and recommends adjustments.
final coachingCheckInStatusProvider = Provider<CheckInRecommendation>((ref) {
  final program = ref.watch(weeklyMacroProgramProvider);
  final profile = ref.watch(userProfileProvider);
  final expenditure = ref.watch(expenditureStateProvider);

  return CoachingEngine.evaluateWeeklyCheckIn(
    currentProgram: program,
    profile: profile,
    currentExpenditureKcal: expenditure.expenditureKcal,
    currentDate: DateTime.now(),
  );
});

/// List of historical coaching check-in entries from SQLite.
final coachingCheckInHistoryProvider = Provider<List<CoachingCheckIn>>((ref) {
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
  } on FormatException catch (_) {
    return program.days.first.toMacroTarget();
  }
});
