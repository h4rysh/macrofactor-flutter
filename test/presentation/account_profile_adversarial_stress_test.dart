import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/algorithms/weight_trend_v2.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/models/workout_session.dart';
import 'package:sique/domain/services/auth_service.dart';
import 'package:sique/domain/services/health_sync_adapter.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/account_profile_screen.dart';
import 'package:sique/presentation/widgets/recent_workout_card.dart';
import 'package:sique/presentation/widgets/workout_consistency_tracker.dart';

class _FakeAuthService implements AuthService {
  _FakeAuthService();

  UserAccount? currentUser;
  int signInCallCount = 0;
  int signOutCallCount = 0;

  @override
  Future<UserAccount?> getCurrentUser() async => currentUser;

  @override
  Future<UserAccount?> signInSilently() async => currentUser;

  @override
  Future<UserAccount> signInWithGoogle() async {
    signInCallCount++;
    currentUser = UserAccount.fromGoogle(
      googleUserId: 'google_stress_user',
      displayName: 'Stress Athlete',
      email: 'stress@example.com',
    );
    return currentUser!;
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    currentUser = null;
  }
}

class _FakeHealthSyncAdapter implements HealthSyncAdapter {
  int fetchWorkoutsCallCount = 0;

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
  }) async {
    fetchWorkoutsCallCount++;
    return [];
  }

  @override
  Future<List<ScaleWeightEntry>> fetchWeights({
    required DateTime startTime,
    required DateTime endTime,
  }) async =>
      [];
}

void main() {
  late AppDatabase db;
  late _FakeAuthService authService;
  late _FakeHealthSyncAdapter syncAdapter;

  setUp(() {
    db = AppDatabase.inMemory();
    authService = _FakeAuthService();
    syncAdapter = _FakeHealthSyncAdapter();
  });

  tearDown(() {
    db.close();
  });

  Widget createHarness({
    UserAccount? user,
    List<WorkoutSession> sessions = const [],
    Size size = const Size(1080, 2400),
  }) {
    if (user != null) {
      db.saveAccountSession(user);
      authService.currentUser = user;
    }
    if (sessions.isNotEmpty) {
      db.insertWorkoutSessions(sessions);
    }

    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        authServiceProvider.overrideWithValue(authService),
        healthSyncAdapterProvider.overrideWithValue(syncAdapter),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: const AccountProfileScreen(),
        ),
      ),
    );
  }

  group('Challenge 1: Zero Workouts & Empty State Resilience', () {
    testWidgets(
        'renders clean empty state with Key("recent_workouts_empty_state") and 0 stats',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      // Empty state container must be rendered
      final emptyFinder = find.byKey(const Key('recent_workouts_empty_state'));
      expect(emptyFinder, findsOneWidget);
      expect(find.text('No workouts synced yet'), findsOneWidget);
      expect(
          find.text(
              'Workouts logged in Hevy or Google Health Connect will appear here.'),
          findsOneWidget);

      // Hero Grid shows 0 stats without division-by-zero or NaN
      expect(find.byKey(const Key('hero_stat_total_workouts')), findsOneWidget);
      expect(find.text('0'), findsWidgets); // Total workouts, active cals
      expect(find.text('0m'), findsWidgets); // Total duration, avg duration
      expect(find.text('0 Hevy'), findsOneWidget);

      // Weekly Consistency Tracker
      expect(find.text('0 sessions this week'), findsOneWidget);
      expect(find.text('4-wk avg: 0.0 / wk'), findsOneWidget);

      // Ensure no workout cards exist
      expect(find.byType(RecentWorkoutCard), findsNothing);
    });
  });

  group('Challenge 2: Extreme Large Values & Volume Stress', () {
    testWidgets('stress-tests 10,000 workouts without UI overflow or crash',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();
      // Generate 10,000 workout sessions
      final largeBatch = List.generate(
        10000,
        (i) => WorkoutSession(
          id: 'stress_workout_$i',
          source: i.isEven ? WorkoutSource.hevy : WorkoutSource.healthConnect,
          title: 'Session #$i',
          startTime: now.subtract(Duration(hours: i * 2)),
          endTime: now.subtract(Duration(hours: i * 2 - 1)),
          durationMinutes: 60,
          caloriesBurned: 350.0,
          createdAt: now.subtract(Duration(hours: i * 2)),
        ),
      );

      await tester.pumpWidget(createHarness(sessions: largeBatch));
      await tester.pumpAndSettle();

      // Verify feed caps at recent 10 and renders total
      expect(find.text('10 total'), findsOneWidget);
      expect(find.byType(RecentWorkoutCard), findsNWidgets(10));
      expect(
          find.byKey(const Key('recent_workouts_empty_state')), findsNothing);

      // Verify hero stats displays 10000 workouts and 5000 Hevy
      expect(find.text('10000'), findsOneWidget);
      expect(find.text('5000 via Hevy'), findsOneWidget);
      expect(find.text('5000 Hevy'), findsOneWidget);
    });

    testWidgets(
        'handles giant values: 999,999 minutes and giant calories on standard viewport',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();
      final extremeSession = WorkoutSession(
        id: 'extreme_values_1',
        source: WorkoutSource.hevy,
        title: 'Ultra Marathon Workout',
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now,
        durationMinutes: 999999,
        caloriesBurned: 12345678.0,
        createdAt: now,
      );

      await tester.pumpWidget(
        createHarness(
          sessions: [extremeSession],
          size: const Size(1080, 2400),
        ),
      );
      await tester.pumpAndSettle();

      // Check duration formatting (999999 / 60 = 16666.7h)
      expect(find.text('16666.7h'), findsOneWidget);
      expect(find.text('999999 mins total'), findsOneWidget);

      // Check giant calories
      expect(find.text('12345678'), findsOneWidget);

      // Ensure no flutter overflow errors occurred on standard width
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'compact viewport width (360px) renders WorkoutConsistencyTracker without horizontal RenderFlex overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();
      final session = WorkoutSession(
        id: 'compact_session_1',
        source: WorkoutSource.hevy,
        title: 'Standard Workout',
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now,
        durationMinutes: 45,
        caloriesBurned: 300.0,
        createdAt: now,
      );

      await tester.pumpWidget(
        createHarness(
          sessions: [session],
          size: const Size(360, 640),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('handles 0 calories and 0 duration minutes sessions cleanly',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final zeroSession = WorkoutSession(
        id: 'zero_cal_1',
        source: WorkoutSource.manual,
        title: 'Meditation Session',
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
        endTime: DateTime.now(),
        durationMinutes: 0,
        caloriesBurned: 0.0,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createHarness(sessions: [zeroSession]));
      await tester.pumpAndSettle();

      expect(find.text('0m'), findsWidgets);
      expect(find.text('0 kcal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Challenge 3: 7-Day Consistency Tracker Boundary Dates', () {
    testWidgets(
        'handles sessions spanning current week boundary and month transitions',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();
      // Calculate Monday of current week
      final startOfWeek = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));

      final boundarySessions = [
        // Monday morning of current week (00:01)
        WorkoutSession(
          id: 'bound_mon',
          source: WorkoutSource.hevy,
          title: 'Monday Morning Lift',
          startTime: startOfWeek.add(const Duration(minutes: 1)),
          endTime: startOfWeek.add(const Duration(minutes: 61)),
          durationMinutes: 60,
          caloriesBurned: 300.0,
          createdAt: startOfWeek,
        ),
        // Just before Monday (Sunday night 23:59:00 - previous week)
        WorkoutSession(
          id: 'bound_prev_sun',
          source: WorkoutSource.hevy,
          title: 'Previous Sunday Session',
          startTime: startOfWeek.subtract(const Duration(minutes: 1)),
          endTime: startOfWeek.subtract(const Duration(seconds: 1)),
          durationMinutes: 30,
          caloriesBurned: 200.0,
          createdAt: startOfWeek,
        ),
      ];

      await tester.pumpWidget(createHarness(sessions: boundarySessions));
      await tester.pumpAndSettle();

      // Only Monday session belongs to current week
      expect(find.text('1 sessions this week'), findsOneWidget);
      expect(find.byType(WorkoutConsistencyTracker), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Challenge 4: Long Strings, Unicode & Special Characters', () {
    testWidgets(
        'handles extreme user name, long email and long workout title without layout clipping',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const extremeName =
          'Supercalifragilisticexpialidocious Ultra Marathoner & Powerlifter 🏋️‍♂️ 筋トレ・マッスルファクター 🏆 力量训练';
      const extremeEmail =
          'ultra.supercalifragilisticexpialidocious.athlete.ironman@subdomain.extremely.long.domain.name.example.com';
      const extremeTitle =
          'Hypertrophy Push Day A (Incline Barbell Bench 4x8, DB Shoulder Press 3x10, Lateral Raises 4x15, Skull Crushers 3x12, Cable Flys drop set to failure) 🔥';

      final user = UserAccount.fromGoogle(
        googleUserId: 'extreme_user_1',
        displayName: extremeName,
        email: extremeEmail,
      );

      final session = WorkoutSession(
        id: 'extreme_title_1',
        source: WorkoutSource.hevy,
        title: extremeTitle,
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().subtract(const Duration(hours: 1)),
        durationMinutes: 60,
        caloriesBurned: 450.0,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createHarness(user: user, sessions: [session]));
      await tester.pumpAndSettle();

      // Verify text rendered
      expect(find.text(extremeName), findsOneWidget);
      expect(find.text(extremeEmail), findsOneWidget);
      expect(find.text(extremeTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'handles emoji-first display name in avatar fallback initial without crash',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Emoji "🔥" consists of UTF-16 surrogate pairs (2 code units)
      final emojiUser = UserAccount.fromGoogle(
        googleUserId: 'emoji_user',
        displayName: '🔥 Fire Athlete',
        email: 'fire@example.com',
        photoUrl: null, // Forces fallback initial
      );

      await tester.pumpWidget(createHarness(user: emojiUser));
      await tester.pumpAndSettle();

      expect(find.text('🔥 Fire Athlete'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Challenge 5: Null / Missing Fields & Fallbacks', () {
    testWidgets(
        'handles null photoUrl, empty email, empty displayName gracefully',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = UserAccount(
        id: 'null_fields_user',
        googleUserId: 'g_null_1',
        displayName: '',
        email: '',
        photoUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAuthenticated: true,
      );

      await tester.pumpWidget(createHarness(user: user));
      await tester.pumpAndSettle();

      // Email fallback
      expect(find.text('Local Guest Account'), findsOneWidget);
      // Fallback initial 'G'
      expect(find.text('G'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles null notes and unknown source in RecentWorkoutCard',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final session = WorkoutSession(
        id: 'session_unknown_source',
        source: 'garmin_connect',
        title: 'Outdoor Cycling',
        startTime: DateTime.now().subtract(const Duration(hours: 3)),
        endTime: DateTime.now().subtract(const Duration(hours: 2)),
        durationMinutes: 60,
        caloriesBurned: 500.0,
        notes: null,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createHarness(sessions: [session]));
      await tester.pumpAndSettle();

      expect(find.text('Outdoor Cycling'), findsOneWidget);
      expect(find.text('garmin_connect'),
          findsOneWidget); // AppleBadge fallback to raw source
      expect(tester.takeException(), isNull);
    });
  });

  group(
      'Challenge 6: Rapid Tactile Taps on AppleBouncy without Crash or Deadlock',
      () {
    testWidgets(
        'survives rapid repeated burst taps on buttons and cards without deadlock',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final session = WorkoutSession(
        id: 'rapid_tap_session',
        source: WorkoutSource.hevy,
        title: 'Tactile Test Session',
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now(),
        durationMinutes: 45,
        caloriesBurned: 300.0,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createHarness(sessions: [session]));
      await tester.pumpAndSettle();

      // Rapidly burst tap Sign In button (15 times)
      final signInBtn = find.byKey(const Key('profile_sign_in_btn'));
      expect(signInBtn, findsOneWidget);
      for (int i = 0; i < 15; i++) {
        await tester.tap(signInBtn, warnIfMissed: false);
      }
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Rapidly burst tap RecentWorkoutCard AppleBouncy
      final workoutCard =
          find.byKey(const Key('recent_workout_card_rapid_tap_session'));
      expect(workoutCard, findsOneWidget);
      for (int i = 0; i < 15; i++) {
        await tester.tap(workoutCard, warnIfMissed: false);
      }
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Rapidly burst tap Health Connect Sync Now button
      final syncBtn = find.byKey(const Key('profile_sync_now_btn'));
      await tester.scrollUntilVisible(syncBtn, 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      for (int i = 0; i < 15; i++) {
        await tester.tap(syncBtn, warnIfMissed: false);
      }
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Rapidly burst tap Edit button on PhysicalStatsSummaryCard
      final editBtn = find.byKey(const Key('physical_stats_edit_btn'));
      expect(editBtn, findsOneWidget);
      for (int i = 0; i < 10; i++) {
        await tester.tap(editBtn, warnIfMissed: false);
      }
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Ensure no exceptions thrown during or after rapid tapping
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'rapid taps during authenticated sign out dialog confirmation do not deadlock',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authedUser = UserAccount.fromGoogle(
        googleUserId: 'g_authed_rapid',
        displayName: 'Rapid Tapper',
        email: 'rapid@example.com',
      );

      await tester.pumpWidget(createHarness(user: authedUser));
      await tester.pumpAndSettle();

      final signOutBtn = find.byKey(const Key('profile_sign_out_btn'));
      expect(signOutBtn, findsOneWidget);

      // Rapidly tap sign out button 5 times
      for (int i = 0; i < 5; i++) {
        await tester.tap(signOutBtn, warnIfMissed: false);
      }
      await tester.pumpAndSettle();

      // Dialog should be displayed
      expect(find.text('Sign Out'), findsWidgets);

      // Tap Cancel
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(authService.signOutCallCount, equals(0));
      expect(tester.takeException(), isNull);
    });
  });
}
