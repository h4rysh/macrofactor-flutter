import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_factor_app/data/local/app_database.dart';
import 'package:macro_factor_app/data/services/google_auth_service.dart';
import 'package:macro_factor_app/domain/models/user_account.dart';
import 'package:macro_factor_app/domain/services/auth_service.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';

/// Sealed state hierarchy representing authentication status.
@immutable
sealed class AuthState {
  const AuthState({required this.user});

  /// The active user account (authenticated Google user or UserAccount.guest).
  final UserAccount user;

  /// Convenience getter indicating whether the user is an authenticated Google user.
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

/// Successfully authenticated Google account state.
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

/// Notifier managing authentication lifecycle, offline session persistence, and Google OAuth.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._db, this._authService) : super(_loadInitialState(_db));

  final AppDatabase _db;
  final AuthService _authService;

  /// Loads cached session from SQLite on app startup.
  static AuthState _loadInitialState(AppDatabase db) {
    try {
      final session = db.getAccountSession();
      if (session != null && session.isAuthenticated) {
        return AuthAuthenticated(session);
      }
    } catch (_) {
      // Graceful fallback for fresh installs or uninitialized tables
    }
    return AuthUnauthenticated();
  }

  /// Checks current authentication status silently on startup.
  /// Preserves SQLite session if offline or silent sign-in fails.
  Future<void> checkCurrentUser() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        _db.saveAccountSession(currentUser);
        state = AuthAuthenticated(currentUser);
      }
    } catch (_) {
      // Offline mode: preserve cached SQLite session
    }
  }

  /// Initiates interactive Google Sign-In.
  Future<bool> signInWithGoogle() async {
    final previousUser = state.user;
    state = AuthLoading(user: previousUser);
    try {
      final user = await _authService.signInWithGoogle();
      _db.saveAccountSession(user);
      state = AuthAuthenticated(user);
      return true;
    } catch (e) {
      final cleanMessage =
          e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      state = AuthError(
        user: previousUser,
        message: cleanMessage.isEmpty ? 'Google Sign-In failed' : cleanMessage,
      );
      return false;
    }
  }

  /// Non-destructive sign-out: clears active user account session only.
  /// Preserves all local food logs, scale weights, and workout records.
  Future<void> signOut() async {
    final currentUser = state.user;
    state = AuthLoading(user: currentUser);
    try {
      await _authService.signOut();
    } catch (_) {
      // Non-fatal if platform network call fails
    } finally {
      try {
        _db.clearAccountSession();
      } catch (_) {}
      state = AuthUnauthenticated();
    }
  }

  /// Updates Health Connect enablement flag on the active session.
  void setHealthConnectEnabled(bool enabled) {
    final current = state.user;
    final updated = current.copyWith(
      healthConnectEnabled: enabled,
      updatedAt: DateTime.now(),
    );
    try {
      _db.saveAccountSession(updated);
    } catch (_) {}
    if (state is AuthAuthenticated) {
      state = AuthAuthenticated(updated);
    }
  }

  /// Updates the last health sync timestamp on the active session.
  void updateLastHealthSync(DateTime syncTime) {
    final current = state.user;
    final updated = current.copyWith(
      lastHealthSyncTime: syncTime,
      updatedAt: DateTime.now(),
    );
    try {
      _db.saveAccountSession(updated);
    } catch (_) {}
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

/// Provider for AuthService abstraction. Defaults to [GoogleAuthServiceImpl] for production authentication.
final authServiceProvider = Provider<AuthService>((ref) {
  return GoogleAuthServiceImpl();
});

/// Riverpod StateNotifierProvider for authentication state.
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final db = ref.watch(databaseProvider);
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(db, authService);
});

/// Convenience provider returning the active [UserAccount] (authenticated user or guest).
final currentUserProvider = Provider<UserAccount>((ref) {
  return ref.watch(authNotifierProvider).user;
});

/// Convenience boolean provider indicating whether the user is authenticated with Google.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});
