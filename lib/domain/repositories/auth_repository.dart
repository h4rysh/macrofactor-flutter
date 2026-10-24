import 'package:sique/domain/models/user_account.dart';

/// Abstract contract for authentication operations.
/// UI screens and view models depend exclusively on this interface.
abstract interface class AuthRepository {
  /// Stream emitting active user account changes (null on sign-out).
  Stream<UserAccount?> get authStateChanges;

  /// Retrieves the current cached or active session user, or null if unauthenticated.
  Future<UserAccount?> getCurrentUser();

  /// Authenticates using email and password.
  Future<UserAccount> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Registers a new user with email and password.
  Future<UserAccount> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Initiates interactive Google Sign-In.
  Future<UserAccount> signInWithGoogle();

  /// Dispatches password reset link to user email.
  Future<void> sendPasswordResetEmail(String email);

  /// Changes password for email-authenticated accounts.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Permanently deletes the active user account.
  /// Provider-aware: [password] is required for email/password accounts,
  /// while Google accounts re-authenticate via fresh Google OAuth token.
  Future<void> deleteAccount({
    String? password,
  });

  /// Signs out of the active session and clears tokens.
  Future<void> signOut();

  /// Whether the authentication provider backend is fully configured.
  bool get isConfigured;
}
