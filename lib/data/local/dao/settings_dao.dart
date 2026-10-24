import 'package:sqlite3/common.dart';

/// Data Access Object managing key-value application settings in `app_settings`.
class SettingsDao {
  SettingsDao(this._db);

  final CommonDatabase _db;

  /// Retrieves a key-value setting or returns [defaultValue] if not found.
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

  /// Clears all settings entries.
  void clearSettings() {
    _db.execute('DELETE FROM app_settings;');
  }
}
