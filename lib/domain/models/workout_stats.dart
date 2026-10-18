import 'package:flutter/foundation.dart';

import 'package:macro_factor_app/domain/models/workout_session.dart';

/// Aggregated training and workout analytics derived reactively from logged/synced workout sessions.
@immutable
class WorkoutStats {
  const WorkoutStats({
    required this.totalWorkouts,
    required this.hevyWorkoutsCount,
    required this.totalDurationMinutes,
    required this.averageDurationMinutes,
    required this.totalCaloriesBurned,
    required this.averageCaloriesBurned,
    required this.weeklyFrequency,
    required this.workoutsThisWeek,
    required this.activeDaysThisWeek,
    required this.recentWorkouts,
  });

  /// Empty stats sentinel for new users or when zero sessions exist.
  static const empty = WorkoutStats(
    totalWorkouts: 0,
    hevyWorkoutsCount: 0,
    totalDurationMinutes: 0,
    averageDurationMinutes: 0.0,
    totalCaloriesBurned: 0.0,
    averageCaloriesBurned: 0.0,
    weeklyFrequency: 0.0,
    workoutsThisWeek: 0,
    activeDaysThisWeek: {},
    recentWorkouts: [],
  );

  /// Total count of all logged and synced workout sessions.
  final int totalWorkouts;

  /// Count of sessions specifically synced from Hevy.
  final int hevyWorkoutsCount;

  /// Cumulative training time in minutes across all sessions.
  final int totalDurationMinutes;

  /// Average workout duration in minutes per session.
  final double averageDurationMinutes;

  /// Cumulative active calories burned across all sessions.
  final double totalCaloriesBurned;

  /// Average active calories burned per workout.
  final double averageCaloriesBurned;

  /// Average number of workouts per week over the past 4-week window.
  final double weeklyFrequency;

  /// Number of workouts logged in the current calendar week (Monday to Sunday).
  final int workoutsThisWeek;

  /// Set of weekday indices (1 = Monday, 7 = Sunday) with at least one workout in the current week.
  final Set<int> activeDaysThisWeek;

  /// Most recent workout sessions (up to 10), ordered descending by start time.
  final List<WorkoutSession> recentWorkouts;

  /// Average duration formatted as an integer.
  int get roundedAverageDurationMinutes => averageDurationMinutes.round();

  /// Average calories formatted as an integer.
  int get roundedAverageCaloriesBurned => averageCaloriesBurned.round();

  /// Weekly frequency formatted to one decimal place (e.g. "4.2").
  String get formattedWeeklyFrequency => weeklyFrequency.toStringAsFixed(1);

  /// Computes comprehensive WorkoutStats from a list of sessions.
  factory WorkoutStats.fromSessions(
    List<WorkoutSession> sessions, {
    DateTime? referenceDate,
    int recentLimit = 10,
  }) {
    if (sessions.isEmpty) return WorkoutStats.empty;

    final now = referenceDate ?? DateTime.now();

    // Sort descending by start time for consistent calculation
    final sorted = List<WorkoutSession>.from(sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    final total = sorted.length;
    var hevyCount = 0;
    var totalMins = 0;
    var totalCals = 0.0;

    for (final s in sorted) {
      if (s.isHevy) hevyCount++;
      totalMins += s.durationMinutes;
      totalCals += s.caloriesBurned;
    }

    final avgMins = total > 0 ? totalMins / total : 0.0;
    final avgCals = total > 0 ? totalCals / total : 0.0;

    // Current calendar week (Monday = 1, Sunday = 7)
    final startOfCurrentWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final endOfCurrentWeek = startOfCurrentWeek
        .add(const Duration(days: 7))
        .subtract(const Duration(microseconds: 1));

    var thisWeekCount = 0;
    final activeDays = <int>{};

    for (final s in sorted) {
      if (!s.startTime.isBefore(startOfCurrentWeek) &&
          !s.startTime.isAfter(endOfCurrentWeek)) {
        thisWeekCount++;
        activeDays.add(s.startTime.weekday);
      }
    }

    // Weekly frequency over trailing 28 days (4 weeks)
    final fourWeeksAgo = now.subtract(const Duration(days: 28));
    final past4WeeksSessions =
        sorted.where((s) => s.startTime.isAfter(fourWeeksAgo)).length;
    final weeklyFreq = past4WeeksSessions / 4.0;

    final recent = sorted.take(recentLimit).toList();

    return WorkoutStats(
      totalWorkouts: total,
      hevyWorkoutsCount: hevyCount,
      totalDurationMinutes: totalMins,
      averageDurationMinutes: avgMins,
      totalCaloriesBurned: totalCals,
      averageCaloriesBurned: avgCals,
      weeklyFrequency: weeklyFreq,
      workoutsThisWeek: thisWeekCount,
      activeDaysThisWeek: Set.unmodifiable(activeDays),
      recentWorkouts: List.unmodifiable(recent),
    );
  }

  WorkoutStats copyWith({
    int? totalWorkouts,
    int? hevyWorkoutsCount,
    int? totalDurationMinutes,
    double? averageDurationMinutes,
    double? totalCaloriesBurned,
    double? averageCaloriesBurned,
    double? weeklyFrequency,
    int? workoutsThisWeek,
    Set<int>? activeDaysThisWeek,
    List<WorkoutSession>? recentWorkouts,
  }) {
    return WorkoutStats(
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      hevyWorkoutsCount: hevyWorkoutsCount ?? this.hevyWorkoutsCount,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
      averageDurationMinutes:
          averageDurationMinutes ?? this.averageDurationMinutes,
      totalCaloriesBurned: totalCaloriesBurned ?? this.totalCaloriesBurned,
      averageCaloriesBurned:
          averageCaloriesBurned ?? this.averageCaloriesBurned,
      weeklyFrequency: weeklyFrequency ?? this.weeklyFrequency,
      workoutsThisWeek: workoutsThisWeek ?? this.workoutsThisWeek,
      activeDaysThisWeek: activeDaysThisWeek ?? this.activeDaysThisWeek,
      recentWorkouts: recentWorkouts ?? this.recentWorkouts,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutStats &&
          runtimeType == other.runtimeType &&
          totalWorkouts == other.totalWorkouts &&
          hevyWorkoutsCount == other.hevyWorkoutsCount &&
          totalDurationMinutes == other.totalDurationMinutes &&
          averageDurationMinutes == other.averageDurationMinutes &&
          totalCaloriesBurned == other.totalCaloriesBurned &&
          averageCaloriesBurned == other.averageCaloriesBurned &&
          weeklyFrequency == other.weeklyFrequency &&
          workoutsThisWeek == other.workoutsThisWeek &&
          setEquals(activeDaysThisWeek, other.activeDaysThisWeek) &&
          listEquals(recentWorkouts, other.recentWorkouts);

  @override
  int get hashCode => Object.hash(
        totalWorkouts,
        hevyWorkoutsCount,
        totalDurationMinutes,
        averageDurationMinutes,
        totalCaloriesBurned,
        averageCaloriesBurned,
        weeklyFrequency,
        workoutsThisWeek,
        Object.hashAll(activeDaysThisWeek),
        Object.hashAll(recentWorkouts),
      );

  @override
  String toString() =>
      'WorkoutStats(total: $totalWorkouts, hevy: $hevyWorkoutsCount, totalMins: $totalDurationMinutes, weeklyFreq: $formattedWeeklyFrequency, thisWeek: $workoutsThisWeek)';
}
