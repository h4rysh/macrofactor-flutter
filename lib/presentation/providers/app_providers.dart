import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/algorithms/anthropometric_service.dart';
import 'package:sique/domain/algorithms/expenditure_kalman_v4.dart';
import 'package:sique/domain/algorithms/expenditure_kalman_v5.dart';
import 'package:sique/domain/algorithms/weight_trend_v2.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/strategy_providers.dart';
import 'package:sique/presentation/providers/workout_providers.dart';

export 'auth_providers.dart';
export 'health_sync_providers.dart';
export 'logging_streak_provider.dart';
export 'strategy_providers.dart';
export 'workout_providers.dart';

/// Database singleton provider, overridden in main() or tests.
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
      'databaseProvider must be overridden in ProviderScope');
});

/// System clock provider, defaulting to real wall clock [DateTime.now].
/// Overridable in widget and golden tests to ensure deterministic time rendering.
final clockProvider = Provider<DateTime Function()>((ref) {
  return () => DateTime.now();
});

/// Currently selected date in the dashboard and food log (YYYY-MM-DD).
final selectedDateProvider = StateProvider<String>((ref) {
  final clock = ref.watch(clockProvider);
  return DateFormat('yyyy-MM-dd').format(clock());
});

/// Root reactive user session epoch provider incremented whenever active user
/// logs out, deletes account, or switches sessions, forcing all user data
/// stores to rebuild.
final userDataEpochProvider = StateProvider<int>((ref) => 0);

/// Global revision counter tracking food log additions, edits, and deletions.
final foodLogsRevisionProvider = StateProvider<int>((ref) => 0);

/// Manages day completion status and exposes toggle / set capabilities.
class DayCompletionsNotifier extends StateNotifier<Map<String, bool>> {
  DayCompletionsNotifier(this._db) : super({}) {
    refresh();
  }

  final AppDatabase _db;

  void refresh() {
    state = _db.getDayCompletions();
  }

  void toggleDayComplete(String date) {
    final current = isDayComplete(date);
    setDayComplete(date, !current);
  }

  void setDayComplete(String date, bool isComplete) {
    _db.setDayComplete(date, isComplete);
    state = {...state, date: isComplete};
  }

  bool isDayComplete(String date) {
    if (state.containsKey(date)) return state[date]!;
    return _db.isDayComplete(date);
  }
}

final dayCompletionsProvider =
    StateNotifierProvider<DayCompletionsNotifier, Map<String, bool>>((ref) {
  ref.watch(userDataEpochProvider);
  final db = ref.watch(databaseProvider);
  return DayCompletionsNotifier(db);
});

/// Default user profile when app is first installed.
const defaultUserProfile = UserProfile(
  id: 'usr_me',
  name: 'Athlete',
  currentWeightKg: 75.0,
  targetWeightKg: 70.0,
  heightCm: 175.0,
  age: 28,
  isMale: true,
  goalType: GoalType.fatLoss,
  programMode: ProgramMode.coached,
  weeklyRateOfChangePct: -0.5,
  proteinPreference: ProteinPreference.high,
  calorieFloor: 1400.0,
  baselineExpenditureKcal: 2350.0,
);

/// User profile notifier managing goal configuration and persistence.
class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier(this._db, [this._ref]) : super(_loadInitial(_db));

  final AppDatabase _db;
  final Ref? _ref;

  static UserProfile _loadInitial(AppDatabase db) {
    final existing = db.getUserProfile();
    if (existing != null) return existing;
    db.saveUserProfile(defaultUserProfile);
    return defaultUserProfile;
  }

  void updateProfile(UserProfile newProfile) {
    final oldProfile = state;
    _db.saveUserProfile(newProfile);
    state = newProfile;

    if (_ref != null &&
        (oldProfile.goalType != newProfile.goalType ||
            oldProfile.currentWeightKg != newProfile.currentWeightKg ||
            oldProfile.targetWeightKg != newProfile.targetWeightKg ||
            oldProfile.weeklyRateOfChangePct !=
                newProfile.weeklyRateOfChangePct ||
            oldProfile.proteinPreference != newProfile.proteinPreference ||
            oldProfile.programMode != newProfile.programMode ||
            oldProfile.isInDietBreak != newProfile.isInDietBreak ||
            oldProfile.reverseDietPacing != newProfile.reverseDietPacing ||
            oldProfile.calorieFloor != newProfile.calorieFloor ||
            oldProfile.customCalories != newProfile.customCalories ||
            oldProfile.customProteinGrams != newProfile.customProteinGrams ||
            oldProfile.customCarbsGrams != newProfile.customCarbsGrams ||
            oldProfile.customFatGrams != newProfile.customFatGrams)) {
      final enteredReverse =
          oldProfile.reverseDietPacing != newProfile.reverseDietPacing &&
              newProfile.reverseDietPacing != 'none';
      _ref.read(weeklyMacroProgramProvider.notifier).regenerateFromProfile(
            newProfile,
            applyReverseRamp: enteredReverse,
          );
    }
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  ref.watch(userDataEpochProvider);
  final db = ref.watch(databaseProvider);
  return UserProfileNotifier(db, ref);
});

/// Notifier managing daily logged meals.
class DailyFoodLogsNotifier extends StateNotifier<List<FoodLogEntry>> {
  DailyFoodLogsNotifier(this._db, this._date, [this._ref]) : super([]) {
    refresh();
  }

  final AppDatabase _db;
  final String _date;
  final Ref? _ref;

  void _notifyMutation() {
    if (_ref != null) {
      _ref.read(foodLogsRevisionProvider.notifier).state++;
    }
  }

  void refresh() {
    state = _db.getFoodLogsForDate(_date);
  }

  int addFood(FoodLogEntry entry) {
    final id = _db.insertFoodLog(entry);
    refresh();
    _notifyMutation();
    return id;
  }

  void deleteFood(int id) {
    _db.deleteFoodLog(id);
    refresh();
    _notifyMutation();
  }

  void removeEntry(int? id) {
    if (id != null) {
      deleteFood(id);
    }
  }

  int restoreEntry(FoodLogEntry entry) {
    final id = _db.restoreFoodLog(entry);
    refresh();
    _notifyMutation();
    return id;
  }

  /// Copies all food entries from [fromDate] ('yyyy-MM-dd') into the current date.
  /// Returns the number of copied entries.
  int copyFromDate(String fromDate) {
    final sourceLogs = _db.getFoodLogsForDate(fromDate);
    if (sourceLogs.isEmpty) return 0;

    final targetParts = _date.split('-');
    if (targetParts.length != 3) return 0;
    final targetYear = int.tryParse(targetParts[0]);
    final targetMonth = int.tryParse(targetParts[1]);
    final targetDay = int.tryParse(targetParts[2]);
    if (targetYear == null || targetMonth == null || targetDay == null) {
      return 0;
    }

    for (final src in sourceLogs) {
      final newLoggedAt = DateTime(
        targetYear,
        targetMonth,
        targetDay,
        src.loggedAt.hour,
        src.loggedAt.minute,
        src.loggedAt.second,
      );
      final newEntry = src.copyWith(
        id: 0,
        date: _date,
        loggedAt: newLoggedAt,
      );
      _db.insertFoodLog(newEntry);
    }
    refresh();
    _notifyMutation();
    return sourceLogs.length;
  }

  int addEntry({
    required FoodItem food,
    required PortionUnit portionUnit,
    required double quantity,
    required MealType mealType,
    required OilModifier oilModifier,
    required DateTime loggedAt,
    double? oilGrams,
  }) {
    final nutrition = food.calculateNutrition(
      quantity: quantity,
      unit: portionUnit,
      oilModifier: oilModifier,
      oilGrams: oilGrams,
    );

    final entry = FoodLogEntry(
      id: 0,
      date: DateFormat('yyyy-MM-dd').format(loggedAt),
      mealType: mealType,
      foodId: food.id,
      foodName: food.name,
      servingQuantity: quantity,
      unitName: portionUnit.unitName,
      gramWeight: nutrition.totalGrams,
      calories: nutrition.calories,
      protein: nutrition.protein,
      carbs: nutrition.carbs,
      fat: nutrition.fat,
      fiber: nutrition.fiber,
      oilModifier: oilModifier,
      loggedAt: loggedAt,
      iconSvg: food.category,
    );
    return addFood(entry);
  }

  /// Batch-inserts multiple pre-built entries atomically so downstream Kalman
  /// and challenge providers recompute once instead of N times.
  void addEntries(List<FoodLogEntry> entries) {
    if (entries.isEmpty) return;
    _db.rawDb.execute('BEGIN TRANSACTION;');
    try {
      for (final entry in entries) {
        _db.insertFoodLog(entry);
      }
      _db.rawDb.execute('COMMIT;');
    } catch (_) {
      try {
        _db.rawDb.execute('ROLLBACK;');
      } catch (_) {}
      rethrow;
    }
    refresh();
    _notifyMutation();
  }
}

final dailyFoodLogsProvider =
    StateNotifierProvider<DailyFoodLogsNotifier, List<FoodLogEntry>>((ref) {
  ref.watch(userDataEpochProvider);
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  return DailyFoodLogsNotifier(db, date, ref);
});

/// Aggregate total calories and macronutrients consumed for selected date.
final dailyNutritionSummaryProvider = Provider<NutritionalValues>((ref) {
  final logs = ref.watch(dailyFoodLogsProvider);

  double totalCalories = 0.0;
  double totalProtein = 0.0;
  double totalCarbs = 0.0;
  double totalFat = 0.0;
  double totalFiber = 0.0;
  double totalGrams = 0.0;

  for (final entry in logs) {
    totalCalories += entry.calories;
    totalProtein += entry.protein;
    totalCarbs += entry.carbs;
    totalFat += entry.fat;
    totalFiber += entry.fiber;
    totalGrams += entry.gramWeight;
  }

  return NutritionalValues(
    calories: totalCalories,
    protein: totalProtein,
    carbs: totalCarbs,
    fat: totalFat,
    fiber: totalFiber,
    totalGrams: totalGrams,
  );
});

/// Notifier for scale weight observations.
class WeightLogsNotifier extends StateNotifier<List<ScaleWeightEntry>> {
  WeightLogsNotifier(this._db, [this._ref]) : super([]) {
    refresh();
  }

  final AppDatabase _db;
  final Ref? _ref;

  void refresh() {
    state = _db.getAllWeightLogs();
  }

  void logWeight(String date, double weightKg, String? note) {
    _db.insertWeightLog(date, weightKg, note);
    refresh();
    _ref?.invalidate(userProfileProvider);
  }

  void deleteWeight(String date) {
    _db.deleteWeightLogForDate(date);
    refresh();
    _ref?.invalidate(userProfileProvider);
  }
}

final weightLogsProvider =
    StateNotifierProvider<WeightLogsNotifier, List<ScaleWeightEntry>>((ref) {
  ref.watch(userDataEpochProvider);
  final db = ref.watch(databaseProvider);
  return WeightLogsNotifier(db, ref);
});

/// Smoothed bidirectional Weight Trend series with noise envelopes.
final weightTrendSeriesProvider = Provider<List<WeightTrendPoint>>((ref) {
  final weights = ref.watch(weightLogsProvider);
  if (weights.isEmpty) return const [];
  return WeightTrendV2Series.compute(entries: weights, bidirectional: true)
      .points;
});

/// Latest smoothed trend weight value.
final latestTrendWeightProvider = Provider<WeightTrendPoint?>((ref) {
  final series = ref.watch(weightTrendSeriesProvider);
  if (series.isEmpty) return null;
  return series.last;
});

/// Dynamic Joint Kalman Filter (V4) Expenditure Tracker.
final expenditureStateProvider = Provider<ExpenditureState>((ref) {
  ref.watch(userDataEpochProvider);
  final profile = ref.watch(userProfileProvider);
  final weights = ref.watch(weightLogsProvider);
  final db = ref.watch(databaseProvider);
  ref.watch(foodLogsRevisionProvider);
  ref.watch(workoutSessionsProvider);
  final dayCompletions = ref.watch(dayCompletionsProvider);

  final baselineKcal = profile.baselineExpenditureKcal > 0
      ? profile.baselineExpenditureKcal
      : 2000.0;

  final clock = ref.watch(clockProvider);
  final now = clock();
  final todayDate = DateTime(now.year, now.month, now.day);

  // If no weights logged at all, return uninitialized baseline state
  if (weights.isEmpty) {
    return ExpenditureState(
      date: todayDate,
      expenditureKcal: baselineKcal,
      trendWeightKg:
          profile.currentWeightKg > 0 ? profile.currentWeightKg : 70.0,
      variance: 300.0 * 300.0,
      weightVariance: 0.5 * 0.5,
      crossCovariance: 0.0,
      confidence: 0.0,
      isPaused: true,
      unloggedDaysInWindow: 7,
      isDayComplete: false,
    );
  }

  // 1. Single O(1) batch retrieval of historical calorie totals
  final dailyCalories = db.getDailyCalorieTotals();

  // 2. Map weights by 'YYYY-MM-DD'
  final weightsByDate = <String, double>{};
  for (final w in weights) {
    final dStr = DateFormat('yyyy-MM-dd').format(w.date);
    weightsByDate[dStr] = w.weightKg;
  }

  // 3. Determine earliest and latest observation dates across food logs and weights
  DateTime earliestDate = DateTime(
    weights.first.date.year,
    weights.first.date.month,
    weights.first.date.day,
  );
  DateTime latestObsDate = earliestDate;

  for (final w in weights) {
    final d = DateTime(w.date.year, w.date.month, w.date.day);
    if (d.isBefore(earliestDate)) earliestDate = d;
    if (d.isAfter(latestObsDate)) latestObsDate = d;
  }

  for (final dStr in dailyCalories.keys) {
    try {
      final d = DateTime.parse(dStr);
      final truncated = DateTime(d.year, d.month, d.day);
      if (truncated.isBefore(earliestDate)) earliestDate = truncated;
      if (truncated.isAfter(latestObsDate)) latestObsDate = truncated;
    } on FormatException catch (e, st) {
      developer.log(
        'Invalid date key encountered in dailyCalories: "$dStr"',
        name: 'AppProviders',
        error: e,
        stackTrace: st,
      );
    }
  }

  // 4. Instantiate Multi-Modal 2D Joint-State Kalman Filter V5
  final isNotSureTrend =
      profile.recentWeightTrend.toLowerCase().contains('not') ||
          profile.recentWeightTrend.toLowerCase().contains('sure');
  final sigmaE0 = isNotSureTrend ? 450.0 : 300.0;

  final recentMeasurements =
      db.bodyMeasurementsDao.getRecentMeasurements(limit: 10);
  double? latestBodyFatPct;
  for (final m in recentMeasurements) {
    if (todayDate.difference(m.date).inDays <= 30) {
      latestBodyFatPct = m.bodyFatPct ??
          (m.waistCm != null && m.neckCm != null && profile.heightCm > 0
              ? AnthropometricService.calculateNavyBodyFatPct(
                  isMale: profile.isMale,
                  heightCm: profile.heightCm,
                  waistCm: m.waistCm!,
                  neckCm: m.neckCm!,
                  hipsCm: m.hipsCm,
                )
              : null);
      if (latestBodyFatPct != null) break;
    }
  }

  final bmr = ExpenditureKalmanV5.computeBlendedBmr(
    weightKg: weights.first.weightKg,
    heightCm: profile.heightCm,
    age: profile.age,
    isMale: profile.isMale,
    bodyFatPct: latestBodyFatPct,
  );
  final filter = ExpenditureKalmanV5(
    initialExpenditureKcal: baselineKcal,
    initialWeightKg: weights.first.weightKg,
    bmrKcal: bmr,
    sigmaE0: sigmaE0,
  );

  final recordsToSave = <ExpenditureRecord>[];
  ExpenditureState latestState = filter.currentState;

  // Determine end date: step up to max(todayDate, latestObsDate)
  // For historical tests (>30 days in the past), clamp to latestObsDate
  final targetEndDate = (todayDate.difference(latestObsDate).inDays > 30 &&
          !dailyCalories
              .containsKey(DateFormat('yyyy-MM-dd').format(todayDate)) &&
          !weightsByDate
              .containsKey(DateFormat('yyyy-MM-dd').format(todayDate)))
      ? latestObsDate
      : (latestObsDate.isAfter(todayDate) ? latestObsDate : todayDate);

  // Batch-load multi-modal signals for V5 (Workouts, Water, Sodium, Fasting)
  final workoutLoadByDate = <String, double>{};
  final workoutDaysSet = <String>{};
  for (final w in db.getWorkoutSessionsInRange(earliestDate, targetEndDate)) {
    final wStr = DateFormat('yyyy-MM-dd').format(w.startTime);
    final kcal =
        w.caloriesBurned > 0 ? w.caloriesBurned : w.durationMinutes * 5.0;
    workoutLoadByDate[wStr] = (workoutLoadByDate[wStr] ?? 0.0) + kcal;
    workoutDaysSet.add(wStr);
  }

  final waterByDate = <String, int>{};
  for (final w in db.waterDao.getAllWaterLogs(limit: 2000)) {
    waterByDate[w.date] = (waterByDate[w.date] ?? 0) + w.amountMl;
  }

  final sodiumByDate = db.barcodeDao.getDailySodiumWithCoverage();

  final extendedFastDates = <String>{};
  for (final f in db.fastingDao.getRecentFasts(limit: 90)) {
    final end =
        f.actualEndTime ?? (f.state == 'active' ? now : f.targetEndTime);
    if (end.difference(f.startTime).inHours >= 18) {
      final d = DateTime(end.year, end.month, end.day);
      extendedFastDates.add(DateFormat('yyyy-MM-dd').format(d));
      extendedFastDates.add(
        DateFormat('yyyy-MM-dd').format(d.add(const Duration(days: 1))),
      );
    }
  }

  // 5. Sequential calendar day stepper (Delta t = 1 day)
  DateTime iterDate = earliestDate;
  while (!iterDate.isAfter(targetEndDate)) {
    final dStr = DateFormat('yyyy-MM-dd').format(iterDate);
    final isToday = iterDate.year == todayDate.year &&
        iterDate.month == todayDate.month &&
        iterDate.day == todayDate.day;

    final scaleWeight = weightsByDate[dStr];
    final calories = dailyCalories[dStr];
    final isLogged = calories != null && calories > 0.0;

    // Day completion policy:
    // Explicit toggle ? use value : (past days with food are complete, today is incomplete)
    final bool isComplete;
    if (dayCompletions.containsKey(dStr)) {
      isComplete = dayCompletions[dStr]!;
    } else {
      isComplete = !isToday && isLogged;
    }

    final naEntry = sodiumByDate[dStr];
    final validSodium = (naEntry != null && naEntry.coverageRatio >= 0.60)
        ? naEntry.sodiumMg
        : null;

    final input = DailyExpenditureInputV5(
      date: iterDate,
      scaleWeightKg: scaleWeight,
      loggedIntakeKcal: calories,
      isLogged: isLogged,
      isDayComplete: isComplete,
      workoutLoadKcal: workoutLoadByDate[dStr] ?? 0.0,
      hasWorkoutOnDay: workoutDaysSet.contains(dStr),
      waterMl: waterByDate[dStr],
      sodiumMg: validSodium,
      hadExtendedFast: extendedFastDates.contains(dStr),
    );

    latestState = filter.processDay(input);

    // Save completed past days to database
    if (isComplete) {
      recordsToSave.add(ExpenditureRecord.fromState(latestState));
    }

    iterDate = DateTime(iterDate.year, iterDate.month, iterDate.day + 1);
  }

  // 6. Dirty-diff transaction: persist changed records & prune stale dates
  final existingMap = {
    for (final r in db.getExpenditureHistory()) r.date: r,
  };
  final targetDates = {for (final r in recordsToSave) r.date};
  final staleDates =
      existingMap.keys.where((d) => !targetDates.contains(d)).toList();

  if (staleDates.isNotEmpty) {
    final delStmt = db.rawDb.prepare(
      'DELETE FROM expenditure_history WHERE user_id = ? AND date = ?;',
    );
    try {
      for (final d in staleDates) {
        delStmt.execute([db.currentUserId, d]);
      }
    } finally {
      delStmt.dispose();
    }
  }

  if (recordsToSave.isNotEmpty) {
    final dirtyRecords = recordsToSave.where((r) {
      final prev = existingMap[r.date];
      if (prev == null) return true;
      return (prev.expenditureKcal - r.expenditureKcal).abs() > 0.01 ||
          (prev.trendWeightKg - r.trendWeightKg).abs() > 0.001 ||
          (prev.variance - r.variance).abs() > 0.01 ||
          (prev.confidence - r.confidence).abs() > 0.001;
    }).toList();
    if (dirtyRecords.isNotEmpty) {
      db.saveExpenditures(dirtyRecords);
    }
  }

  return latestState;
});

/// Chronological expenditure history series for interactive analytics charts.
final expenditureHistorySeriesProvider =
    Provider<List<ExpenditureRecord>>((ref) {
  final current = ref.watch(expenditureStateProvider);
  final db = ref.watch(databaseProvider);
  final persisted = db.getExpenditureHistory();
  if (persisted.isEmpty) {
    return current.confidence > 0
        ? [ExpenditureRecord.fromState(current)]
        : const [];
  }
  final todayStr = DateFormat('yyyy-MM-dd').format(current.date);
  if (persisted.last.date == todayStr) return persisted;
  return [...persisted, ExpenditureRecord.fromState(current)];
});

/// 3-band probabilistic Goal ETA projection (with Recomp & Singularity guards).
final goalEtaProjectionProvider = Provider<GoalEtaProjection>((ref) {
  final exp = ref.watch(expenditureStateProvider);
  final profile = ref.watch(userProfileProvider);
  final trendSeries = ref.watch(weightTrendSeriesProvider);
  final db = ref.watch(databaseProvider);
  final clock = ref.watch(clockProvider);
  final now = clock();

  double observedVelKgWk = 0.0;
  if (trendSeries.length >= 2) {
    final latest = trendSeries.last;
    final anchor = trendSeries.lastWhere(
      (p) => latest.date.difference(p.date).inDays >= 14,
      orElse: () => trendSeries.first,
    );
    final days = latest.date.difference(anchor.date).inDays.clamp(1, 365);
    observedVelKgWk =
        ((latest.trendWeightKg - anchor.trendWeightKg) / days) * 7.0;
  }

  final measurements = db.bodyMeasurementsDao.getRecentMeasurements(limit: 30);
  final waistEntries = measurements.where((m) => m.waistCm != null).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  double? currentWaist;
  double? waistDelta14;
  bool isSilentRecomp = false;
  if (waistEntries.length >= 2) {
    var smoothed = waistEntries.first.waistCm!;
    final series = <({DateTime date, double value})>[
      (date: waistEntries.first.date, value: smoothed),
    ];
    for (var i = 1; i < waistEntries.length; i++) {
      smoothed = AnthropometricService.smoothCircumference(
        currentObservedCm: waistEntries[i].waistCm!,
        previousSmoothedCm: smoothed,
        deltaDays:
            waistEntries[i].date.difference(waistEntries[i - 1].date).inDays,
      );
      series.add((date: waistEntries[i].date, value: smoothed));
    }
    currentWaist = series.last.value;
    final anchorW = series.lastWhere(
      (s) => series.last.date.difference(s.date).inDays >= 14,
      orElse: () => series.first,
    );
    waistDelta14 = currentWaist - anchorW.value;
    isSilentRecomp = AnthropometricService.isSilentRecomposition(
      weightDelta7DayKg: observedVelKgWk,
      smoothedWaistDelta14DayCm: waistDelta14,
    );
  }

  final goalStr = switch (profile.goalType) {
    GoalType.fatLoss => 'lose',
    GoalType.muscleGain => 'gain',
    GoalType.maintenance => 'maintain',
  };

  return GoalEtaCalculator.compute(
    now: now,
    trendWeightKg:
        exp.trendWeightKg > 0 ? exp.trendWeightKg : profile.currentWeightKg,
    goalWeightKg: profile.targetWeightKg,
    goalType: goalStr,
    targetRatePctPerWeek: profile.weeklyRateOfChangePct,
    observedVelocityKgPerWeek: observedVelKgWk,
    expenditureKcal: exp.expenditureKcal,
    expenditureVariance: exp.variance,
    isSilentRecomp: isSilentRecomp,
    currentWaistCm: currentWaist,
    waistDelta14Cm: waistDelta14,
    heightCm: profile.heightCm,
  );
});

/// User unit-system preference ('imperial' -> lbs, default 'metric' -> kg).
class UseImperialUnitsNotifier extends StateNotifier<bool> {
  UseImperialUnitsNotifier(this._db)
      : super(_db.getSetting('unit_system', 'metric') == 'imperial');

  final AppDatabase _db;

  void setImperial(bool useImperial) {
    _db.setSetting('unit_system', useImperial ? 'imperial' : 'metric');
    state = useImperial;
  }
}

final useImperialUnitsProvider =
    StateNotifierProvider<UseImperialUnitsNotifier, bool>((ref) {
  ref.watch(userDataEpochProvider);
  final db = ref.watch(databaseProvider);
  return UseImperialUnitsNotifier(db);
});

/// Target daily calories and macronutrient breakdown for the selected date.
/// Automatically reflects 7-day program day-shifting (workout vs rest) when active.
final dailyMacroTargetProvider = Provider<MacroTarget>((ref) {
  return ref.watch(dayMacroTargetForSelectedDateProvider);
});

/// Backwards compatible alias for dailyMacroTargetProvider
final macroTargetProvider = dailyMacroTargetProvider;

/// Recently and frequently logged foods for 1-tap quick logging / search suggestions.
final recentLoggedFoodsProvider = Provider<List<FoodItem>>((ref) {
  ref.watch(userDataEpochProvider);
  ref.watch(foodLogsRevisionProvider);
  final db = ref.watch(databaseProvider);

  final result = db.getRecentFoods(limit: 10);
  final seenIds = result.map((f) => f.id).toSet();

  // Fallback to top catalog staples if fewer than 5 items have been logged
  if (result.length < 5) {
    final defaults = db.searchFoods('', limit: 8);
    for (final food in defaults) {
      if (seenIds.add(food.id)) {
        result.add(food);
      }
      if (result.length >= 8) break;
    }
  }

  return result;
});
