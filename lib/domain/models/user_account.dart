import 'package:flutter/foundation.dart';

/// Represents a persistent user account with Google Identity and Health Connect synchronization metadata.
@immutable
class UserAccount {
  const UserAccount({
    required this.id,
    required this.googleUserId,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.healthConnectEnabled = false,
    this.lastHealthSyncTime,
    required this.createdAt,
    required this.updatedAt,
    this.isAuthenticated = true,
  });

  /// Unique session or user ID (e.g. 'active_session' for the singleton device session).
  final String id;

  /// Google OAuth Subject identifier.
  final String googleUserId;

  /// User's display name from Google profile or custom preference.
  final String displayName;

  /// User's email address from Google profile.
  final String email;

  /// URL to the user's Google profile photo.
  final String? photoUrl;

  /// Whether synchronization with Google Health Connect is active.
  final bool healthConnectEnabled;

  /// Timestamp of the last successful Health Connect synchronization.
  final DateTime? lastHealthSyncTime;

  /// When this account record was created.
  final DateTime createdAt;

  /// When this account record was last updated.
  final DateTime updatedAt;

  /// Whether this user is an authenticated Google user (false for guest mode).
  final bool isAuthenticated;

  /// Pre-configured guest user for unauthenticated mode.
  static final UserAccount guest = UserAccount(
    id: 'guest',
    googleUserId: '',
    displayName: 'Guest Athlete',
    email: '',
    photoUrl: null,
    healthConnectEnabled: false,
    lastHealthSyncTime: null,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    isAuthenticated: false,
  );

  /// Factory for creating an authenticated UserAccount from Google OAuth details.
  factory UserAccount.fromGoogle({
    String id = 'active_session',
    required String googleUserId,
    required String displayName,
    required String email,
    String? photoUrl,
    bool healthConnectEnabled = false,
    DateTime? lastHealthSyncTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return UserAccount(
      id: id,
      googleUserId: googleUserId,
      displayName: displayName,
      email: email,
      photoUrl: photoUrl,
      healthConnectEnabled: healthConnectEnabled,
      lastHealthSyncTime: lastHealthSyncTime,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      isAuthenticated: true,
    );
  }

  /// Maps SQLite row map to UserAccount.
  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      id: map['id'] as String? ?? 'active_session',
      googleUserId: map['google_user_id'] as String? ?? '',
      displayName: map['display_name'] as String? ?? 'Guest Athlete',
      email: map['email'] as String? ?? '',
      photoUrl: map['photo_url'] as String?,
      healthConnectEnabled: (map['health_connect_enabled'] as int? ?? 0) == 1,
      lastHealthSyncTime: map['last_health_sync_time'] != null
          ? DateTime.tryParse(map['last_health_sync_time'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'] as String) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? (DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now())
          : DateTime.now(),
      isAuthenticated: (map['google_user_id'] as String? ?? '').isNotEmpty,
    );
  }

  /// Converts UserAccount to SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'google_user_id': googleUserId,
      'display_name': displayName,
      'email': email,
      'photo_url': photoUrl,
      'health_connect_enabled': healthConnectEnabled ? 1 : 0,
      'last_health_sync_time': lastHealthSyncTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy with modified fields.
  UserAccount copyWith({
    String? id,
    String? googleUserId,
    String? displayName,
    String? email,
    String? photoUrl,
    bool? healthConnectEnabled,
    DateTime? lastHealthSyncTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isAuthenticated,
    bool clearPhotoUrl = false,
    bool clearLastSyncTime = false,
  }) {
    return UserAccount(
      id: id ?? this.id,
      googleUserId: googleUserId ?? this.googleUserId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      healthConnectEnabled: healthConnectEnabled ?? this.healthConnectEnabled,
      lastHealthSyncTime: clearLastSyncTime
          ? null
          : (lastHealthSyncTime ?? this.lastHealthSyncTime),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAccount &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          googleUserId == other.googleUserId &&
          displayName == other.displayName &&
          email == other.email &&
          photoUrl == other.photoUrl &&
          healthConnectEnabled == other.healthConnectEnabled &&
          lastHealthSyncTime == other.lastHealthSyncTime &&
          isAuthenticated == other.isAuthenticated;

  @override
  int get hashCode => Object.hash(
        id,
        googleUserId,
        displayName,
        email,
        photoUrl,
        healthConnectEnabled,
        lastHealthSyncTime,
        isAuthenticated,
      );

  @override
  String toString() =>
      'UserAccount(id: $id, name: $displayName, email: $email, googleId: $googleUserId, healthConnect: $healthConnectEnabled, authed: $isAuthenticated)';
}
