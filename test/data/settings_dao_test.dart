import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('SettingsDao Direct Unit Tests', () {
    late Database rawDb;
    late SettingsDao settingsDao;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      rawDb.execute('''
        CREATE TABLE app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        );
      ''');
      settingsDao = SettingsDao(rawDb);
    });

    tearDown(() {
      rawDb.dispose();
    });

    test('getSetting returns defaultValue when key is absent', () {
      final value = settingsDao.getSetting('non_existent', 'default_val');
      expect(value, equals('default_val'));
    });

    test('setSetting inserts and updates on conflict', () {
      settingsDao.setSetting('theme', 'dark');
      expect(settingsDao.getSetting('theme', 'light'), equals('dark'));

      settingsDao.setSetting('theme', 'system');
      expect(settingsDao.getSetting('theme', 'light'), equals('system'));
    });

    test(
        'getAllSettings returns empty map initially and all pairs after inserts',
        () {
      expect(settingsDao.getAllSettings(), isEmpty);

      settingsDao.setSetting('k1', 'v1');
      settingsDao.setSetting('k2', 'v2');

      final settings = settingsDao.getAllSettings();
      expect(settings, equals({'k1': 'v1', 'k2': 'v2'}));
    });

    test('clearSettings deletes all stored records', () {
      settingsDao.setSetting('k1', 'v1');
      settingsDao.setSetting('k2', 'v2');
      expect(settingsDao.getAllSettings(), hasLength(2));

      settingsDao.clearSettings();
      expect(settingsDao.getAllSettings(), isEmpty);
    });
  });
}
