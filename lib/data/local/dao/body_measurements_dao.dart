import 'package:sique/domain/models/body_measurement_entry.dart';
import 'package:sqlite3/common.dart';

/// Data Access Object managing anthropometric body measurements with tenant scoping.
class BodyMeasurementsDao {
  BodyMeasurementsDao(
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

  /// Inserts or updates body measurements for a specific date.
  void upsertMeasurement(BodyMeasurementEntry entry, {String? userId}) {
    final uid = userId ??
        (effectiveUserId != 'default_user'
            ? effectiveUserId
            : (entry.userId.isNotEmpty ? entry.userId : 'default_user'));
    final stmt = _db.prepare('''
      INSERT INTO body_measurements (
        id, user_id, date, waist_cm, hips_cm, chest_cm, neck_cm,
        biceps_cm, thigh_cm, body_fat_pct, source, notes, logged_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(user_id, date) DO UPDATE SET
        waist_cm = excluded.waist_cm,
        hips_cm = excluded.hips_cm,
        chest_cm = excluded.chest_cm,
        neck_cm = excluded.neck_cm,
        biceps_cm = excluded.biceps_cm,
        thigh_cm = excluded.thigh_cm,
        body_fat_pct = excluded.body_fat_pct,
        source = excluded.source,
        notes = excluded.notes,
        logged_at = excluded.logged_at;
    ''');

    try {
      stmt.execute([
        entry.id,
        uid,
        entry.dateString,
        entry.waistCm,
        entry.hipsCm,
        entry.chestCm,
        entry.neckCm,
        entry.bicepsCm,
        entry.thighCm,
        entry.bodyFatPct,
        entry.source,
        entry.notes,
        entry.loggedAt.toIso8601String(),
      ]);
    } finally {
      stmt.dispose();
    }
  }

  /// Retrieves measurement for a specific date, or null if unlogged.
  BodyMeasurementEntry? getMeasurementForDate(DateTime date, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final stmt = _db.prepare(
      'SELECT * FROM body_measurements WHERE user_id = ? AND date = ? LIMIT 1;',
    );

    try {
      final rows = stmt.select([uid, dateStr]);
      if (rows.isEmpty) return null;
      return BodyMeasurementEntry.fromRow(rows.first);
    } finally {
      stmt.dispose();
    }
  }

  /// Retrieves recent measurements chronologically descending (newest first).
  List<BodyMeasurementEntry> getRecentMeasurements({
    int limit = 90,
    String? userId,
  }) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare(
      'SELECT * FROM body_measurements WHERE user_id = ? ORDER BY date DESC LIMIT ?;',
    );

    try {
      final rows = stmt.select([uid, limit]);
      return rows.map(BodyMeasurementEntry.fromRow).toList();
    } finally {
      stmt.dispose();
    }
  }

  /// Deletes a measurement by entry id.
  void deleteMeasurement(String id, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare(
      'DELETE FROM body_measurements WHERE id = ? AND user_id = ?;',
    );

    try {
      stmt.execute([id, uid]);
    } finally {
      stmt.dispose();
    }
  }
}
