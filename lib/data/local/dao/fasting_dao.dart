import 'package:sique/domain/models/lifestyle_models.dart';
import 'package:sqlite3/common.dart';

/// Data Access Object managing intermittent fasting sessions with tenant scoping.
class FastingDao {
  FastingDao(
    this._db, {
    this.userId = 'default_user',
    String Function()? userIdProvider,
  }) : _userIdProvider = userIdProvider;

  final CommonDatabase _db;
  String userId;
  String Function()? _userIdProvider;

  set userIdProvider(String Function()? provider) => _userIdProvider = provider;

  /// Active tenant user id for multi-tenant data scoping.
  String get effectiveUserId =>
      _userIdProvider != null ? _userIdProvider!() : userId;

  /// Starts a new fasting session. Cancels/completes any currently active session first.
  void startFast(FastingSession session, {String? userId}) {
    final uid = userId ??
        (effectiveUserId != 'default_user'
            ? effectiveUserId
            : (session.userId.isNotEmpty ? session.userId : 'default_user'));

    // Conclude any existing active fast
    final nowStr = DateTime.now().toIso8601String();
    final cancelStmt = _db.prepare('''
      UPDATE fasting_sessions
      SET state = CASE
            WHEN ? >= target_end_time THEN 'completed'
            ELSE 'broken_early'
          END,
          actual_end_time = ?
      WHERE user_id = ? AND state = 'active';
    ''');
    try {
      cancelStmt.execute([nowStr, nowStr, uid]);
    } finally {
      cancelStmt.dispose();
    }

    // Insert new active fast
    final stmt = _db.prepare('''
      INSERT INTO fasting_sessions (
        id, user_id, protocol, start_time, target_end_time, actual_end_time, state, notes
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    ''');

    try {
      stmt.execute([
        session.id,
        uid,
        session.protocol.name,
        session.startTime.toIso8601String(),
        session.targetEndTime.toIso8601String(),
        session.actualEndTime?.toIso8601String(),
        session.state,
        session.notes,
      ]);
    } finally {
      stmt.dispose();
    }
  }

  /// Retrieves the currently active fasting session, or null if no active fast.
  FastingSession? getActiveFast({String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare('''
      SELECT * FROM fasting_sessions
      WHERE user_id = ? AND state = 'active'
      ORDER BY start_time DESC LIMIT 1;
    ''');

    try {
      final rows = stmt.select([uid]);
      if (rows.isEmpty) return null;
      return FastingSession.fromRow(rows.first);
    } finally {
      stmt.dispose();
    }
  }

  /// Ends an active fasting session.
  void endFast(
    String id, {
    bool completed = true,
    DateTime? endTime,
    String? userId,
  }) {
    final uid = userId ?? effectiveUserId;
    final actualEnd = endTime ?? DateTime.now();
    final stmt = _db.prepare('''
      UPDATE fasting_sessions
      SET state = ?, actual_end_time = ?
      WHERE id = ? AND user_id = ?;
    ''');

    try {
      stmt.execute([completed ? 'completed' : 'broken_early', actualEnd.toIso8601String(), id, uid]);
    } finally {
      stmt.dispose();
    }
  }

  /// Retrieves recent fasting sessions.
  List<FastingSession> getRecentFasts({int limit = 14, String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare('''
      SELECT * FROM fasting_sessions
      WHERE user_id = ?
      ORDER BY start_time DESC LIMIT ?;
    ''');

    try {
      final rows = stmt.select([uid, limit]);
      return rows.map(FastingSession.fromRow).toList();
    } finally {
      stmt.dispose();
    }
  }
}
