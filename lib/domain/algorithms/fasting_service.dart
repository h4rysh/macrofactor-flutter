import 'package:sique/domain/models/lifestyle_models.dart';

/// Helper service for intermittent fasting calculations and biological stage progressions.
class FastingService {
  const FastingService._();

  /// Computes target end time from start time and protocol.
  static DateTime calculateTargetEndTime(
    DateTime startTime,
    FastingProtocol protocol,
  ) {
    return startTime.add(Duration(hours: protocol.fastHours));
  }

  /// Calculates biological fasting stage from elapsed duration.
  static FastingStage getStage(Duration elapsed) {
    final hours = elapsed.inMinutes / 60.0;
    return FastingStage.fromHoursElapsed(hours);
  }

  /// Calculates remaining time until target end time.
  static Duration getRemainingTime(DateTime targetEndTime) {
    final now = DateTime.now();
    if (now.isAfter(targetEndTime)) return Duration.zero;
    return targetEndTime.difference(now);
  }

  /// Formats duration as HH:MM:SS.
  static String formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
