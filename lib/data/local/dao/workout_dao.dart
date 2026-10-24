import 'package:sique/domain/models/workout_session.dart';
import 'package:sqlite3/common.dart';

/// Data Access Object managing workout sessions and training telemetry.
class WorkoutDao {
  WorkoutDao(this._db);

  final CommonDatabase _db;

  /// Inserts or updates a list of workout sessions within an atomic transaction.
  void insertWorkoutSessions(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) return;
    final stmt = _db.prepare(
      'INSERT INTO workout_sessions (id, source, title, start_time, end_time, duration_minutes, calories_burned, notes, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) '
      'ON CONFLICT(id) DO UPDATE SET source = excluded.source, title = excluded.title, start_time = excluded.start_time, end_time = excluded.end_time, duration_minutes = excluded.duration_minutes, calories_burned = excluded.calories_burned, notes = excluded.notes;',
    );

    _db.execute('BEGIN TRANSACTION;');
    try {
      for (final session in sessions) {
        stmt.execute([
          session.id,
          session.source,
          session.title,
          session.startTime.toIso8601String(),
          session.endTime.toIso8601String(),
          session.durationMinutes,
          session.caloriesBurned,
          session.notes,
          session.createdAt.toIso8601String(),
        ]);
      }
      _db.execute('COMMIT;');
    } catch (_) {
      _db.execute('ROLLBACK;');
      rethrow;
    } finally {
      stmt.dispose();
    }
  }

  /// Retrieves all workout sessions ordered chronologically descending (newest first).
  List<WorkoutSession> getAllWorkoutSessions() {
    final stmt = _db.prepare(
      'SELECT id, source, title, start_time, end_time, duration_minutes, calories_burned, notes, created_at FROM workout_sessions ORDER BY start_time DESC;',
    );
    final result = stmt.select();
    stmt.dispose();
    return result.map(_mapWorkoutSessionRow).toList();
  }

  /// Retrieves workout sessions whose start_time is between [start] and [end] (inclusive).
  List<WorkoutSession> getWorkoutSessionsInRange(DateTime start, DateTime end) {
    final stmt = _db.prepare(
      'SELECT id, source, title, start_time, end_time, duration_minutes, calories_burned, notes, created_at FROM workout_sessions WHERE start_time >= ? AND start_time <= ? ORDER BY start_time DESC;',
    );
    final result =
        stmt.select([start.toIso8601String(), end.toIso8601String()]);
    stmt.dispose();
    return result.map(_mapWorkoutSessionRow).toList();
  }

  /// Deletes a workout session by its identifier.
  void deleteWorkoutSession(dynamic id) {
    final stmt = _db.prepare('DELETE FROM workout_sessions WHERE id = ?;');
    stmt.execute([id.toString()]);
    stmt.dispose();
  }

  WorkoutSession _mapWorkoutSessionRow(Row row) {
    return WorkoutSession(
      id: row['id'] as String,
      source: row['source'] as String? ?? WorkoutSource.healthConnect,
      title: row['title'] as String? ?? 'Workout',
      startTime: DateTime.parse(row['start_time'] as String),
      endTime: DateTime.parse(row['end_time'] as String),
      durationMinutes: (row['duration_minutes'] as num).toInt(),
      caloriesBurned: (row['calories_burned'] as num).toDouble(),
      notes: row['notes'] as String?,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
    );
  }
}
