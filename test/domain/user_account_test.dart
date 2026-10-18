import 'package:flutter_test/flutter_test.dart';
import 'package:macro_factor_app/domain/models/user_account.dart';

void main() {
  group('UserAccount Domain Model Tests', () {
    test('UserAccount.guest creates unauthenticated guest user', () {
      final guest = UserAccount.guest;

      expect(guest.id, equals('guest'));
      expect(guest.googleUserId, isEmpty);
      expect(guest.displayName, equals('Guest Athlete'));
      expect(guest.email, isEmpty);
      expect(guest.photoUrl, isNull);
      expect(guest.healthConnectEnabled, isFalse);
      expect(guest.lastHealthSyncTime, isNull);
      expect(guest.isAuthenticated, isFalse);
    });

    test(
        'UserAccount.fromGoogle creates authenticated user with active session',
        () {
      final now = DateTime(2026, 10, 17, 12, 0);
      final user = UserAccount.fromGoogle(
        googleUserId: 'google_12345',
        displayName: 'Jane Doe',
        email: 'jane.doe@example.com',
        photoUrl: 'https://example.com/jane.jpg',
        healthConnectEnabled: true,
        lastHealthSyncTime: now,
      );

      expect(user.id, equals('active_session'));
      expect(user.googleUserId, equals('google_12345'));
      expect(user.displayName, equals('Jane Doe'));
      expect(user.email, equals('jane.doe@example.com'));
      expect(user.photoUrl, equals('https://example.com/jane.jpg'));
      expect(user.healthConnectEnabled, isTrue);
      expect(user.lastHealthSyncTime, equals(now));
      expect(user.isAuthenticated, isTrue);
    });

    test('toMap and fromMap serialize and deserialize accurately', () {
      final created = DateTime(2026, 10, 10, 8, 30);
      final updated = DateTime(2026, 10, 17, 9, 45);
      final syncTime = DateTime(2026, 10, 17, 9, 30);

      final user = UserAccount(
        id: 'user_999',
        googleUserId: 'gid_888',
        displayName: 'Sam Runner',
        email: 'sam@fitness.org',
        photoUrl: 'https://avatar.com/sam.png',
        healthConnectEnabled: true,
        lastHealthSyncTime: syncTime,
        createdAt: created,
        updatedAt: updated,
        isAuthenticated: true,
      );

      final map = user.toMap();
      expect(map['id'], equals('user_999'));
      expect(map['google_user_id'], equals('gid_888'));
      expect(map['display_name'], equals('Sam Runner'));
      expect(map['email'], equals('sam@fitness.org'));
      expect(map['photo_url'], equals('https://avatar.com/sam.png'));
      expect(map['health_connect_enabled'], equals(1));
      expect(map['last_health_sync_time'], equals(syncTime.toIso8601String()));
      expect(map['created_at'], equals(created.toIso8601String()));
      expect(map['updated_at'], equals(updated.toIso8601String()));

      final deserialized = UserAccount.fromMap(map);
      expect(deserialized.id, equals(user.id));
      expect(deserialized.googleUserId, equals(user.googleUserId));
      expect(deserialized.displayName, equals(user.displayName));
      expect(deserialized.email, equals(user.email));
      expect(deserialized.photoUrl, equals(user.photoUrl));
      expect(
          deserialized.healthConnectEnabled, equals(user.healthConnectEnabled));
      expect(deserialized.lastHealthSyncTime, equals(user.lastHealthSyncTime));
      expect(deserialized.createdAt, equals(user.createdAt));
      expect(deserialized.updatedAt, equals(user.updatedAt));
      expect(deserialized.isAuthenticated, isTrue);
      expect(deserialized, equals(user));
    });

    test('fromMap handles empty and null fallback fields cleanly', () {
      final minimalMap = <String, dynamic>{};
      final user = UserAccount.fromMap(minimalMap);

      expect(user.id, equals('active_session'));
      expect(user.googleUserId, isEmpty);
      expect(user.displayName, equals('Guest Athlete'));
      expect(user.email, isEmpty);
      expect(user.photoUrl, isNull);
      expect(user.healthConnectEnabled, isFalse);
      expect(user.lastHealthSyncTime, isNull);
      expect(user.isAuthenticated, isFalse);
    });

    test('copyWith updates fields and clears nullable values when specified',
        () {
      final initial = UserAccount.fromGoogle(
        googleUserId: 'gid_1',
        displayName: 'Initial Name',
        email: 'init@test.com',
        photoUrl: 'https://test.com/photo.png',
        healthConnectEnabled: false,
        lastHealthSyncTime: DateTime(2026, 10, 1),
      );

      final updated = initial.copyWith(
        displayName: 'Updated Name',
        healthConnectEnabled: true,
      );

      expect(updated.displayName, equals('Updated Name'));
      expect(updated.healthConnectEnabled, isTrue);
      expect(updated.email, equals('init@test.com'));
      expect(updated.photoUrl, equals('https://test.com/photo.png'));

      final cleared = updated.copyWith(
        clearPhotoUrl: true,
        clearLastSyncTime: true,
      );

      expect(cleared.photoUrl, isNull);
      expect(cleared.lastHealthSyncTime, isNull);
      expect(cleared.displayName, equals('Updated Name'));
    });

    test('equality and hashCode support value semantics', () {
      final t1 = DateTime(2026, 1, 1);
      final t2 = DateTime(2026, 1, 2);

      final userA = UserAccount(
        id: 'u1',
        googleUserId: 'g1',
        displayName: 'User',
        email: 'u@test.com',
        photoUrl: 'photo',
        healthConnectEnabled: true,
        lastHealthSyncTime: t2,
        createdAt: t1,
        updatedAt: t2,
        isAuthenticated: true,
      );

      final userB = UserAccount(
        id: 'u1',
        googleUserId: 'g1',
        displayName: 'User',
        email: 'u@test.com',
        photoUrl: 'photo',
        healthConnectEnabled: true,
        lastHealthSyncTime: t2,
        createdAt: t1,
        updatedAt: t2,
        isAuthenticated: true,
      );

      expect(userA, equals(userB));
      expect(userA.hashCode, equals(userB.hashCode));
      expect(userA.toString(), contains('UserAccount(id: u1'));
    });
  });
}
