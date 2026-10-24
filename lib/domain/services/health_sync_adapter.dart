import 'package:sique/domain/algorithms/weight_trend_v2.dart';
import 'package:sique/domain/models/workout_session.dart';

/// Contract for health data synchronization (Google Health Connect on Android).
abstract interface class HealthSyncAdapter {
  /// Checks whether Health Connect is available on the current platform and device.
  Future<bool> isAvailable();

  /// Checks whether required Health Connect read permissions have been granted.
  Future<bool> hasPermissions();

  /// Prompts the user to grant required Health Connect read permissions.
  /// Returns true if all requested permissions are granted.
  Future<bool> requestPermissions();

  /// Fetches workout sessions from Health Connect within the specified time window.
  Future<List<WorkoutSession>> fetchWorkouts({
    required DateTime startTime,
    required DateTime endTime,
  });

  /// Fetches body weight logs from Health Connect within the specified time window.
  Future<List<ScaleWeightEntry>> fetchWeights({
    required DateTime startTime,
    required DateTime endTime,
  });
}
