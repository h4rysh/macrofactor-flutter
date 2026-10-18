import 'package:flutter_test/flutter_test.dart';
import 'package:macro_factor_app/domain/models/workout_session.dart';

void main() {
  group('WorkoutSession Domain Model Tests', () {
    test('isHevy and isHealthConnect identify source provenance correctly', () {
      final hevySession = WorkoutSession(
        id: 's_1',
        source: WorkoutSource.hevy,
        title: 'Push Day',
        startTime: DateTime(2026, 10, 15, 10, 0),
        endTime: DateTime(2026, 10, 15, 11, 0),
        durationMinutes: 60,
        caloriesBurned: 400.0,
        createdAt: DateTime(2026, 10, 15, 11, 5),
      );

      final hcSession = WorkoutSession(
        id: 's_2',
        source: WorkoutSource.healthConnect,
        title: 'Treadmill',
        startTime: DateTime(2026, 10, 15, 12, 0),
        endTime: DateTime(2026, 10, 15, 12, 30),
        durationMinutes: 30,
        caloriesBurned: 220.0,
        createdAt: DateTime(2026, 10, 15, 12, 35),
      );

      final manualSession = WorkoutSession(
        id: 's_3',
        source: WorkoutSource.manual,
        title: 'Calisthenics',
        startTime: DateTime(2026, 10, 15, 14, 0),
        endTime: DateTime(2026, 10, 15, 14, 45),
        durationMinutes: 45,
        caloriesBurned: 250.0,
        createdAt: DateTime(2026, 10, 15, 14, 50),
      );

      expect(hevySession.isHevy, isTrue);
      expect(hevySession.isHealthConnect, isFalse);

      expect(hcSession.isHevy, isFalse);
      expect(hcSession.isHealthConnect, isTrue);

      expect(manualSession.isHevy, isFalse);
      expect(manualSession.isHealthConnect, isFalse);
    });

    test('duration and formattedDuration calculate properly', () {
      final start = DateTime(2026, 10, 16, 8, 0);
      final sessionUnderHour = WorkoutSession(
        id: 'd_1',
        source: WorkoutSource.hevy,
        title: 'Arms',
        startTime: start,
        endTime: start.add(const Duration(minutes: 45)),
        durationMinutes: 45,
        caloriesBurned: 280.0,
        createdAt: start,
      );

      final sessionHourAndMinutes = WorkoutSession(
        id: 'd_2',
        source: WorkoutSource.hevy,
        title: 'Legs',
        startTime: start,
        endTime: start.add(const Duration(minutes: 75)),
        durationMinutes: 75,
        caloriesBurned: 520.0,
        createdAt: start,
      );

      final sessionExactHours = WorkoutSession(
        id: 'd_3',
        source: WorkoutSource.hevy,
        title: 'Long Ride',
        startTime: start,
        endTime: start.add(const Duration(hours: 2)),
        durationMinutes: 120,
        caloriesBurned: 800.0,
        createdAt: start,
      );

      expect(sessionUnderHour.duration, equals(const Duration(minutes: 45)));
      expect(sessionUnderHour.formattedDuration, equals('45m'));

      expect(
          sessionHourAndMinutes.duration, equals(const Duration(minutes: 75)));
      expect(sessionHourAndMinutes.formattedDuration, equals('1h 15m'));

      expect(sessionExactHours.duration, equals(const Duration(hours: 2)));
      expect(sessionExactHours.formattedDuration, equals('2h'));
    });

    test('toMap and fromMap serialize and deserialize cleanly', () {
      final start = DateTime(2026, 10, 17, 7, 0);
      final end = DateTime(2026, 10, 17, 8, 15);
      final created = DateTime(2026, 10, 17, 8, 20);

      final session = WorkoutSession(
        id: 'session_uuid_456',
        source: WorkoutSource.hevy,
        title: 'Heavy Deadlifts & Core',
        startTime: start,
        endTime: end,
        durationMinutes: 75,
        caloriesBurned: 460.5,
        notes: 'Felt strong, 5x5 completed',
        createdAt: created,
      );

      final map = session.toMap();
      expect(map['id'], equals('session_uuid_456'));
      expect(map['source'], equals('hevy'));
      expect(map['title'], equals('Heavy Deadlifts & Core'));
      expect(map['start_time'], equals(start.toIso8601String()));
      expect(map['end_time'], equals(end.toIso8601String()));
      expect(map['duration_minutes'], equals(75));
      expect(map['calories_burned'], equals(460.5));
      expect(map['notes'], equals('Felt strong, 5x5 completed'));
      expect(map['created_at'], equals(created.toIso8601String()));

      final restored = WorkoutSession.fromMap(map);
      expect(restored.id, equals(session.id));
      expect(restored.source, equals(session.source));
      expect(restored.title, equals(session.title));
      expect(restored.startTime, equals(session.startTime));
      expect(restored.endTime, equals(session.endTime));
      expect(restored.durationMinutes, equals(session.durationMinutes));
      expect(restored.caloriesBurned, equals(session.caloriesBurned));
      expect(restored.notes, equals(session.notes));
      expect(restored.createdAt, equals(session.createdAt));
      expect(restored, equals(session));
    });

    test('copyWith updates specific attributes and supports clearing notes',
        () {
      final initial = WorkoutSession(
        id: 'copy_1',
        source: WorkoutSource.manual,
        title: 'Initial Title',
        startTime: DateTime(2026, 10, 1, 10, 0),
        endTime: DateTime(2026, 10, 1, 10, 45),
        durationMinutes: 45,
        caloriesBurned: 300.0,
        notes: 'Some notes',
        createdAt: DateTime(2026, 10, 1, 10, 50),
      );

      final updated = initial.copyWith(
        title: 'Updated Title',
        durationMinutes: 50,
      );

      expect(updated.title, equals('Updated Title'));
      expect(updated.durationMinutes, equals(50));
      expect(updated.notes, equals('Some notes'));

      final notesCleared = updated.copyWith(clearNotes: true);
      expect(notesCleared.notes, isNull);
      expect(notesCleared.title, equals('Updated Title'));
    });

    test('value equality and hashCode behave predictably', () {
      final start = DateTime(2026, 10, 10, 9, 0);
      final end = DateTime(2026, 10, 10, 10, 0);

      final s1 = WorkoutSession(
        id: 'id_1',
        source: 'hevy',
        title: 'Workout',
        startTime: start,
        endTime: end,
        durationMinutes: 60,
        caloriesBurned: 350.0,
        createdAt: start,
      );

      final s2 = WorkoutSession(
        id: 'id_1',
        source: 'hevy',
        title: 'Workout',
        startTime: start,
        endTime: end,
        durationMinutes: 60,
        caloriesBurned: 350.0,
        createdAt: start,
      );

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1.toString(), contains('WorkoutSession(id: id_1'));
    });
  });
}
