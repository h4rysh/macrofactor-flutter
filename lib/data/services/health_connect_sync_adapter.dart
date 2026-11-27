import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:sique/domain/algorithms/weight_trend_v2.dart';
import 'package:sique/domain/models/workout_session.dart';
import 'package:sique/domain/services/health_sync_adapter.dart';

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
    HealthDataType.STEPS,
    HealthDataType.SLEEP_SESSION,
  ];

  static const List<HealthDataAccess> _readPermissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
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

        final rawNotes = point.metadata?['notes'];
        final safeNotes = rawNotes is String && rawNotes.trim().isNotEmpty
            ? (rawNotes.trim().length > 500
                ? rawNotes.trim().substring(0, 500)
                : rawNotes.trim())
            : null;
        workouts.add(
          WorkoutSession(
            id: id,
            source: isHevy ? WorkoutSource.hevy : WorkoutSource.healthConnect,
            title: title,
            startTime: point.dateFrom,
            endTime: point.dateTo,
            durationMinutes: duration,
            caloriesBurned: calories,
            notes: safeNotes,
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
        if (!weightKg.isFinite || weightKg < 20.0 || weightKg > 350.0) continue;

        final note =
            point.sourceName.isNotEmpty ? point.sourceName : 'Health Connect';

        weights.add(
          ScaleWeightEntry(
            date: point.dateFrom,
            weightKg: weightKg,
            note: note,
            source: 'health_connect',
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
    final rawMeta = point.metadata?['source'];
    final metaSource = rawMeta is String ? rawMeta.toLowerCase() : '';
    return sourceName.contains('hevy') ||
        sourceId.contains('hevy') ||
        metaSource.contains('hevy');
  }

  int _calculateDurationMinutes(DateTime start, DateTime end) {
    final diff = end.difference(start).inMinutes;
    return diff > 0 ? diff.clamp(1, 10000000) : 1;
  }

  double _extractCaloriesBurned(HealthDataPoint point) {
    final value = point.value;
    if (value is WorkoutHealthValue) {
      final burned = value.totalEnergyBurned?.toDouble();
      if (burned != null && burned.isFinite && burned > 0) {
        return burned.clamp(0.0, 15000.0);
      }
    }
    final summaryBurned = point.workoutSummary?.totalEnergyBurned.toDouble();
    if (summaryBurned != null && summaryBurned.isFinite && summaryBurned > 0) {
      return summaryBurned.clamp(0.0, 15000.0);
    }

    return 0.0;
  }

  String _formatWorkoutTitle(HealthDataPoint point, {required bool isHevy}) {
    final rawTitle = point.metadata?['title'];
    if (rawTitle is String && rawTitle.trim().isNotEmpty) {
      return rawTitle.trim();
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
        return formatted;
      }
    }

    return 'Workout Session';
  }

  /// Fetches daily steps and total sleep hours from Health Connect.
  Future<({int steps, double sleepHours})> fetchDailyStepsAndSleepHours(
    DateTime date,
  ) async {
    if (!_isAndroid) return (steps: 0, sleepHours: 0.0);
    try {
      await _ensureConfigured();
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      final steps = await _health.getTotalStepsInInterval(start, end) ?? 0;
      final windowStart = start.subtract(const Duration(hours: 6));
      final sleepPoints = await _health.getHealthDataFromTypes(
        startTime: windowStart,
        endTime: end,
        types: const [HealthDataType.SLEEP_SESSION],
      );
      // Merge overlapping sleep intervals (e.g. phone + watch) before summing
      final intervals = <(DateTime, DateTime)>[];
      for (final p in sleepPoints) {
        final s = p.dateFrom.isBefore(windowStart) ? windowStart : p.dateFrom;
        final e = p.dateTo.isAfter(end) ? end : p.dateTo;
        if (e.isAfter(s)) {
          intervals.add((s, e));
        }
      }
      intervals.sort((a, b) => a.$1.compareTo(b.$1));
      var sleepMins = 0;
      DateTime? curStart;
      DateTime? curEnd;
      for (final (s, e) in intervals) {
        if (curStart == null || curEnd == null) {
          curStart = s;
          curEnd = e;
        } else if (!s.isAfter(curEnd)) {
          if (e.isAfter(curEnd)) curEnd = e;
        } else {
          sleepMins += curEnd.difference(curStart).inMinutes;
          curStart = s;
          curEnd = e;
        }
      }
      if (curStart != null && curEnd != null) {
        sleepMins += curEnd.difference(curStart).inMinutes;
      }
      return (steps: steps, sleepHours: (sleepMins.clamp(0, 960)) / 60.0);
    } catch (_) {
      return (steps: 0, sleepHours: 0.0);
    }
  }

  /// Two-way Health Connect write-back: writes logged meal macros to Health Connect NUTRITION.
  Future<bool> writeNutritionSummary({
    required DateTime startTime,
    required DateTime endTime,
    required String mealName,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    double fiber = 0.0,
  }) async {
    if (!_isAndroid ||
        !calories.isFinite ||
        calories <= 0 ||
        !protein.isFinite ||
        protein < 0 ||
        !carbs.isFinite ||
        carbs < 0 ||
        !fat.isFinite ||
        fat < 0 ||
        !fiber.isFinite ||
        fiber < 0) {
      return false;
    }
    try {
      await _ensureConfigured();
      final hasWritePerm = await _health.hasPermissions(
        const [HealthDataType.NUTRITION],
        permissions: const [HealthDataAccess.WRITE],
      );
      if (hasWritePerm != true) {
        final granted = await _health.requestAuthorization(
          const [HealthDataType.NUTRITION],
          permissions: const [HealthDataAccess.WRITE],
        );
        if (!granted) return false;
      }
      return await _health.writeMeal(
        mealType: MealType.UNKNOWN,
        startTime: startTime,
        endTime: endTime,
        name: mealName,
        caloriesConsumed: calories.clamp(0.0, 15000.0),
        protein: protein.clamp(0.0, 1000.0),
        carbohydrates: carbs.clamp(0.0, 2000.0),
        fatTotal: fat.clamp(0.0, 1000.0),
        fiber: fiber.clamp(0.0, 500.0),
      );
    } catch (_) {
      return false;
    }
  }
}
