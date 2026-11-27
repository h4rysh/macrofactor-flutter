import 'package:sqlite3/common.dart';

class RepeatItemRecord {
  const RepeatItemRecord({
    required this.id,
    this.userId = 'default_user',
    required this.foodId,
    required this.foodName,
    required this.mealType,
    required this.hour,
    required this.servingQuantity,
    required this.unitName,
    required this.gramWeight,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    this.activeDaysMask = 127,
    this.isActive = true,
    this.lastLoggedDate,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final int foodId;
  final String foodName;
  final String mealType;
  final int hour;
  final double servingQuantity;
  final String unitName;
  final double gramWeight;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final int activeDaysMask;
  final bool isActive;
  final String? lastLoggedDate;
  final String createdAt;

  bool isScheduledForWeekday(int weekday) {
    // weekday: 1 (Mon) .. 7 (Sun) -> bit 0 .. 6
    final bit = 1 << ((weekday - 1).clamp(0, 6));
    return (activeDaysMask & bit) != 0;
  }

  factory RepeatItemRecord.fromRow(Row row) {
    return RepeatItemRecord(
      id: row['id'] as String,
      userId: (row['user_id'] as String?) ?? 'default_user',
      foodId: (row['food_id'] as num).toInt(),
      foodName: row['food_name'] as String,
      mealType: row['meal_type'] as String,
      hour: (row['hour'] as num).toInt(),
      servingQuantity: (row['serving_quantity'] as num).toDouble(),
      unitName: row['unit_name'] as String,
      gramWeight: (row['gram_weight'] as num).toDouble(),
      calories: (row['calories'] as num).toDouble(),
      protein: (row['protein'] as num).toDouble(),
      carbs: (row['carbs'] as num).toDouble(),
      fat: (row['fat'] as num).toDouble(),
      fiber: (row['fiber'] as num).toDouble(),
      activeDaysMask: (row['active_days_mask'] as num?)?.toInt() ?? 127,
      isActive: ((row['is_active'] as num?)?.toInt() ?? 1) == 1,
      lastLoggedDate: row['last_logged_date'] as String?,
      createdAt: row['created_at'] as String,
    );
  }
}

/// DAO managing Schema v7 Diary Power-Tools: repeat_items, day_notes, micro_goals.
class DiaryToolsDao {
  DiaryToolsDao(
    this._db, {
    this.userId = 'default_user',
    String Function()? userIdProvider,
  }) : _userIdProvider = userIdProvider;

  final CommonDatabase _db;
  String userId;
  String Function()? _userIdProvider;

  set userIdProvider(String Function()? provider) => _userIdProvider = provider;

  String get effectiveUserId =>
      _userIdProvider != null ? _userIdProvider!() : userId;

  // --- Repeat Items ---

  void upsertRepeatItem(RepeatItemRecord item, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare('''
      INSERT INTO repeat_items (
        id, user_id, food_id, food_name, meal_type, hour, serving_quantity,
        unit_name, gram_weight, calories, protein, carbs, fat, fiber,
        active_days_mask, is_active, last_logged_date, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        food_id = excluded.food_id,
        food_name = excluded.food_name,
        meal_type = excluded.meal_type,
        hour = excluded.hour,
        serving_quantity = excluded.serving_quantity,
        unit_name = excluded.unit_name,
        gram_weight = excluded.gram_weight,
        calories = excluded.calories,
        protein = excluded.protein,
        carbs = excluded.carbs,
        fat = excluded.fat,
        fiber = excluded.fiber,
        active_days_mask = excluded.active_days_mask,
        is_active = excluded.is_active,
        last_logged_date = excluded.last_logged_date
      WHERE repeat_items.user_id = excluded.user_id;
    ''');
    try {
      stmt.execute([
        item.id,
        uid,
        item.foodId,
        item.foodName,
        item.mealType,
        item.hour,
        item.servingQuantity,
        item.unitName,
        item.gramWeight,
        item.calories,
        item.protein,
        item.carbs,
        item.fat,
        item.fiber,
        item.activeDaysMask,
        item.isActive ? 1 : 0,
        item.lastLoggedDate,
        item.createdAt,
      ]);
    } finally {
      stmt.dispose();
    }
  }

  List<RepeatItemRecord> getPendingRepeatItemsForDate(
    DateTime date, {
    String? userId,
  }) {
    final uid = userId ?? effectiveUserId;
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final stmt = _db.prepare('''
      SELECT * FROM repeat_items
      WHERE user_id = ? AND is_active = 1
        AND (last_logged_date IS NULL OR last_logged_date != ?)
      ORDER BY hour ASC;
    ''');
    try {
      return stmt
          .select([uid, dateStr])
          .map(RepeatItemRecord.fromRow)
          .where((r) => r.isScheduledForWeekday(date.weekday))
          .toList();
    } finally {
      stmt.dispose();
    }
  }

  void markRepeatItemLogged(String id, String dateStr, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare(
      'UPDATE repeat_items SET last_logged_date = ? WHERE id = ? AND user_id = ?;',
    );
    try {
      stmt.execute([dateStr, id, uid]);
    } finally {
      stmt.dispose();
    }
  }

  void deleteRepeatItem(String id, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare(
      'DELETE FROM repeat_items WHERE id = ? AND user_id = ?;',
    );
    try {
      stmt.execute([id, uid]);
    } finally {
      stmt.dispose();
    }
  }

  List<RepeatItemRecord> getAllRepeatItems({String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare(
      'SELECT * FROM repeat_items WHERE user_id = ? ORDER BY hour ASC, created_at ASC;',
    );
    try {
      return stmt.select([uid]).map(RepeatItemRecord.fromRow).toList();
    } finally {
      stmt.dispose();
    }
  }

  // --- Day Notes ---

  Map<String, String> getAllDayNotes({String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare(
      'SELECT date, note FROM day_notes WHERE user_id = ? ORDER BY date ASC;',
    );
    try {
      final out = <String, String>{};
      for (final row in stmt.select([uid])) {
        final date = row['date'] as String?;
        final note = row['note'] as String?;
        if (date != null && note != null && note.isNotEmpty) {
          out[date] = note;
        }
      }
      return out;
    } finally {
      stmt.dispose();
    }
  }

  String? getDayNote(String dateStr, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare(
      'SELECT note FROM day_notes WHERE user_id = ? AND date = ? LIMIT 1;',
    );
    try {
      final rows = stmt.select([uid, dateStr]);
      if (rows.isEmpty) return null;
      return rows.first['note'] as String?;
    } finally {
      stmt.dispose();
    }
  }

  void saveDayNote(String dateStr, String note, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      final del = _db.prepare(
        'DELETE FROM day_notes WHERE user_id = ? AND date = ?;',
      );
      try {
        del.execute([uid, dateStr]);
      } finally {
        del.dispose();
      }
      return;
    }
    final stmt = _db.prepare('''
      INSERT INTO day_notes (user_id, date, note, updated_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(user_id, date) DO UPDATE SET
        note = excluded.note,
        updated_at = excluded.updated_at;
    ''');
    try {
      stmt.execute([uid, dateStr, trimmed, DateTime.now().toIso8601String()]);
    } finally {
      stmt.dispose();
    }
  }

  // --- Custom Micro Goals ---

  Map<int, double> getCustomMicroGoals({String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare(
      'SELECT nutrient_id, custom_target FROM micro_goals WHERE user_id = ?;',
    );
    try {
      final out = <int, double>{};
      for (final row in stmt.select([uid])) {
        out[(row['nutrient_id'] as num).toInt()] =
            (row['custom_target'] as num).toDouble();
      }
      return out;
    } finally {
      stmt.dispose();
    }
  }

  void setCustomMicroGoal(int nutrientId, double target, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare('''
      INSERT INTO micro_goals (user_id, nutrient_id, custom_target, updated_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(user_id, nutrient_id) DO UPDATE SET
        custom_target = excluded.custom_target,
        updated_at = excluded.updated_at;
    ''');
    try {
      stmt.execute([uid, nutrientId, target, DateTime.now().toIso8601String()]);
    } finally {
      stmt.dispose();
    }
  }

  void deleteCustomMicroGoal(int nutrientId, {String? userId}) {
    final uid = userId ?? effectiveUserId;
    final stmt = _db.prepare(
      'DELETE FROM micro_goals WHERE user_id = ? AND nutrient_id = ?;',
    );
    try {
      stmt.execute([uid, nutrientId]);
    } finally {
      stmt.dispose();
    }
  }
}
