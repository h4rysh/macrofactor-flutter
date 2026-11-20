import 'dart:convert';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/scale_weight_entry.dart';
import 'package:sique/domain/models/user_profile.dart';

/// Archive encoder and decoder for Sique full database backups (.sique.json).
/// Enforces schema version validation (supported: <= 3).
class BackupCodec {
  static const int currentSchemaVersion = 3;
  static const String appSignature = 'Sique';

  /// Serializes full backup to pretty JSON string.
  static String encodeBackup({
    required UserProfile profile,
    required List<FoodLogEntry> foodLogs,
    required List<ScaleWeightEntry> weightLogs,
  }) {
    final backup = {
      'app': appSignature,
      'backupVersion': 1,
      'schemaVersion': currentSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profileToMap(profile),
      'foodLogs': foodLogs.map(foodLogToMap).toList(),
      'weightLogs': weightLogs.map(weightToMap).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  /// Validates and decodes raw backup JSON string.
  /// Throws [FormatException] if structure or schema version is invalid.
  static DecodedBackup decodeAndValidate(String jsonContent) {
    final decoded = json.decode(jsonContent);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup: root must be a JSON object');
    }

    if (decoded['app'] != appSignature) {
      throw const FormatException(
          'Invalid backup file: missing Sique app signature');
    }

    final schemaVersion = decoded['schemaVersion'] as int?;
    if (schemaVersion == null ||
        schemaVersion < 1 ||
        schemaVersion > currentSchemaVersion) {
      throw FormatException(
          'Incompatible backup schema version: ${schemaVersion ?? "unknown"} (Supported: <= $currentSchemaVersion)');
    }

    UserProfile? profile;
    if (decoded['profile'] is Map<String, dynamic>) {
      profile = profileFromMap(decoded['profile'] as Map<String, dynamic>);
    }

    final weightLogs = <ScaleWeightEntry>[];
    if (decoded['weightLogs'] is List) {
      for (final item in decoded['weightLogs'] as List) {
        if (item is Map<String, dynamic>) {
          weightLogs.add(weightFromMap(item));
        }
      }
    }

    final foodLogs = <FoodLogEntry>[];
    if (decoded['foodLogs'] is List) {
      for (final item in decoded['foodLogs'] as List) {
        if (item is Map<String, dynamic>) {
          foodLogs.add(foodLogFromMap(item));
        }
      }
    }

    return DecodedBackup(
      schemaVersion: schemaVersion,
      exportedAt: decoded['exportedAt'] as String?,
      profile: profile,
      weightLogs: weightLogs,
      foodLogs: foodLogs,
    );
  }

  // --- Profile Mapping ---

  static Map<String, dynamic> profileToMap(UserProfile p) => {
        'id': p.id,
        'name': p.name,
        'currentWeightKg': p.currentWeightKg,
        'targetWeightKg': p.targetWeightKg,
        'heightCm': p.heightCm,
        'age': p.age,
        'isMale': p.isMale,
        'goalType': p.goalType.name,
        'programMode': p.programMode.name,
        'weeklyRateOfChangePct': p.weeklyRateOfChangePct,
        'proteinPreference': p.proteinPreference.name,
        'calorieFloor': p.calorieFloor,
        'baselineExpenditureKcal': p.baselineExpenditureKcal,
        'customCalories': p.customCalories,
        'customProteinGrams': p.customProteinGrams,
        'customCarbsGrams': p.customCarbsGrams,
        'customFatGrams': p.customFatGrams,
        'dietType': p.dietType,
        'calorieFloorType': p.calorieFloorType,
        'liftingExperience': p.liftingExperience,
        'cardioExperience': p.cardioExperience,
        'bodyFatRange': p.bodyFatRange,
        'weightHistoryMax': p.weightHistoryMax,
        'distributionMode': p.distributionMode,
        'recentWeightTrend': p.recentWeightTrend,
        'exerciseFrequency': p.exerciseFrequency,
        'dailyActivity': p.dailyActivity,
      };

  static UserProfile profileFromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as String? ?? 'active_user',
        name: map['name'] as String? ?? 'Athlete',
        currentWeightKg: (map['currentWeightKg'] as num?)?.toDouble() ?? 75.0,
        targetWeightKg: (map['targetWeightKg'] as num?)?.toDouble() ?? 70.0,
        heightCm: (map['heightCm'] as num?)?.toDouble() ?? 175.0,
        age: (map['age'] as num?)?.toInt() ?? 28,
        isMale: map['isMale'] as bool? ?? true,
        goalType: GoalType.values.firstWhere(
          (g) => g.name == map['goalType'],
          orElse: () => GoalType.fatLoss,
        ),
        programMode: ProgramMode.values.firstWhere(
          (p) => p.name == map['programMode'],
          orElse: () => ProgramMode.coached,
        ),
        weeklyRateOfChangePct:
            (map['weeklyRateOfChangePct'] as num?)?.toDouble() ?? -0.5,
        proteinPreference: ProteinPreference.values.firstWhere(
          (p) => p.name == map['proteinPreference'],
          orElse: () => ProteinPreference.high,
        ),
        calorieFloor: (map['calorieFloor'] as num?)?.toDouble() ?? 1500.0,
        baselineExpenditureKcal:
            (map['baselineExpenditureKcal'] as num?)?.toDouble() ?? 2400.0,
        customCalories: (map['customCalories'] as num?)?.toDouble(),
        customProteinGrams: (map['customProteinGrams'] as num?)?.toDouble(),
        customCarbsGrams: (map['customCarbsGrams'] as num?)?.toDouble(),
        customFatGrams: (map['customFatGrams'] as num?)?.toDouble(),
        dietType: map['dietType'] as String? ?? 'standard',
        calorieFloorType: map['calorieFloorType'] as String? ?? 'standard',
        liftingExperience: map['liftingExperience'] as String? ?? 'beginner',
        cardioExperience: map['cardioExperience'] as String? ?? 'beginner',
        bodyFatRange: map['bodyFatRange'] as String?,
        weightHistoryMax: (map['weightHistoryMax'] as num?)?.toDouble(),
        distributionMode: map['distributionMode'] as String? ?? 'even',
        recentWeightTrend: map['recentWeightTrend'] as String? ?? 'stable',
        exerciseFrequency: map['exerciseFrequency'] as String? ?? '1-3',
        dailyActivity: map['dailyActivity'] as String? ?? 'moderate',
      );

  // --- Weight Mapping ---

  static Map<String, dynamic> weightToMap(ScaleWeightEntry w) => {
        'date': w.date.toIso8601String().split('T').first,
        'weightKg': w.weightKg,
        'note': w.note,
        'source': w.source,
      };

  static ScaleWeightEntry weightFromMap(Map<String, dynamic> map) =>
      ScaleWeightEntry(
        date: DateTime.parse(map['date'] as String),
        weightKg: (map['weightKg'] as num).toDouble(),
        note: map['note'] as String?,
        source: map['source'] as String? ?? 'manual',
      );

  // --- Food Log Mapping ---

  static Map<String, dynamic> foodLogToMap(FoodLogEntry e) => {
        'id': e.id,
        'date': e.date,
        'mealType': e.mealType.name,
        'foodId': e.foodId,
        'foodName': e.foodName,
        'servingQuantity': e.servingQuantity,
        'unitName': e.unitName,
        'gramWeight': e.gramWeight,
        'calories': e.calories,
        'protein': e.protein,
        'carbs': e.carbs,
        'fat': e.fat,
        'fiber': e.fiber,
        'oilModifier': e.oilModifier.displayName,
        'loggedAt': e.loggedAt.toIso8601String(),
        'iconSvg': e.iconSvg,
      };

  static FoodLogEntry foodLogFromMap(Map<String, dynamic> map) {
    final oilMod = OilModifier.values.firstWhere(
      (o) =>
          o.displayName == map['oilModifier'] || o.name == map['oilModifier'],
      orElse: () => OilModifier.standard,
    );
    final meal = MealType.values.firstWhere(
      (m) => m.name == map['mealType'],
      orElse: () => MealType.lunch,
    );
    return FoodLogEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      mealType: meal,
      foodId: (map['foodId'] as num?)?.toInt() ?? 0,
      foodName: map['foodName'] as String? ?? 'Custom Food',
      servingQuantity: (map['servingQuantity'] as num).toDouble(),
      unitName: map['unitName'] as String? ?? 'serving',
      gramWeight: (map['gramWeight'] as num?)?.toDouble() ?? 100.0,
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      fiber: (map['fiber'] as num?)?.toDouble() ?? 0.0,
      oilModifier: oilMod,
      loggedAt: DateTime.parse(map['loggedAt'] as String),
      iconSvg: map['iconSvg'] as String? ?? 'i10.svg',
    );
  }
}

/// Structured container for validated backup contents.
class DecodedBackup {
  const DecodedBackup({
    required this.schemaVersion,
    this.exportedAt,
    this.profile,
    required this.weightLogs,
    required this.foodLogs,
  });

  final int schemaVersion;
  final String? exportedAt;
  final UserProfile? profile;
  final List<ScaleWeightEntry> weightLogs;
  final List<FoodLogEntry> foodLogs;
}
