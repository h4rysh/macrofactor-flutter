import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:macro_factor_app/data/services/health_connect_sync_adapter.dart';
import 'package:macro_factor_app/domain/models/workout_session.dart';

/// Test double simulating Android Health Connect under adversarial conditions.
class AdversarialFakeHealth extends Health {
  AdversarialFakeHealth({
    this.sdkStatus = HealthConnectSdkStatus.sdkAvailable,
    this.hasPerms = true,
    this.requestAuth = true,
    this.dataPoints = const [],
    this.shouldThrow = false,
    this.errorToThrow,
  });

  HealthConnectSdkStatus sdkStatus;
  bool hasPerms;
  bool requestAuth;
  List<HealthDataPoint> dataPoints;
  bool shouldThrow;
  Object? errorToThrow;

  @override
  Future<void> configure() async {
    if (shouldThrow) throw errorToThrow ?? Exception('Config failed');
  }

  @override
  Future<HealthConnectSdkStatus?> getHealthConnectSdkStatus() async {
    if (shouldThrow) throw errorToThrow ?? Exception('SDK status failed');
    return sdkStatus;
  }

  @override
  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    if (shouldThrow) throw errorToThrow ?? Exception('Permissions failed');
    return hasPerms;
  }

  @override
  Future<bool> requestAuthorization(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    if (shouldThrow) throw errorToThrow ?? Exception('Auth failed');
    return requestAuth;
  }

  @override
  Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required List<HealthDataType> types,
    Map<HealthDataType, HealthDataUnit>? preferredUnits,
    required DateTime startTime,
    required DateTime endTime,
    List<RecordingMethod> recordingMethodsToFilter = const [],
  }) async {
    if (shouldThrow) throw errorToThrow ?? Exception('Query failed');
    return dataPoints;
  }
}

HealthDataPoint makeWorkoutPoint({
  String uuid = 'test-uuid-1',
  String sourceName = 'Hevy',
  String sourceId = 'com.hevy.app',
  required DateTime from,
  required DateTime to,
  HealthValue? value,
  int? burnedCalories,
  HealthWorkoutActivityType activityType =
      HealthWorkoutActivityType.WEIGHTLIFTING,
  WorkoutSummary? workoutSummary,
  Map<String, dynamic>? metadata,
}) {
  final healthValue = value ??
      WorkoutHealthValue(
        workoutActivityType: activityType,
        totalEnergyBurned: burnedCalories,
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
      );

  return HealthDataPoint(
    uuid: uuid,
    value: healthValue,
    type: HealthDataType.WORKOUT,
    unit: HealthDataUnit.NO_UNIT,
    dateFrom: from,
    dateTo: to,
    sourcePlatform: HealthPlatformType.googleHealthConnect,
    sourceDeviceId: 'phone_pixel_9',
    sourceId: sourceId,
    sourceName: sourceName,
    workoutSummary: workoutSummary ??
        WorkoutSummary(
          workoutType: 'Strength',
          totalDistance: 0,
          totalEnergyBurned: burnedCalories ?? 0,
          totalSteps: 0,
        ),
    metadata: metadata,
  );
}

HealthDataPoint makeWeightPoint({
  String uuid = 'weight-uuid-1',
  required HealthValue value,
  required DateTime timestamp,
  String sourceName = 'Withings Body+',
  HealthDataType type = HealthDataType.WEIGHT,
}) {
  return HealthDataPoint(
    uuid: uuid,
    value: value,
    type: type,
    unit: HealthDataUnit.KILOGRAM,
    dateFrom: timestamp,
    dateTo: timestamp,
    sourcePlatform: HealthPlatformType.googleHealthConnect,
    sourceDeviceId: 'scale_device_01',
    sourceId: 'com.withings.wscale',
    sourceName: sourceName,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AdversarialFakeHealth fakeHealth;
  late HealthConnectSyncAdapter adapter;

  setUp(() {
    fakeHealth = AdversarialFakeHealth();
    adapter = HealthConnectSyncAdapter(
      health: fakeHealth,
      isAndroidOverride: true,
    );
  });

  group('Category 1: Boundary & Corrupt Dates', () {
    test('Zero and sub-minute durations clamp to 1 minute', () async {
      final t = DateTime(2026, 10, 17, 12, 0);
      fakeHealth.dataPoints = [
        makeWorkoutPoint(uuid: 'z1', from: t, to: t, burnedCalories: 50),
        makeWorkoutPoint(
          uuid: 'z2',
          from: t,
          to: t.add(const Duration(seconds: 40)),
          burnedCalories: 25,
        ),
      ];

      final res = await adapter.fetchWorkouts(
        startTime: t.subtract(const Duration(days: 1)),
        endTime: t.add(const Duration(days: 1)),
      );

      expect(res.length, equals(2));
      expect(res[0].durationMinutes, equals(1));
      expect(res[1].durationMinutes, equals(1));
    });

    test('Inverted duration (dateTo earlier than dateFrom) clamps to 1 minute',
        () async {
      final start = DateTime(2026, 10, 17, 14, 0);
      final earlierEnd = DateTime(2026, 10, 17, 13, 0);
      fakeHealth.dataPoints = [
        makeWorkoutPoint(from: start, to: earlierEnd, burnedCalories: 150),
      ];

      final res = await adapter.fetchWorkouts(
        startTime: DateTime(2026, 10, 17),
        endTime: DateTime(2026, 10, 18),
      );

      expect(res.first.durationMinutes, equals(1));
      expect(res.first.startTime, equals(start));
      expect(res.first.endTime, equals(earlierEnd));
    });

    test('Extreme duration: Multi-year session does not overflow', () async {
      final start = DateTime(2020, 1, 1);
      final end = DateTime(2026, 10, 17);
      fakeHealth.dataPoints = [
        makeWorkoutPoint(from: start, to: end, burnedCalories: 1000),
      ];

      final res = await adapter.fetchWorkouts(
        startTime: DateTime(2019),
        endTime: DateTime(2027),
      );

      expect(res.first.durationMinutes, greaterThan(3500000));
      expect(res.first.formattedDuration, endsWith('h'));
    });

    test('Unix Epoch and boundary years (1970, 2024 leap, 2099 future)',
        () async {
      final epochStart = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      final leapStart = DateTime(2024, 2, 29, 9, 0);
      final futureStart = DateTime(2099, 12, 31, 23, 0);

      fakeHealth.dataPoints = [
        makeWorkoutPoint(
          uuid: 'epoch',
          from: epochStart,
          to: epochStart.add(const Duration(minutes: 30)),
        ),
        makeWorkoutPoint(
          uuid: 'leap',
          from: leapStart,
          to: leapStart.add(const Duration(minutes: 45)),
        ),
        makeWorkoutPoint(
          uuid: 'future',
          from: futureStart,
          to: futureStart.add(const Duration(hours: 1)),
        ),
      ];

      final res = await adapter.fetchWorkouts(
        startTime: epochStart,
        endTime: DateTime(2100),
      );

      expect(res.length, equals(3));
      expect(res[0].durationMinutes, equals(30));
      expect(res[1].durationMinutes, equals(45));
      expect(res[1].startTime.day, equals(29));
      expect(res[2].durationMinutes, equals(60));
    });
  });

  group('Category 2: Missing, Null, and Adversarial Metadata', () {
    final start = DateTime(2026, 10, 17, 8, 0);
    final end = DateTime(2026, 10, 17, 9, 0);

    test('Missing, empty, and null-valued metadata parsed safely', () async {
      fakeHealth.dataPoints = [
        makeWorkoutPoint(uuid: 'm1', from: start, to: end, metadata: null),
        makeWorkoutPoint(uuid: 'm2', from: start, to: end, metadata: {}),
        makeWorkoutPoint(
          uuid: 'm3',
          from: start,
          to: end,
          metadata: {'title': null, 'source': null, 'notes': null},
        ),
      ];

      final res = await adapter.fetchWorkouts(startTime: start, endTime: end);
      expect(res.length, equals(3));
      for (final w in res) {
        expect(w.isHevy, isTrue);
        expect(w.title, equals('Hevy: Weightlifting'));
        expect(w.notes, isNull);
      }
    });

    test('Whitespace-only title falls back to activity type', () async {
      fakeHealth.dataPoints = [
        makeWorkoutPoint(
          from: start,
          to: end,
          metadata: {'title': '   \t\n  '},
        ),
      ];

      final res = await adapter.fetchWorkouts(startTime: start, endTime: end);
      expect(res.first.title, equals('Hevy: Weightlifting'));
    });

    test('Empty UUID in HealthDataPoint falls back to timestamp-based ID',
        () async {
      fakeHealth.dataPoints = [
        makeWorkoutPoint(uuid: '', from: start, to: end),
      ];

      final res = await adapter.fetchWorkouts(startTime: start, endTime: end);
      expect(
        res.first.id,
        equals('hc_workout_${start.millisecondsSinceEpoch}'),
      );
    });

    test('Unicode emojis, symbols, and extreme titles (2,000 chars) preserved',
        () async {
      const complexTitle = '🏋️ Heavy Squat PR + Core 🔥 (Week 4)';
      final hugeTitle = 'Bench Press ' * 180;
      fakeHealth.dataPoints = [
        makeWorkoutPoint(
          uuid: 'u1',
          from: start,
          to: end,
          metadata: {'title': complexTitle},
        ),
        makeWorkoutPoint(
          uuid: 'u2',
          from: start,
          to: end,
          metadata: {'title': hugeTitle},
        ),
      ];

      final res = await adapter.fetchWorkouts(startTime: start, endTime: end);
      expect(res[0].title, equals('Hevy: $complexTitle'));
      expect(res[1].title, startsWith('Hevy: Bench Press'));
      expect(res[1].title.length, greaterThan(2000));
    });
  });

  group('Category 3: Negative, Zero, and Irregular Calorie Metrics', () {
    final start = DateTime(2026, 10, 17, 10, 0);
    final end = DateTime(2026, 10, 17, 11, 0);

    test('Negative and zero calories clamped safely to 0.0', () async {
      fakeHealth.dataPoints = [
        makeWorkoutPoint(
            uuid: 'c1', from: start, to: end, burnedCalories: -450),
        makeWorkoutPoint(uuid: 'c2', from: start, to: end, burnedCalories: 0),
        makeWorkoutPoint(
          uuid: 'c3',
          from: start,
          to: end,
          value: WorkoutHealthValue(
            workoutActivityType: HealthWorkoutActivityType.WEIGHTLIFTING,
            totalEnergyBurned: null,
          ),
          workoutSummary: WorkoutSummary(
            workoutType: 'Strength',
            totalDistance: 0,
            totalEnergyBurned: -120,
            totalSteps: 0,
          ),
        ),
      ];

      final res = await adapter.fetchWorkouts(startTime: start, endTime: end);
      expect(res.length, equals(3));
      for (final w in res) {
        expect(w.caloriesBurned, equals(0.0));
      }
    });

    test('Large and non-WorkoutHealthValue calories parsed accurately',
        () async {
      fakeHealth.dataPoints = [
        makeWorkoutPoint(
          uuid: 'c4',
          from: start,
          to: end,
          burnedCalories: 15000,
        ),
        makeWorkoutPoint(
          uuid: 'c5',
          from: start,
          to: end,
          value: NumericHealthValue(numericValue: 350),
          workoutSummary: WorkoutSummary(
            workoutType: 'Strength',
            totalDistance: 0,
            totalEnergyBurned: 220,
            totalSteps: 0,
          ),
        ),
      ];

      final res = await adapter.fetchWorkouts(startTime: start, endTime: end);
      expect(res[0].caloriesBurned, equals(15000.0));
      expect(res[1].caloriesBurned, equals(220.0));
      expect(res[1].title, equals('Hevy Strength Session'));
    });
  });

  group('Category 4: Activity Types & Hevy Provenance Heuristics', () {
    final start = DateTime(2026, 10, 17, 15, 0);
    final end = DateTime(2026, 10, 17, 16, 0);

    test('ActivityType.OTHER falls back to default title for Hevy and non-Hevy',
        () async {
      fakeHealth.dataPoints = [
        makeWorkoutPoint(
          uuid: 'h1',
          sourceName: 'Hevy',
          from: start,
          to: end,
          activityType: HealthWorkoutActivityType.OTHER,
        ),
        makeWorkoutPoint(
          uuid: 'nh1',
          sourceName: 'Fitbit',
          sourceId: 'com.fitbit',
          from: start,
          to: end,
          activityType: HealthWorkoutActivityType.OTHER,
        ),
      ];

      final res = await adapter.fetchWorkouts(startTime: start, endTime: end);
      expect(res[0].title, equals('Hevy Strength Session'));
      expect(res[1].title, equals('Health Connect Workout'));
    });

    test('Multi-word activity types formatted in Title Case with spaces',
        () async {
      fakeHealth.dataPoints = [
        makeWorkoutPoint(
          from: start,
          to: end,
          activityType:
              HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING,
        ),
      ];

      final res = await adapter.fetchWorkouts(startTime: start, endTime: end);
      expect(
        res.first.title,
        equals('Hevy: High Intensity Interval Training'),
      );
    });

    test(
        'Case-insensitive Hevy source detection across sourceName and sourceId',
        () async {
      fakeHealth.dataPoints = [
        makeWorkoutPoint(
          uuid: 'h-name',
          sourceName: 'HEVY - WORKOUT TRACKER',
          sourceId: 'com.someapp',
          from: start,
          to: end,
        ),
        makeWorkoutPoint(
          uuid: 'h-id',
          sourceName: 'Third Party Bridge',
          sourceId: 'com.HEVY.android.sync',
          from: start,
          to: end,
        ),
      ];

      final res = await adapter.fetchWorkouts(startTime: start, endTime: end);
      expect(res[0].isHevy, isTrue);
      expect(res[0].source, equals(WorkoutSource.hevy));
      expect(res[1].isHevy, isTrue);
      expect(res[1].source, equals(WorkoutSource.hevy));
    });

    test('Diverse third-party non-Hevy sources attribute to healthConnect',
        () async {
      final sources = [
        'Garmin Connect',
        'Polar Flow',
        'Samsung Health',
        'Wahoo Fitness',
        'Strava',
      ];
      fakeHealth.dataPoints = [
        for (var i = 0; i < sources.length; i++)
          makeWorkoutPoint(
            uuid: 'tp-$i',
            sourceName: sources[i],
            sourceId: 'com.tracker.${sources[i].toLowerCase()}',
            from: start.add(Duration(days: i)),
            to: end.add(Duration(days: i)),
          ),
      ];

      final res = await adapter.fetchWorkouts(
        startTime: start,
        endTime: end.add(const Duration(days: 10)),
      );

      expect(res.length, equals(sources.length));
      for (final w in res) {
        expect(w.isHevy, isFalse);
        expect(w.source, equals(WorkoutSource.healthConnect));
      }
    });

    test('Hevy title prefixing avoids duplicate prefixes', () async {
      fakeHealth.dataPoints = [
        makeWorkoutPoint(
          sourceName: 'Hevy',
          from: start,
          to: end,
          metadata: {'title': 'hevy: Push Day Hypertrophy'},
        ),
        makeWorkoutPoint(
          uuid: 'test-uuid-2',
          sourceName: 'Hevy',
          from: start,
          to: end,
          metadata: {'title': 'HEVY Leg Day'},
        ),
      ];

      final res = await adapter.fetchWorkouts(startTime: start, endTime: end);
      expect(res[0].title, equals('hevy: Push Day Hypertrophy'));
      expect(res[1].title, equals('HEVY Leg Day'));
    });
  });

  group('Category 5: Scale Weight Edge Cases & Filtering', () {
    final t = DateTime(2026, 10, 17, 7, 30);

    test('Negative, zero, and non-numeric weights are skipped', () async {
      fakeHealth.dataPoints = [
        makeWeightPoint(
          uuid: 'w-neg',
          value: NumericHealthValue(numericValue: -75.5),
          timestamp: t,
        ),
        makeWeightPoint(
          uuid: 'w-zero',
          value: NumericHealthValue(numericValue: 0.0),
          timestamp: t,
        ),
        makeWeightPoint(
          uuid: 'w-badtype',
          value: WorkoutHealthValue(
            workoutActivityType: HealthWorkoutActivityType.WEIGHTLIFTING,
          ),
          timestamp: t,
        ),
      ];

      final weights = await adapter.fetchWeights(
        startTime: t.subtract(const Duration(days: 1)),
        endTime: t.add(const Duration(days: 1)),
      );

      expect(weights, isEmpty);
    });

    test('Empty sourceName falls back to "Health Connect" note', () async {
      fakeHealth.dataPoints = [
        makeWeightPoint(
          value: NumericHealthValue(numericValue: 81.2),
          timestamp: t,
          sourceName: '',
        ),
      ];

      final weights = await adapter.fetchWeights(
        startTime: t.subtract(const Duration(days: 1)),
        endTime: t.add(const Duration(days: 1)),
      );

      expect(weights.length, equals(1));
      expect(weights.first.weightKg, equals(81.2));
      expect(weights.first.note, equals('Health Connect'));
    });

    test('Extreme realistic weights (35.0 kg and 350.0 kg) are preserved',
        () async {
      fakeHealth.dataPoints = [
        makeWeightPoint(
          uuid: 'w1',
          value: NumericHealthValue(numericValue: 35.0),
          timestamp: t,
        ),
        makeWeightPoint(
          uuid: 'w2',
          value: NumericHealthValue(numericValue: 350.0),
          timestamp: t.add(const Duration(days: 1)),
        ),
      ];

      final weights = await adapter.fetchWeights(
        startTime: t.subtract(const Duration(days: 1)),
        endTime: t.add(const Duration(days: 2)),
      );

      expect(weights.length, equals(2));
      expect(weights[0].weightKg, equals(35.0));
      expect(weights[1].weightKg, equals(350.0));
    });
  });

  group('Category 6: Stream Filtering & Fault Isolation', () {
    final now = DateTime(2026, 10, 17, 12, 0);

    test('Mixed data types: queries filter out foreign types strictly',
        () async {
      fakeHealth.dataPoints = [
        makeWeightPoint(
          value: NumericHealthValue(numericValue: 80.0),
          timestamp: now,
          type: HealthDataType.WEIGHT,
        ),
        makeWorkoutPoint(
          from: now.subtract(const Duration(hours: 1)),
          to: now,
        ),
      ];

      final workouts = await adapter.fetchWorkouts(
        startTime: now.subtract(const Duration(days: 1)),
        endTime: now,
      );
      final weights = await adapter.fetchWeights(
        startTime: now.subtract(const Duration(days: 1)),
        endTime: now,
      );

      expect(workouts.length, equals(1));
      expect(workouts.first.source, equals(WorkoutSource.hevy));
      expect(weights.length, equals(1));
      expect(weights.first.weightKg, equals(80.0));
    });

    test('Empty data stream returns empty list without error', () async {
      fakeHealth.dataPoints = [];

      final workouts = await adapter.fetchWorkouts(
        startTime: now.subtract(const Duration(days: 1)),
        endTime: now,
      );
      final weights = await adapter.fetchWeights(
        startTime: now.subtract(const Duration(days: 1)),
        endTime: now,
      );

      expect(workouts, isEmpty);
      expect(weights, isEmpty);
    });
  });

  group('Category 7: High-Volume Batch Stress Testing', () {
    test('Stress: 500 workouts in a single payload parse within milliseconds',
        () async {
      final baseDate = DateTime(2026, 1, 1);
      final batchPoints = List.generate(
        500,
        (i) => makeWorkoutPoint(
          uuid: 'stress-session-$i',
          sourceName: i.isEven ? 'Hevy' : 'Peloton',
          sourceId: i.isEven ? 'com.hevy' : 'com.peloton',
          from: baseDate.add(Duration(hours: i * 2)),
          to: baseDate.add(Duration(hours: i * 2, minutes: 45)),
          burnedCalories: 200 + (i % 300),
          workoutSummary: WorkoutSummary(
            workoutType: 'CrossFit',
            totalDistance: 0,
            totalEnergyBurned: 200 + (i % 300),
            totalSteps: 0,
          ),
          metadata: {'title': 'Stress Workout #$i'},
        ),
      );

      fakeHealth.dataPoints = batchPoints;

      final stopwatch = Stopwatch()..start();
      final workouts = await adapter.fetchWorkouts(
        startTime: baseDate,
        endTime: baseDate.add(const Duration(days: 365)),
      );
      stopwatch.stop();

      expect(workouts.length, equals(500));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(workouts.where((w) => w.isHevy).length, equals(250));
      expect(workouts.where((w) => !w.isHevy).length, equals(250));
    });

    test(
        'Stress: 500 scale weights in a single payload parse within milliseconds',
        () async {
      final baseDate = DateTime(2026, 1, 1);
      final batchPoints = List.generate(
        500,
        (i) => makeWeightPoint(
          uuid: 'stress-weight-$i',
          value: NumericHealthValue(numericValue: 70.0 + (i % 20) * 0.5),
          timestamp: baseDate.add(Duration(days: i)),
          sourceName: 'Smart Scale $i',
        ),
      );

      fakeHealth.dataPoints = batchPoints;

      final stopwatch = Stopwatch()..start();
      final weights = await adapter.fetchWeights(
        startTime: baseDate,
        endTime: baseDate.add(const Duration(days: 600)),
      );
      stopwatch.stop();

      expect(weights.length, equals(500));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(weights.first.weightKg, equals(70.0));
    });
  });
}
