import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/services/auth_service.dart';

/// Production implementation of [AuthService] leveraging `google_sign_in: ^6.2.2`.
///
/// Implements full authentication lifecycle handling across Android, iOS, and Web,
/// featuring platform capability detection, non-interactive silent recovery,
/// and safe null-guarded mapping into domain [UserAccount] entities.
class GoogleAuthServiceImpl implements AuthService {
  /// Constructs [GoogleAuthServiceImpl].
  ///
  /// An optional [googleSignIn] instance can be injected for unit tests.
  GoogleAuthServiceImpl({
    GoogleSignIn? googleSignIn,
    List<String> scopes = const <String>[
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
    String? clientId,
    String? serverClientId = const String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue: '',
    ),
  }) : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: scopes,
              clientId: clientId,
              serverClientId:
                  serverClientId?.isNotEmpty == true ? serverClientId : null,
            );

  final GoogleSignIn _googleSignIn;

  /// Returns true if the host platform is supported natively by Google Sign-In.
  bool get isPlatformSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Returns the current active user account if cached in memory or authenticated.
  /// If not yet present in memory, attempts silent re-authentication.
  /// Returns null if unauthenticated or running on an unsupported platform.
  @override
  Future<UserAccount?> getCurrentUser() async {
    if (!isPlatformSupported) return null;

    final cachedAccount = _googleSignIn.currentUser;
    if (cachedAccount != null) {
      return _toUserAccount(cachedAccount);
    }

    // Attempt silent recovery if in-memory cache is null after app restart
    return signInSilently();
  }

  /// Attempts silent authentication with cached Google credentials without user interaction.
  ///
  /// Returns null if silent sign-in fails, credentials have expired, or running offline/unsupported.
  @override
  Future<UserAccount?> signInSilently() async {
    if (!isPlatformSupported) return null;

    try {
      final account = await _googleSignIn.signInSilently(suppressErrors: true);
      if (account == null) return null;
      return _toUserAccount(account);
    } on PlatformException catch (e) {
      debugPrint(
        'GoogleAuthServiceImpl: PlatformException during signInSilently: ${e.code} - ${e.message}',
      );
      return null;
    } catch (e) {
      debugPrint(
          'GoogleAuthServiceImpl: Unexpected error during signInSilently: $e');
      return null;
    }
  }

  /// Initiates interactive Google Sign-In flow.
  ///
  /// Returns authenticated [UserAccount] on success.
  /// Throws [Exception] if the user cancels or authentication fails.
  @override
  Future<UserAccount> signInWithGoogle() async {
    if (!isPlatformSupported) {
      throw UnsupportedError(
        'Google Sign-In is only supported on Android, iOS, and Web platforms.',
      );
    }

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User aborted the native dialog or pressed back/cancel
        throw Exception('Google Sign-In canceled by user');
      }
      return _toUserAccount(account);
    } on PlatformException catch (e) {
      if (e.code == GoogleSignIn.kSignInCanceledError) {
        throw Exception('Google Sign-In canceled by user');
      }
      if (e.code == GoogleSignIn.kNetworkError) {
        throw Exception(
          'Network error during Google Sign-In. Please check your connection.',
        );
      }
      final msg = e.message ?? '';
      final code = e.code;
      if (code == '10' ||
          code.contains('10') ||
          msg.contains('10') ||
          msg.contains('DEVELOPER_ERROR')) {
        throw Exception(
          'Google Play Services configuration error (Code 10: DEVELOPER_ERROR). '
          'Please ensure the Google Sign-In provider is enabled in Firebase Console.',
        );
      }
      throw Exception('Google Sign-In failed: ${msg.isNotEmpty ? msg : code}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Google Sign-In failed: $e');
    }
  }

  /// Signs out of the Google account and clears local authentication state.
  @override
  Future<void> signOut() async {
    if (!isPlatformSupported) return;

    try {
      await _googleSignIn.signOut();
    } on PlatformException catch (e) {
      debugPrint(
        'GoogleAuthServiceImpl: PlatformException during signOut: ${e.code} - ${e.message}',
      );
    } catch (e) {
      debugPrint('GoogleAuthServiceImpl: Unexpected error during signOut: $e');
    }
  }

  /// Safely maps a native [GoogleSignInAccount] into a domain [UserAccount].
  UserAccount _toUserAccount(GoogleSignInAccount account) {
    final rawName = account.displayName?.trim();
    final effectiveDisplayName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (account.email.isNotEmpty && account.email.contains('@')
            ? account.email.split('@').first
            : 'Athlete');

    return UserAccount.fromGoogle(
      id: 'active_session',
      googleUserId: account.id,
      displayName: effectiveDisplayName,
      email: account.email,
      photoUrl: account.photoUrl,
      healthConnectEnabled: false,
    );
  }
}
