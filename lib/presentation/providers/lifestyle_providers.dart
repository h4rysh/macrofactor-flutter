import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/domain/algorithms/anthropometric_service.dart';
import 'package:sique/domain/algorithms/challenge_generation_service.dart';
import 'package:sique/domain/algorithms/weight_trend_v2.dart';
import 'package:sique/domain/models/body_measurement_entry.dart';
import 'package:sique/domain/models/lifestyle_models.dart';
import 'package:sique/domain/models/weekly_challenge_model.dart';
import 'package:sique/presentation/providers/app_providers.dart';

// ============================================================================
// Hydration Tracking Providers
// ============================================================================

class DailyWaterNotifier extends StateNotifier<int> {
  DailyWaterNotifier(this._ref) : super(0) {
    _loadTodayWater();
  }

  final Ref _ref;

  void _loadTodayWater() {
    final db = _ref.read(databaseProvider);
    state = db.waterDao.getDailyWaterMl(DateTime.now());
  }

  void addWater(int amountMl) {
    if (amountMl <= 0) return;
    final db = _ref.read(databaseProvider);
    db.waterDao.logWater(amountMl);
    state += amountMl;
  }

  void resetToday() {
    final db = _ref.read(databaseProvider);
    db.waterDao.clearDayWater(DateTime.now());
    state = 0;
  }
}

final dailyWaterProvider =
    StateNotifierProvider<DailyWaterNotifier, int>((ref) {
  ref.watch(userDataEpochProvider);
  return DailyWaterNotifier(ref);
});

// ============================================================================
// Intermittent Fasting Providers
// ============================================================================

class FastingSessionNotifier extends StateNotifier<FastingSession?> {
  FastingSessionNotifier(this._ref) : super(null) {
    _loadActive();
  }

  final Ref _ref;

  void _loadActive() {
    final db = _ref.read(databaseProvider);
    state = db.fastingDao.getActiveFast();
  }

  void startFast(FastingProtocol protocol, {DateTime? startTime}) {
    final db = _ref.read(databaseProvider);
    final start = startTime ?? DateTime.now();
    final targetEnd = start.add(Duration(hours: protocol.fastHours));

    final session = FastingSession(
      id: 'fast_${DateTime.now().millisecondsSinceEpoch}',
      protocol: protocol,
      startTime: start,
      targetEndTime: targetEnd,
      state: 'active',
    );

    db.fastingDao.startFast(session);
    state = session;
  }

  void endFast({bool completed = true}) {
    final current = state;
    if (current == null) return;

    final db = _ref.read(databaseProvider);
    db.fastingDao.endFast(current.id, completed: completed);
    state = null;
  }
}

final fastingSessionProvider =
    StateNotifierProvider<FastingSessionNotifier, FastingSession?>((ref) {
  ref.watch(userDataEpochProvider);
  return FastingSessionNotifier(ref);
});

// ============================================================================
// Anthropometric Body Measurements Providers
// ============================================================================

class BodyMeasurementsNotifier
    extends StateNotifier<List<BodyMeasurementEntry>> {
  BodyMeasurementsNotifier(this._ref) : super([]) {
    loadRecent();
  }

  final Ref _ref;

  void loadRecent() {
    final db = _ref.read(databaseProvider);
    state = db.bodyMeasurementsDao.getRecentMeasurements(limit: 90);
  }

  void saveMeasurement(BodyMeasurementEntry entry) {
    final db = _ref.read(databaseProvider);
    db.bodyMeasurementsDao.upsertMeasurement(entry);
    loadRecent();
  }

  void deleteMeasurement(String id) {
    final db = _ref.read(databaseProvider);
    db.bodyMeasurementsDao.deleteMeasurement(id);
    loadRecent();
  }
}

final bodyMeasurementsProvider =
    StateNotifierProvider<BodyMeasurementsNotifier, List<BodyMeasurementEntry>>(
        (ref) {
  ref.watch(userDataEpochProvider);
  return BodyMeasurementsNotifier(ref);
});

/// Evaluates whether the user is in a state of Silent Recomposition.
/// Uses bidirectional WeightTrendV2Series smoothed weight (immune to 1-day water/sodium spikes)
/// and applies time-aware 1D exponential smoothing to waist measurements.
final recompositionStatusProvider = Provider<bool>((ref) {
  final measurements = ref.watch(bodyMeasurementsProvider);
  if (measurements.length < 2) return false;

  final weights = ref.watch(weightLogsProvider);
  if (weights.length < 2) return false;

  final double weightDelta7Day;
  if (weights.length >= 5) {
    final trendSeries = WeightTrendV2Series.compute(
      entries: weights
          .map((w) => ScaleWeightEntry(date: w.date, weightKg: w.weightKg))
          .toList(),
      bidirectional: true,
    );
    if (trendSeries.points.length < 2) return false;
    final latestTrend = trendSeries.points.last;
    if (latestTrend.date.difference(trendSeries.points.first.date).inDays < 7) {
      return false;
    }
    final anchorTrend = trendSeries.points.lastWhere(
      (p) => latestTrend.date.difference(p.date).inDays >= 7,
      orElse: () => trendSeries.points.first,
    );
    weightDelta7Day = latestTrend.trendWeightKg - anchorTrend.trendWeightKg;
  } else {
    final sortedWeights = List.of(weights)
      ..sort((a, b) => a.date.compareTo(b.date));
    final latestWeightEntry = sortedWeights.last;
    if (latestWeightEntry.date.difference(sortedWeights.first.date).inDays <
        7) {
      return false;
    }
    final anchorWeightEntry = sortedWeights.lastWhere(
      (w) => latestWeightEntry.date.difference(w.date).inDays >= 7,
      orElse: () => sortedWeights.first,
    );
    weightDelta7Day = latestWeightEntry.weightKg - anchorWeightEntry.weightKg;
  }

  // Chronological (oldest -> newest) waist series for time-aware 1D exponential smoothing.
  final waistEntries = measurements.where((m) => m.waistCm != null).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  if (waistEntries.length < 2) return false;

  double smoothed = waistEntries.first.waistCm!;
  final smoothedSeries = <({DateTime date, double value})>[
    (date: waistEntries.first.date, value: smoothed),
  ];
  for (var i = 1; i < waistEntries.length; i++) {
    final deltaDays =
        waistEntries[i].date.difference(waistEntries[i - 1].date).inDays;
    smoothed = AnthropometricService.smoothCircumference(
      currentObservedCm: waistEntries[i].waistCm!,
      previousSmoothedCm: smoothed,
      deltaDays: deltaDays,
    );
    smoothedSeries.add((date: waistEntries[i].date, value: smoothed));
  }

  final latestSmoothed = smoothedSeries.last;
  final anchorSmoothed = smoothedSeries.lastWhere(
    (s) => latestSmoothed.date.difference(s.date).inDays >= 14,
    orElse: () => smoothedSeries.first,
  );
  final smoothedWaistDelta = latestSmoothed.value - anchorSmoothed.value;

  return AnthropometricService.isSilentRecomposition(
    weightDelta7DayKg: weightDelta7Day,
    smoothedWaistDelta14DayCm: smoothedWaistDelta,
  );
});

// ============================================================================
// Dynamic Weekly Behavioral Challenges Providers
// ============================================================================

class WeeklyChallengesNotifier
    extends StateNotifier<List<WeeklyChallengeModel>> {
  WeeklyChallengesNotifier(this._ref) : super([]) {
    _initChallenges();
  }

  final Ref _ref;

  void _initChallenges() {
    final db = _ref.read(databaseProvider);
    var active = db.challengesDao.getActiveChallenges();

    // Check if existing challenges expired (> 7 days since start)
    final now = DateTime.now();
    final isExpired =
        active.isNotEmpty && now.isAfter(active.first.weekEndDate);

    if (active.isEmpty || isExpired) {
      // Mark old as completed/failed if expired
      if (isExpired) {
        for (final ch in active) {
          final status = ch.isFulfilled
              ? ChallengeStatus.completed
              : ChallengeStatus.failed;
          db.challengesDao.updateChallengeStatus(ch.id, status);
        }
      }

      // Generate 2 new challenges based on V2 6-table deficit mining scoped to tenant userId
      final profile = _ref.read(userProfileProvider);
      final pTarget =
          profile.proteinPreference.gramsPerKg * profile.currentWeightKg;
      final mined = db.challengesDao.mineDeficitMetricsV2(
        proteinTargetG: pTarget,
        weightKg: profile.currentWeightKg > 0 ? profile.currentWeightKg : 70.0,
        isFemale: !profile.isMale,
      );

      var newChallenges =
          ChallengeGenerationService.generateAdaptiveChallengesV2(
        metrics: mined,
        weekStart: now,
        userId: db.currentUserId,
        proteinTargetG: pTarget,
        limit: 2,
      );
      if (newChallenges.isEmpty) {
        newChallenges = ChallengeGenerationService.generateWeeklyChallenges(
          metrics: mined,
          weekStart: now,
          userId: db.currentUserId,
          proteinTargetG: pTarget,
        );
      }

      for (final ch in newChallenges) {
        db.challengesDao.upsertChallenge(ch);
      }
      active = newChallenges;
    }

    state = active;
    syncFromLogs();
  }

  /// Automatically synchronizes active challenge progress against SQLite food, weight, and water logs.
  void syncFromLogs() {
    if (state.isEmpty) return;
    final db = _ref.read(databaseProvider);
    final profile = _ref.read(userProfileProvider);
    final pTarget =
        profile.proteinPreference.gramsPerKg * profile.currentWeightKg;

    var changed = false;
    final syncedList = <WeeklyChallengeModel>[];
    for (final ch in state) {
      final newVal = db.challengesDao.syncChallengeWithLogs(
        ch,
        proteinTargetG: pTarget,
      );
      final isFulfilled = newVal >= ch.targetValue;
      final nextStatus = isFulfilled
          ? ChallengeStatus.completed
          : (ch.status == ChallengeStatus.completed
              ? ChallengeStatus.active
              : ch.status);
      if (newVal != ch.currentValue || nextStatus != ch.status) {
        changed = true;
        syncedList.add(ch.copyWith(
          currentValue: newVal,
          status: nextStatus,
          completedAt: isFulfilled ? (ch.completedAt ?? DateTime.now()) : null,
        ));
      } else {
        syncedList.add(ch);
      }
    }
    if (changed) {
      state = syncedList;
    }
  }

  void incrementProgress(String challengeId, double delta) {
    final db = _ref.read(databaseProvider);
    final updatedList = <WeeklyChallengeModel>[];

    for (final ch in state) {
      if (ch.id == challengeId) {
        final newVal = ch.currentValue + delta;
        final isFulfilled = newVal >= ch.targetValue;
        final newStatus = isFulfilled ? ChallengeStatus.completed : ch.status;

        db.challengesDao.updateChallengeProgress(
          challengeId,
          newVal,
          status: newStatus,
          completedAt: isFulfilled ? DateTime.now() : null,
        );

        updatedList.add(ch.copyWith(
          currentValue: newVal,
          status: newStatus,
          completedAt: isFulfilled ? DateTime.now() : null,
        ));
      } else {
        updatedList.add(ch);
      }
    }

    state = updatedList;
  }

  void dismissChallenge(String challengeId) {
    final db = _ref.read(databaseProvider);
    db.challengesDao.updateChallengeStatus(
      challengeId,
      ChallengeStatus.dismissed,
    );
    state = state.where((ch) => ch.id != challengeId).toList();
  }

  /// Swaps out a challenge for the next highest-priority candidate (Pick-2-of-3 autonomy).
  void swapChallenge(String challengeId) {
    final db = _ref.read(databaseProvider);
    final profile = _ref.read(userProfileProvider);
    final pTarget =
        profile.proteinPreference.gramsPerKg * profile.currentWeightKg;
    db.challengesDao.updateChallengeStatus(
      challengeId,
      ChallengeStatus.dismissed,
    );
    final existingTypes =
        state.where((c) => c.id != challengeId).map((c) => c.type).toSet();
    final mined = db.challengesDao.mineDeficitMetricsV2(
      proteinTargetG: pTarget,
      weightKg: profile.currentWeightKg > 0 ? profile.currentWeightKg : 70.0,
      isFemale: !profile.isMale,
    );
    final candidates = ChallengeGenerationService.generateAdaptiveChallengesV2(
      metrics: mined,
      weekStart: DateTime.now(),
      userId: db.currentUserId,
      proteinTargetG: pTarget,
      limit: 5,
    );
    final replacement = candidates
        .where((c) => !existingTypes.contains(c.type) && c.id != challengeId)
        .firstOrNull;
    final remaining = state.where((c) => c.id != challengeId).toList();
    if (replacement != null) {
      db.challengesDao.upsertChallenge(replacement);
      remaining.add(replacement);
    }
    state = remaining;
    syncFromLogs();
  }
}

final weeklyChallengesProvider =
    StateNotifierProvider<WeeklyChallengesNotifier, List<WeeklyChallengeModel>>(
        (ref) {
  ref.watch(userDataEpochProvider);
  final notifier = WeeklyChallengesNotifier(ref);
  ref.listen<int>(foodLogsRevisionProvider, (_, __) => notifier.syncFromLogs());
  ref.listen(weightLogsProvider, (_, __) => notifier.syncFromLogs());
  ref.listen<int>(dailyWaterProvider, (_, __) => notifier.syncFromLogs());
  return notifier;
});
