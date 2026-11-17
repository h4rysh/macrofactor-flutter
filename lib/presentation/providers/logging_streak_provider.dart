import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'app_providers.dart';

/// Computes the current consecutive-day food logging streak up to and
/// including today. A day counts only if at least one food entry was logged
/// on that calendar date. The streak resets the moment a past day has no log.
final loggingStreakProvider = Provider<int>((ref) {
  // Re-compute whenever logs change or the selected date changes.
  ref.watch(foodLogsRevisionProvider);

  final clock = ref.watch(clockProvider);
  final db = ref.watch(databaseProvider);
  final fmt = DateFormat('yyyy-MM-dd');

  // Fetch calorie totals keyed by date string — O(1) single DB pass.
  final dailyCalories = db.getDailyCalorieTotals();

  final today = clock();
  int streak = 0;

  // Walk backwards from today until we hit an un-logged day.
  for (int offset = 0; offset <= 365; offset++) {
    final day = today.subtract(Duration(days: offset));
    final key = fmt.format(day);
    final calories = dailyCalories[key] ?? 0.0;
    if (calories > 0) {
      streak++;
    } else {
      // Gap found — streak ends here.
      break;
    }
  }

  return streak;
});
