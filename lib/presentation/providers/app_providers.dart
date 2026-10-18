import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:macro_factor_app/data/local/app_database.dart';
import 'package:macro_factor_app/domain/algorithms/expenditure_algorithm_v3.dart';
import 'package:macro_factor_app/domain/algorithms/weight_trend_v2.dart';
import 'package:macro_factor_app/domain/models/food_models.dart';
import 'package:macro_factor_app/domain/models/user_profile.dart';

export 'auth_providers.dart';
export 'health_sync_providers.dart';
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
  UserProfileNotifier(this._db) : super(_loadInitial(_db));

  final AppDatabase _db;

  static UserProfile _loadInitial(AppDatabase db) {
    final existing = db.getUserProfile();
    if (existing != null) return existing;
    db.saveUserProfile(defaultUserProfile);
    return defaultUserProfile;
  }

  void updateProfile(UserProfile newProfile) {
    _db.saveUserProfile(newProfile);
    state = newProfile;
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  final db = ref.watch(databaseProvider);
  return UserProfileNotifier(db);
});

/// Notifier managing daily logged meals.
class DailyFoodLogsNotifier extends StateNotifier<List<FoodLogEntry>> {
  DailyFoodLogsNotifier(this._db, this._date) : super([]) {
    refresh();
  }

  final AppDatabase _db;
  final String _date;

  void refresh() {
    state = _db.getFoodLogsForDate(_date);
  }

  int addFood(FoodLogEntry entry) {
    final id = _db.insertFoodLog(entry);
    refresh();
    return id;
  }

  void deleteFood(int id) {
    _db.deleteFoodLog(id);
    refresh();
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
  }) {
    final grams = (portionUnit.gramsPerUnit * quantity);
    final effectiveCalories =
        (food.caloriesPer100g * grams / 100.0) + oilModifier.additionalCalories;
    final effectiveProtein = food.proteinPer100g * grams / 100.0;
    final effectiveFat = (food.fatPer100g * grams / 100.0) +
        (oilModifier.additionalCalories / 9.0);
    final effectiveCarbs = food.carbsPer100g * grams / 100.0;
    final effectiveFiber = food.fiberPer100g * grams / 100.0;

    final entry = FoodLogEntry(
      id: 0,
      date: DateFormat('yyyy-MM-dd').format(loggedAt),
      mealType: mealType,
      foodId: food.id,
      foodName: food.name,
      servingQuantity: quantity,
      unitName: portionUnit.unitName,
      gramWeight: grams,
      calories: effectiveCalories,
      protein: effectiveProtein,
      carbs: effectiveCarbs,
      fat: effectiveFat,
      fiber: effectiveFiber,
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
  return DailyFoodLogsNotifier(db, date);
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

/// Dynamic Bayesian Expenditure tracker.
final expenditureStateProvider = Provider<ExpenditureState>((ref) {
  final profile = ref.watch(userProfileProvider);
  final weights = ref.watch(weightLogsProvider);
  final db = ref.watch(databaseProvider);

  final tracker = ExpenditureAlgorithmV3(
    initialExpenditureKcal: profile.baselineExpenditureKcal,
  );

  if (weights.isEmpty) {
    return tracker.currentState;
  }

  final trendSeries =
      WeightTrendV2Series.compute(entries: weights, bidirectional: true).points;
  if (trendSeries.length < 2) {
    return tracker.currentState;
  }

  // Iterate chronologically through observations
  for (int i = 1; i < trendSeries.length; i++) {
    final prevPoint = trendSeries[i - 1];
    final currPoint = trendSeries[i];
    final dateStr = DateFormat('yyyy-MM-dd').format(currPoint.date);

    final dayLogs = db.getFoodLogsForDate(dateStr);
    final dayCalories =
        dayLogs.fold<double>(0.0, (acc, item) => acc + item.calories);

    final isLogged =
        dayCalories > 500.0; // Adherence neutrality: only count logged days

    final observation = DailyEnergyObservation(
      date: currPoint.date,
      loggedIntakeKcal: isLogged ? dayCalories : 0.0,
      trendWeightDeltaKg: currPoint.trendWeightKg - prevPoint.trendWeightKg,
      isFullyLogged: isLogged,
    );

    tracker.updateDaily(observation);
  }

  return tracker.currentState;
});

/// Target daily calories and macronutrient breakdown.
final dailyMacroTargetProvider = Provider<MacroTarget>((ref) {
  final profile = ref.watch(userProfileProvider);
  final expenditureState = ref.watch(expenditureStateProvider);
  return profile.calculateTargetMacros(expenditureState.expenditureKcal);
});

/// Backwards compatible alias for dailyMacroTargetProvider
final macroTargetProvider = dailyMacroTargetProvider;
