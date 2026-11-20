import 'package:sique/domain/models/scale_weight_entry.dart';
import 'package:sqlite3/common.dart';

/// Data Access Object managing weight logging, source conflict resolution, and multi-tenancy.
class WeightDao {
  WeightDao(this._db,
      {this.userId = 'default_user', String Function()? userIdProvider})
      : _userIdProvider = userIdProvider;

  final CommonDatabase _db;
  String userId;
  String Function()? _userIdProvider;

  set userIdProvider(String Function()? provider) => _userIdProvider = provider;

  /// Active tenant user id for multi-tenant data scoping.
  String get effectiveUserId =>
      _userIdProvider != null ? _userIdProvider!() : userId;

  /// Logs or updates scale weight for a given date with composite (user_id, date) uniqueness.
  void insertWeightLog(
    String date,
    double scaleWeight,
    String? note, {
    String source = 'manual',
    String? userId,
  }) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare('''
      INSERT INTO weight_logs (user_id, date, scale_weight, note, source, logged_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(user_id, date) DO UPDATE SET
        scale_weight = excluded.scale_weight,
        note = excluded.note,
        source = excluded.source,
        logged_at = excluded.logged_at
      WHERE weight_logs.source != 'manual' OR excluded.source = 'manual';
    ''');
    try {
      stmt.execute([
        uid,
        date,
        scaleWeight,
        note,
        source,
        DateTime.now().toIso8601String(),
      ]);
    } finally {
      stmt.dispose();
    }

    // Synchronize user_profile.current_weight to the latest logged scale weight
    _syncUserProfileWeight(userId: uid);
  }

  /// Synchronizes user_profile.current_weight with the most recent scale weight entry.
  void _syncUserProfileWeight({String? userId}) {
    final uid = userId ?? effectiveUserId;
    try {
      final stmt = _db.prepare('''
        UPDATE user_profile
        SET current_weight = (
          SELECT scale_weight FROM weight_logs
          WHERE user_id = ?
          ORDER BY date DESC, logged_at DESC
          LIMIT 1
        )
        WHERE (user_id = ? OR id = ?) AND EXISTS (SELECT 1 FROM weight_logs WHERE user_id = ?);
      ''');
      try {
        stmt.execute([uid, uid, uid, uid]);
      } finally {
        stmt.dispose();
      }
    } catch (_) {}
  }

  /// Convenience method to insert scale weight from DateTime.
  void insertScaleWeight(DateTime date, double weightKg,
      [String? note, String? userId]) {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    insertWeightLog(dateStr, weightKg, note, userId: userId);
  }

  /// Gets scale weights within a date range (YYYY-MM-DD inclusive) scoped to user_id.
  List<ScaleWeightEntry> getScaleWeights(String startDate, String endDate,
      {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare('''
      SELECT date, scale_weight, note FROM weight_logs
      WHERE user_id = ? AND date >= ? AND date <= ?
      ORDER BY date ASC;
    ''');
    try {
      final result = stmt.select([uid, startDate, endDate]);
      return result.map((row) {
        return ScaleWeightEntry(
          date: DateTime.parse(row['date'] as String),
          weightKg: (row['scale_weight'] as num).toDouble(),
          note: row['note'] as String?,
        );
      }).toList();
    } finally {
      stmt.dispose();
    }
  }

  /// Retrieves all weight logs chronologically scoped to user_id.
  List<ScaleWeightEntry> getAllWeightLogs({String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare('''
      SELECT date, scale_weight, note, source FROM weight_logs
      WHERE user_id = ?
      ORDER BY date ASC;
    ''');
    try {
      final result = stmt.select([uid]);
      return result.map((row) {
        return ScaleWeightEntry(
          date: DateTime.parse(row['date'] as String),
          weightKg: (row['scale_weight'] as num).toDouble(),
          note: row['note'] as String?,
        );
      }).toList();
    } finally {
      stmt.dispose();
    }
  }

  /// Retrieves the single weight log entry for a specific date (YYYY-MM-DD) scoped to user_id.
  ScaleWeightEntry? getWeightLogForDate(String date, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare('''
      SELECT date, scale_weight, note FROM weight_logs
      WHERE user_id = ? AND date = ?
      LIMIT 1;
    ''');
    try {
      final result = stmt.select([uid, date]);
      if (result.isEmpty) return null;

      final row = result.first;
      return ScaleWeightEntry(
        date: DateTime.parse(row['date'] as String),
        weightKg: (row['scale_weight'] as num).toDouble(),
        note: row['note'] as String?,
      );
    } finally {
      stmt.dispose();
    }
  }

  /// Retrieves recent weight entries up to limit scoped to user_id.
  List<ScaleWeightEntry> getWeightEntries({int limit = 90, String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare('''
      SELECT date, scale_weight, note FROM weight_logs
      WHERE user_id = ?
      ORDER BY date DESC
      LIMIT ?;
    ''');
    try {
      final result = stmt.select([uid, limit]);
      return result
          .map((row) => ScaleWeightEntry(
                date: DateTime.parse(row['date'] as String),
                weightKg: (row['scale_weight'] as num).toDouble(),
                note: row['note'] as String?,
              ))
          .toList();
    } finally {
      stmt.dispose();
    }
  }

  /// Deletes weight log by date scoped to user_id.
  void deleteWeightLogForDate(String date, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt =
        _db.prepare('DELETE FROM weight_logs WHERE user_id = ? AND date = ?;');
    try {
      stmt.execute([uid, date]);
    } finally {
      stmt.dispose();
    }
    _syncUserProfileWeight(userId: uid);
  }
}
