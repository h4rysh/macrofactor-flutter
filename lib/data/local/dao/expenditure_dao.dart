import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'package:sique/data/local/app_database_expenditure.dart'
    show ExpenditureRecord;
import 'package:sqlite3/common.dart';

/// Data Access Object managing daily energy expenditure estimates and day completions.
class ExpenditureDao {
  ExpenditureDao(this._db,
      {this.userId = 'default_user', String Function()? userIdProvider})
      : _userIdProvider = userIdProvider;

  final CommonDatabase _db;
  String userId;
  String Function()? _userIdProvider;

  set userIdProvider(String Function()? provider) => _userIdProvider = provider;

  /// Active tenant user id for multi-tenant data scoping.
  String get effectiveUserId =>
      _userIdProvider != null ? _userIdProvider!() : userId;

  /// Saves a single expenditure record scoped to user_id.
  void saveExpenditure(ExpenditureRecord record, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare('''
      INSERT INTO expenditure_history (
        user_id, date, expenditure_kcal, trend_weight_kg, variance, confidence
      ) VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(user_id, date) DO UPDATE SET
        expenditure_kcal = excluded.expenditure_kcal,
        trend_weight_kg = excluded.trend_weight_kg,
        variance = excluded.variance,
        confidence = excluded.confidence;
    ''');
    try {
      stmt.execute([
        uid,
        record.date,
        record.expenditureKcal,
        record.trendWeightKg,
        record.variance,
        record.confidence,
      ]);
    } finally {
      stmt.dispose();
    }
  }

  /// Atomically saves a batch of expenditure records inside a single SQLite transaction scoped to user_id.
  void saveExpenditures(List<ExpenditureRecord> records, {String? userId}) {
    if (records.isEmpty) return;
    final uid = userId ?? effectiveUserId;

    _db.execute('BEGIN TRANSACTION;');
    try {
      final stmt = _db.prepare('''
        INSERT INTO expenditure_history (
          user_id, date, expenditure_kcal, trend_weight_kg, variance, confidence
        ) VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(user_id, date) DO UPDATE SET
          expenditure_kcal = excluded.expenditure_kcal,
          trend_weight_kg = excluded.trend_weight_kg,
          variance = excluded.variance,
          confidence = excluded.confidence;
      ''');
      try {
        for (final record in records) {
          stmt.execute([
            uid,
            record.date,
            record.expenditureKcal,
            record.trendWeightKg,
            record.variance,
            record.confidence,
          ]);
        }
        _db.execute('COMMIT;');
      } finally {
        stmt.dispose();
      }
    } on SqliteException catch (e, st) {
      developer.log(
        'Transaction failed during saveExpenditures; executing rollback',
        name: 'ExpenditureDao',
        error: e,
        stackTrace: st,
      );
      try {
        _db.execute('ROLLBACK;');
      } catch (_) {}
      rethrow;
    }
  }

  /// Retrieves expenditure history ordered chronologically ascending scoped to user_id.
  List<ExpenditureRecord> getExpenditureHistory({
    String? startDate,
    String? endDate,
    String? userId,
  }) {
    final uid = userId ?? effectiveUserId;
    final where = [
      'user_id = ?',
      if (startDate != null) 'date >= ?',
      if (endDate != null) 'date <= ?',
    ];
    final whereClause = 'WHERE ${where.join(' AND ')}';
    final args = [
      uid,
      if (startDate != null) startDate,
      if (endDate != null) endDate,
    ];

    final stmt = _db.prepare('''
      SELECT * FROM expenditure_history
      $whereClause
      ORDER BY date ASC;
    ''');
    try {
      final result = stmt.select(args);
      return result.map(ExpenditureRecord.fromRow).toList();
    } finally {
      stmt.dispose();
    }
  }

  /// Retrieves the expenditure record for a specific date, or null if none saved.
  ExpenditureRecord? getExpenditureForDate(String date, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare('''
      SELECT * FROM expenditure_history WHERE user_id = ? AND date = ? LIMIT 1;
    ''');
    try {
      final result = stmt.select([uid, date]);
      if (result.isEmpty) return null;
      return ExpenditureRecord.fromRow(result.first);
    } finally {
      stmt.dispose();
    }
  }

  /// Retrieves the most recent expenditure record on or before [date].
  ExpenditureRecord? getLatestExpenditureBefore(String date, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare('''
      SELECT * FROM expenditure_history
      WHERE user_id = ? AND date <= ?
      ORDER BY date DESC
      LIMIT 1;
    ''');
    try {
      final result = stmt.select([uid, date]);
      if (result.isEmpty) return null;
      return ExpenditureRecord.fromRow(result.first);
    } finally {
      stmt.dispose();
    }
  }

  /// Deletes expenditure records on or after [date] during forward recomputation.
  void deleteExpendituresFrom(String date, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare('''
      DELETE FROM expenditure_history WHERE user_id = ? AND date >= ?;
    ''');
    try {
      stmt.execute([uid, date]);
    } finally {
      stmt.dispose();
    }
  }

  /// Sets whether the day was complete for food logging scoped to user_id.
  void setDayComplete(String date, bool isComplete, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final stmt = _db.prepare('''
      INSERT INTO day_completions (user_id, date, is_complete, updated_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(user_id, date) DO UPDATE SET
        is_complete = excluded.is_complete,
        updated_at = excluded.updated_at;
    ''');
    try {
      stmt.execute([uid, date, isComplete ? 1 : 0, nowIso]);
    } finally {
      stmt.dispose();
    }
  }

  /// Checks whether a specific day is marked complete.
  /// If not recorded: past days default to true, today defaults to false.
  bool isDayComplete(String date, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare('''
      SELECT is_complete FROM day_completions WHERE user_id = ? AND date = ? LIMIT 1;
    ''');
    try {
      final result = stmt.select([uid, date]);
      if (result.isEmpty) {
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        return date.compareTo(todayStr) < 0;
      }
      return (result.first['is_complete'] as int) == 1;
    } finally {
      stmt.dispose();
    }
  }

  /// Batch retrieves day completion flags, optionally bounded by [startDate, endDate].
  Map<String, bool> getDayCompletions(
      {String? startDate, String? endDate, String? userId}) {
    final uid = userId ?? effectiveUserId;
    final where = [
      'user_id = ?',
      if (startDate != null) 'date >= ?',
      if (endDate != null) 'date <= ?',
    ];
    final whereClause = 'WHERE ${where.join(' AND ')}';
    final args = [
      uid,
      if (startDate != null) startDate,
      if (endDate != null) endDate,
    ];

    final stmt = _db.prepare('''
      SELECT date, is_complete FROM day_completions
      $whereClause
      ORDER BY date ASC;
    ''');
    try {
      final result = stmt.select(args);
      final map = <String, bool>{};
      for (final row in result) {
        map[row['date'] as String] = (row['is_complete'] as int) == 1;
      }
      return map;
    } finally {
      stmt.dispose();
    }
  }
}
