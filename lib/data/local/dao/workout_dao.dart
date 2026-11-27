import 'dart:developer' as developer;
import 'package:sique/domain/models/workout_session.dart';
import 'package:sqlite3/common.dart';

/// Data Access Object managing workout sessions, training telemetry, and deterministic deduplication.
class WorkoutDao {
  WorkoutDao(this._db,
      {this.userId = 'default_user', String Function()? userIdProvider})
      : _userIdProvider = userIdProvider;

  final CommonDatabase _db;
  String userId;
  String Function()? _userIdProvider;

  set userIdProvider(String Function()? provider) => _userIdProvider = provider;

  /// Active tenant user id for multi-tenant data scoping.
  String get effectiveUserId =>
      _userIdProvider != null ? _userIdProvider!() : userId;

  /// Generates a deterministic workout UUID/ID from source, timestamps, and title.
  static String deterministicWorkoutId({
    required String source,
    required DateTime startTime,
    required DateTime endTime,
    String title = '',
  }) {
    final s = source.trim().toLowerCase();
    final startMs = startTime.toUtc().millisecondsSinceEpoch;
    final endMs = endTime.toUtc().millisecondsSinceEpoch;
    final t = title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    return 'workout_${s}_${startMs}_${endMs}_$t';
  }

  /// Inserts or updates a list of workout sessions with deduplication on workout_uuid / deterministic ID.
  /// Enforces try/finally statement disposal and comprehensive rollback safety (ISS-8-04, ISS-8-05).
  void insertWorkoutSessions(
    List<WorkoutSession> sessions, {
    String? userId,
    bool manageTransaction = true,
  }) {
    if (sessions.isEmpty) return;
    final uid = userId ?? effectiveUserId;

    // 1. In-batch deduplication and deterministic ID mapping
    final Map<String, WorkoutSession> deduplicatedBatch = {};
    for (final session in sessions) {
      final resolvedId =
          session.id.trim().isNotEmpty && !session.id.startsWith('temp_')
              ? session.id.trim()
              : deterministicWorkoutId(
                  source: session.source,
                  startTime: session.startTime,
                  endTime: session.endTime,
                  title: session.title,
                );

      final normalized = session.id == resolvedId
          ? session
          : WorkoutSession(
              id: resolvedId,
              source: session.source,
              title: session.title,
              startTime: session.startTime,
              endTime: session.endTime,
              durationMinutes: session.durationMinutes,
              caloriesBurned: session.caloriesBurned,
              notes: session.notes,
              createdAt: session.createdAt,
            );

      deduplicatedBatch[resolvedId] = normalized;
    }

    final stmt = _db.prepare('''
      INSERT INTO workout_sessions (
        id, user_id, source, title, start_time, end_time, duration_minutes, calories_burned, notes, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        source = excluded.source,
        title = excluded.title,
        start_time = excluded.start_time,
        end_time = excluded.end_time,
        duration_minutes = excluded.duration_minutes,
        calories_burned = excluded.calories_burned,
        notes = excluded.notes
      WHERE workout_sessions.user_id = excluded.user_id;
    ''');

    try {
      if (manageTransaction) {
        _db.execute('BEGIN TRANSACTION;');
      }
      try {
        for (final session in deduplicatedBatch.values) {
          stmt.execute([
            session.id,
            uid,
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
        if (manageTransaction) {
          _db.execute('COMMIT;');
        }
      } catch (e, st) {
        developer.log(
          'Transaction failed during insertWorkoutSessions; executing rollback',
          name: 'WorkoutDao',
          error: e,
          stackTrace: st,
        );
        if (manageTransaction) {
          try {
            _db.execute('ROLLBACK;');
          } catch (rollbackErr, rollbackSt) {
            developer.log(
              'Rollback failed during insertWorkoutSessions',
              name: 'WorkoutDao',
              error: rollbackErr,
              stackTrace: rollbackSt,
            );
          }
        }
        rethrow;
      }
    } finally {
      stmt.dispose();
    }
  }

  /// Retrieves all workout sessions ordered chronologically descending (newest first).
  List<WorkoutSession> getAllWorkoutSessions({String? userId}) {
    final uid = userId ?? effectiveUserId;

    final stmt = _db.prepare('''
      SELECT id, source, title, start_time, end_time, duration_minutes, calories_burned, notes, created_at
      FROM workout_sessions
      WHERE user_id = ?
      ORDER BY start_time DESC;
    ''');
    try {
      final result = stmt.select([uid]);
      return result.map(_mapWorkoutSessionRow).toList();
    } finally {
      stmt.dispose();
    }
  }

  /// Retrieves workout sessions whose start_time is between [start] and [end] dates (inclusive of end day).
  List<WorkoutSession> getWorkoutSessionsInRange(DateTime start, DateTime end,
      {String? userId}) {
    final uid = userId ?? effectiveUserId;
    if (end.isBefore(start)) return const [];

    final isDateOnlyRange = start.hour == 0 &&
        start.minute == 0 &&
        start.second == 0 &&
        start.millisecond == 0 &&
        start.microsecond == 0 &&
        end.hour == 0 &&
        end.minute == 0 &&
        end.second == 0 &&
        end.millisecond == 0 &&
        end.microsecond == 0;

    final String sql;
    final List<Object?> args;
    if (isDateOnlyRange) {
      final endExclusive = DateTime(end.year, end.month, end.day + 1);
      sql = '''
        SELECT id, source, title, start_time, end_time, duration_minutes, calories_burned, notes, created_at
        FROM workout_sessions
        WHERE user_id = ? AND start_time >= ? AND start_time < ?
        ORDER BY start_time DESC;
      ''';
      args = [uid, start.toIso8601String(), endExclusive.toIso8601String()];
    } else {
      sql = '''
        SELECT id, source, title, start_time, end_time, duration_minutes, calories_burned, notes, created_at
        FROM workout_sessions
        WHERE user_id = ? AND start_time >= ? AND start_time <= ?
        ORDER BY start_time DESC;
      ''';
      args = [uid, start.toIso8601String(), end.toIso8601String()];
    }

    final stmt = _db.prepare(sql);
    try {
      final result = stmt.select(args);
      return result.map(_mapWorkoutSessionRow).toList();
    } finally {
      stmt.dispose();
    }
  }

  /// Deletes a workout session by its identifier.
  void deleteWorkoutSession(dynamic id, {String? userId}) {
    final uid = userId ?? effectiveUserId;

    final stmt = _db
        .prepare('DELETE FROM workout_sessions WHERE id = ? AND user_id = ?;');
    try {
      stmt.execute([id.toString(), uid]);
    } finally {
      stmt.dispose();
    }
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
