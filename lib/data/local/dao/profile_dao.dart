import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sqlite3/common.dart';

/// Data Access Object managing user profile, account session, and app preferences.
class ProfileDao {
  ProfileDao(this._db);

  final CommonDatabase _db;

  /// Saves user profile and coaching settings.
  void saveUserProfile(UserProfile profile) {
    final stmt = _db.prepare('''
      INSERT INTO user_profile (
        id, name, current_weight, target_weight, height_cm, age,
        is_male, goal_type, program_mode, weekly_rate,
        protein_preference, calorie_floor, baseline_expenditure,
        custom_calories, custom_protein, custom_carbs, custom_fat,
        diet_type, calorie_floor_type, lifting_experience, cardio_experience,
        body_fat_range, weight_history_max, distribution_mode
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        current_weight = excluded.current_weight,
        target_weight = excluded.target_weight,
        height_cm = excluded.height_cm,
        age = excluded.age,
        is_male = excluded.is_male,
        goal_type = excluded.goal_type,
        program_mode = excluded.program_mode,
        weekly_rate = excluded.weekly_rate,
        protein_preference = excluded.protein_preference,
        calorie_floor = excluded.calorie_floor,
        baseline_expenditure = excluded.baseline_expenditure,
        custom_calories = excluded.custom_calories,
        custom_protein = excluded.custom_protein,
        custom_carbs = excluded.custom_carbs,
        custom_fat = excluded.custom_fat,
        diet_type = excluded.diet_type,
        calorie_floor_type = excluded.calorie_floor_type,
        lifting_experience = excluded.lifting_experience,
        cardio_experience = excluded.cardio_experience,
        body_fat_range = excluded.body_fat_range,
        weight_history_max = excluded.weight_history_max,
        distribution_mode = excluded.distribution_mode;
    ''');

    stmt.execute([
      profile.id,
      profile.name,
      profile.currentWeightKg,
      profile.targetWeightKg,
      profile.heightCm,
      profile.age,
      profile.isMale ? 1 : 0,
      profile.goalType.name,
      profile.programMode.name,
      profile.weeklyRateOfChangePct,
      profile.proteinPreference.name,
      profile.calorieFloor,
      profile.baselineExpenditureKcal,
      profile.customCalories,
      profile.customProteinGrams,
      profile.customCarbsGrams,
      profile.customFatGrams,
      profile.dietType,
      profile.calorieFloorType,
      profile.liftingExperience,
      profile.cardioExperience,
      profile.bodyFatRange,
      profile.weightHistoryMax,
      profile.distributionMode,
    ]);
    stmt.dispose();
  }

  /// Retrieves user profile or null if none saved.
  UserProfile? getUserProfile() {
    final stmt = _db.prepare('SELECT * FROM user_profile LIMIT 1;');
    final result = stmt.select();
    stmt.dispose();
    if (result.isEmpty) return null;

    final row = result.first;
    return UserProfile(
      id: row['id'] as String,
      name: row['name'] as String,
      currentWeightKg: (row['current_weight'] as num).toDouble(),
      targetWeightKg: (row['target_weight'] as num).toDouble(),
      heightCm: (row['height_cm'] as num).toDouble(),
      age: row['age'] as int,
      isMale: (row['is_male'] as int) == 1,
      goalType: GoalType.values.firstWhere((g) => g.name == row['goal_type']),
      programMode:
          ProgramMode.values.firstWhere((p) => p.name == row['program_mode']),
      weeklyRateOfChangePct: (row['weekly_rate'] as num).toDouble(),
      proteinPreference: ProteinPreference.values
          .firstWhere((p) => p.name == row['protein_preference']),
      calorieFloor: (row['calorie_floor'] as num).toDouble(),
      baselineExpenditureKcal: (row['baseline_expenditure'] as num).toDouble(),
      customCalories: (row['custom_calories'] as num?)?.toDouble(),
      customProteinGrams: (row['custom_protein'] as num?)?.toDouble(),
      customCarbsGrams: (row['custom_carbs'] as num?)?.toDouble(),
      customFatGrams: (row['custom_fat'] as num?)?.toDouble(),
      dietType: row['diet_type'] as String? ?? 'standard',
      calorieFloorType: row['calorie_floor_type'] as String? ?? 'standard',
      liftingExperience: row['lifting_experience'] as String? ?? 'beginner',
      cardioExperience: row['cardio_experience'] as String? ?? 'beginner',
      bodyFatRange: row['body_fat_range'] as String?,
      weightHistoryMax: (row['weight_history_max'] as num?)?.toDouble(),
      distributionMode: row['distribution_mode'] as String? ?? 'even',
    );
  }

  /// Retrieves a key-value setting or returns defaultValue.
  String getSetting(String key, String defaultValue) {
    try {
      final stmt =
          _db.prepare('SELECT value FROM app_settings WHERE key = ? LIMIT 1;');
      final result = stmt.select([key]);
      stmt.dispose();
      if (result.isEmpty) return defaultValue;
      return result.first['value'] as String;
    } catch (_) {
      return defaultValue;
    }
  }

  /// Sets or updates a key-value setting.
  void setSetting(String key, String value) {
    final stmt = _db.prepare('''
      INSERT INTO app_settings (key, value)
      VALUES (?, ?)
      ON CONFLICT(key) DO UPDATE SET value = excluded.value;
    ''');
    stmt.execute([key, value]);
    stmt.dispose();
  }

  /// Returns all stored key-value settings.
  Map<String, String> getAllSettings() {
    try {
      final stmt = _db.prepare('SELECT key, value FROM app_settings;');
      final result = stmt.select();
      stmt.dispose();
      return {
        for (final row in result) row['key'] as String: row['value'] as String
      };
    } catch (_) {
      return {};
    }
  }

  /// Saves or updates the active user account session in SQLite.
  void saveAccountSession(UserAccount session) {
    final stmt = _db.prepare(
      'INSERT INTO user_account_session (id, google_user_id, display_name, email, photo_url, health_connect_enabled, last_health_sync_time, created_at, updated_at, auth_provider) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) '
      'ON CONFLICT(id) DO UPDATE SET google_user_id = excluded.google_user_id, display_name = excluded.display_name, email = excluded.email, photo_url = excluded.photo_url, health_connect_enabled = excluded.health_connect_enabled, last_health_sync_time = excluded.last_health_sync_time, updated_at = excluded.updated_at, auth_provider = excluded.auth_provider;',
    );
    stmt.execute([
      session.id,
      session.googleUserId,
      session.displayName,
      session.email,
      session.photoUrl,
      session.healthConnectEnabled ? 1 : 0,
      session.lastHealthSyncTime?.toIso8601String(),
      session.createdAt.toIso8601String(),
      session.updatedAt.toIso8601String(),
      session.authProvider.providerId,
    ]);
    stmt.dispose();
  }

  /// Retrieves the active user account session, or null if unauthenticated.
  UserAccount? getAccountSession() {
    final stmt = _db.prepare(
      'SELECT id, google_user_id, display_name, email, photo_url, health_connect_enabled, last_health_sync_time, created_at, updated_at, auth_provider FROM user_account_session LIMIT 1;',
    );
    final result = stmt.select();
    stmt.dispose();
    if (result.isEmpty) return null;

    final row = result.first;
    final providerId = (row['auth_provider'] as String?) ?? 'google.com';
    final googleUserId = row['google_user_id'] as String;
    final authProvider = (providerId == AuthProviderType.email.providerId ||
            googleUserId.startsWith('email_'))
        ? AuthProviderType.email
        : AuthProviderType.google;

    return UserAccount(
      id: row['id'] as String,
      googleUserId: googleUserId,
      displayName: row['display_name'] as String,
      email: row['email'] as String,
      photoUrl: row['photo_url'] as String?,
      healthConnectEnabled: (row['health_connect_enabled'] as int) == 1,
      lastHealthSyncTime: row['last_health_sync_time'] != null
          ? DateTime.tryParse(row['last_health_sync_time'] as String)
          : null,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ??
          DateTime.now(),
      isAuthenticated: googleUserId.isNotEmpty,
      authProvider: authProvider,
    );
  }

  /// Clears the active user account session upon sign-out.
  void clearAccountSession() {
    final stmt = _db.prepare('DELETE FROM user_account_session;');
    stmt.execute();
    stmt.dispose();
  }

  /// Wipes all user-generated data across all tables.
  void clearAllData() {
    _db.execute('DELETE FROM food_logs;');
    _db.execute('DELETE FROM weight_logs;');
    _db.execute('DELETE FROM user_profile;');
    _db.execute('DELETE FROM expenditure_history;');
    _db.execute('DELETE FROM workout_sessions;');
    _db.execute('DELETE FROM coaching_check_ins;');
    _db.execute('DELETE FROM day_completions;');
    _db.execute('DELETE FROM app_settings;');
    _db.execute('DELETE FROM user_account_session;');
  }
}
