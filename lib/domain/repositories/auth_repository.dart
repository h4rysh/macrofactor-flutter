import 'package:sique/domain/models/user_account.dart';

/// Abstract contract for authentication operations (Google Sign-In + Local Guest).
/// UI screens and view models depend exclusively on this interface.
abstract interface class AuthRepository {
  /// Stream emitting active user account changes (null on sign-out).
  Stream<UserAccount?> get authStateChanges;

  /// Retrieves the current cached or active session user, or null if unauthenticated.
  Future<UserAccount?> getCurrentUser();

  /// Initiates interactive Google Sign-In.
  Future<UserAccount> signInWithGoogle();

  /// Permanently deletes the active user account and clears local session data.
  Future<void> deleteAccount();

  /// Signs out of the active session and clears tokens.
  Future<void> signOut();

  /// Whether the authentication provider backend is fully configured.
  bool get isConfigured;
}
