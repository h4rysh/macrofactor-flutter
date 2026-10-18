import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:macro_factor_app/domain/algorithms/weight_trend_v2.dart';
import 'package:macro_factor_app/domain/models/workout_session.dart';
import 'package:macro_factor_app/domain/services/health_sync_adapter.dart';

/// Production Health Connect sync adapter for Android.
///
/// Implements [HealthSyncAdapter] using `package:health` (Health Connect SDK).
/// Handles Hevy workout attribution, smart scale weight logs, and robust
/// platform guardrails for headless CI/CD environments.
class HealthConnectSyncAdapter implements HealthSyncAdapter {
  HealthConnectSyncAdapter({
    Health? health,
    Health? healthPlugin,
    bool? isAndroidOverride,
  })  : _health = health ?? healthPlugin ?? Health(),
        _isAndroid = isAndroidOverride ?? (!kIsWeb && Platform.isAndroid);

  final Health _health;
  final bool _isAndroid;
  bool _isConfigured = false;

  static const List<HealthDataType> _syncedTypes = [
    HealthDataType.WORKOUT,
    HealthDataType.WEIGHT,
  ];

  static const List<HealthDataAccess> _readPermissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<void> _ensureConfigured() async {
    if (_isConfigured) return;
    try {
      await _health.configure();
      _isConfigured = true;
    } on MissingPluginException {
      debugPrint('HealthConnect: MissingPluginException during configure');
    } on PlatformException catch (e) {
      debugPrint('HealthConnect: PlatformException during configure: $e');
    } on Exception catch (e) {
      debugPrint('HealthConnect: Exception during configure: $e');
    }
  }

  @override
  Future<bool> isAvailable() async {
    if (!_isAndroid) return false;

    try {
      await _ensureConfigured();
      final status = await _health.getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> hasPermissions() async {
    if (!_isAndroid) return false;

    try {
      await _ensureConfigured();
      final hasPerm = await _health.hasPermissions(
        _syncedTypes,
        permissions: _readPermissions,
      );
      return hasPerm ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    if (!_isAndroid) return false;

    try {
      await _ensureConfigured();
      final granted = await _health.requestAuthorization(
        _syncedTypes,
        permissions: _readPermissions,
      );
      return granted;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } on Exception {
      return false;
    }
  }

  @override
  Future<List<WorkoutSession>> fetchWorkouts({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (!_isAndroid) return const [];

    try {
      await _ensureConfigured();
      final dataPoints = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.WORKOUT],
        startTime: startTime,
        endTime: endTime,
      );

      final workouts = <WorkoutSession>[];
      for (final point in dataPoints) {
        if (point.type != HealthDataType.WORKOUT) continue;

        final isHevy = _detectHevySource(point);
        final title = _formatWorkoutTitle(point, isHevy: isHevy);
        final duration =
            _calculateDurationMinutes(point.dateFrom, point.dateTo);
        final calories = _extractCaloriesBurned(point);
        final id = point.uuid.isNotEmpty
            ? point.uuid
            : 'hc_workout_${point.dateFrom.millisecondsSinceEpoch}';

        workouts.add(
          WorkoutSession(
            id: id,
            source: isHevy ? WorkoutSource.hevy : WorkoutSource.healthConnect,
            title: title,
            startTime: point.dateFrom,
            endTime: point.dateTo,
            durationMinutes: duration,
            caloriesBurned: calories,
            notes: point.metadata?['notes'] as String?,
            createdAt: point.dateFrom,
          ),
        );
      }
      return workouts;
    } on MissingPluginException {
      return const [];
    } on PlatformException catch (e) {
      debugPrint('HealthConnect: PlatformException in fetchWorkouts: $e');
      return const [];
    } on Exception catch (e) {
      debugPrint('HealthConnect: Exception in fetchWorkouts: $e');
      return const [];
    }
  }

  @override
  Future<List<ScaleWeightEntry>> fetchWeights({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (!_isAndroid) return const [];

    try {
      await _ensureConfigured();
      final dataPoints = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.WEIGHT],
        startTime: startTime,
        endTime: endTime,
      );

      final weights = <ScaleWeightEntry>[];
      for (final point in dataPoints) {
        if (point.type != HealthDataType.WEIGHT) continue;
        final value = point.value;
        if (value is! NumericHealthValue) continue;

        final weightKg = value.numericValue.toDouble();
        if (weightKg <= 0) continue;

        final note =
            point.sourceName.isNotEmpty ? point.sourceName : 'Health Connect';

        weights.add(
          ScaleWeightEntry(
            date: point.dateFrom,
            weightKg: weightKg,
            note: note,
          ),
        );
      }
      return weights;
    } on MissingPluginException {
      return const [];
    } on PlatformException catch (e) {
      debugPrint('HealthConnect: PlatformException in fetchWeights: $e');
      return const [];
    } on Exception catch (e) {
      debugPrint('HealthConnect: Exception in fetchWeights: $e');
      return const [];
    }
  }

  bool _detectHevySource(HealthDataPoint point) {
    final sourceName = point.sourceName.toLowerCase();
    final sourceId = point.sourceId.toLowerCase();
    final metaSource =
        (point.metadata?['source'] as String?)?.toLowerCase() ?? '';
    return sourceName.contains('hevy') ||
        sourceId.contains('hevy') ||
        metaSource.contains('hevy');
  }

  int _calculateDurationMinutes(DateTime start, DateTime end) {
    final diff = end.difference(start).inMinutes;
    return diff > 0 ? diff : 1;
  }

  double _extractCaloriesBurned(HealthDataPoint point) {
    final value = point.value;
    if (value is WorkoutHealthValue) {
      final burned = value.totalEnergyBurned?.toDouble();
      if (burned != null && burned > 0) return burned;
    }
    final summaryBurned = point.workoutSummary?.totalEnergyBurned.toDouble();
    if (summaryBurned != null && summaryBurned > 0) return summaryBurned;

    return 0.0;
  }

  String _formatWorkoutTitle(HealthDataPoint point, {required bool isHevy}) {
    final metaTitle = point.metadata?['title'] as String?;
    if (metaTitle != null && metaTitle.trim().isNotEmpty) {
      final trimmed = metaTitle.trim();
      if (isHevy && !trimmed.toLowerCase().startsWith('hevy')) {
        return 'Hevy: $trimmed';
      }
      return trimmed;
    }

    final value = point.value;
    if (value is WorkoutHealthValue) {
      final activityName = value.workoutActivityType.name;
      final formatted = activityName
          .split('_')
          .map((word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
          .join(' ');
      if (formatted.isNotEmpty &&
          formatted != 'Other' &&
          formatted != 'Unknown') {
        return isHevy ? 'Hevy: $formatted' : formatted;
      }
    }

    return isHevy ? 'Hevy Strength Session' : 'Health Connect Workout';
  }
}
