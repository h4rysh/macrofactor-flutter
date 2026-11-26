import 'dart:convert';
import 'dart:developer' as developer;
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sqlite3/sqlite3.dart';

/// Extension on [AppDatabase] providing persistence for Sique coaching programs
/// and weekly metabolic check-in records.
extension AppDatabaseCoachingExtension on AppDatabase {
  static const String _activeProgramKey = 'active_coaching_program';

  /// Saves the active WeeklyMacroProgram as serialized JSON in app_settings.
  void saveCoachingProgram(WeeklyMacroProgram program) {
    final jsonStr = jsonEncode(program.toJson());
    setSetting(_activeProgramKey, jsonStr);
  }

  /// Retrieves the persisted active WeeklyMacroProgram, or null if none saved.
  WeeklyMacroProgram? getCoachingProgram() {
    final jsonStr = getSetting(_activeProgramKey, '');
    if (jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return WeeklyMacroProgram.fromJson(map);
    } on FormatException catch (e, st) {
      developer.log(
        'Malformed coaching program JSON',
        name: 'AppDatabaseCoaching',
        error: e,
        stackTrace: st,
      );
      return null;
    } on TypeError catch (e, st) {
      developer.log(
        'Coaching program JSON schema mismatch',
        name: 'AppDatabaseCoaching',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Inserts a new coaching check-in record scoped to user_id.
  void insertCoachingCheckIn(CoachingCheckIn checkIn, {String? userId}) {
    final uid = userId ?? currentUserId;
    final stmt = rawDb.prepare('''
      INSERT INTO coaching_check_ins (
        id, user_id, check_in_date, previous_calories, recommended_calories,
        expenditure_kcal, weight_trend_kg, is_accepted, status_note, created_at,
        raw_calorie_delta, damped_calorie_delta, was_clamped, silent_recomp_detected
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        user_id = excluded.user_id,
        previous_calories = excluded.previous_calories,
        recommended_calories = excluded.recommended_calories,
        expenditure_kcal = excluded.expenditure_kcal,
        weight_trend_kg = excluded.weight_trend_kg,
        is_accepted = excluded.is_accepted,
        status_note = excluded.status_note,
        raw_calorie_delta = excluded.raw_calorie_delta,
        damped_calorie_delta = excluded.damped_calorie_delta,
        was_clamped = excluded.was_clamped,
        silent_recomp_detected = excluded.silent_recomp_detected;
    ''');

    try {
      stmt.execute([
        checkIn.id,
        uid,
        checkIn.checkInDate.toIso8601String(),
        checkIn.previousCalories,
        checkIn.recommendedCalories,
        checkIn.expenditureKcal,
        checkIn.weightTrendKg,
        checkIn.isAccepted ? 1 : 0,
        checkIn.statusNote,
        checkIn.createdAt.toIso8601String(),
        checkIn.rawCalorieDelta,
        checkIn.dampedCalorieDelta,
        checkIn.wasClamped ? 1 : 0,
        checkIn.silentRecompDetected ? 1 : 0,
      ]);
    } finally {
      stmt.dispose();
    }
  }

  /// Retrieves all historical coaching check-ins ordered chronologically descending, scoped to user_id.
  List<CoachingCheckIn> getCoachingCheckIns({String? userId}) {
    final uid = userId ?? currentUserId;
    final stmt = rawDb.prepare('''
      SELECT * FROM coaching_check_ins
      WHERE user_id = ?
      ORDER BY check_in_date DESC, created_at DESC;
    ''');
    final ResultSet result;
    try {
      result = stmt.select([uid]);
    } finally {
      stmt.dispose();
    }

    return result.map((row) {
      return CoachingCheckIn(
        id: row['id'] as String,
        checkInDate: DateTime.parse(row['check_in_date'] as String),
        previousCalories: (row['previous_calories'] as num).toDouble(),
        recommendedCalories: (row['recommended_calories'] as num).toDouble(),
        expenditureKcal: (row['expenditure_kcal'] as num).toDouble(),
        weightTrendKg: (row['weight_trend_kg'] as num).toDouble(),
        isAccepted: (row['is_accepted'] as int) == 1,
        statusNote: row['status_note'] as String? ?? '',
        createdAt: DateTime.parse(row['created_at'] as String),
        rawCalorieDelta: (row['raw_calorie_delta'] as num?)?.toDouble(),
        dampedCalorieDelta: (row['damped_calorie_delta'] as num?)?.toDouble(),
        wasClamped: (row['was_clamped'] as int? ?? 0) == 1,
        silentRecompDetected: (row['silent_recomp_detected'] as int? ?? 0) == 1,
      );
    }).toList();
  }
}
