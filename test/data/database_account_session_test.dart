import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:macro_factor_app/data/local/app_database.dart';
import 'package:macro_factor_app/domain/models/food_models.dart';
import 'package:macro_factor_app/domain/models/user_account.dart';
import 'package:macro_factor_app/domain/models/workout_session.dart';

void main() {
  group('AppDatabase User Account Session DAO Tests', () {
    late Database rawDb;
    late AppDatabase appDb;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      appDb = AppDatabase(rawDb);
      appDb.initUserTables();
    });

    tearDown(() {
      rawDb.dispose();
    });

    UserAccount createTestAccount({
      String id = 'active_session',
      String googleUserId = 'google_user_998877',
      String displayName = 'Marcus Thorne',
      String email = 'marcus.thorne@athletic.io',
      String? photoUrl = 'https://lh3.googleusercontent.com/a/avatar_sample',
      bool healthConnectEnabled = true,
      DateTime? lastHealthSyncTime,
      bool defaultSyncTime = true,
      DateTime? createdAt,
      DateTime? updatedAt,
    }) {
      final now = DateTime(2026, 10, 17, 12, 0);
      return UserAccount(
        id: id,
        googleUserId: googleUserId,
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
        healthConnectEnabled: healthConnectEnabled,
        lastHealthSyncTime: defaultSyncTime
            ? (lastHealthSyncTime ?? now.subtract(const Duration(hours: 1)))
            : lastHealthSyncTime,
        createdAt: createdAt ?? now.subtract(const Duration(days: 30)),
        updatedAt: updatedAt ?? now,
        isAuthenticated: true,
      );
    }

    test('Initial database launch returns null account session', () {
      final session = appDb.getAccountSession();
      expect(session, isNull);
    });

    test('Saves authenticated Google session and retrieves with exact fidelity',
        () {
      final testAccount = createTestAccount();
      appDb.saveAccountSession(testAccount);

      final loaded = appDb.getAccountSession();
      expect(loaded, isNotNull);
      expect(loaded!.id, equals(testAccount.id));
      expect(loaded.googleUserId, equals('google_user_998877'));
      expect(loaded.displayName, equals('Marcus Thorne'));
      expect(loaded.email, equals('marcus.thorne@athletic.io'));
      expect(loaded.photoUrl, equals(testAccount.photoUrl));
      expect(loaded.healthConnectEnabled, isTrue);
      expect(loaded.lastHealthSyncTime, equals(testAccount.lastHealthSyncTime));
      expect(loaded.isAuthenticated, isTrue);
    });

    test('Handles boolean healthConnectEnabled conversion accurately (1 vs 0)',
        () {
      final disabledAccount = createTestAccount(healthConnectEnabled: false);
      appDb.saveAccountSession(disabledAccount);
      expect(appDb.getAccountSession()!.healthConnectEnabled, isFalse);

      final enabledAccount = createTestAccount(healthConnectEnabled: true);
      appDb.saveAccountSession(enabledAccount);
      expect(appDb.getAccountSession()!.healthConnectEnabled, isTrue);
    });

    test(
        'Handles nullable photoUrl and nullable lastHealthSyncTime without error',
        () {
      final minimalAccount = createTestAccount(
        photoUrl: null,
        lastHealthSyncTime: null,
        defaultSyncTime: false,
      );
      appDb.saveAccountSession(minimalAccount);

      final loaded = appDb.getAccountSession();
      expect(loaded, isNotNull);
      expect(loaded!.photoUrl, isNull);
      expect(loaded.lastHealthSyncTime, isNull);
      expect(loaded.displayName, equals('Marcus Thorne'));
    });

    test(
        'Re-saving active session updates existing record without creating duplicates',
        () {
      final initial =
          createTestAccount(displayName: 'Old Name', photoUrl: 'url_1');
      appDb.saveAccountSession(initial);

      final updated = initial.copyWith(
        displayName: 'New Name',
        photoUrl: 'url_2',
        healthConnectEnabled: false,
      );
      appDb.saveAccountSession(updated);

      final loaded = appDb.getAccountSession();
      expect(loaded!.displayName, equals('New Name'));
      expect(loaded.photoUrl, equals('url_2'));
      expect(loaded.healthConnectEnabled, isFalse);

      // Verify row count remains exactly 1 in table
      final stmt =
          rawDb.prepare('SELECT COUNT(*) as count FROM user_account_session;');
      final count = (stmt.select().first['count'] as num).toInt();
      stmt.dispose();
      expect(count, equals(1));
    });

    test('clearAccountSession removes cached session cleanly', () {
      final account = createTestAccount();
      appDb.saveAccountSession(account);
      expect(appDb.getAccountSession(), isNotNull);

      appDb.clearAccountSession();
      expect(appDb.getAccountSession(), isNull);
    });

    test('clearAccountSession is idempotent and safe when called repeatedly',
        () {
      expect(() {
        appDb.clearAccountSession();
        appDb.clearAccountSession();
      }, returnsNormally);
      expect(appDb.getAccountSession(), isNull);
    });

    test(
        'Data Sovereignty: clearAccountSession preserves all food, weight, and workout logs',
        () {
      // 1. Seed food log entry
      final foodLogId = appDb.insertFoodLog(FoodLogEntry(
        date: '2026-10-17',
        mealType: MealType.breakfast,
        foodId: 1,
        foodName: 'Oatmeal & Whey',
        servingQuantity: 1.0,
        unitName: 'Bowl',
        gramWeight: 200.0,
        calories: 320.0,
        protein: 30.0,
        carbs: 45.0,
        fat: 4.0,
        fiber: 6.0,
        oilModifier: OilModifier.standard,
        loggedAt: DateTime(2026, 10, 17, 8, 0),
      ));

      // 2. Seed weight log entry
      appDb.insertWeightLog('2026-10-17', 76.4, 'Morning fasted');

      // 3. Seed workout session
      appDb.insertWorkoutSessions([
        WorkoutSession(
          id: 'sovereignty_workout',
          source: WorkoutSource.hevy,
          title: 'Squat PR Session',
          startTime: DateTime(2026, 10, 17, 10, 0),
          endTime: DateTime(2026, 10, 17, 11, 0),
          durationMinutes: 60,
          caloriesBurned: 400.0,
          notes: 'Felt great',
          createdAt: DateTime(2026, 10, 17, 11, 5),
        )
      ]);

      // 4. Save and clear account session (Sign out)
      appDb.saveAccountSession(createTestAccount());
      expect(appDb.getAccountSession(), isNotNull);

      appDb.clearAccountSession();

      // 5. Assert account session is gone
      expect(appDb.getAccountSession(), isNull);

      // 6. Assert all nutrition, weight, and workout logs remain 100% intact
      final foodLogs = appDb.getFoodLogsForDate('2026-10-17');
      expect(foodLogs.length, equals(1));
      expect(foodLogs.first.id, equals(foodLogId));
      expect(foodLogs.first.foodName, equals('Oatmeal & Whey'));

      final weights = appDb.getAllWeightLogs();
      expect(weights.length, equals(1));
      expect(weights.first.weightKg, equals(76.4));

      final workouts = appDb.getAllWorkoutSessions();
      expect(workouts.length, equals(1));
      expect(workouts.first.id, equals('sovereignty_workout'));
    });
  });
}
