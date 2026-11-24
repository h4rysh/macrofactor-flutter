/// Database schema definitions and DDL scripts for Sique local SQLite storage.
class DatabaseSchema {
  const DatabaseSchema._();

  static const String createFoodLogsTable = '''
    CREATE TABLE IF NOT EXISTS food_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT NOT NULL DEFAULT 'default_user',
      date TEXT NOT NULL,
      meal_type TEXT NOT NULL,
      food_id INTEGER NOT NULL,
      food_name TEXT NOT NULL,
      serving_quantity REAL NOT NULL,
      unit_name TEXT NOT NULL,
      gram_weight REAL NOT NULL,
      calories REAL NOT NULL,
      protein REAL NOT NULL,
      carbs REAL NOT NULL,
      fat REAL NOT NULL,
      fiber REAL NOT NULL,
      oil_modifier TEXT NOT NULL,
      logged_at TEXT NOT NULL,
      icon_svg TEXT NOT NULL
    );
  ''';

  static const String createFoodLogsIndex = '''
    CREATE INDEX IF NOT EXISTS idx_food_logs_date ON food_logs(date);
  ''';

  static const String createFoodLogsUserDateIndex = '''
    CREATE INDEX IF NOT EXISTS idx_food_logs_user_date ON food_logs(user_id, date, logged_at);
  ''';

  static const String createWeightLogsTable = '''
    CREATE TABLE IF NOT EXISTS weight_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT NOT NULL DEFAULT 'default_user',
      date TEXT NOT NULL,
      scale_weight REAL NOT NULL,
      note TEXT,
      source TEXT NOT NULL DEFAULT 'manual',
      logged_at TEXT NOT NULL,
      UNIQUE(user_id, date)
    );
  ''';

  static const String createWeightLogsIndex = '''
    CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);
  ''';

  static const String createWeightLogsUserDateIndex = '''
    CREATE INDEX IF NOT EXISTS idx_weight_logs_user_date ON weight_logs(user_id, date);
  ''';

  static const String createUserProfileTable = '''
    CREATE TABLE IF NOT EXISTS user_profile (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL DEFAULT 'default_user',
      name TEXT NOT NULL,
      current_weight REAL NOT NULL,
      target_weight REAL NOT NULL,
      height_cm REAL NOT NULL,
      age INTEGER NOT NULL,
      date_of_birth TEXT,
      is_male INTEGER NOT NULL,
      goal_type TEXT NOT NULL,
      program_mode TEXT NOT NULL,
      weekly_rate REAL NOT NULL,
      protein_preference TEXT NOT NULL,
      calorie_floor REAL NOT NULL,
      baseline_expenditure REAL NOT NULL,
      custom_calories REAL,
      custom_protein REAL,
      custom_carbs REAL,
      custom_fat REAL,
      diet_type TEXT NOT NULL DEFAULT 'standard',
      calorie_floor_type TEXT NOT NULL DEFAULT 'standard',
      lifting_experience TEXT NOT NULL DEFAULT 'beginner',
      cardio_experience TEXT NOT NULL DEFAULT 'beginner',
      body_fat_range TEXT,
      weight_history_max REAL,
      distribution_mode TEXT NOT NULL DEFAULT 'even',
      recent_weight_trend TEXT NOT NULL DEFAULT 'stable',
      exercise_frequency TEXT NOT NULL DEFAULT '1-3',
      daily_activity TEXT NOT NULL DEFAULT 'moderate',
      reverse_diet_pacing TEXT NOT NULL DEFAULT 'none',
      is_in_diet_break INTEGER NOT NULL DEFAULT 0,
      daily_water_target_ml INTEGER NOT NULL DEFAULT 2500,
      default_fasting_protocol TEXT NOT NULL DEFAULT 'none',
      peri_workout_timing_enabled INTEGER NOT NULL DEFAULT 0,
      neck_circumference_cm REAL
    );
  ''';

  static const String createExpenditureHistoryTable = '''
    CREATE TABLE IF NOT EXISTS expenditure_history (
      user_id TEXT NOT NULL DEFAULT 'default_user',
      date TEXT NOT NULL,
      expenditure_kcal REAL NOT NULL,
      trend_weight_kg REAL NOT NULL,
      variance REAL NOT NULL,
      confidence REAL NOT NULL,
      PRIMARY KEY(user_id, date)
    );
  ''';

  static const String createAppSettingsTable = '''
    CREATE TABLE IF NOT EXISTS app_settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  ''';

  static const String createWorkoutSessionsTable = '''
    CREATE TABLE IF NOT EXISTS workout_sessions (
      id TEXT PRIMARY KEY,
      source TEXT NOT NULL,
      title TEXT NOT NULL,
      start_time TEXT NOT NULL,
      end_time TEXT NOT NULL,
      duration_minutes INTEGER NOT NULL,
      calories_burned REAL NOT NULL,
      notes TEXT,
      created_at TEXT NOT NULL
    );
  ''';

  static const String createWorkoutSessionsStartTimeIndex = '''
    CREATE INDEX IF NOT EXISTS idx_workout_sessions_start_time ON workout_sessions(start_time);
  ''';

  static const String createWorkoutSessionsSourceIndex = '''
    CREATE INDEX IF NOT EXISTS idx_workout_sessions_source ON workout_sessions(source);
  ''';

  static const String createUserAccountSessionTable = '''
    CREATE TABLE IF NOT EXISTS user_account_session (
      id TEXT PRIMARY KEY,
      google_user_id TEXT NOT NULL,
      display_name TEXT NOT NULL,
      email TEXT NOT NULL,
      photo_url TEXT,
      health_connect_enabled INTEGER NOT NULL DEFAULT 0,
      last_health_sync_time TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      auth_provider TEXT NOT NULL DEFAULT 'google.com'
    );
  ''';

  static const String createCoachingCheckInsTable = '''
    CREATE TABLE IF NOT EXISTS coaching_check_ins (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL DEFAULT 'default_user',
      check_in_date TEXT NOT NULL,
      previous_calories REAL NOT NULL,
      recommended_calories REAL NOT NULL,
      expenditure_kcal REAL NOT NULL,
      weight_trend_kg REAL NOT NULL,
      is_accepted INTEGER NOT NULL DEFAULT 0,
      status_note TEXT,
      created_at TEXT NOT NULL,
      raw_calorie_delta REAL,
      damped_calorie_delta REAL,
      was_clamped INTEGER NOT NULL DEFAULT 0,
      silent_recomp_detected INTEGER NOT NULL DEFAULT 0
    );
  ''';

  static const String createCoachingCheckInsIndex = '''
    CREATE INDEX IF NOT EXISTS idx_coaching_check_ins_user_date ON coaching_check_ins(user_id, check_in_date);
  ''';

  static const String createDayCompletionsTable = '''
    CREATE TABLE IF NOT EXISTS day_completions (
      user_id TEXT NOT NULL DEFAULT 'default_user',
      date TEXT NOT NULL,
      is_complete INTEGER NOT NULL,
      updated_at TEXT NOT NULL,
      PRIMARY KEY(user_id, date)
    );
  ''';

  static const String createDayCompletionsIndex = '''
    CREATE INDEX IF NOT EXISTS idx_day_completions_date ON day_completions(date);
  ''';

  static const String createBodyMeasurementsTable = '''
    CREATE TABLE IF NOT EXISTS body_measurements (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL DEFAULT 'default_user',
      date TEXT NOT NULL,
      waist_cm REAL,
      hips_cm REAL,
      chest_cm REAL,
      neck_cm REAL,
      biceps_cm REAL,
      thigh_cm REAL,
      body_fat_pct REAL,
      source TEXT NOT NULL DEFAULT 'manual',
      notes TEXT,
      logged_at TEXT NOT NULL,
      UNIQUE(user_id, date)
    );
  ''';

  static const String createBodyMeasurementsIndex = '''
    CREATE INDEX IF NOT EXISTS idx_body_measurements_user_date ON body_measurements(user_id, date);
  ''';

  static const String createWeeklyChallengesTable = '''
    CREATE TABLE IF NOT EXISTS weekly_challenges (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL DEFAULT 'default_user',
      type TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      target_metric TEXT NOT NULL,
      target_value REAL NOT NULL,
      current_value REAL NOT NULL DEFAULT 0.0,
      unit TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'active',
      week_start_date TEXT NOT NULL,
      week_end_date TEXT NOT NULL,
      completed_at TEXT,
      created_at TEXT NOT NULL
    );
  ''';

  static const String createWeeklyChallengesIndex = '''
    CREATE INDEX IF NOT EXISTS idx_weekly_challenges_user_status ON weekly_challenges(user_id, status);
  ''';

  static const String createChallengeDailyProgressTable = '''
    CREATE TABLE IF NOT EXISTS challenge_daily_progress (
      id TEXT PRIMARY KEY,
      challenge_id TEXT NOT NULL,
      date TEXT NOT NULL,
      achieved_value REAL NOT NULL,
      is_target_hit INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (challenge_id) REFERENCES weekly_challenges(id) ON DELETE CASCADE,
      UNIQUE(challenge_id, date)
    );
  ''';

  static const String createChallengeDailyProgressIndex = '''
    CREATE INDEX IF NOT EXISTS idx_challenge_progress_lookup ON challenge_daily_progress(challenge_id, date);
  ''';

  static const String createWaterLogsTable = '''
    CREATE TABLE IF NOT EXISTS water_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT NOT NULL DEFAULT 'default_user',
      date TEXT NOT NULL,
      amount_ml INTEGER NOT NULL,
      logged_at TEXT NOT NULL
    );
  ''';

  static const String createWaterLogsIndex = '''
    CREATE INDEX IF NOT EXISTS idx_water_logs_user_date ON water_logs(user_id, date);
  ''';

  static const String createFastingSessionsTable = '''
    CREATE TABLE IF NOT EXISTS fasting_sessions (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL DEFAULT 'default_user',
      protocol TEXT NOT NULL,
      start_time TEXT NOT NULL,
      target_end_time TEXT NOT NULL,
      actual_end_time TEXT,
      state TEXT NOT NULL DEFAULT 'active',
      notes TEXT
    );
  ''';

  static const String createFastingSessionsIndex = '''
    CREATE INDEX IF NOT EXISTS idx_fasting_sessions_user_state ON fasting_sessions(user_id, state);
  ''';

  static const List<String> allCreateStatements = [
    createFoodLogsTable,
    createFoodLogsIndex,
    createFoodLogsUserDateIndex,
    createWeightLogsTable,
    createWeightLogsIndex,
    createWeightLogsUserDateIndex,
    createUserProfileTable,
    createExpenditureHistoryTable,
    createAppSettingsTable,
    createWorkoutSessionsTable,
    createWorkoutSessionsStartTimeIndex,
    createWorkoutSessionsSourceIndex,
    createUserAccountSessionTable,
    createCoachingCheckInsTable,
    createCoachingCheckInsIndex,
    createDayCompletionsTable,
    createDayCompletionsIndex,
    createBodyMeasurementsTable,
    createBodyMeasurementsIndex,
    createWeeklyChallengesTable,
    createWeeklyChallengesIndex,
    createChallengeDailyProgressTable,
    createChallengeDailyProgressIndex,
    createWaterLogsTable,
    createWaterLogsIndex,
    createFastingSessionsTable,
    createFastingSessionsIndex,
  ];
}
