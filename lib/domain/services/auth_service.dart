import 'package:macro_factor_app/domain/models/user_account.dart';

/// Contract for authentication operations and Google Identity integration.
abstract interface class AuthService {
  /// Returns the current active user account if cached or authenticated,
  /// or null if unauthenticated (guest mode).
  Future<UserAccount?> getCurrentUser();

  /// Attempts silent authentication with cached credentials without user interaction.
  /// Returns null if silent sign-in fails or no prior session exists.
  Future<UserAccount?> signInSilently();

  /// Initiates interactive Google Sign-In flow.
  /// Returns authenticated [UserAccount] on success.
  /// Throws an exception if user cancels or authentication fails.
  Future<UserAccount> signInWithGoogle();

  /// Signs out of the Google account and clears local authentication state.
  Future<void> signOut();
}
