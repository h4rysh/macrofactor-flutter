import 'dart:convert';
import 'package:sique/data/local/app_database_expenditure.dart';
import 'package:sique/data/local/dao/diary_tools_dao.dart';
import 'package:sique/domain/models/body_measurement_entry.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/lifestyle_models.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/domain/models/recipe_models.dart';
import 'package:sique/domain/models/scale_weight_entry.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/domain/models/weekly_challenge_model.dart';
import 'package:sique/domain/models/workout_session.dart';

/// Archive encoder and decoder for Sique full database backups (.sique.json / .sique.enc).
/// Supports schema versions 1 through 6.
class BackupCodec {
  static const int currentSchemaVersion = 7;
  static const String appSignature = 'Sique';

  /// Serializes complete backup snapshot (including Wave 4/5/6 lifestyle & recipes tables) to JSON.
  static String encodeBackup({
    required UserProfile profile,
    required List<FoodLogEntry> foodLogs,
    required List<ScaleWeightEntry> weightLogs,
    List<WorkoutSession> workoutSessions = const [],
    List<ExpenditureRecord> expenditureHistory = const [],
    List<CoachingCheckIn> coachingCheckIns = const [],
    Map<String, bool> dayCompletions = const {},
    Map<String, String> appSettings = const {},
    List<BodyMeasurementEntry> bodyMeasurements = const [],
    List<WeeklyChallengeModel> weeklyChallenges = const [],
    List<WaterLog> waterLogs = const [],
    List<FastingSession> fastingSessions = const [],
    List<CustomRecipe> customRecipes = const [],
    List<RepeatItemRecord> repeatItems = const [],
    Map<String, String> dayNotes = const {},
    Map<int, double> microGoals = const {},
  }) {
    final backup = {
      'app': appSignature,
      'backupVersion': 3,
      'schemaVersion': currentSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profileToMap(profile),
      'foodLogs': foodLogs.map(foodLogToMap).toList(),
      'weightLogs': weightLogs.map(weightToMap).toList(),
      'workoutSessions': workoutSessions.map((w) => w.toMap()).toList(),
      'expenditureHistory': expenditureHistory.map((e) => e.toMap()).toList(),
      'coachingCheckIns': coachingCheckIns.map((c) => c.toJson()).toList(),
      'dayCompletions': dayCompletions,
      'appSettings': appSettings,
      'bodyMeasurements': bodyMeasurements.map((b) => b.toMap()).toList(),
      'weeklyChallenges': weeklyChallenges.map((c) => c.toMap()).toList(),
      'waterLogs': waterLogs.map((w) => w.toMap()).toList(),
      'fastingSessions': fastingSessions.map(fastingSessionToMap).toList(),
      'customRecipes': customRecipes.map(recipeToMap).toList(),
      'repeatItems': repeatItems.map(repeatItemToMap).toList(),
      'dayNotes': dayNotes,
      'microGoals': microGoals.map((k, v) => MapEntry(k.toString(), v)),
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

    final rawSchema = decoded['schemaVersion'];
    final schemaVersion = rawSchema is int ? rawSchema : null;
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

    final workoutSessions = <WorkoutSession>[];
    if (decoded['workoutSessions'] is List) {
      for (final item in decoded['workoutSessions'] as List) {
        if (item is Map<String, dynamic>) {
          workoutSessions.add(WorkoutSession.fromMap(item));
        }
      }
    }

    final expenditureHistory = <ExpenditureRecord>[];
    if (decoded['expenditureHistory'] is List) {
      for (final item in decoded['expenditureHistory'] as List) {
        if (item is Map<String, dynamic>) {
          expenditureHistory.add(ExpenditureRecord(
            date: item['date'] as String,
            expenditureKcal: (item['expenditure_kcal'] as num).toDouble(),
            trendWeightKg: (item['trend_weight_kg'] as num).toDouble(),
            variance: (item['variance'] as num).toDouble(),
            confidence: (item['confidence'] as num).toDouble(),
          ));
        }
      }
    }

    final coachingCheckIns = <CoachingCheckIn>[];
    if (decoded['coachingCheckIns'] is List) {
      for (final item in decoded['coachingCheckIns'] as List) {
        if (item is Map<String, dynamic>) {
          coachingCheckIns.add(CoachingCheckIn.fromJson(item));
        }
      }
    }

    final dayCompletions = <String, bool>{};
    if (decoded['dayCompletions'] is Map) {
      (decoded['dayCompletions'] as Map).forEach((k, v) {
        if (k is String && v is bool) {
          dayCompletions[k] = v;
        }
      });
    }

    final appSettings = <String, String>{};
    if (decoded['appSettings'] is Map) {
      (decoded['appSettings'] as Map).forEach((k, v) {
        if (k is String && v is String) {
          appSettings[k] = v;
        }
      });
    }

    final bodyMeasurements = <BodyMeasurementEntry>[];
    if (decoded['bodyMeasurements'] is List) {
      for (final item in decoded['bodyMeasurements'] as List) {
        if (item is Map<String, dynamic>) {
          bodyMeasurements.add(bodyMeasurementFromMap(item));
        }
      }
    }

    final weeklyChallenges = <WeeklyChallengeModel>[];
    if (decoded['weeklyChallenges'] is List) {
      for (final item in decoded['weeklyChallenges'] as List) {
        if (item is Map<String, dynamic>) {
          weeklyChallenges.add(challengeFromMap(item));
        }
      }
    }

    final waterLogs = <WaterLog>[];
    if (decoded['waterLogs'] is List) {
      for (final item in decoded['waterLogs'] as List) {
        if (item is Map<String, dynamic>) {
          waterLogs.add(waterLogFromMap(item));
        }
      }
    }

    final fastingSessions = <FastingSession>[];
    if (decoded['fastingSessions'] is List) {
      for (final item in decoded['fastingSessions'] as List) {
        if (item is Map<String, dynamic>) {
          fastingSessions.add(fastingSessionFromMap(item));
        }
      }
    }

    final customRecipes = <CustomRecipe>[];
    if (decoded['customRecipes'] is List) {
      for (final item in decoded['customRecipes'] as List) {
        if (item is Map<String, dynamic>) {
          customRecipes.add(recipeFromMap(item));
        }
      }
    }

    final repeatItems = <RepeatItemRecord>[];
    if (decoded['repeatItems'] is List) {
      for (final item in decoded['repeatItems'] as List) {
        if (item is Map<String, dynamic>) {
          repeatItems.add(repeatItemFromMap(item));
        }
      }
    }

    final dayNotes = <String, String>{};
    if (decoded['dayNotes'] is Map) {
      final isoDateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      (decoded['dayNotes'] as Map).forEach((k, v) {
        if (k is String &&
            isoDateRegex.hasMatch(k) &&
            v is String &&
            v.trim().isNotEmpty &&
            dayNotes.length < 10000) {
          final safeNote =
              v.trim().length > 1000 ? v.trim().substring(0, 1000) : v.trim();
          dayNotes[k] = safeNote;
        }
      });
    }

    final microGoals = <int, double>{};
    if (decoded['microGoals'] is Map) {
      (decoded['microGoals'] as Map).forEach((k, v) {
        final nid = int.tryParse(k.toString());
        if (nid != null &&
            nid > 0 &&
            v is num &&
            v.isFinite &&
            v > 0 &&
            v <= 100000 &&
            microGoals.length < 200) {
          microGoals[nid] = v.toDouble();
        }
      });
    }

    return DecodedBackup(
      schemaVersion: schemaVersion,
      exportedAt: decoded['exportedAt'] as String?,
      profile: profile,
      weightLogs: weightLogs,
      foodLogs: foodLogs,
      workoutSessions: workoutSessions,
      expenditureHistory: expenditureHistory,
      coachingCheckIns: coachingCheckIns,
      dayCompletions: dayCompletions,
      appSettings: appSettings,
      bodyMeasurements: bodyMeasurements,
      weeklyChallenges: weeklyChallenges,
      waterLogs: waterLogs,
      fastingSessions: fastingSessions,
      customRecipes: customRecipes,
      repeatItems: repeatItems,
      dayNotes: dayNotes,
      microGoals: microGoals,
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
        'dateOfBirth': p.dateOfBirth,
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
        'reverseDietPacing': p.reverseDietPacing,
        'isInDietBreak': p.isInDietBreak,
        'dailyWaterTargetMl': p.dailyWaterTargetMl,
        'defaultFastingProtocol': p.defaultFastingProtocol,
        'periWorkoutTimingEnabled': p.periWorkoutTimingEnabled,
        'neckCircumferenceCm': p.neckCircumferenceCm,
      };

  static UserProfile profileFromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as String? ?? 'active_user',
        name: map['name'] as String? ?? 'Athlete',
        currentWeightKg: (map['currentWeightKg'] as num?)?.toDouble() ?? 75.0,
        targetWeightKg: (map['targetWeightKg'] as num?)?.toDouble() ?? 70.0,
        heightCm: (map['heightCm'] as num?)?.toDouble() ?? 175.0,
        age: (map['age'] as num?)?.toInt() ?? 28,
        dateOfBirth: map['dateOfBirth'] as String?,
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
        reverseDietPacing: map['reverseDietPacing'] as String? ?? 'none',
        isInDietBreak: map['isInDietBreak'] as bool? ?? false,
        dailyWaterTargetMl:
            (map['dailyWaterTargetMl'] as num?)?.toInt() ?? 2500,
        defaultFastingProtocol:
            map['defaultFastingProtocol'] as String? ?? 'none',
        periWorkoutTimingEnabled:
            map['periWorkoutTimingEnabled'] as bool? ?? false,
        neckCircumferenceCm: (map['neckCircumferenceCm'] as num?)?.toDouble(),
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
    final clampedCalories =
        ((map['calories'] as num).toDouble()).clamp(0.0, 20000.0);
    final clampedProtein =
        ((map['protein'] as num).toDouble()).clamp(0.0, 2000.0);
    final clampedCarbs = ((map['carbs'] as num).toDouble()).clamp(0.0, 3000.0);
    final clampedFat = ((map['fat'] as num).toDouble()).clamp(0.0, 2000.0);
    final clampedFiber =
        (((map['fiber'] as num?)?.toDouble()) ?? 0.0).clamp(0.0, 500.0);
    final rawName = map['foodName'] as String? ?? 'Custom Food';
    return FoodLogEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      mealType: meal,
      foodId: (map['foodId'] as num?)?.toInt() ?? 0,
      foodName: rawName.length > 200 ? rawName.substring(0, 200) : rawName,
      servingQuantity:
          ((map['servingQuantity'] as num).toDouble()).clamp(0.01, 500.0),
      unitName: map['unitName'] as String? ?? 'serving',
      gramWeight: (((map['gramWeight'] as num?)?.toDouble()) ?? 100.0)
          .clamp(0.1, 20000.0),
      calories: clampedCalories,
      protein: clampedProtein,
      carbs: clampedCarbs,
      fat: clampedFat,
      fiber: clampedFiber,
      oilModifier: oilMod,
      loggedAt: DateTime.parse(map['loggedAt'] as String),
      iconSvg: map['iconSvg'] as String? ?? 'i10.svg',
    );
  }

  // --- Wave 4/5/6 Tables ---

  static BodyMeasurementEntry bodyMeasurementFromMap(Map<String, dynamic> m) =>
      BodyMeasurementEntry(
        id: m['id'] as String,
        userId: m['user_id'] as String? ?? 'default_user',
        date: DateTime.parse(m['date'] as String),
        waistCm: (m['waist_cm'] as num?)?.toDouble(),
        hipsCm: (m['hips_cm'] as num?)?.toDouble(),
        chestCm: (m['chest_cm'] as num?)?.toDouble(),
        neckCm: (m['neck_cm'] as num?)?.toDouble(),
        bicepsCm: (m['biceps_cm'] as num?)?.toDouble(),
        thighCm: (m['thigh_cm'] as num?)?.toDouble(),
        bodyFatPct: (m['body_fat_pct'] as num?)?.toDouble(),
        source: m['source'] as String? ?? 'manual',
        notes: m['notes'] as String?,
        loggedAt: DateTime.parse(m['logged_at'] as String),
      );

  static WeeklyChallengeModel challengeFromMap(Map<String, dynamic> m) =>
      WeeklyChallengeModel(
        id: m['id'] as String,
        userId: m['user_id'] as String? ?? 'default_user',
        type: ChallengeType.values.firstWhere(
          (t) => t.name == m['type'],
          orElse: () => ChallengeType.proteinAnchor,
        ),
        title: m['title'] as String,
        description: m['description'] as String,
        targetMetric: m['target_metric'] as String,
        targetValue: (m['target_value'] as num).toDouble(),
        currentValue: (m['current_value'] as num?)?.toDouble() ?? 0.0,
        unit: m['unit'] as String,
        status: ChallengeStatus.fromString(m['status'] as String),
        weekStartDate: DateTime.parse(m['week_start_date'] as String),
        weekEndDate: DateTime.parse(m['week_end_date'] as String),
        completedAt: m['completed_at'] != null
            ? DateTime.parse(m['completed_at'] as String)
            : null,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  static WaterLog waterLogFromMap(Map<String, dynamic> m) => WaterLog(
        userId: m['user_id'] as String? ?? 'default_user',
        date: m['date'] as String,
        amountMl: (m['amount_ml'] as num).toInt(),
        loggedAt: DateTime.parse(m['logged_at'] as String),
      );

  static Map<String, dynamic> fastingSessionToMap(FastingSession f) => {
        'id': f.id,
        'user_id': f.userId,
        'protocol': f.protocol.name,
        'start_time': f.startTime.toIso8601String(),
        'target_end_time': f.targetEndTime.toIso8601String(),
        'actual_end_time': f.actualEndTime?.toIso8601String(),
        'state': f.state,
        'notes': f.notes,
      };

  static FastingSession fastingSessionFromMap(Map<String, dynamic> m) =>
      FastingSession(
        id: m['id'] as String,
        userId: m['user_id'] as String? ?? 'default_user',
        protocol: FastingProtocol.fromString(m['protocol'] as String),
        startTime: DateTime.parse(m['start_time'] as String),
        targetEndTime: DateTime.parse(m['target_end_time'] as String),
        actualEndTime: m['actual_end_time'] != null
            ? DateTime.parse(m['actual_end_time'] as String)
            : null,
        state: m['state'] as String? ?? 'completed',
        notes: m['notes'] as String?,
      );

  static Map<String, dynamic> recipeToMap(CustomRecipe r) => {
        'id': r.id,
        'user_id': r.userId,
        'name': r.name,
        'servings': r.safeServings,
        'total_weight_g': r.totalWeightG,
        'cooked_weight_g': r.cookedWeightG,
        'prep_instructions': r.prepInstructions,
        'source_url': r.sourceUrl,
        'created_at': r.createdAt.toIso8601String(),
        'updated_at': r.updatedAt.toIso8601String(),
        'ingredients': r.ingredients
            .map((i) => {
                  'id': i.id,
                  'recipe_id': i.recipeId,
                  'food_id': i.foodId,
                  'food_name': i.foodName,
                  'serving_quantity': i.servingQuantity,
                  'unit_name': i.unitName,
                  'gram_weight': i.gramWeight,
                  'calories': i.calories,
                  'protein': i.protein,
                  'carbs': i.carbs,
                  'fat': i.fat,
                  'fiber': i.fiber,
                })
            .toList(),
      };

  static CustomRecipe recipeFromMap(Map<String, dynamic> m) => CustomRecipe(
        id: m['id'] as String,
        userId: m['user_id'] as String? ?? 'default_user',
        name: m['name'] as String,
        servings: (m['servings'] as num?)?.toInt() ?? 1,
        totalWeightG: (m['total_weight_g'] as num?)?.toDouble(),
        cookedWeightG: (m['cooked_weight_g'] as num?)?.toDouble(),
        prepInstructions: m['prep_instructions'] as String?,
        sourceUrl: m['source_url'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
        ingredients: (m['ingredients'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((i) => RecipeIngredient(
                  id: i['id'] as String,
                  recipeId: i['recipe_id'] as String,
                  foodId: (i['food_id'] as num).toInt(),
                  foodName: i['food_name'] as String,
                  servingQuantity: (i['serving_quantity'] as num).toDouble(),
                  unitName: i['unit_name'] as String,
                  gramWeight: (i['gram_weight'] as num).toDouble(),
                  calories: (i['calories'] as num).toDouble(),
                  protein: (i['protein'] as num).toDouble(),
                  carbs: (i['carbs'] as num).toDouble(),
                  fat: (i['fat'] as num).toDouble(),
                  fiber: (i['fiber'] as num).toDouble(),
                ))
            .toList(),
      );

  static Map<String, dynamic> repeatItemToMap(RepeatItemRecord r) => {
        'id': r.id,
        'user_id': r.userId,
        'food_id': r.foodId,
        'food_name': r.foodName,
        'meal_type': r.mealType,
        'hour': r.hour,
        'serving_quantity': r.servingQuantity,
        'unit_name': r.unitName,
        'gram_weight': r.gramWeight,
        'calories': r.calories,
        'protein': r.protein,
        'carbs': r.carbs,
        'fat': r.fat,
        'fiber': r.fiber,
        'active_days_mask': r.activeDaysMask,
        'is_active': r.isActive,
        'last_logged_date': r.lastLoggedDate,
        'created_at': r.createdAt,
      };

  static RepeatItemRecord repeatItemFromMap(Map<String, dynamic> m) =>
      RepeatItemRecord(
        id: m['id'] as String,
        userId: m['user_id'] as String? ?? 'default_user',
        foodId: (m['food_id'] as num).toInt(),
        foodName: (m['food_name'] as String).length > 200
            ? (m['food_name'] as String).substring(0, 200)
            : m['food_name'] as String,
        mealType: m['meal_type'] as String? ?? 'lunch',
        hour: ((m['hour'] as num?)?.toInt() ?? 12).clamp(0, 23),
        servingQuantity:
            ((m['serving_quantity'] as num).toDouble()).clamp(0.01, 500.0),
        unitName: m['unit_name'] as String? ?? 'serving',
        gramWeight: ((m['gram_weight'] as num).toDouble()).clamp(0.1, 20000.0),
        calories: ((m['calories'] as num).toDouble()).clamp(0.0, 20000.0),
        protein: ((m['protein'] as num).toDouble()).clamp(0.0, 2000.0),
        carbs: ((m['carbs'] as num).toDouble()).clamp(0.0, 3000.0),
        fat: ((m['fat'] as num).toDouble()).clamp(0.0, 2000.0),
        fiber: (((m['fiber'] as num?)?.toDouble()) ?? 0.0).clamp(0.0, 500.0),
        activeDaysMask: (m['active_days_mask'] as num?)?.toInt() ?? 127,
        isActive: (m['is_active'] as bool?) ?? true,
        lastLoggedDate: m['last_logged_date'] as String?,
        createdAt:
            m['created_at'] as String? ?? DateTime.now().toIso8601String(),
      );
}

/// Structured container for validated backup contents across all user data tables.
class DecodedBackup {
  const DecodedBackup({
    required this.schemaVersion,
    this.exportedAt,
    this.profile,
    required this.weightLogs,
    required this.foodLogs,
    this.workoutSessions = const [],
    this.expenditureHistory = const [],
    this.coachingCheckIns = const [],
    this.dayCompletions = const {},
    this.appSettings = const {},
    this.bodyMeasurements = const [],
    this.weeklyChallenges = const [],
    this.waterLogs = const [],
    this.fastingSessions = const [],
    this.customRecipes = const [],
    this.repeatItems = const [],
    this.dayNotes = const {},
    this.microGoals = const {},
  });

  final int schemaVersion;
  final String? exportedAt;
  final UserProfile? profile;
  final List<ScaleWeightEntry> weightLogs;
  final List<FoodLogEntry> foodLogs;
  final List<WorkoutSession> workoutSessions;
  final List<ExpenditureRecord> expenditureHistory;
  final List<CoachingCheckIn> coachingCheckIns;
  final Map<String, bool> dayCompletions;
  final Map<String, String> appSettings;
  final List<BodyMeasurementEntry> bodyMeasurements;
  final List<WeeklyChallengeModel> weeklyChallenges;
  final List<WaterLog> waterLogs;
  final List<FastingSession> fastingSessions;
  final List<CustomRecipe> customRecipes;
  final List<RepeatItemRecord> repeatItems;
  final Map<String, String> dayNotes;
  final Map<int, double> microGoals;
}
