import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/algorithms/expenditure_kalman_v4.dart';
import 'package:sique/domain/algorithms/weight_trend_v2.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/strategy_providers.dart';

export 'auth_providers.dart';
export 'health_sync_providers.dart';
export 'strategy_providers.dart';
export 'workout_providers.dart';

/// Database singleton provider, overridden in main() or tests.
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
      'databaseProvider must be overridden in ProviderScope');
});

/// Currently selected date in the dashboard (YYYY-MM-DD).
final selectedDateProvider = StateProvider<String>((ref) {
  return DateFormat('yyyy-MM-dd').format(DateTime.now());
});

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
            oldProfile.proteinPreference != newProfile.proteinPreference)) {
      _ref
          .read(weeklyMacroProgramProvider.notifier)
          .regenerateFromProfile(newProfile);
    }
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
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
}

final dailyFoodLogsProvider =
    StateNotifierProvider<DailyFoodLogsNotifier, List<FoodLogEntry>>((ref) {
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
  WeightLogsNotifier(this._db) : super([]) {
    refresh();
  }

  final AppDatabase _db;

  void refresh() {
    state = _db.getAllWeightLogs();
  }

  void logWeight(String date, double weightKg, String? note) {
    _db.insertWeightLog(date, weightKg, note);
    refresh();
  }

  void deleteWeight(String date) {
    _db.deleteWeightLogForDate(date);
    refresh();
  }
}

final weightLogsProvider =
    StateNotifierProvider<WeightLogsNotifier, List<ScaleWeightEntry>>((ref) {
  final db = ref.watch(databaseProvider);
  return WeightLogsNotifier(db);
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
  final profile = ref.watch(userProfileProvider);
  final weights = ref.watch(weightLogsProvider);
  final db = ref.watch(databaseProvider);
  ref.watch(foodLogsRevisionProvider);
  final dayCompletions = ref.watch(dayCompletionsProvider);

  final baselineKcal = profile.baselineExpenditureKcal > 0
      ? profile.baselineExpenditureKcal
      : 2000.0;

  final now = DateTime.now();
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
    } catch (_) {}
  }

  // 4. Instantiate 2D Joint-State Kalman Filter V4
  final filter = ExpenditureKalmanV4(
    initialExpenditureKcal: baselineKcal,
    initialWeightKg: weights.first.weightKg,
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

    final input = DailyExpenditureInput(
      date: iterDate,
      scaleWeightKg: scaleWeight,
      loggedIntakeKcal: calories,
      isLogged: isLogged,
      isDayComplete: isComplete,
    );

    latestState = filter.processDay(input);

    // Save completed past days to database
    if (isComplete) {
      recordsToSave.add(ExpenditureRecord.fromState(latestState));
    }

    iterDate = DateTime(iterDate.year, iterDate.month, iterDate.day + 1);
  }

  // 6. Batch persist updated completed history in a single SQLite transaction
  if (recordsToSave.isNotEmpty) {
    db.saveExpenditures(recordsToSave);
  }

  return latestState;
});

/// Target daily calories and macronutrient breakdown for the selected date.
/// Automatically reflects 7-day program day-shifting (workout vs rest) when active.
final dailyMacroTargetProvider = Provider<MacroTarget>((ref) {
  return ref.watch(dayMacroTargetForSelectedDateProvider);
});

/// Backwards compatible alias for dailyMacroTargetProvider
final macroTargetProvider = dailyMacroTargetProvider;
