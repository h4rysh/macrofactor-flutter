/// Database schema definitions and DDL scripts for MacroFactor local SQLite storage.
class DatabaseSchema {
  const DatabaseSchema._();

  static const String createFoodLogsTable = '''
    CREATE TABLE IF NOT EXISTS food_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
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

  static const String createWeightLogsTable = '''
    CREATE TABLE IF NOT EXISTS weight_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL UNIQUE,
      scale_weight REAL NOT NULL,
      note TEXT,
      source TEXT NOT NULL DEFAULT 'manual',
      logged_at TEXT NOT NULL
    );
  ''';

  static const String createWeightLogsIndex = '''
    CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);
  ''';

  static const String createUserProfileTable = '''
    CREATE TABLE IF NOT EXISTS user_profile (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      current_weight REAL NOT NULL,
      target_weight REAL NOT NULL,
      height_cm REAL NOT NULL,
      age INTEGER NOT NULL,
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
      custom_fat REAL
    );
  ''';

  static const String createExpenditureHistoryTable = '''
    CREATE TABLE IF NOT EXISTS expenditure_history (
      date TEXT PRIMARY KEY,
      expenditure_kcal REAL NOT NULL,
      trend_weight_kg REAL NOT NULL,
      variance REAL NOT NULL,
      confidence REAL NOT NULL
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
      updated_at TEXT NOT NULL
    );
  ''';

  static const String createCoachingCheckInsTable = '''
    CREATE TABLE IF NOT EXISTS coaching_check_ins (
      id TEXT PRIMARY KEY,
      check_in_date TEXT NOT NULL,
      previous_calories REAL NOT NULL,
      recommended_calories REAL NOT NULL,
      expenditure_kcal REAL NOT NULL,
      weight_trend_kg REAL NOT NULL,
      is_accepted INTEGER NOT NULL DEFAULT 0,
      status_note TEXT,
      created_at TEXT NOT NULL
    );
  ''';

  static const String createCoachingCheckInsIndex = '''
    CREATE INDEX IF NOT EXISTS idx_coaching_check_ins_date ON coaching_check_ins(check_in_date);
  ''';

  static const List<String> allCreateStatements = [
    createFoodLogsTable,
    createFoodLogsIndex,
    createWeightLogsTable,
    createWeightLogsIndex,
    createUserProfileTable,
    createExpenditureHistoryTable,
    createAppSettingsTable,
    createWorkoutSessionsTable,
    createWorkoutSessionsStartTimeIndex,
    createWorkoutSessionsSourceIndex,
    createUserAccountSessionTable,
    createCoachingCheckInsTable,
    createCoachingCheckInsIndex,
  ];
}
