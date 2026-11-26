import 'package:sique/domain/models/lifestyle_models.dart';
import 'package:sqlite3/common.dart';

/// Data Access Object managing hydration tracking with multi-tenant data scoping.
class WaterDao {
  WaterDao(
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

  /// Logs a water entry in ml.
  void logWater(
    int amountMl, {
    DateTime? date,
    DateTime? loggedAt,
    String? userId,
  }) {
    if (amountMl <= 0 || amountMl > 10000) return;
    final uid = userId ?? effectiveUserId;
    final now = loggedAt ?? DateTime.now();
    final effectiveDate = date ?? now;
    final dateStr =
        '${effectiveDate.year.toString().padLeft(4, '0')}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.day.toString().padLeft(2, '0')}';

    final stmt = _db.prepare('''
      INSERT INTO water_logs (user_id, date, amount_ml, logged_at)
      VALUES (?, ?, ?, ?);
    ''');

    try {
      stmt.execute([uid, dateStr, amountMl, now.toIso8601String()]);
    } finally {
      stmt.dispose();
    }
  }

  /// Calculates total water logged in ml for a given calendar date.
  int getDailyWaterMl(DateTime date, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final stmt = _db.prepare('''
      SELECT SUM(amount_ml) AS total_ml
      FROM water_logs
      WHERE user_id = ? AND date = ?;
    ''');

    try {
      final rows = stmt.select([uid, dateStr]);
      if (rows.isEmpty || rows.first['total_ml'] == null) return 0;
      return (rows.first['total_ml'] as num).toInt();
    } finally {
      stmt.dispose();
    }
  }

  /// Retrieves list of raw water entries for a date.
  List<WaterLog> getWaterEntriesForDate(DateTime date, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final stmt = _db.prepare('''
      SELECT * FROM water_logs
      WHERE user_id = ? AND date = ?
      ORDER BY logged_at ASC;
    ''');

    try {
      final rows = stmt.select([uid, dateStr]);
      return rows.map(WaterLog.fromRow).toList();
    } finally {
      stmt.dispose();
    }
  }

  /// Retrieves all water logs for the tenant ordered chronologically.
  List<WaterLog> getAllWaterLogs({int limit = 2000, String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare('''
      SELECT * FROM water_logs
      WHERE user_id = ?
      ORDER BY date ASC, logged_at ASC
      LIMIT ?;
    ''');

    try {
      final rows = stmt.select([uid, limit]);
      return rows.map(WaterLog.fromRow).toList();
    } finally {
      stmt.dispose();
    }
  }

  /// Clears all water logs for a specific date (for undo / reset).
  void clearDayWater(DateTime date, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final stmt = _db.prepare('''
      DELETE FROM water_logs WHERE user_id = ? AND date = ?;
    ''');

    try {
      stmt.execute([uid, dateStr]);
    } finally {
      stmt.dispose();
    }
  }
}
