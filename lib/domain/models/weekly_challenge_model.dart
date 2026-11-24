import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sqlite3/common.dart';

/// Categories of dynamic behavioral challenges derived from habit deficits.
enum ChallengeType {
  proteinAnchor('Protein Anchor', 'Hit your personalized daily protein goal.'),
  fiberBuilder('Fiber & Satiety Builder', 'Reach at least 25g of fiber daily.'),
  produceBooster('Produce Booster', 'Log 2+ servings of fresh fruits or vegetables.'),
  scaleCadence('Consistent Weigh-In', 'Log your weight in the morning 5+ days.'),
  hydrationHero('Hydration Baseline', 'Drink at least 2.5L of water daily.'),
  nightCapTamer('Mindful Evening', 'Keep late-night calories under 15% of your daily budget.');

  const ChallengeType(this.defaultTitle, this.defaultDescription);
  final String defaultTitle;
  final String defaultDescription;
}

/// Lifecycle status for a weekly challenge.
enum ChallengeStatus {
  active,
  completed,
  dismissed,
  failed;

  static ChallengeStatus fromString(String val) {
    return ChallengeStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == val.toLowerCase(),
      orElse: () => ChallengeStatus.active,
    );
  }
}

/// A dynamic behavioral habit challenge for a 7-day coaching block.
@immutable
class WeeklyChallengeModel {
  const WeeklyChallengeModel({
    required this.id,
    this.userId = 'default_user',
    required this.type,
    required this.title,
    required this.description,
    required this.targetMetric,
    required this.targetValue,
    this.currentValue = 0.0,
    required this.unit,
    this.status = ChallengeStatus.active,
    required this.weekStartDate,
    required this.weekEndDate,
    this.completedAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final ChallengeType type;
  final String title;
  final String description;
  final String targetMetric;
  final double targetValue;
  final double currentValue;
  final String unit;
  final ChallengeStatus status;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final DateTime? completedAt;
  final DateTime createdAt;

  /// Progress fraction in [0.0, 1.0].
  double get progressFraction {
    if (targetValue <= 0.0) return 1.0;
    return math.min(1.0, math.max(0.0, currentValue / targetValue));
  }

  /// Whether the target has been fulfilled.
  bool get isFulfilled => currentValue >= targetValue;

  /// Whether this challenge is still active.
  bool get isActive => status == ChallengeStatus.active;

  WeeklyChallengeModel copyWith({
    String? id,
    String? userId,
    ChallengeType? type,
    String? title,
    String? description,
    String? targetMetric,
    double? targetValue,
    double? currentValue,
    String? unit,
    ChallengeStatus? status,
    DateTime? weekStartDate,
    DateTime? weekEndDate,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return WeeklyChallengeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      targetMetric: targetMetric ?? this.targetMetric,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      weekEndDate: weekEndDate ?? this.weekEndDate,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory WeeklyChallengeModel.fromRow(Row row) {
    return WeeklyChallengeModel(
      id: row['id'] as String,
      userId: row['user_id'] as String? ?? 'default_user',
      type: ChallengeType.values.firstWhere(
        (t) => t.name == row['type'],
        orElse: () => ChallengeType.proteinAnchor,
      ),
      title: row['title'] as String,
      description: row['description'] as String,
      targetMetric: row['target_metric'] as String,
      targetValue: (row['target_value'] as num).toDouble(),
      currentValue: (row['current_value'] as num?)?.toDouble() ?? 0.0,
      unit: row['unit'] as String,
      status: ChallengeStatus.fromString(row['status'] as String),
      weekStartDate: DateTime.parse(row['week_start_date'] as String),
      weekEndDate: DateTime.parse(row['week_end_date'] as String),
      completedAt: row['completed_at'] != null
          ? DateTime.parse(row['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'type': type.name,
        'title': title,
        'description': description,
        'target_metric': targetMetric,
        'target_value': targetValue,
        'current_value': currentValue,
        'unit': unit,
        'status': status.name,
        'week_start_date': weekStartDate.toIso8601String().substring(0, 10),
        'week_end_date': weekEndDate.toIso8601String().substring(0, 10),
        'completed_at': completedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyChallengeModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          type == other.type &&
          currentValue == other.currentValue &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, userId, type, currentValue, status);
}

/// Daily breakdown tracking whether a specific challenge criteria was hit on a given date.
@immutable
class ChallengeDailyProgress {
  const ChallengeDailyProgress({
    required this.id,
    required this.challengeId,
    required this.date,
    required this.achievedValue,
    required this.isTargetHit,
  });

  final String id;
  final String challengeId;
  final String date;
  final double achievedValue;
  final bool isTargetHit;

  factory ChallengeDailyProgress.fromRow(Row row) {
    return ChallengeDailyProgress(
      id: row['id'] as String,
      challengeId: row['challenge_id'] as String,
      date: row['date'] as String,
      achievedValue: (row['achieved_value'] as num).toDouble(),
      isTargetHit: (row['is_target_hit'] as int) == 1,
    );
  }
}
