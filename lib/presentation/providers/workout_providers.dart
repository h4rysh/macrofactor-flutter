import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/workout_session.dart';
import 'package:sique/domain/models/workout_stats.dart';
import 'package:sique/presentation/providers/app_providers.dart';

/// Notifier managing synced and logged workout sessions from SQLite.
class WorkoutSessionsNotifier extends StateNotifier<List<WorkoutSession>> {
  WorkoutSessionsNotifier(this._db) : super([]) {
    refresh();
  }

  final AppDatabase _db;

  /// Reloads all workout sessions chronologically from SQLite.
  void refresh() {
    try {
      state = _db.getAllWorkoutSessions();
    } on SqliteException catch (e, st) {
      developer.log(
        'Failed to refresh workout sessions from DB',
        name: 'WorkoutProviders',
        error: e,
        stackTrace: st,
      );
      state = [];
    }
  }

  /// Inserts a single workout session and refreshes state.
  void addSession(WorkoutSession session) {
    _db.insertWorkoutSessions([session]);
    refresh();
  }

  /// Inserts a batch of workout sessions and refreshes state.
  void addSessions(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) return;
    _db.insertWorkoutSessions(sessions);
    refresh();
  }

  /// Deletes a workout session by its identifier and refreshes state.
  void deleteSession(dynamic id) {
    _db.deleteWorkoutSession(id);
    refresh();
  }

  /// Queries workout sessions within a specific date range.
  List<WorkoutSession> getSessionsInRange(DateTime start, DateTime end) {
    try {
      return _db.getWorkoutSessionsInRange(start, end);
    } on SqliteException catch (e, st) {
      developer.log(
        'Failed to query workout sessions in range; falling back to in-memory filter',
        name: 'WorkoutProviders',
        error: e,
        stackTrace: st,
      );
      return state
          .where(
              (s) => !s.startTime.isBefore(start) && !s.startTime.isAfter(end))
          .toList();
    }
  }
}

/// Main workout sessions provider managing list of synced/logged sessions.
final workoutSessionsProvider =
    StateNotifierProvider<WorkoutSessionsNotifier, List<WorkoutSession>>((ref) {
  final db = ref.watch(databaseProvider);
  return WorkoutSessionsNotifier(db);
});

/// Pure reactive workout stats derived automatically from workoutSessionsProvider.
final workoutStatsProvider = Provider<WorkoutStats>((ref) {
  final sessions = ref.watch(workoutSessionsProvider);
  return WorkoutStats.fromSessions(sessions);
});

/// Most recent workout sessions (up to 10), ordered descending by start time.
final recentWorkoutsProvider = Provider<List<WorkoutSession>>((ref) {
  final stats = ref.watch(workoutStatsProvider);
  return stats.recentWorkouts;
});

/// Count of workouts specifically imported from Hevy.
final hevyWorkoutsCountProvider = Provider<int>((ref) {
  final stats = ref.watch(workoutStatsProvider);
  return stats.hevyWorkoutsCount;
});
