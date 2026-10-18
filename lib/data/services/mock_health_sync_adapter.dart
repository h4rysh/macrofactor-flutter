import 'dart:async';

import 'package:macro_factor_app/domain/algorithms/weight_trend_v2.dart';
import 'package:macro_factor_app/domain/models/workout_session.dart';
import 'package:macro_factor_app/domain/services/health_sync_adapter.dart';

/// Deterministic mock implementation of [HealthSyncAdapter] for headless tests and CI.
class MockHealthSyncAdapter implements HealthSyncAdapter {
  MockHealthSyncAdapter({
    this.isAvailableResult = true,
    this.hasPermissionsResult = true,
    this.requestPermissionsResult = true,
    List<WorkoutSession>? mockWorkouts,
    List<ScaleWeightEntry>? mockWeights,
    this.shouldFailFetchWorkouts = false,
    this.shouldFailFetchWeights = false,
    this.delay = Duration.zero,
  })  : _workouts =
            mockWorkouts != null ? List.from(mockWorkouts) : _defaultWorkouts(),
        _weights =
            mockWeights != null ? List.from(mockWeights) : _defaultWeights();

  bool isAvailableResult;
  bool hasPermissionsResult;
  bool requestPermissionsResult;
  bool shouldFailFetchWorkouts;
  bool shouldFailFetchWeights;
  Duration delay;

  List<WorkoutSession> _workouts;
  List<ScaleWeightEntry> _weights;

  // Telemetry & Call tracking for test assertions
  int isAvailableCallCount = 0;
  int hasPermissionsCallCount = 0;
  int requestPermissionsCallCount = 0;
  int fetchWorkoutsCallCount = 0;
  int fetchWeightsCallCount = 0;

  DateTime? lastFetchWorkoutsStartTime;
  DateTime? lastFetchWorkoutsEndTime;
  DateTime? lastFetchWeightsStartTime;
  DateTime? lastFetchWeightsEndTime;

  @override
  Future<bool> isAvailable() async {
    isAvailableCallCount++;
    if (delay > Duration.zero) await Future.delayed(delay);
    return isAvailableResult;
  }

  @override
  Future<bool> hasPermissions() async {
    hasPermissionsCallCount++;
    if (delay > Duration.zero) await Future.delayed(delay);
    return hasPermissionsResult;
  }

  @override
  Future<bool> requestPermissions() async {
    requestPermissionsCallCount++;
    if (delay > Duration.zero) await Future.delayed(delay);
    hasPermissionsResult = requestPermissionsResult;
    return requestPermissionsResult;
  }

  @override
  Future<List<WorkoutSession>> fetchWorkouts({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    fetchWorkoutsCallCount++;
    lastFetchWorkoutsStartTime = startTime;
    lastFetchWorkoutsEndTime = endTime;
    if (delay > Duration.zero) await Future.delayed(delay);

    if (shouldFailFetchWorkouts) {
      throw Exception('Health Connect service disconnected');
    }

    return _workouts.where((w) {
      return !w.startTime.isBefore(startTime) && !w.startTime.isAfter(endTime);
    }).toList();
  }

  @override
  Future<List<ScaleWeightEntry>> fetchWeights({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    fetchWeightsCallCount++;
    lastFetchWeightsStartTime = startTime;
    lastFetchWeightsEndTime = endTime;
    if (delay > Duration.zero) await Future.delayed(delay);

    if (shouldFailFetchWeights) {
      throw Exception('Health Connect sensor read error');
    }

    return _weights.where((w) {
      return !w.date.isBefore(startTime) && !w.date.isAfter(endTime);
    }).toList();
  }

  /// Mutator to supply specific workouts during tests.
  void setWorkouts(List<WorkoutSession> workouts) {
    _workouts = List.from(workouts);
  }

  /// Mutator to supply specific weights during tests.
  void setWeights(List<ScaleWeightEntry> weights) {
    _weights = List.from(weights);
  }

  /// Resets telemetry counters and state for test isolation.
  void reset() {
    isAvailableCallCount = 0;
    hasPermissionsCallCount = 0;
    requestPermissionsCallCount = 0;
    fetchWorkoutsCallCount = 0;
    fetchWeightsCallCount = 0;
    lastFetchWorkoutsStartTime = null;
    lastFetchWorkoutsEndTime = null;
    lastFetchWeightsStartTime = null;
    lastFetchWeightsEndTime = null;
    shouldFailFetchWorkouts = false;
    shouldFailFetchWeights = false;
  }

  static List<WorkoutSession> _defaultWorkouts() {
    final now = DateTime.now();
    return [
      WorkoutSession(
        id: 'hevy_session_101',
        source: WorkoutSource.hevy,
        title: 'Upper Body A - Chest & Triceps',
        startTime: now.subtract(const Duration(days: 1, hours: 2)),
        endTime: now.subtract(const Duration(days: 1, hours: 1)),
        durationMinutes: 60,
        caloriesBurned: 385.0,
        notes: 'Bench press PR + Tricep extensions (Hevy)',
        createdAt: now.subtract(const Duration(days: 1, hours: 1)),
      ),
      WorkoutSession(
        id: 'hevy_session_102',
        source: WorkoutSource.hevy,
        title: 'Lower Body B - Squats & Calves',
        startTime: now.subtract(const Duration(days: 3, hours: 2)),
        endTime: now.subtract(const Duration(days: 3, hours: 1, minutes: 15)),
        durationMinutes: 45,
        caloriesBurned: 310.0,
        notes: 'Back squat 120kg 3x5 (Hevy)',
        createdAt: now.subtract(const Duration(days: 3, hours: 1)),
      ),
      WorkoutSession(
        id: 'hc_session_103',
        source: WorkoutSource.healthConnect,
        title: 'Outdoor Running',
        startTime: now.subtract(const Duration(days: 5, hours: 1)),
        endTime: now.subtract(const Duration(days: 5)),
        durationMinutes: 30,
        caloriesBurned: 260.0,
        notes: 'Google Health Connect synced activity',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  static List<ScaleWeightEntry> _defaultWeights() {
    final now = DateTime.now();
    return [
      ScaleWeightEntry(
        date: DateTime(now.year, now.month, now.day - 1),
        weightKg: 74.5,
        note: 'Smart Scale (Health Connect)',
      ),
      ScaleWeightEntry(
        date: DateTime(now.year, now.month, now.day - 3),
        weightKg: 74.8,
        note: 'Smart Scale (Health Connect)',
      ),
    ];
  }
}
