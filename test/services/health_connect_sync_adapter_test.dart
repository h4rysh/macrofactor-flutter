import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:sique/data/services/health_connect_sync_adapter.dart';
import 'package:sique/domain/models/workout_session.dart';

/// Test double extending [Health] to stub native Google Health Connect behavior.
class FakeHealth extends Health {
  FakeHealth({
    this.mockIsAvailable = true,
    this.mockSdkStatus = HealthConnectSdkStatus.sdkAvailable,
    this.mockHasPermissions = true,
    this.mockRequestAuth = true,
    this.mockDataPoints = const [],
    this.shouldThrow = false,
  });

  bool mockIsAvailable;
  HealthConnectSdkStatus mockSdkStatus;
  bool mockHasPermissions;
  bool mockRequestAuth;
  List<HealthDataPoint> mockDataPoints;
  bool shouldThrow;

  @override
  Future<void> configure() async {
    if (shouldThrow) throw Exception('Native configuration failure');
  }

  Future<bool?> isHealthDataAvailable() async {
    if (shouldThrow) throw Exception('Native health bridge failure');
    return mockIsAvailable;
  }

  @override
  Future<HealthConnectSdkStatus?> getHealthConnectSdkStatus() async {
    if (shouldThrow) throw Exception('Native SDK status check failure');
    return mockSdkStatus;
  }

  @override
  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    if (shouldThrow) throw Exception('Native permission inquiry failure');
    return mockHasPermissions;
  }

  @override
  Future<bool> requestAuthorization(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    if (shouldThrow) throw Exception('Native authorization request failure');
    return mockRequestAuth;
  }

  @override
  Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required List<HealthDataType> types,
    Map<HealthDataType, HealthDataUnit>? preferredUnits,
    required DateTime startTime,
    required DateTime endTime,
    List<RecordingMethod> recordingMethodsToFilter = const [],
  }) async {
    if (shouldThrow) throw Exception('Native data fetch failure');
    return mockDataPoints;
  }
}

HealthDataPoint createSampleWorkoutPoint({
  required String uuid,
  required String sourceName,
  required String sourceId,
  required DateTime from,
  required DateTime to,
  String? workoutTitle,
  int? burnedCalories,
  HealthWorkoutActivityType activityType =
      HealthWorkoutActivityType.WEIGHTLIFTING,
  Map<String, dynamic>? metadata,
}) {
  final mergedMetadata = <String, dynamic>{
    if (workoutTitle != null) 'title': workoutTitle,
    ...?metadata,
  };

  return HealthDataPoint(
    uuid: uuid,
    value: WorkoutHealthValue(
      workoutActivityType: activityType,
      totalEnergyBurned: burnedCalories,
      totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
    ),
    type: HealthDataType.WORKOUT,
    unit: HealthDataUnit.NO_UNIT,
    dateFrom: from,
    dateTo: to,
    sourcePlatform: HealthPlatformType.googleHealthConnect,
    sourceDeviceId: 'phone_test_device',
    sourceId: sourceId,
    sourceName: sourceName,
    workoutSummary: WorkoutSummary(
      workoutType: 'Strength Training',
      totalDistance: 0,
      totalEnergyBurned: burnedCalories ?? 0,
      totalSteps: 0,
    ),
    metadata: mergedMetadata,
  );
}

HealthDataPoint createSampleWeightPoint({
  required String uuid,
  required double weightKg,
  required DateTime timestamp,
  String sourceName = 'Smart Scale',
}) {
  return HealthDataPoint(
    uuid: uuid,
    value: NumericHealthValue(numericValue: weightKg),
    type: HealthDataType.WEIGHT,
    unit: HealthDataUnit.KILOGRAM,
    dateFrom: timestamp,
    dateTo: timestamp,
    sourcePlatform: HealthPlatformType.googleHealthConnect,
    sourceDeviceId: 'scale_test_device',
    sourceId: 'com.withings.healthmate',
    sourceName: sourceName,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthConnectSyncAdapter Platform Guard Tests', () {
    test('returns false / empty when non-Android platform is detected',
        () async {
      final fakeHealth = FakeHealth();
      final adapter = HealthConnectSyncAdapter(
        health: fakeHealth,
        isAndroidOverride: false,
      );

      expect(await adapter.isAvailable(), isFalse);
      expect(await adapter.hasPermissions(), isFalse);
      expect(await adapter.requestPermissions(), isFalse);

      final now = DateTime.now();
      final workouts = await adapter.fetchWorkouts(
        startTime: now.subtract(const Duration(days: 7)),
        endTime: now,
      );
      expect(workouts, isEmpty);

      final weights = await adapter.fetchWeights(
        startTime: now.subtract(const Duration(days: 7)),
        endTime: now,
      );
      expect(weights, isEmpty);
    });
  });

  group('HealthConnectSyncAdapter Availability & Permissions', () {
    test(
        'isAvailable returns true when health data available and SDK is installed',
        () async {
      final fakeHealth = FakeHealth(
        mockIsAvailable: true,
        mockSdkStatus: HealthConnectSdkStatus.sdkAvailable,
      );
      final adapter = HealthConnectSyncAdapter(
        health: fakeHealth,
        isAndroidOverride: true,
      );

      final available = await adapter.isAvailable();
      expect(available, isTrue);
    });

    test(
        'isAvailable returns false when SDK status is unavailable or requires update',
        () async {
      final fakeHealth = FakeHealth(
        mockIsAvailable: true,
        mockSdkStatus: HealthConnectSdkStatus.sdkUnavailable,
      );
      final adapter = HealthConnectSyncAdapter(
        health: fakeHealth,
        isAndroidOverride: true,
      );
      expect(await adapter.isAvailable(), isFalse);

      fakeHealth.mockSdkStatus =
          HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired;
      expect(await adapter.isAvailable(), isFalse);
    });

    test('isAvailable catches exceptions and returns false safely', () async {
      final fakeHealth = FakeHealth(shouldThrow: true);
      final adapter = HealthConnectSyncAdapter(
        health: fakeHealth,
        isAndroidOverride: true,
      );

      expect(await adapter.isAvailable(), isFalse);
    });

    test('hasPermissions returns true only when all permissions are granted',
        () async {
      final fakeHealth = FakeHealth(mockHasPermissions: true);
      final adapter = HealthConnectSyncAdapter(
        health: fakeHealth,
        isAndroidOverride: true,
      );

      expect(await adapter.hasPermissions(), isTrue);

      fakeHealth.mockHasPermissions = false;
      expect(await adapter.hasPermissions(), isFalse);
    });

    test(
        'requestPermissions delegates to Health and returns authorization status',
        () async {
      final fakeHealth = FakeHealth(mockRequestAuth: true);
      final adapter = HealthConnectSyncAdapter(
        health: fakeHealth,
        isAndroidOverride: true,
      );

      expect(await adapter.requestPermissions(), isTrue);

      fakeHealth.mockRequestAuth = false;
      expect(await adapter.requestPermissions(), isFalse);
    });

    test('requestPermissions handles native platform errors gracefully',
        () async {
      final fakeHealth = FakeHealth(shouldThrow: true);
      final adapter = HealthConnectSyncAdapter(
        health: fakeHealth,
        isAndroidOverride: true,
      );

      expect(await adapter.requestPermissions(), isFalse);
    });
  });

  group('HealthConnectSyncAdapter Workout Ingestion & Hevy Parsing', () {
    final now = DateTime(2026, 10, 17, 10, 0);
    final startTime = now.subtract(const Duration(hours: 1));

    test('returns empty when permissions are missing', () async {
      final fakeHealth = FakeHealth(mockHasPermissions: false);
      final adapter = HealthConnectSyncAdapter(
        health: fakeHealth,
        isAndroidOverride: true,
      );

      final workouts = await adapter.fetchWorkouts(
        startTime: startTime,
        endTime: now,
      );
      expect(workouts, isEmpty);
    });

    test('correctly detects and parses Hevy workouts by sourceName', () async {
      final hevyPoint = createSampleWorkoutPoint(
        uuid: 'hevy-session-001',
        sourceName: 'Hevy',
        sourceId: 'com.hevy.app',
        from: DateTime(2026, 10, 17, 8, 0),
        to: DateTime(2026, 10, 17, 9, 15),
        workoutTitle: 'Chest and Triceps Hypertrophy',
        burnedCalories: 420,
      );

      final fakeHealth = FakeHealth(
        mockHasPermissions: true,
        mockDataPoints: [hevyPoint],
      );
      final adapter = HealthConnectSyncAdapter(
        health: fakeHealth,
        isAndroidOverride: true,
      );

      final workouts = await adapter.fetchWorkouts(
        startTime: DateTime(2026, 10, 17, 0, 0),
        endTime: DateTime(2026, 10, 17, 23, 59),
      );

      expect(workouts.length, equals(1));
      final workout = workouts.first;
      expect(workout.id, equals('hevy-session-001'));
      expect(workout.source, equals(WorkoutSource.hevy));
      expect(workout.title, equals('Hevy: Chest and Triceps Hypertrophy'));
      expect(workout.durationMinutes, equals(75));
      expect(workout.caloriesBurned, equals(420.0));
    });

    test(
        'handles Hevy title without redundant prefix when title already starts with Hevy',
        () async {
      final hevyPoint = createSampleWorkoutPoint(
        uuid: 'hevy-session-002',
        sourceName: 'hevy_tracker',
        sourceId: 'com.hevy',
        from: DateTime(2026, 10, 17, 7, 0),
        to: DateTime(2026, 10, 17, 8, 0),
        workoutTitle: 'Hevy Leg Day',
        burnedCalories: 510,
      );

      final fakeHealth = FakeHealth(
        mockHasPermissions: true,
        mockDataPoints: [hevyPoint],
      );
      final adapter = HealthConnectSyncAdapter(
        health: fakeHealth,
        isAndroidOverride: true,
      );

      final workouts = await adapter.fetchWorkouts(
        startTime: DateTime(2026, 10, 17, 0, 0),
        endTime: DateTime(2026, 10, 17, 23, 59),
      );

      expect(workouts.first.title, equals('Hevy Leg Day'));
      expect(workouts.first.source, equals(WorkoutSource.hevy));
    });

    test(
        'detects Hevy via metadata source attribute when sourceName is generic',
        () async {
      final hevyPoint = createSampleWorkoutPoint(
        uuid: 'hevy-session-003',
        sourceName: 'Health Connect Sync',
        sourceId: 'android.healthconnect',
        from: DateTime(2026, 10, 16, 18, 0),
        to: DateTime(2026, 10, 16, 19, 0),
        activityType: HealthWorkoutActivityType.OTHER,
        workoutTitle: null,
        metadata: {'source': 'hevy'},
      );

      final fakeHealth = FakeHealth(
        mockHasPermissions: true,
        mockDataPoints: [hevyPoint],
      );
      final adapter = HealthConnectSyncAdapter(
        health: fakeHealth,
        isAndroidOverride: true,
      );

      final workouts = await adapter.fetchWorkouts(
        startTime: DateTime(2026, 10, 16, 0, 0),
        endTime: DateTime(2026, 10, 16, 23, 59),
      );

      expect(workouts.first.source, equals(WorkoutSource.hevy));
      expect(workouts.first.title, equals('Hevy Strength Session'));
    });

    test('maps non-Hevy third-party workouts to WorkoutSource.healthConnect',
        () async {
      final stravaPoint = createSampleWorkoutPoint(
        uuid: 'strava-run-001',
        sourceName: 'Strava',
        sourceId: 'com.strava',
        from: DateTime(2026, 10, 17, 6, 0),
        to: DateTime(2026, 10, 17, 6, 45),
        workoutTitle: 'Morning 5K Tempo Run',
        burnedCalories: 380,
      );

      final fakeHealth = FakeHealth(
        mockHasPermissions: true,
        mockDataPoints: [stravaPoint],
      );
      final adapter = HealthConnectSyncAdapter(
        health: fakeHealth,
        isAndroidOverride: true,
      );

      final workouts = await adapter.fetchWorkouts(
        startTime: DateTime(2026, 10, 17, 0, 0),
        endTime: DateTime(2026, 10, 17, 23, 59),
      );

      expect(workouts.length, equals(1));
      expect(workouts.first.source, equals(WorkoutSource.healthConnect));
      expect(workouts.first.title, equals('Morning 5K Tempo Run'));
      expect(workouts.first.durationMinutes, equals(45));
      expect(workouts.first.caloriesBurned, equals(380.0));
    });

    test('handles exceptions during workout retrieval gracefully', () async {
      final fakeHealth = FakeHealth(
        mockHasPermissions: true,
        shouldThrow: true,
      );
      final adapter = HealthConnectSyncAdapter(
        health: fakeHealth,
        isAndroidOverride: true,
      );

      final workouts = await adapter.fetchWorkouts(
        startTime: startTime,
        endTime: now,
      );
      expect(workouts, isEmpty);
    });
  });

  group('HealthConnectSyncAdapter Scale Weight Ingestion', () {
    test('returns empty when permissions are missing', () async {
      final fakeHealth = FakeHealth(mockHasPermissions: false);
      final adapter = HealthConnectSyncAdapter(
        health: fakeHealth,
        isAndroidOverride: true,
      );

      final weights = await adapter.fetchWeights(
        startTime: DateTime(2026, 10, 1),
        endTime: DateTime(2026, 10, 17),
      );
      expect(weights, isEmpty);
    });

    test('parses weight data points into ScaleWeightEntry models', () async {
      final timestamp = DateTime(2026, 10, 17, 7, 30);
      final weightPoint = createSampleWeightPoint(
        uuid: 'weight-entry-001',
        weightKg: 82.45,
        timestamp: timestamp,
        sourceName: 'Withings Smart Scale',
      );

      final fakeHealth = FakeHealth(
        mockHasPermissions: true,
        mockDataPoints: [weightPoint],
      );
      final adapter = HealthConnectSyncAdapter(
        health: fakeHealth,
        isAndroidOverride: true,
      );

      final weights = await adapter.fetchWeights(
        startTime: DateTime(2026, 10, 16),
        endTime: DateTime(2026, 10, 18),
      );

      expect(weights.length, equals(1));
      final entry = weights.first;
      expect(entry.date, equals(timestamp));
      expect(entry.weightKg, equals(82.45));
      expect(entry.note, contains('Withings Smart Scale'));
      expect(entry.source, equals('health_connect'));
    });

    test('handles exceptions during weight retrieval gracefully', () async {
      final fakeHealth = FakeHealth(
        mockHasPermissions: true,
        shouldThrow: true,
      );
      final adapter = HealthConnectSyncAdapter(
        health: fakeHealth,
        isAndroidOverride: true,
      );

      final weights = await adapter.fetchWeights(
        startTime: DateTime(2026, 10, 1),
        endTime: DateTime(2026, 10, 17),
      );
      expect(weights, isEmpty);
    });
  });
}
