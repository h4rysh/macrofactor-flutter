import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:macro_factor_app/data/local/app_database.dart';
import 'package:macro_factor_app/data/services/health_connect_sync_adapter.dart';
import 'package:macro_factor_app/domain/algorithms/weight_trend_v2.dart';
import 'package:macro_factor_app/domain/models/workout_session.dart';
import 'package:macro_factor_app/domain/services/health_sync_adapter.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';

/// Discrete operational status of Health Connect synchronization.
enum HealthSyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Immutable state modeling Health Connect synchronization status, telemetry, and error reporting.
@immutable
class HealthSyncState {
  const HealthSyncState({
    this.status = HealthSyncStatus.idle,
    this.lastSyncedAt,
    this.errorMessage,
    this.syncedWorkoutsCount = 0,
    this.syncedWeightsCount = 0,
    this.isAvailable = true,
    this.hasPermissions = false,
  });

  /// Current operation status.
  final HealthSyncStatus status;

  /// Timestamp of last successful synchronization.
  final DateTime? lastSyncedAt;

  /// Error message if last sync attempt failed.
  final String? errorMessage;

  /// Count of workouts synced in the most recent operation.
  final int syncedWorkoutsCount;

  /// Count of scale weights synced in the most recent operation.
  final int syncedWeightsCount;

  /// Whether Health Connect is available on the device.
  final bool isAvailable;

  /// Whether necessary Health Connect read permissions are granted.
  final bool hasPermissions;

  /// Convenience getters.
  bool get isSyncing => status == HealthSyncStatus.syncing;
  bool get isSuccess => status == HealthSyncStatus.success;
  bool get isError => status == HealthSyncStatus.error;

  /// Formatted last synced string (e.g. "Today at 2:30 PM" or "Never").
  String get formattedLastSync {
    if (lastSyncedAt == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(lastSyncedAt!);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(lastSyncedAt!);
  }

  HealthSyncState copyWith({
    HealthSyncStatus? status,
    DateTime? lastSyncedAt,
    String? errorMessage,
    int? syncedWorkoutsCount,
    int? syncedWeightsCount,
    bool? isAvailable,
    bool? hasPermissions,
    bool clearError = false,
  }) {
    return HealthSyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      syncedWorkoutsCount: syncedWorkoutsCount ?? this.syncedWorkoutsCount,
      syncedWeightsCount: syncedWeightsCount ?? this.syncedWeightsCount,
      isAvailable: isAvailable ?? this.isAvailable,
      hasPermissions: hasPermissions ?? this.hasPermissions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthSyncState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          lastSyncedAt == other.lastSyncedAt &&
          errorMessage == other.errorMessage &&
          syncedWorkoutsCount == other.syncedWorkoutsCount &&
          syncedWeightsCount == other.syncedWeightsCount &&
          isAvailable == other.isAvailable &&
          hasPermissions == other.hasPermissions;

  @override
  int get hashCode => Object.hash(
        status,
        lastSyncedAt,
        errorMessage,
        syncedWorkoutsCount,
        syncedWeightsCount,
        isAvailable,
        hasPermissions,
      );

  @override
  String toString() =>
      'HealthSyncState(status: $status, lastSynced: $lastSyncedAt, workouts: $syncedWorkoutsCount, weights: $syncedWeightsCount, err: $errorMessage)';
}

/// Notifier executing background and manual synchronization with Health Connect.
class HealthSyncNotifier extends StateNotifier<HealthSyncState> {
  HealthSyncNotifier({
    required AppDatabase db,
    required HealthSyncAdapter adapter,
    Ref? ref,
  })  : _db = db,
        _adapter = adapter,
        _ref = ref,
        super(_loadInitialState(db)) {
    checkAvailabilityAndPermissions();
  }

  final AppDatabase _db;
  final HealthSyncAdapter _adapter;
  final Ref? _ref;

  static HealthSyncState _loadInitialState(AppDatabase db) {
    try {
      final session = db.getAccountSession();
      if (session != null) {
        return HealthSyncState(
          lastSyncedAt: session.lastHealthSyncTime,
          hasPermissions: session.healthConnectEnabled,
        );
      }
    } catch (_) {}
    return const HealthSyncState();
  }

  /// Verifies availability and current permission status.
  Future<void> checkAvailabilityAndPermissions() async {
    try {
      final available = await _adapter.isAvailable();
      final perms = available && await _adapter.hasPermissions();
      state = state.copyWith(
        isAvailable: available,
        hasPermissions: perms,
      );
    } catch (_) {}
  }

  /// Requests required Health Connect permissions from the user.
  Future<bool> requestPermissions() async {
    try {
      final granted = await _adapter.requestPermissions();
      state = state.copyWith(hasPermissions: granted);
      if (granted) {
        _ref?.read(authNotifierProvider.notifier).setHealthConnectEnabled(true);
      }
      return granted;
    } catch (e) {
      state = state.copyWith(
        status: HealthSyncStatus.error,
        errorMessage: 'Failed to request permissions: ${e.toString()}',
      );
      return false;
    }
  }

  /// Synchronizes workouts and smart scale weights from Health Connect.
  /// Inserts results into SQLite and refreshes dependent Riverpod providers.
  Future<bool> syncNow({int trailingDays = 30}) async {
    if (state.isSyncing) return false;

    state = state.copyWith(
      status: HealthSyncStatus.syncing,
      clearError: true,
    );

    try {
      final isAvailable = await _adapter.isAvailable();
      if (!isAvailable) {
        state = state.copyWith(
          status: HealthSyncStatus.error,
          errorMessage: 'Google Health Connect is not available on this device',
          isAvailable: false,
        );
        return false;
      }

      var hasPerms = await _adapter.hasPermissions();
      if (!hasPerms) {
        hasPerms = await _adapter.requestPermissions();
        if (!hasPerms) {
          state = state.copyWith(
            status: HealthSyncStatus.error,
            errorMessage: 'Health Connect permissions not granted',
            hasPermissions: false,
          );
          return false;
        }
      }

      state = state.copyWith(hasPermissions: true);

      final now = DateTime.now();
      final startTime = now.subtract(Duration(days: trailingDays));

      // Fetch workouts & weights concurrently
      final workoutsFuture = _adapter.fetchWorkouts(
        startTime: startTime,
        endTime: now,
      );
      final weightsFuture = _adapter.fetchWeights(
        startTime: startTime,
        endTime: now,
      );

      final results = await Future.wait([workoutsFuture, weightsFuture]);
      final workouts = results[0] as List<WorkoutSession>;
      final weights = results[1] as List<ScaleWeightEntry>;

      // 1. Persist workouts to SQLite & refresh workoutSessionsProvider
      if (workouts.isNotEmpty) {
        _db.insertWorkoutSessions(workouts);
        _ref?.read(workoutSessionsProvider.notifier).refresh();
      }

      // 2. Persist smart scale weights to SQLite & refresh weightLogsProvider
      if (weights.isNotEmpty) {
        for (final entry in weights) {
          final dateStr = DateFormat('yyyy-MM-dd').format(entry.date);
          _db.insertWeightLog(
              dateStr, entry.weightKg, entry.note ?? 'Health Connect');
        }
        _ref?.read(weightLogsProvider.notifier).refresh();
      }

      // 3. Update session sync time in SQLite and AuthNotifier
      _ref?.read(authNotifierProvider.notifier).updateLastHealthSync(now);

      state = state.copyWith(
        status: HealthSyncStatus.success,
        lastSyncedAt: now,
        syncedWorkoutsCount: workouts.length,
        syncedWeightsCount: weights.length,
        clearError: true,
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      state = state.copyWith(
        status: HealthSyncStatus.error,
        errorMessage: msg.isEmpty ? 'Health Connect sync failed' : msg,
      );
      return false;
    }
  }

  /// Clears transient error state.
  void clearError() {
    state = state.copyWith(clearError: true, status: HealthSyncStatus.idle);
  }
}

/// Provider for HealthSyncAdapter abstraction. Defaults to [HealthConnectSyncAdapter] for production Health Connect sync.
final healthSyncAdapterProvider = Provider<HealthSyncAdapter>((ref) {
  return HealthConnectSyncAdapter();
});

/// Riverpod StateNotifierProvider for Health Connect synchronization.
final healthConnectSyncProvider =
    StateNotifierProvider<HealthSyncNotifier, HealthSyncState>((ref) {
  final db = ref.watch(databaseProvider);
  final adapter = ref.watch(healthSyncAdapterProvider);
  return HealthSyncNotifier(
    db: db,
    adapter: adapter,
    ref: ref,
  );
});

/// Backwards-compatible alias for healthConnectSyncProvider.
final healthSyncProvider = healthConnectSyncProvider;
