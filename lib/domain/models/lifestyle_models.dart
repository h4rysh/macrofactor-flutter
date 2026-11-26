import 'package:flutter/foundation.dart';
import 'package:sqlite3/common.dart';

/// Represents a single water intake log.
@immutable
class WaterLog {
  const WaterLog({
    this.id,
    this.userId = 'default_user',
    required this.date,
    required this.amountMl,
    required this.loggedAt,
  });

  final int? id;
  final String userId;
  final String date; // YYYY-MM-DD
  final int amountMl;
  final DateTime loggedAt;

  factory WaterLog.fromRow(Row row) {
    return WaterLog(
      id: row['id'] as int?,
      userId: row['user_id'] as String? ?? 'default_user',
      date: row['date'] as String,
      amountMl: row['amount_ml'] as int,
      loggedAt: DateTime.parse(row['logged_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'date': date,
        'amount_ml': amountMl,
        'logged_at': loggedAt.toIso8601String(),
      };
}

/// Protocols for intermittent fasting.
enum FastingProtocol {
  f16_8('16:8 Fast', 16, 8),
  f14_10('14:10 Fast', 14, 10),
  f18_6('18:6 Fast', 18, 6),
  f20_4('20:4 Warrior', 20, 4),
  custom('Custom Fast', 16, 8);

  const FastingProtocol(this.displayName, this.fastHours, this.feedHours);
  final String displayName;
  final int fastHours;
  final int feedHours;

  static FastingProtocol fromString(String val) {
    return FastingProtocol.values.firstWhere(
      (p) => p.name.toLowerCase() == val.toLowerCase(),
      orElse: () => FastingProtocol.f16_8,
    );
  }
}

/// Biological stages of fasting progression.
enum FastingStage {
  anabolic('Digesting & Nutrient Absorption', 0, 4,
      'Blood sugar and insulin levels normalize.'),
  postAbsorptive(
      'Blood Sugar Drop', 4, 12, 'Glycogen breakdown begins; insulin drops.'),
  ketosis('Fat Burning & Ketosis', 12, 18,
      'Liver starts converting fat stores into ketones.'),
  autophagy('Cellular Autophagy', 18, 24,
      'Cellular cleanup and deep biological repair begin.');

  const FastingStage(
      this.title, this.startHour, this.endHour, this.description);
  final String title;
  final int startHour;
  final int endHour;
  final String description;

  static FastingStage fromHoursElapsed(double hours) {
    if (hours < 4.0) return FastingStage.anabolic;
    if (hours < 12.0) return FastingStage.postAbsorptive;
    if (hours < 18.0) return FastingStage.ketosis;
    return FastingStage.autophagy;
  }
}

/// Represents an active or historical intermittent fasting session.
@immutable
class FastingSession {
  const FastingSession({
    required this.id,
    this.userId = 'default_user',
    required this.protocol,
    required this.startTime,
    required this.targetEndTime,
    this.actualEndTime,
    this.state = 'active', // 'active', 'completed', 'broken_early'
    this.notes,
  });

  final String id;
  final String userId;
  final FastingProtocol protocol;
  final DateTime startTime;
  final DateTime targetEndTime;
  final DateTime? actualEndTime;
  final String state;
  final String? notes;

  bool get isActive => state == 'active';
  bool get isCompleted => state == 'completed';

  Duration get targetDuration => targetEndTime.difference(startTime);

  Duration get elapsedDuration {
    final end = actualEndTime ?? DateTime.now();
    return end.isAfter(startTime) ? end.difference(startTime) : Duration.zero;
  }

  double get elapsedHours => elapsedDuration.inMinutes / 60.0;

  double get progressFraction {
    final totalMin = targetDuration.inMinutes;
    if (totalMin <= 0) return 1.0;
    final elapsedMin = elapsedDuration.inMinutes;
    return (elapsedMin / totalMin).clamp(0.0, 1.0);
  }

  FastingStage get currentStage => FastingStage.fromHoursElapsed(elapsedHours);

  factory FastingSession.fromRow(Row row) {
    return FastingSession(
      id: row['id'] as String,
      userId: row['user_id'] as String? ?? 'default_user',
      protocol: FastingProtocol.fromString(row['protocol'] as String),
      startTime: DateTime.parse(row['start_time'] as String),
      targetEndTime: DateTime.parse(row['target_end_time'] as String),
      actualEndTime: row['actual_end_time'] != null
          ? DateTime.parse(row['actual_end_time'] as String)
          : null,
      state: row['state'] as String? ?? 'active',
      notes: row['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'protocol': protocol.name,
        'start_time': startTime.toIso8601String(),
        'target_end_time': targetEndTime.toIso8601String(),
        'actual_end_time': actualEndTime?.toIso8601String(),
        'state': state,
        'notes': notes,
      };
}
