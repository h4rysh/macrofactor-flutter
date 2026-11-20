import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/utils/backup_codec.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/scale_weight_entry.dart';
import 'package:sique/domain/models/user_profile.dart';

void main() {
  group('BackupCodec Unit & Validation Tests', () {
    const sampleProfile = UserProfile(
      id: 'athlete_001',
      name: 'Rohan Sharma',
      currentWeightKg: 82.5,
      targetWeightKg: 75.0,
      heightCm: 178.0,
      age: 29,
      isMale: true,
      goalType: GoalType.fatLoss,
      programMode: ProgramMode.coached,
      weeklyRateOfChangePct: -0.65,
      proteinPreference: ProteinPreference.high,
      calorieFloor: 1500.0,
      baselineExpenditureKcal: 2550.0,
      dietType: 'pure_veg',
      calorieFloorType: 'standard',
      liftingExperience: 'intermediate',
      cardioExperience: 'beginner',
      bodyFatRange: '18 – 22%',
      weightHistoryMax: 88.0,
      distributionMode: 'shifted',
      recentWeightTrend: 'stable',
      exerciseFrequency: '4',
      dailyActivity: 'moderate',
    );

    final sampleWeight = ScaleWeightEntry(
      date: DateTime(2026, 11, 20),
      weightKg: 82.4,
      note: 'Morning fasted',
      source: 'smart_scale',
    );

    final sampleFood = FoodLogEntry(
      id: 101,
      date: '2026-11-20',
      mealType: MealType.breakfast,
      foodId: 42,
      foodName: 'Paneer Bhurji',
      servingQuantity: 1.5,
      unitName: 'plate',
      gramWeight: 200.0,
      calories: 340.0,
      protein: 24.0,
      carbs: 6.0,
      fat: 22.0,
      fiber: 2.0,
      oilModifier: OilModifier.standard,
      loggedAt: DateTime(2026, 11, 20, 8, 30),
      iconSvg: 'i10.svg',
    );

    test('Encodes and decodes full backup with high fidelity roundtrip', () {
      final jsonStr = BackupCodec.encodeBackup(
        profile: sampleProfile,
        foodLogs: [sampleFood],
        weightLogs: [sampleWeight],
      );

      expect(jsonStr, contains('"app": "Sique"'));
      expect(jsonStr, contains('"schemaVersion": 3'));
      expect(jsonStr, contains('"Rohan Sharma"'));
      expect(jsonStr, contains('"Paneer Bhurji"'));

      final decoded = BackupCodec.decodeAndValidate(jsonStr);

      expect(decoded.schemaVersion, equals(3));
      expect(decoded.profile, isNotNull);
      expect(decoded.profile!.name, equals('Rohan Sharma'));
      expect(decoded.profile!.currentWeightKg, equals(82.5));
      expect(decoded.profile!.goalType, equals(GoalType.fatLoss));
      expect(
          decoded.profile!.proteinPreference, equals(ProteinPreference.high));

      expect(decoded.weightLogs.length, equals(1));
      expect(decoded.weightLogs.first.weightKg, equals(82.4));
      expect(decoded.weightLogs.first.note, equals('Morning fasted'));
      expect(decoded.weightLogs.first.source, equals('smart_scale'));

      expect(decoded.foodLogs.length, equals(1));
      expect(decoded.foodLogs.first.foodName, equals('Paneer Bhurji'));
      expect(decoded.foodLogs.first.mealType, equals(MealType.breakfast));
      expect(decoded.foodLogs.first.calories, equals(340.0));
      expect(decoded.foodLogs.first.oilModifier, equals(OilModifier.standard));
    });

    test('Rejects invalid JSON root (non-object)', () {
      expect(
        () => BackupCodec.decodeAndValidate('["not", "an", "object"]'),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            contains('root must be a JSON object'))),
      );
    });

    test('Rejects backup without Sique app signature', () {
      final foreignBackup = json.encode({
        'app': 'CompetitorDiet',
        'schemaVersion': 3,
        'profile': {},
      });

      expect(
        () => BackupCodec.decodeAndValidate(foreignBackup),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            contains('missing Sique app signature'))),
      );
    });

    test('Rejects incompatible schema version > 3', () {
      final futureBackup = json.encode({
        'app': 'Sique',
        'schemaVersion': 4,
        'profile': {},
      });

      expect(
        () => BackupCodec.decodeAndValidate(futureBackup),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            contains('Incompatible backup schema version: 4'))),
      );
    });

    test('Rejects invalid schema version <= 0 or missing', () {
      final invalidZero = json.encode({
        'app': 'Sique',
        'schemaVersion': 0,
      });

      expect(
        () => BackupCodec.decodeAndValidate(invalidZero),
        throwsA(isA<FormatException>()),
      );

      final missingVersion = json.encode({
        'app': 'Sique',
      });

      expect(
        () => BackupCodec.decodeAndValidate(missingVersion),
        throwsA(isA<FormatException>()),
      );
    });

    test('Accepts valid historical schema versions (v1, v2, v3)', () {
      for (int v = 1; v <= 3; v++) {
        final payload = json.encode({
          'app': 'Sique',
          'schemaVersion': v,
          'profile': {'name': 'Legacy User $v'},
          'weightLogs': [],
          'foodLogs': [],
        });

        final decoded = BackupCodec.decodeAndValidate(payload);
        expect(decoded.schemaVersion, equals(v));
        expect(decoded.profile?.name, equals('Legacy User $v'));
      }
    });

    test('Handles empty and null log arrays gracefully without throwing', () {
      final minimalJson = json.encode({
        'app': 'Sique',
        'schemaVersion': 3,
      });

      final decoded = BackupCodec.decodeAndValidate(minimalJson);
      expect(decoded.schemaVersion, equals(3));
      expect(decoded.profile, isNull);
      expect(decoded.weightLogs, isEmpty);
      expect(decoded.foodLogs, isEmpty);
    });
  });
}
