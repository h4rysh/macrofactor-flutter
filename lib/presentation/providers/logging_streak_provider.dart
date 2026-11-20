import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'app_providers.dart';

/// Computes the current consecutive-day food logging streak up to and
/// including today. A day counts only if at least one food entry was logged
/// on that calendar date.
///
/// Grants a grace period for the current day until midnight: if food has not
/// yet been logged today (e.g., in the morning before breakfast), yesterday's
/// streak is preserved rather than resetting to 0 (ISS-2-06). Once food is logged
/// today, today increments the streak. If yesterday was also unlogged, streak is 0.
final loggingStreakProvider = Provider<int>((ref) {
  // Re-compute whenever logs change or the selected date changes.
  ref.watch(foodLogsRevisionProvider);

  final clock = ref.watch(clockProvider);
  final db = ref.watch(databaseProvider);
  final fmt = DateFormat('yyyy-MM-dd');

  // Fetch calorie totals keyed by date string — O(1) single DB pass.
  final dailyCalories = db.getDailyCalorieTotals();

  final today = clock();
  final todayKey = fmt.format(today);
  final bool loggedToday = (dailyCalories[todayKey] ?? 0.0) > 0;

  int streak = 0;

  if (loggedToday) {
    streak = 1;
    // Walk backwards from yesterday
    for (int offset = 1; offset <= 365; offset++) {
      final day = DateTime(today.year, today.month, today.day - offset);
      final key = fmt.format(day);
      final calories = dailyCalories[key] ?? 0.0;
      if (calories > 0) {
        streak++;
      } else {
        break;
      }
    }
  } else {
    // Grace period for today: count streak ending on yesterday
    for (int offset = 1; offset <= 365; offset++) {
      final day = DateTime(today.year, today.month, today.day - offset);
      final key = fmt.format(day);
      final calories = dailyCalories[key] ?? 0.0;
      if (calories > 0) {
        streak++;
      } else {
        break;
      }
    }
  }

  return streak;
});
