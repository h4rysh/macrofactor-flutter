import 'dart:developer' as developer;
import 'package:sqlite3/common.dart';

/// Data Access Object managing key-value application settings in `app_settings` scoped by user_id.
class SettingsDao {
  SettingsDao(this._db,
      {this.userId = 'default_user', String Function()? userIdProvider})
      : _userIdProvider = userIdProvider;

  final CommonDatabase _db;
  String userId;
  String Function()? _userIdProvider;

  set userIdProvider(String Function()? provider) => _userIdProvider = provider;

  /// Active tenant user id for multi-tenant data scoping.
  String get effectiveUserId =>
      _userIdProvider != null ? _userIdProvider!() : userId;

  String _scopedKey(String key, [String? overrideUserId]) {
    final uid = overrideUserId ?? effectiveUserId;
    if (key.startsWith('$uid:')) return key;
    return '$uid:$key';
  }

  /// Retrieves a key-value setting or returns [defaultValue] if not found.
  /// Scoped to active or passed user_id.
  String getSetting(String key, String defaultValue, {String? userId}) {
    try {
      final scopedKey = _scopedKey(key, userId);
      final stmt =
          _db.prepare('SELECT value FROM app_settings WHERE key = ? LIMIT 1;');
      try {
        var result = stmt.select([scopedKey]);
        if (result.isEmpty && !key.contains(':')) {
          // Fallback for legacy unscoped settings
          result = stmt.select([key]);
        }
        if (result.isEmpty) return defaultValue;
        return result.first['value'] as String;
      } finally {
        stmt.dispose();
      }
    } on SqliteException catch (e, st) {
      developer.log(
        'Failed to read setting for key: "$key"',
        name: 'SettingsDao',
        error: e,
        stackTrace: st,
      );
      return defaultValue;
    }
  }

  /// Sets or updates a key-value setting scoped to user_id.
  void setSetting(String key, String value, {String? userId}) {
    final scopedKey = _scopedKey(key, userId);
    final stmt = _db.prepare('''
      INSERT INTO app_settings (key, value)
      VALUES (?, ?)
      ON CONFLICT(key) DO UPDATE SET value = excluded.value;
    ''');
    try {
      stmt.execute([scopedKey, value]);
    } finally {
      stmt.dispose();
    }
  }

  /// Returns all stored key-value settings scoped to user_id.
  Map<String, String> getAllSettings({String? userId}) {
    try {
      final uid = userId ?? effectiveUserId;
      final prefix = '$uid:';
      final stmt = _db.prepare('SELECT key, value FROM app_settings;');
      final ResultSet result;
      try {
        result = stmt.select();
      } finally {
        stmt.dispose();
      }
      final map = <String, String>{};
      for (final row in result) {
        final k = row['key'] as String;
        final v = row['value'] as String;
        if (k.startsWith(prefix)) {
          map[k.substring(prefix.length)] = v;
        } else if (!k.contains(':')) {
          map.putIfAbsent(k, () => v);
        }
      }
      return map;
    } on SqliteException catch (e, st) {
      developer.log(
        'Failed to retrieve all settings',
        name: 'SettingsDao',
        error: e,
        stackTrace: st,
      );
      return {};
    }
  }

  /// Clears settings entries scoped to user_id, or across all users if [allUsers] is true.
  void clearSettings({String? userId, bool allUsers = false}) {
    if (allUsers) {
      _db.execute('DELETE FROM app_settings;');
    } else {
      final uid = userId ?? effectiveUserId;
      final prefix = '$uid:';
      final stmt = _db.prepare(
          'DELETE FROM app_settings WHERE key LIKE ? OR key NOT LIKE "%:%";');
      try {
        stmt.execute(['$prefix%']);
      } finally {
        stmt.dispose();
      }
    }
  }
}
