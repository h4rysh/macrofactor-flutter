import 'package:flutter/foundation.dart';
import 'package:sqlite3/common.dart';

/// Represents an anthropometric body measurement entry.
@immutable
class BodyMeasurementEntry {
  const BodyMeasurementEntry({
    required this.id,
    this.userId = 'default_user',
    required this.date,
    this.waistCm,
    this.hipsCm,
    this.chestCm,
    this.neckCm,
    this.bicepsCm,
    this.thighCm,
    this.bodyFatPct,
    this.source = 'manual',
    this.notes,
    required this.loggedAt,
  });

  final String id;
  final String userId;
  final DateTime date;
  final double? waistCm;
  final double? hipsCm;
  final double? chestCm;
  final double? neckCm;
  final double? bicepsCm;
  final double? thighCm;
  final double? bodyFatPct;
  final String source;
  final String? notes;
  final DateTime loggedAt;

  /// Waist-to-Height Ratio (WHtR).
  /// Clinical risk thresholds: < 0.40 Underweight, 0.40 - 0.49 Healthy, 0.50 - 0.59 Increased risk, >= 0.60 Very high risk.
  double? waistToHeightRatio(double heightCm) {
    if (waistCm == null ||
        !waistCm!.isFinite ||
        waistCm! <= 0 ||
        !heightCm.isFinite ||
        heightCm <= 0) {
      return null;
    }
    return waistCm! / heightCm;
  }

  /// Waist-to-Hip Ratio (WHR).
  /// Male risk threshold: > 0.90; Female risk threshold: > 0.85.
  double? get waistToHipRatio {
    if (waistCm == null ||
        hipsCm == null ||
        !waistCm!.isFinite ||
        !hipsCm!.isFinite ||
        waistCm! <= 0 ||
        hipsCm! <= 0) {
      return null;
    }
    return waistCm! / hipsCm!;
  }

  /// Calendar date formatted as YYYY-MM-DD.
  String get dateString =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  BodyMeasurementEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? waistCm,
    double? hipsCm,
    double? chestCm,
    double? neckCm,
    double? bicepsCm,
    double? thighCm,
    double? bodyFatPct,
    String? source,
    String? notes,
    DateTime? loggedAt,
  }) {
    return BodyMeasurementEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      waistCm: waistCm ?? this.waistCm,
      hipsCm: hipsCm ?? this.hipsCm,
      chestCm: chestCm ?? this.chestCm,
      neckCm: neckCm ?? this.neckCm,
      bicepsCm: bicepsCm ?? this.bicepsCm,
      thighCm: thighCm ?? this.thighCm,
      bodyFatPct: bodyFatPct ?? this.bodyFatPct,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  factory BodyMeasurementEntry.fromRow(Row row) {
    return BodyMeasurementEntry(
      id: row['id'] as String,
      userId: row['user_id'] as String? ?? 'default_user',
      date: DateTime.parse(row['date'] as String),
      waistCm: (row['waist_cm'] as num?)?.toDouble(),
      hipsCm: (row['hips_cm'] as num?)?.toDouble(),
      chestCm: (row['chest_cm'] as num?)?.toDouble(),
      neckCm: (row['neck_cm'] as num?)?.toDouble(),
      bicepsCm: (row['biceps_cm'] as num?)?.toDouble(),
      thighCm: (row['thigh_cm'] as num?)?.toDouble(),
      bodyFatPct: (row['body_fat_pct'] as num?)?.toDouble(),
      source: row['source'] as String? ?? 'manual',
      notes: row['notes'] as String?,
      loggedAt: DateTime.parse(row['logged_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'date': dateString,
        'waist_cm': waistCm,
        'hips_cm': hipsCm,
        'chest_cm': chestCm,
        'neck_cm': neckCm,
        'biceps_cm': bicepsCm,
        'thigh_cm': thighCm,
        'body_fat_pct': bodyFatPct,
        'source': source,
        'notes': notes,
        'logged_at': loggedAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyMeasurementEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          dateString == other.dateString &&
          waistCm == other.waistCm &&
          hipsCm == other.hipsCm &&
          chestCm == other.chestCm &&
          neckCm == other.neckCm &&
          bicepsCm == other.bicepsCm &&
          thighCm == other.thighCm &&
          bodyFatPct == other.bodyFatPct;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        dateString,
        waistCm,
        hipsCm,
        chestCm,
        neckCm,
        bicepsCm,
        thighCm,
        bodyFatPct,
      );
}
