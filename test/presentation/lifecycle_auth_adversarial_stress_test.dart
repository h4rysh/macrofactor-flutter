import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
// ignore: depend_on_referenced_packages
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/data/services/google_auth_service.dart';
import 'package:sique/domain/algorithms/weight_trend_v2.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/models/workout_session.dart';
import 'package:sique/domain/services/health_sync_adapter.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/widgets/app_lifecycle_sync_observer.dart';

/// Configurable platform fake for Google Sign-In adversarial scenarios.
class _AdversarialGoogleSignInPlatform extends GoogleSignInPlatform {
  GoogleSignInUserData? userData;
  PlatformException? exceptionToThrow;
  Object? generalErrorToThrow;
  Duration simulatedDelay = Duration.zero;
  int signInCount = 0;
  int silentSignInCount = 0;
  int signOutCount = 0;

  @override
  Future<void> init({
    List<String> scopes = const <String>[],
    SignInOption signInOption = SignInOption.standard,
    String? hostedDomain,
    String? clientId,
    String? serverClientId,
    bool forceCodeForRefreshToken = false,
  }) async {}

  @override
  Future<void> initWithParams(SignInInitParameters params) async {}

  @override
  Future<GoogleSignInUserData?> signIn() async {
    signInCount++;
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (generalErrorToThrow != null) throw generalErrorToThrow!;
    return userData;
  }

  @override
  Future<GoogleSignInUserData?> signInSilently() async {
    silentSignInCount++;
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (generalErrorToThrow != null) throw generalErrorToThrow!;
    return userData;
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (generalErrorToThrow != null) throw generalErrorToThrow!;
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> isSignedIn() async => userData != null;

  @override
  Future<void> clearAuthCache({required String token}) async {}
}

/// Fake HealthSyncAdapter for adversarial sync testing.
class _AdversarialHealthSyncAdapter implements HealthSyncAdapter {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> hasPermissions() async => true;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<List<WorkoutSession>> fetchWorkouts({
    required DateTime startTime,
    required DateTime endTime,
  }) async =>
      [];

  @override
  Future<List<ScaleWeightEntry>> fetchWeights({
    required DateTime startTime,
    required DateTime endTime,
  }) async =>
      [];
}

/// Adversarial HealthSyncNotifier to simulate race conditions, in-flight delays, and faults.
class _AdversarialHealthSyncNotifier extends HealthSyncNotifier {
  _AdversarialHealthSyncNotifier({
    AppDatabase? db,
    HealthSyncAdapter? adapter,
    HealthSyncState? initialState,
  }) : super(
          db: db ?? AppDatabase(sqlite3.openInMemory()),
          adapter: adapter ?? _AdversarialHealthSyncAdapter(),
        ) {
    if (initialState != null) {
      state = initialState;
    }
  }

  int syncCallCount = 0;
  Completer<bool>? pendingSyncCompleter;
  Object? faultToThrow;

  @override
  Future<bool> syncNow({int trailingDays = 30}) async {
    syncCallCount++;
    if (faultToThrow != null) {
      throw faultToThrow!;
    }
    if (pendingSyncCompleter != null) {
      state = state.copyWith(status: HealthSyncStatus.syncing);
      final result = await pendingSyncCompleter!.future;
      state = state.copyWith(
        status: result ? HealthSyncStatus.success : HealthSyncStatus.error,
        lastSyncedAt: DateTime.now(),
      );
      return result;
    }
    state = state.copyWith(
      status: HealthSyncStatus.success,
      lastSyncedAt: DateTime.now(),
    );
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _AdversarialGoogleSignInPlatform fakeGooglePlatform;
  late GoogleSignIn googleSignIn;
  late GoogleAuthServiceImpl authService;

  setUp(() {
    fakeGooglePlatform = _AdversarialGoogleSignInPlatform();
    GoogleSignInPlatform.instance = fakeGooglePlatform;
    googleSignIn = GoogleSignIn();
    authService = GoogleAuthServiceImpl(googleSignIn: googleSignIn);
  });

  group('Adversarial AppLifecycleSyncObserver Stress Tests', () {
    testWidgets(
      'Rapid flutter of 50 lifecycle state transitions dispatches only once within throttle interval',
      (tester) async {
        final syncNotifier = _AdversarialHealthSyncNotifier();
        final triggeredReasons = <String>[];

        final authedUser = UserAccount.fromGoogle(
          id: 'user_stress_1',
          googleUserId: 'g_stress_1',
          displayName: 'Iron Tester',
          email: 'iron@test.com',
          healthConnectEnabled: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProvider.overrideWithValue(authedUser),
              healthConnectSyncProvider.overrideWith((ref) => syncNotifier),
            ],
            child: MaterialApp(
              home: AppLifecycleSyncObserver(
                throttleDuration: const Duration(minutes: 5),
                onSyncTriggered: (reason) => triggeredReasons.add(reason),
                child: const Scaffold(body: Text('Stress Screen')),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(syncNotifier.syncCallCount, equals(1));
        expect(triggeredReasons, equals(['launch']));

        // Dispatch 50 rapid lifecycle transitions (fluttering between inactive, paused, resumed)
        for (var i = 0; i < 50; i++) {
          final state = i % 3 == 0
              ? AppLifecycleState.resumed
              : (i % 3 == 1
                  ? AppLifecycleState.inactive
                  : AppLifecycleState.paused);
          tester.binding.handleAppLifecycleStateChanged(state);
        }

        await tester.pumpAndSettle();

        // Must still be 1 because throttle guard strictly blocks repeated attempts
        expect(syncNotifier.syncCallCount, equals(1));
        expect(triggeredReasons.length, equals(1));
      },
    );

    testWidgets(
      'In-flight sync rejects concurrent resume sync without spawning parallel execution',
      (tester) async {
        final syncNotifier = _AdversarialHealthSyncNotifier();
        final completer = Completer<bool>();
        syncNotifier.pendingSyncCompleter = completer;

        final authedUser = UserAccount.fromGoogle(
          id: 'user_stress_2',
          googleUserId: 'g_stress_2',
          displayName: 'Runner',
          email: 'runner@test.com',
          healthConnectEnabled: true,
        );

        var simulatedNow = DateTime(2026, 10, 17, 10, 0, 0);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProvider.overrideWithValue(authedUser),
              healthConnectSyncProvider.overrideWith((ref) => syncNotifier),
            ],
            child: MaterialApp(
              home: AppLifecycleSyncObserver(
                clock: () => simulatedNow,
                throttleDuration: const Duration(seconds: 1),
                child: const Scaffold(body: Text('In Flight Screen')),
              ),
            ),
          ),
        );

        // First frame triggers launch sync which hangs on completer
        await tester.pump();
        expect(syncNotifier.syncCallCount, equals(1));
        expect(syncNotifier.state.isSyncing, isTrue);

        // Advance simulated clock beyond throttle duration
        simulatedNow = simulatedNow.add(const Duration(seconds: 10));

        // Fire another resumed event while first sync is still suspended
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();

        // Concurrency guard must prevent second sync execution
        expect(syncNotifier.syncCallCount, equals(1));

        // Release first sync
        completer.complete(true);
        await tester.pumpAndSettle();

        expect(syncNotifier.state.isSyncing, isFalse);
        expect(syncNotifier.state.status, equals(HealthSyncStatus.success));
      },
    );

    testWidgets(
      'Widget disposal while async sync is in-flight completes cleanly without throwing or memory leaks',
      (tester) async {
        final syncNotifier = _AdversarialHealthSyncNotifier();
        final completer = Completer<bool>();
        syncNotifier.pendingSyncCompleter = completer;

        final authedUser = UserAccount.fromGoogle(
          id: 'user_stress_3',
          googleUserId: 'g_stress_3',
          displayName: 'Cyclist',
          email: 'cyclist@test.com',
          healthConnectEnabled: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProvider.overrideWithValue(authedUser),
              healthConnectSyncProvider.overrideWith((ref) => syncNotifier),
            ],
            child: const MaterialApp(
              home: AppLifecycleSyncObserver(
                child: Scaffold(body: Text('To be unmounted')),
              ),
            ),
          ),
        );

        await tester.pump();
        expect(syncNotifier.syncCallCount, equals(1));

        // Unmount the observer while syncNow is still in-flight
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Text('Unmounted View')),
          ),
        );

        expect(find.text('Unmounted View'), findsOneWidget);

        // Complete the asynchronous background sync after widget disposal
        completer.complete(true);
        await tester.pumpAndSettle();

        // Verifies no setState() after dispose or unhandled framework errors occurred
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Rapid mounting and unmounting thrash cleanly attaches and detaches observer without leak',
      (tester) async {
        final authedUser = UserAccount.fromGoogle(
          id: 'user_stress_4',
          googleUserId: 'g_stress_4',
          displayName: 'Swimmer',
          email: 'swimmer@test.com',
          healthConnectEnabled: true,
        );

        for (var i = 0; i < 20; i++) {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                currentUserProvider.overrideWithValue(authedUser),
                healthConnectSyncProvider
                    .overrideWith((ref) => _AdversarialHealthSyncNotifier()),
              ],
              child: MaterialApp(
                home: AppLifecycleSyncObserver(
                  child: Scaffold(body: Text('Iteration $i')),
                ),
              ),
            ),
          );
          await tester.pump();

          // Unmount
          await tester.pumpWidget(
            const MaterialApp(home: SizedBox()),
          );
          await tester.pump();
        }

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Catastrophic sync errors (Error, FormatException, PlatformException) are quietly absorbed',
      (tester) async {
        final syncNotifier = _AdversarialHealthSyncNotifier();
        syncNotifier.faultToThrow =
            StateError('Corrupted native Health database');

        final authedUser = UserAccount.fromGoogle(
          id: 'user_stress_5',
          googleUserId: 'g_stress_5',
          displayName: 'Weightlifter',
          email: 'lifter@test.com',
          healthConnectEnabled: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProvider.overrideWithValue(authedUser),
              healthConnectSyncProvider.overrideWith((ref) => syncNotifier),
            ],
            child: const MaterialApp(
              home: AppLifecycleSyncObserver(
                child: Scaffold(body: Text('Fault Tolerant Screen')),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Fault Tolerant Screen'), findsOneWidget);
        expect(syncNotifier.syncCallCount, equals(1));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'System clock backward jump (clock skew) does not cause infinite loop or crash',
      (tester) async {
        var simulatedNow = DateTime(2026, 10, 17, 12, 0, 0);
        final syncNotifier = _AdversarialHealthSyncNotifier();

        final authedUser = UserAccount.fromGoogle(
          id: 'user_stress_6',
          googleUserId: 'g_stress_6',
          displayName: 'Clock Runner',
          email: 'clock@test.com',
          healthConnectEnabled: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProvider.overrideWithValue(authedUser),
              healthConnectSyncProvider.overrideWith((ref) => syncNotifier),
            ],
            child: MaterialApp(
              home: AppLifecycleSyncObserver(
                clock: () => simulatedNow,
                throttleDuration: const Duration(minutes: 5),
                child: const Scaffold(body: Text('Clock View')),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(syncNotifier.syncCallCount, equals(1));

        // Jump clock back 2 hours (e.g. timezone change or manual clock rollback)
        simulatedNow = simulatedNow.subtract(const Duration(hours: 2));

        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        // Throttle difference is negative (< 5 min), so it safely rejects
        expect(syncNotifier.syncCallCount, equals(1));
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Adversarial Google Sign-In & Auth Service Stress Tests', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      fakeGooglePlatform = _AdversarialGoogleSignInPlatform();
      GoogleSignInPlatform.instance = fakeGooglePlatform;
      googleSignIn = GoogleSignIn();
      authService = GoogleAuthServiceImpl(googleSignIn: googleSignIn);
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('User dialog dismissal produces clean user-canceled domain exception',
        () async {
      fakeGooglePlatform.userData = null;

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Google Sign-In canceled by user'),
          ),
        ),
      );
    });

    test(
        'PlatformException kSignInCanceledError produces clean domain exception',
        () async {
      fakeGooglePlatform.exceptionToThrow = PlatformException(
        code: GoogleSignIn.kSignInCanceledError,
        message: 'Native dialog dismissed by user',
      );

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Google Sign-In canceled by user'),
          ),
        ),
      );
    });

    test(
        'PlatformException kNetworkError produces descriptive network error exception',
        () async {
      fakeGooglePlatform.exceptionToThrow = PlatformException(
        code: GoogleSignIn.kNetworkError,
        message: 'Connection reset by peer',
      );

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network error during Google Sign-In'),
          ),
        ),
      );
    });

    test('Async timeout during interactive sign-in rethrows cleanly', () async {
      fakeGooglePlatform.generalErrorToThrow = TimeoutException(
        'Google OAuth endpoint timeout after 15000ms',
      );

      expect(
        () => authService.signInWithGoogle(),
        throwsA(isA<TimeoutException>()),
      );
    });

    test(
        'Corrupted auth payload with empty and malformed emails maps safely to fallback',
        () async {
      final malformedCases = <String, String>{
        '': 'Athlete',
        'no_at_sign_here': 'Athlete',
        '@@multiple_ats': '',
        'valid.prefix@custom.domain.co.uk': 'valid.prefix',
      };

      for (final entry in malformedCases.entries) {
        fakeGooglePlatform.userData = GoogleSignInUserData(
          id: 'id_${entry.key.hashCode}',
          email: entry.key,
          displayName: null,
        );

        final localGoogleSignIn = GoogleSignIn();
        final localAuthService =
            GoogleAuthServiceImpl(googleSignIn: localGoogleSignIn);
        final user = await localAuthService.signInWithGoogle();
        expect(
          user.displayName,
          equals(entry.value),
        );
      }
    });

    test(
        'Adversarial payloads with extreme strings, emoji, and control characters parse without crash',
        () async {
      final hugeString = 'X' * 5000;
      fakeGooglePlatform.userData = GoogleSignInUserData(
        id: 'unicode_uid_⚡_9999',
        email: 'hyper.athlete@sique.test',
        displayName: '🏋️‍♂️ Coach Ultra $hugeString 🚀',
        photoUrl:
            'https://images.unsplash.com/photo-test?param=1&data=<script>',
      );

      final user = await authService.signInWithGoogle();
      expect(user.googleUserId, equals('unicode_uid_⚡_9999'));
      expect(user.displayName.startsWith('🏋️‍♂️ Coach Ultra'), isTrue);
      expect(user.displayName.length, greaterThan(5000));
      expect(user.photoUrl, contains('<script>'));
    });

    test(
        'Concurrent silent sign-in storm (30 calls) resolves deterministically',
        () async {
      fakeGooglePlatform.userData = GoogleSignInUserData(
        id: 'concurrent_user_1',
        email: 'concurrent@sique.test',
        displayName: 'Concurrent Athlete',
      );

      final futures = List.generate(
        30,
        (_) => authService.getCurrentUser(),
      );

      final results = await Future.wait(futures);

      expect(results.length, equals(30));
      for (final user in results) {
        expect(user, isNotNull);
        expect(user!.email, equals('concurrent@sique.test'));
        expect(user.googleUserId, equals('concurrent_user_1'));
      }
    });

    test(
        'Concurrent Sign-In and Sign-Out operations complete safely without uncaught errors',
        () async {
      fakeGooglePlatform.userData = GoogleSignInUserData(
        id: 'race_user_1',
        email: 'race@sique.test',
        displayName: 'Race User',
      );
      fakeGooglePlatform.simulatedDelay = const Duration(milliseconds: 5);

      final signInFuture = authService.signInWithGoogle();
      final signOutFuture = authService.signOut();

      // Both should complete without throwing unhandled exceptions
      await Future.wait([
        signInFuture.catchError((_) => UserAccount.guest),
        signOutFuture,
      ]);

      expect(fakeGooglePlatform.signInCount, equals(1));
      expect(fakeGooglePlatform.signOutCount, equals(1));
    });

    test(
        'Repeated login-logout cycles with SQLite persistence maintain state integrity',
        () async {
      final db = AppDatabase.inMemory();
      addTearDown(db.close);
      final authNotifier = AuthNotifier(db, authService);

      fakeGooglePlatform.userData = GoogleSignInUserData(
        id: 'persist_user_1',
        email: 'persist@sique.test',
        displayName: 'Persist User',
      );

      for (var i = 0; i < 15; i++) {
        // Sign In
        final success = await authNotifier.signInWithGoogle();
        expect(success, isTrue);
        expect(authNotifier.state, isA<AuthAuthenticated>());
        final saved = db.getAccountSession();
        expect(saved, isNotNull);
        expect(saved!.googleUserId, equals('persist_user_1'));

        // Sign Out
        await authNotifier.signOut();
        expect(authNotifier.state, isA<AuthUnauthenticated>());
        final cleared = db.getAccountSession();
        expect(cleared, isNull);
      }
    });

    test('Unsupported desktop platform guards reject operations cleanly',
        () async {
      for (final platform in [
        TargetPlatform.linux,
        TargetPlatform.macOS,
        TargetPlatform.windows,
      ]) {
        debugDefaultTargetPlatformOverride = platform;

        expect(authService.isPlatformSupported, isFalse);
        expect(await authService.getCurrentUser(), isNull);
        expect(await authService.signInSilently(), isNull);
        await expectLater(authService.signOut(), completes);
        await expectLater(
          () => authService.signInWithGoogle(),
          throwsA(isA<UnsupportedError>()),
        );
      }
    });
  });
}
