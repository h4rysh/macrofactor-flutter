import 'package:sique/domain/models/scale_weight_entry.dart';
import 'package:sqlite3/common.dart';

/// Data Access Object managing weight logging and source conflict resolution.
class WeightDao {
  WeightDao(this._db);

  final CommonDatabase _db;

  /// Logs or updates scale weight for a given date with source sovereignty.
  void insertWeightLog(
    String date,
    double scaleWeight,
    String? note, {
    String source = 'manual',
  }) {
    final stmt = _db.prepare('''
      INSERT INTO weight_logs (date, scale_weight, note, source, logged_at)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(date) DO UPDATE SET
        scale_weight = excluded.scale_weight,
        note = excluded.note,
        source = excluded.source,
        logged_at = excluded.logged_at
      WHERE weight_logs.source != 'manual' OR excluded.source = 'manual';
    ''');
    stmt.execute([
      date,
      scaleWeight,
      note,
      source,
      DateTime.now().toIso8601String(),
    ]);
    stmt.dispose();
  }

  /// Convenience method to insert scale weight from DateTime.
  void insertScaleWeight(DateTime date, double weightKg, [String? note]) {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    insertWeightLog(dateStr, weightKg, note);
  }

  /// Gets scale weights within a date range (YYYY-MM-DD inclusive).
  List<ScaleWeightEntry> getScaleWeights(String startDate, String endDate) {
    final stmt = _db.prepare('''
      SELECT date, scale_weight, note FROM weight_logs
      WHERE date >= ? AND date <= ?
      ORDER BY date ASC;
    ''');
    final result = stmt.select([startDate, endDate]);
    stmt.dispose();
    return result.map((row) {
      return ScaleWeightEntry(
        date: DateTime.parse(row['date'] as String),
        weightKg: (row['scale_weight'] as num).toDouble(),
        note: row['note'] as String?,
      );
    }).toList();
  }

  /// Retrieves all weight logs chronologically.
  List<ScaleWeightEntry> getAllWeightLogs() {
    final stmt = _db.prepare('''
      SELECT date, scale_weight, note, source FROM weight_logs ORDER BY date ASC;
    ''');
    final result = stmt.select();
    stmt.dispose();
    return result.map((row) {
      return ScaleWeightEntry(
        date: DateTime.parse(row['date'] as String),
        weightKg: (row['scale_weight'] as num).toDouble(),
        note: row['note'] as String?,
      );
    }).toList();
  }

  /// Retrieves the single weight log entry for a specific date (YYYY-MM-DD), or null.
  ScaleWeightEntry? getWeightLogForDate(String date) {
    final stmt = _db.prepare('''
      SELECT date, scale_weight, note FROM weight_logs
      WHERE date = ?
      LIMIT 1;
    ''');
    final result = stmt.select([date]);
    stmt.dispose();
    if (result.isEmpty) return null;

    final row = result.first;
    return ScaleWeightEntry(
      date: DateTime.parse(row['date'] as String),
      weightKg: (row['scale_weight'] as num).toDouble(),
      note: row['note'] as String?,
    );
  }

  /// Retrieves recent weight entries up to limit.
  List<ScaleWeightEntry> getWeightEntries({int limit = 90}) {
    final stmt = _db.prepare('''
      SELECT date, scale_weight, note FROM weight_logs
      ORDER BY date DESC
      LIMIT ?;
    ''');
    final result = stmt.select([limit]);
    stmt.dispose();
    return result
        .map((row) => ScaleWeightEntry(
              date: DateTime.parse(row['date'] as String),
              weightKg: (row['scale_weight'] as num).toDouble(),
              note: row['note'] as String?,
            ))
        .toList();
  }

  /// Deletes weight log by date.
  void deleteWeightLogForDate(String date) {
    final stmt = _db.prepare('DELETE FROM weight_logs WHERE date = ?;');
    stmt.execute([date]);
    stmt.dispose();
  }
}
