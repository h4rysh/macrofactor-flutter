import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/data/repositories/firebase_auth_repository.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/repositories/auth_repository.dart';
import 'package:sique/domain/services/auth_service.dart';
import 'package:sique/presentation/providers/app_providers.dart';

/// Sealed state hierarchy representing authentication status.
@immutable
sealed class AuthState {
  const AuthState({required this.user});

  /// The active user account (authenticated user or UserAccount.guest).
  final UserAccount user;

  /// Convenience getter indicating whether the user is an authenticated user.
  bool get isAuthenticated => user.isAuthenticated;

  /// Convenience getter for display name.
  String get displayName => user.displayName;

  /// Convenience getter for email.
  String get email => user.email;

  /// Convenience getter for profile photo URL.
  String? get photoUrl => user.photoUrl;
}

/// Unauthenticated guest state.
final class AuthUnauthenticated extends AuthState {
  AuthUnauthenticated({UserAccount? guestUser})
      : super(user: guestUser ?? UserAccount.guest);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUnauthenticated && user == other.user;

  @override
  int get hashCode => user.hashCode ^ 0x11;

  @override
  String toString() => 'AuthUnauthenticated(user: ${user.displayName})';
}

/// Transient loading state during authentication operations.
final class AuthLoading extends AuthState {
  const AuthLoading({required super.user});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthLoading && user == other.user;

  @override
  int get hashCode => user.hashCode ^ 0x22;

  @override
  String toString() => 'AuthLoading(user: ${user.displayName})';
}

/// Successfully authenticated account state.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(UserAccount user) : super(user: user);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthAuthenticated && user == other.user;

  @override
  int get hashCode => user.hashCode ^ 0x33;

  @override
  String toString() =>
      'AuthAuthenticated(user: ${user.displayName}, email: ${user.email})';
}

/// Error state when authentication or session operation fails.
final class AuthError extends AuthState {
  const AuthError({
    required super.user,
    required this.message,
  });

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthError && user == other.user && message == other.message;

  @override
  int get hashCode => Object.hash(user, message);

  @override
  String toString() =>
      'AuthError(message: "$message", user: ${user.displayName})';
}

/// Notifier managing authentication lifecycle, offline session persistence, and credential providers.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._db, Object authRepoOrService, [this._ref])
      : _authRepo = authRepoOrService is AuthRepository
            ? authRepoOrService
            : _AuthServiceAdapter(authRepoOrService as AuthService),
        super(_loadInitialState(_db));

  final AppDatabase _db;
  final AuthRepository _authRepo;
  final Ref? _ref;

  /// Loads cached session from SQLite on app startup.
  static AuthState _loadInitialState(AppDatabase db) {
    try {
      final session = db.getAccountSession();
      if (session != null && session.isAuthenticated) {
        return AuthAuthenticated(session);
      }
    } on SqliteException catch (e, st) {
      developer.log(
        'Failed to read account session from SQLite on startup',
        name: 'AuthProviders',
        error: e,
        stackTrace: st,
      );
    }
    return AuthUnauthenticated();
  }

  /// Checks current authentication status silently on startup.
  Future<void> checkCurrentUser() async {
    try {
      final currentUser = await _authRepo.getCurrentUser();
      if (currentUser != null) {
        _db.saveAccountSession(currentUser);
        state = AuthAuthenticated(currentUser);
      }
    } on PlatformException catch (e, st) {
      developer.log(
        'PlatformException checking current user (preserving offline state)',
        name: 'AuthProviders',
        error: e,
        stackTrace: st,
      );
    } on Exception catch (e, st) {
      developer.log(
        'Exception checking current user (preserving offline state)',
        name: 'AuthProviders',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Initiates interactive Google Sign-In.
  Future<bool> signInWithGoogle() async {
    final previousUser = state.user;
    state = AuthLoading(user: previousUser);
    try {
      final user = await _authRepo.signInWithGoogle();
      _db.saveAccountSession(user);
      state = AuthAuthenticated(user);
      return true;
    } catch (e) {
      final cleanMessage =
          e.toString().replaceFirst(RegExp(r'^(Exception|StateError):\s*'), '');
      state = AuthError(
        user: previousUser,
        message: cleanMessage.isEmpty ? 'Google Sign-In failed' : cleanMessage,
      );
      return false;
    }
  }

  /// Permanently deletes the active account and wipes local session data.
  Future<bool> deleteAccount() async {
    final currentUser = state.user;
    state = AuthLoading(user: currentUser);
    try {
      await _authRepo.deleteAccount();
      _db.clearAllData();
      _invalidateUserDataProviders();
      state = AuthUnauthenticated();
      unawaited(_wipeExportResidualFiles());
      return true;
    } catch (e) {
      final cleanMessage = e.toString().replaceFirst(
          RegExp(r'^(Exception|ArgumentError|StateError):\s*'), '');
      state = AuthError(
        user: currentUser,
        message:
            cleanMessage.isEmpty ? 'Account deletion failed' : cleanMessage,
      );
      return false;
    }
  }

  void _invalidateUserDataProviders() {
    final ref = _ref;
    if (ref == null) return;
    try {
      ref.read(userDataEpochProvider.notifier).state++;
      ref.invalidate(userProfileProvider);
      ref.invalidate(dayCompletionsProvider);
      ref.invalidate(foodLogsRevisionProvider);
      ref.invalidate(selectedDateProvider);
      ref.invalidate(weightLogsProvider);
      ref.invalidate(workoutSessionsProvider);
    } catch (e, st) {
      developer.log(
        'Provider invalidation notice',
        name: 'AuthNotifier',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _wipeExportResidualFiles() async {
    try {
      final dirs = <Directory>[
        Directory(
            p.join((await getApplicationDocumentsDirectory()).path, 'exports')),
        Directory(
            p.join((await getTemporaryDirectory()).path, 'sique_exports')),
      ];
      for (final dir in dirs) {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      }
    } catch (_) {
      // Safe no-op in headless unit tests without platform path_provider plugins
    }
  }

  /// Authenticates using a Demo Athlete profile for debug/local testing only.
  Future<void> signInWithDemoAthlete({
    String displayName = 'Athlete (Demo)',
    String email = 'athlete.demo@sique.local',
  }) async {
    if (!kDebugMode) return;
    final demoUser = UserAccount(
      id: 'active_session',
      googleUserId: 'demo_athlete_001',
      displayName: displayName,
      email: email,
      photoUrl: null,
      healthConnectEnabled: true,
      authProvider: AuthProviderType.google,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isAuthenticated: true,
    );
    try {
      _db.saveAccountSession(demoUser);
    } on SqliteException catch (e, st) {
      developer.log(
        'Failed to save demo athlete session to DB',
        name: 'AuthProviders',
        error: e,
        stackTrace: st,
      );
    }
    state = AuthAuthenticated(demoUser);
  }

  /// Sets guest mode explicitly.
  void continueAsGuest() {
    state = AuthUnauthenticated();
  }

  /// Non-destructive sign-out: clears active user account session only.
  Future<void> signOut() async {
    final currentUser = state.user;
    state = AuthLoading(user: currentUser);
    try {
      await _authRepo.signOut();
    } on PlatformException catch (e, st) {
      developer.log(
        'Platform error during remote signOut',
        name: 'AuthProviders',
        error: e,
        stackTrace: st,
      );
    } on Exception catch (e, st) {
      developer.log(
        'Error during remote signOut',
        name: 'AuthProviders',
        error: e,
        stackTrace: st,
      );
    } finally {
      try {
        _db.clearAccountSession();
      } on SqliteException catch (e, st) {
        developer.log(
          'Failed to clear SQLite account session during signOut',
          name: 'AuthProviders',
          error: e,
          stackTrace: st,
        );
      }
      state = AuthUnauthenticated();
    }
  }

  /// Updates Health Connect enablement flag on authenticated sessions.
  void setHealthConnectEnabled(bool enabled) {
    final current = state.user;
    if (!current.isAuthenticated) return;
    final updated = current.copyWith(
      healthConnectEnabled: enabled,
      updatedAt: DateTime.now(),
    );
    try {
      _db.saveAccountSession(updated);
    } on SqliteException catch (e, st) {
      developer.log(
        'Failed to save updated Health Connect enablement to session DB',
        name: 'AuthProviders',
        error: e,
        stackTrace: st,
      );
    }
    if (state is AuthAuthenticated) {
      state = AuthAuthenticated(updated);
    }
  }

  /// Updates the last health sync timestamp on authenticated sessions.
  void updateLastHealthSync(DateTime syncTime) {
    final current = state.user;
    if (!current.isAuthenticated) return;
    final updated = current.copyWith(
      lastHealthSyncTime: syncTime,
      updatedAt: DateTime.now(),
    );
    try {
      _db.saveAccountSession(updated);
    } on SqliteException catch (e, st) {
      developer.log(
        'Failed to update last health sync timestamp in session DB',
        name: 'AuthProviders',
        error: e,
        stackTrace: st,
      );
    }
    if (state is AuthAuthenticated) {
      state = AuthAuthenticated(updated);
    }
  }

  /// Resets an active AuthError back to normal state.
  void clearError() {
    if (state is AuthError) {
      if (state.user.isAuthenticated) {
        state = AuthAuthenticated(state.user);
      } else {
        state = AuthUnauthenticated(guestUser: state.user);
      }
    }
  }
}

/// Compatibility adapter wrapping legacy [AuthService] into modern [AuthRepository].
class _AuthServiceAdapter implements AuthRepository {
  _AuthServiceAdapter(this._service);
  final AuthService _service;

  @override
  bool get isConfigured => true;

  @override
  Stream<UserAccount?> get authStateChanges => const Stream.empty();

  @override
  Future<UserAccount?> getCurrentUser() => _service.getCurrentUser();

  @override
  Future<UserAccount> signInWithGoogle() => _service.signInWithGoogle();

  @override
  Future<void> signOut() => _service.signOut();

  @override
  Future<void> deleteAccount() => _service.signOut();
}

/// Legacy compatibility provider for tests overriding [AuthService].
final authServiceProvider = Provider<AuthService?>((ref) => null);

/// Provider for AuthRepository abstraction.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final legacyService = ref.watch(authServiceProvider);
  if (legacyService != null) {
    return _AuthServiceAdapter(legacyService);
  }
  final db = ref.watch(databaseProvider);
  return FirebaseAuthRepository(db: db);
});

/// Riverpod StateNotifierProvider for authentication state.
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final db = ref.watch(databaseProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthNotifier(db, authRepo, ref);
});

/// Convenience provider returning the active [UserAccount].
final currentUserProvider = Provider<UserAccount>((ref) {
  return ref.watch(authNotifierProvider).user;
});

/// Convenience boolean provider indicating whether the user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});
