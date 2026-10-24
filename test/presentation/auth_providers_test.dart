import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/data/services/mock_auth_service.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/models/workout_session.dart';
import 'package:sique/presentation/providers/app_providers.dart';

void main() {
  group('Auth Riverpod Providers & State Lifecycle Tests', () {
    late Database rawDb;
    late AppDatabase appDb;
    late MockAuthService mockAuth;
    late ProviderContainer container;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      appDb = AppDatabase(rawDb);
      appDb.initUserTables();
      mockAuth = MockAuthService();

      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(appDb),
          authServiceProvider.overrideWithValue(mockAuth),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      rawDb.dispose();
    });

    test('Fresh install starts in AuthUnauthenticated guest mode', () {
      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthUnauthenticated>());
      expect(state.isAuthenticated, isFalse);
      expect(state.displayName, equals('Guest Athlete'));
      expect(container.read(isAuthenticatedProvider), isFalse);
      expect(container.read(currentUserProvider).isAuthenticated, isFalse);
    });

    test(
        'Offline Launch: immediately loads cached SQLite session into AuthAuthenticated',
        () {
      final cachedAccount = UserAccount.fromGoogle(
        googleUserId: 'cached_google_123',
        displayName: 'Offline Athlete',
        email: 'offline@athletic.com',
        photoUrl: 'https://avatar.com/cached.png',
        healthConnectEnabled: true,
      );
      appDb.saveAccountSession(cachedAccount);

      // Recreate container with pre-populated SQLite database
      final offlineContainer = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(appDb),
          authServiceProvider.overrideWithValue(mockAuth),
        ],
      );
      addTearDown(offlineContainer.dispose);

      final state = offlineContainer.read(authNotifierProvider);
      expect(state, isA<AuthAuthenticated>());
      expect(state.isAuthenticated, isTrue);
      expect(state.displayName, equals('Offline Athlete'));
      expect(state.email, equals('offline@athletic.com'));
      expect(offlineContainer.read(isAuthenticatedProvider), isTrue);
    });

    test(
        'signInWithGoogle successfully authenticates and caches session to SQLite',
        () async {
      final notifier = container.read(authNotifierProvider.notifier);

      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
      expect(mockAuth.signInWithGoogleCallCount, equals(0));

      final success = await notifier.signInWithGoogle();
      expect(success, isTrue);

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthAuthenticated>());
      expect(state.isAuthenticated, isTrue);
      expect(state.displayName, equals('Alex Mercer'));
      expect(state.email, equals('alex.mercer@gmail.com'));
      expect(mockAuth.signInWithGoogleCallCount, equals(1));

      // Verify persisted to SQLite
      final dbAccount = appDb.getAccountSession();
      expect(dbAccount, isNotNull);
      expect(dbAccount!.displayName, equals('Alex Mercer'));
      expect(dbAccount.email, equals('alex.mercer@gmail.com'));
    });

    test(
        'signInWithGoogle emits AuthError and preserves previous user when sign-in fails',
        () async {
      mockAuth.shouldFailSignIn = true;
      mockAuth.signInErrorMessage = 'User dismissed Google OAuth dialog';

      final notifier = container.read(authNotifierProvider.notifier);
      final success = await notifier.signInWithGoogle();

      expect(success, isFalse);

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthError>());
      final errorState = state as AuthError;
      expect(
          errorState.message, contains('User dismissed Google OAuth dialog'));
      expect(errorState.isAuthenticated, isFalse);

      // SQLite remains clean
      expect(appDb.getAccountSession(), isNull);
    });

    test(
        'signOut clears credentials and returns to AuthUnauthenticated while preserving logs',
        () async {
      final notifier = container.read(authNotifierProvider.notifier);

      // Pre-seed user food and workout data
      appDb.insertFoodLog(FoodLogEntry(
        date: '2026-10-17',
        mealType: MealType.lunch,
        foodId: 2,
        foodName: 'Paneer Makhani',
        servingQuantity: 1.0,
        unitName: 'Katori',
        gramWeight: 150.0,
        calories: 390.0,
        protein: 14.0,
        carbs: 12.0,
        fat: 31.0,
        fiber: 2.0,
        oilModifier: OilModifier.standard,
        loggedAt: DateTime.now(),
      ));
      appDb.insertWorkoutSessions([
        WorkoutSession(
          id: 'w_sess_preserve',
          source: WorkoutSource.hevy,
          title: 'Chest & Arms',
          startTime: DateTime(2026, 10, 17, 9, 0),
          endTime: DateTime(2026, 10, 17, 10, 0),
          durationMinutes: 60,
          caloriesBurned: 380.0,
          notes: 'Hevy sync',
          createdAt: DateTime(2026, 10, 17, 10, 5),
        )
      ]);

      // Sign in first
      await notifier.signInWithGoogle();
      expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());
      expect(appDb.getAccountSession(), isNotNull);

      // Sign out
      await notifier.signOut();
      expect(mockAuth.signOutCallCount, equals(1));

      // Auth state resets
      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
      expect(container.read(isAuthenticatedProvider), isFalse);
      expect(appDb.getAccountSession(), isNull);

      // Local nutrition & workout data preserved
      expect(appDb.getFoodLogsForDate('2026-10-17').length, equals(1));
      expect(appDb.getAllWorkoutSessions().length, equals(1));
    });

    test(
        'setHealthConnectEnabled updates active session flag in memory and SQLite',
        () async {
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signInWithGoogle();

      notifier.setHealthConnectEnabled(true);

      final state = container.read(authNotifierProvider);
      expect(state.user.healthConnectEnabled, isTrue);
      expect(appDb.getAccountSession()!.healthConnectEnabled, isTrue);

      notifier.setHealthConnectEnabled(false);
      expect(container.read(authNotifierProvider).user.healthConnectEnabled,
          isFalse);
      expect(appDb.getAccountSession()!.healthConnectEnabled, isFalse);
    });

    test('updateLastHealthSync updates sync timestamp in memory and SQLite',
        () async {
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signInWithGoogle();

      final syncTime = DateTime(2026, 10, 17, 15, 30);
      notifier.updateLastHealthSync(syncTime);

      final state = container.read(authNotifierProvider);
      expect(state.user.lastHealthSyncTime, equals(syncTime));
      expect(appDb.getAccountSession()!.lastHealthSyncTime, equals(syncTime));
    });

    test('clearError resets AuthError back to normal state', () async {
      mockAuth.shouldFailSignIn = true;
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signInWithGoogle();

      expect(container.read(authNotifierProvider), isA<AuthError>());

      notifier.clearError();
      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
    });

    test(
        'signInWithDemoAthlete sets state to AuthAuthenticated and caches session to SQLite',
        () async {
      final notifier = container.read(authNotifierProvider.notifier);

      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());

      await notifier.signInWithDemoAthlete(
        displayName: 'Special Athlete',
        email: 'special.athlete@sique.local',
      );

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthAuthenticated>());
      expect(state.isAuthenticated, isTrue);
      expect(state.displayName, equals('Special Athlete'));
      expect(state.email, equals('special.athlete@sique.local'));
      expect(container.read(isAuthenticatedProvider), isTrue);

      final dbAccount = appDb.getAccountSession();
      expect(dbAccount, isNotNull);
      expect(dbAccount!.displayName, equals('Special Athlete'));
      expect(dbAccount.email, equals('special.athlete@sique.local'));
      expect(dbAccount.healthConnectEnabled, isTrue);
    });
  });
}
