import 'package:intl/intl.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/algorithms/expenditure_kalman_v4.dart';

/// Persisted record representing estimated energy expenditure and true trend weight.
class ExpenditureRecord {
  const ExpenditureRecord({
    required this.date,
    required this.expenditureKcal,
    required this.trendWeightKg,
    required this.variance,
    required this.confidence,
  });

  /// Calendar date string 'YYYY-MM-DD'.
  final String date;

  /// Estimated daily energy expenditure in kcal/day.
  final double expenditureKcal;

  /// Latent true trend weight in kg.
  final double trendWeightKg;

  /// Posterior expenditure variance P_EE.
  final double variance;

  /// Normalized confidence score [0.0, 1.0].
  final double confidence;

  Map<String, dynamic> toMap() => {
        'date': date,
        'expenditure_kcal': expenditureKcal,
        'trend_weight_kg': trendWeightKg,
        'variance': variance,
        'confidence': confidence,
      };

  factory ExpenditureRecord.fromRow(Row row) {
    return ExpenditureRecord(
      date: row['date'] as String,
      expenditureKcal: (row['expenditure_kcal'] as num).toDouble(),
      trendWeightKg: (row['trend_weight_kg'] as num).toDouble(),
      variance: (row['variance'] as num).toDouble(),
      confidence: (row['confidence'] as num).toDouble(),
    );
  }

  factory ExpenditureRecord.fromState(ExpenditureState state) {
    return ExpenditureRecord(
      date: DateFormat('yyyy-MM-dd').format(state.date),
      expenditureKcal: state.expenditureKcal,
      trendWeightKg: state.trendWeightKg,
      variance: state.variance,
      confidence: state.confidence,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenditureRecord &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          expenditureKcal == other.expenditureKcal &&
          trendWeightKg == other.trendWeightKg &&
          variance == other.variance &&
          confidence == other.confidence;

  @override
  int get hashCode =>
      date.hashCode ^
      expenditureKcal.hashCode ^
      trendWeightKg.hashCode ^
      variance.hashCode ^
      confidence.hashCode;
}

/// Extension on [AppDatabase] providing persistence for daily expenditure history
/// and logging day completion flags.
extension AppDatabaseExpenditureExtension on AppDatabase {
  /// Saves a single expenditure record.
  void saveExpenditure(ExpenditureRecord record) {
    final stmt = rawDb.prepare('''
      INSERT INTO expenditure_history (
        date, expenditure_kcal, trend_weight_kg, variance, confidence
      ) VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(date) DO UPDATE SET
        expenditure_kcal = excluded.expenditure_kcal,
        trend_weight_kg = excluded.trend_weight_kg,
        variance = excluded.variance,
        confidence = excluded.confidence;
    ''');
    try {
      stmt.execute([
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

  /// Atomically saves a batch of expenditure records inside a single SQLite transaction.
  void saveExpenditures(List<ExpenditureRecord> records) {
    if (records.isEmpty) return;

    rawDb.execute('BEGIN TRANSACTION;');
    try {
      final stmt = rawDb.prepare('''
        INSERT INTO expenditure_history (
          date, expenditure_kcal, trend_weight_kg, variance, confidence
        ) VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(date) DO UPDATE SET
          expenditure_kcal = excluded.expenditure_kcal,
          trend_weight_kg = excluded.trend_weight_kg,
          variance = excluded.variance,
          confidence = excluded.confidence;
      ''');

      for (final record in records) {
        stmt.execute([
          record.date,
          record.expenditureKcal,
          record.trendWeightKg,
          record.variance,
          record.confidence,
        ]);
      }
      stmt.dispose();
      rawDb.execute('COMMIT;');
    } catch (e) {
      rawDb.execute('ROLLBACK;');
      rethrow;
    }
  }

  /// Retrieves expenditure history ordered chronologically ascending.
  List<ExpenditureRecord> getExpenditureHistory({
    String? startDate,
    String? endDate,
  }) {
    final where = [
      if (startDate != null) 'date >= ?',
      if (endDate != null) 'date <= ?',
    ];
    final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';
    final args = [
      if (startDate != null) startDate,
      if (endDate != null) endDate,
    ];

    final stmt = rawDb.prepare('''
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
  ExpenditureRecord? getExpenditureForDate(String date) {
    final stmt = rawDb.prepare('''
      SELECT * FROM expenditure_history WHERE date = ? LIMIT 1;
    ''');
    try {
      final result = stmt.select([date]);
      if (result.isEmpty) return null;
      return ExpenditureRecord.fromRow(result.first);
    } finally {
      stmt.dispose();
    }
  }

  /// Retrieves the most recent expenditure record on or before [date].
  ExpenditureRecord? getLatestExpenditureBefore(String date) {
    final stmt = rawDb.prepare('''
      SELECT * FROM expenditure_history
      WHERE date <= ?
      ORDER BY date DESC
      LIMIT 1;
    ''');
    try {
      final result = stmt.select([date]);
      if (result.isEmpty) return null;
      return ExpenditureRecord.fromRow(result.first);
    } finally {
      stmt.dispose();
    }
  }

  /// Deletes expenditure records on or after [date] during forward recomputation.
  void deleteExpendituresFrom(String date) {
    final stmt = rawDb.prepare('''
      DELETE FROM expenditure_history WHERE date >= ?;
    ''');
    try {
      stmt.execute([date]);
    } finally {
      stmt.dispose();
    }
  }

  /// Sets whether the day was complete for food logging.
  void setDayComplete(String date, bool isComplete) {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final stmt = rawDb.prepare('''
      INSERT INTO day_completions (date, is_complete, updated_at)
      VALUES (?, ?, ?)
      ON CONFLICT(date) DO UPDATE SET
        is_complete = excluded.is_complete,
        updated_at = excluded.updated_at;
    ''');
    try {
      stmt.execute([date, isComplete ? 1 : 0, nowIso]);
    } finally {
      stmt.dispose();
    }
  }

  /// Checks whether a specific day is marked complete.
  /// If not recorded: past days default to true, today defaults to false.
  bool isDayComplete(String date) {
    final stmt = rawDb.prepare('''
      SELECT is_complete FROM day_completions WHERE date = ? LIMIT 1;
    ''');
    try {
      final result = stmt.select([date]);
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
  Map<String, bool> getDayCompletions({String? startDate, String? endDate}) {
    final where = [
      if (startDate != null) 'date >= ?',
      if (endDate != null) 'date <= ?',
    ];
    final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';
    final args = [
      if (startDate != null) startDate,
      if (endDate != null) endDate,
    ];

    final stmt = rawDb.prepare('''
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
