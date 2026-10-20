import 'package:flutter_test/flutter_test.dart';
import 'package:macro_factor_app/data/local/app_database.dart';

void main() {
  group('Issue 4 Regression: Weight Source & Conflict Resolution', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.inMemory();
    });

    tearDown(() {
      db.close();
    });

    test(
        'Manual weight entry is NEVER overwritten by subsequent Health Connect sync',
        () {
      const date = '2026-10-18';

      // 1. User logs a manual morning weight
      db.insertWeightLog(date, 72.5, 'Morning weigh-in after waking up',
          source: 'manual');

      final initialLog = db.getWeightLogForDate(date);
      expect(initialLog, isNotNull);
      expect(initialLog!.weightKg, equals(72.5));
      expect(initialLog.note, equals('Morning weigh-in after waking up'));

      // 2. Health Connect sync runs and tries to insert/upsert a weight for the same date
      db.insertWeightLog(date, 74.0, 'Health Connect Smart Scale Sync',
          source: 'health_connect');

      // 3. Manual entry must remain intact!
      final preservedLog = db.getWeightLogForDate(date);
      expect(preservedLog, isNotNull);
      expect(preservedLog!.weightKg, equals(72.5),
          reason: 'Health Connect should not overwrite manual weight');
      expect(preservedLog.note, equals('Morning weigh-in after waking up'));
    });

    test('Health Connect entry CAN be updated by newer Health Connect reading',
        () {
      const date = '2026-10-18';

      // 1. Initial health connect sync
      db.insertWeightLog(date, 73.0, 'Health Connect Sync 1',
          source: 'health_connect');

      // 2. Newer health connect sync on same date updates it
      db.insertWeightLog(date, 72.8, 'Health Connect Sync 2',
          source: 'health_connect');

      final updatedLog = db.getWeightLogForDate(date);
      expect(updatedLog!.weightKg, equals(72.8));
      expect(updatedLog.note, equals('Health Connect Sync 2'));
    });

    test('Manual entry OVERWRITES existing Health Connect entry', () {
      const date = '2026-10-18';

      // 1. Health connect synced first
      db.insertWeightLog(date, 73.5, 'Health Connect Scale',
          source: 'health_connect');

      // 2. User manually corrects it
      db.insertWeightLog(date, 72.4, 'Manual override', source: 'manual');

      final userLog = db.getWeightLogForDate(date);
      expect(userLog!.weightKg, equals(72.4));
      expect(userLog.note, equals('Manual override'));
    });
  });
}
