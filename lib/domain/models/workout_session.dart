import 'package:flutter/foundation.dart';

/// Predefined sources for workout sessions.
class WorkoutSource {
  static const String hevy = 'hevy';
  static const String healthConnect = 'health_connect';
  static const String manual = 'manual';
}

/// Represents an exercise or training session imported from Hevy, Google Health Connect, or logged manually.
@immutable
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.source,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.caloriesBurned,
    this.notes,
    required this.createdAt,
  });

  /// Unique session identifier (UUID from Health Connect, Hevy ID, or generated string).
  final String id;

  /// Source provenance (e.g., 'hevy', 'health_connect', 'manual').
  final String source;

  /// Workout name or activity type (e.g. "Upper Body A - Chest & Triceps", "Strength Training").
  final String title;

  /// Start timestamp of the workout.
  final DateTime startTime;

  /// End timestamp of the workout.
  final DateTime endTime;

  /// Total duration in active training minutes.
  final int durationMinutes;

  /// Estimated or recorded active calories burned in kcal.
  final double caloriesBurned;

  /// Optional session notes or details.
  final String? notes;

  /// Timestamp when this record was saved to the local database.
  final DateTime createdAt;

  /// Whether this workout originated from the Hevy app.
  bool get isHevy => source.toLowerCase().contains('hevy');

  /// Whether this workout originated from Google Health Connect.
  bool get isHealthConnect => source.toLowerCase().contains('health_connect');

  /// Computed actual duration difference.
  Duration get duration => endTime.difference(startTime);

  /// Formatted duration string (e.g. "1h 15m" or "45m").
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours > 0) {
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${mins}m';
  }

  /// Maps SQLite row map to WorkoutSession.
  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'] as String,
      source: map['source'] as String? ?? WorkoutSource.healthConnect,
      title: map['title'] as String? ?? 'Workout',
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 0,
      caloriesBurned: (map['calories_burned'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Converts WorkoutSession to SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source': source,
      'title': title,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'calories_burned': caloriesBurned,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy with modified fields.
  WorkoutSession copyWith({
    String? id,
    String? source,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    double? caloriesBurned,
    String? notes,
    DateTime? createdAt,
    bool clearNotes = false,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      source: source ?? this.source,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          source == other.source &&
          title == other.title &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          durationMinutes == other.durationMinutes &&
          caloriesBurned == other.caloriesBurned &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(
        id,
        source,
        title,
        startTime,
        endTime,
        durationMinutes,
        caloriesBurned,
        notes,
      );

  @override
  String toString() =>
      'WorkoutSession(id: $id, title: "$title", source: $source, duration: ${durationMinutes}m, cals: $caloriesBurned kcal)';
}
