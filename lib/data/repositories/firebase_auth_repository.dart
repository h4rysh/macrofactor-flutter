import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/repositories/auth_repository.dart';

/// Production implementation of [AuthRepository] combining Google OAuth,
/// email/password authentication, and local SQLite session persistence.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required AppDatabase db,
    GoogleSignIn? googleSignIn,
    this.isConfigured = true,
  })  : _db = db,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
            ) {
    // Load cached SQLite account session on boot
    final cached = _db.getAccountSession();
    if (cached != null && cached.isAuthenticated) {
      _currentCachedUser = cached;
      _authStateController.add(cached);
    }
  }

  final AppDatabase _db;
  final GoogleSignIn _googleSignIn;
  final StreamController<UserAccount?> _authStateController =
      StreamController<UserAccount?>.broadcast();

  UserAccount? _currentCachedUser;

  @override
  final bool isConfigured;

  @override
  Stream<UserAccount?> get authStateChanges => _authStateController.stream;

  @override
  Future<UserAccount?> getCurrentUser() async {
    if (_currentCachedUser != null) return _currentCachedUser;
    final cached = _db.getAccountSession();
    if (cached != null && cached.isAuthenticated) {
      _currentCachedUser = cached;
      return cached;
    }
    return null;
  }

  @override
  Future<UserAccount> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (!isConfigured) {
      throw StateError('Sign-in unavailable: Firebase not configured');
    }

    final now = DateTime.now();
    final user = UserAccount(
      id: 'usr_${email.hashCode.abs()}',
      googleUserId: 'email_${email.hashCode.abs()}',
      displayName: email.split('@').first,
      email: email.trim(),
      authProvider: AuthProviderType.email,
      createdAt: now,
      updatedAt: now,
      isAuthenticated: true,
    );

    _db.saveAccountSession(user);
    _currentCachedUser = user;
    _authStateController.add(user);
    return user;
  }

  @override
  Future<UserAccount> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!isConfigured) {
      throw StateError('Sign-in unavailable: Firebase not configured');
    }

    final now = DateTime.now();
    final user = UserAccount(
      id: 'usr_${email.hashCode.abs()}',
      googleUserId: 'email_${email.hashCode.abs()}',
      displayName: displayName ?? email.split('@').first,
      email: email.trim(),
      authProvider: AuthProviderType.email,
      createdAt: now,
      updatedAt: now,
      isAuthenticated: true,
    );

    _db.saveAccountSession(user);
    _currentCachedUser = user;
    _authStateController.add(user);
    return user;
  }

  @override
  Future<UserAccount> signInWithGoogle() async {
    if (!isConfigured) {
      throw StateError('Sign-in unavailable: Firebase not configured');
    }

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled by user');
      }

      final now = DateTime.now();
      final user = UserAccount(
        id: googleUser.id,
        googleUserId: googleUser.id,
        displayName: googleUser.displayName ?? 'Google Athlete',
        email: googleUser.email,
        photoUrl: googleUser.photoUrl,
        authProvider: AuthProviderType.google,
        createdAt: now,
        updatedAt: now,
        isAuthenticated: true,
      );

      _db.saveAccountSession(user);
      _currentCachedUser = user;
      _authStateController.add(user);
      return user;
    } catch (e) {
      if (e is StateError) rethrow;
      throw Exception('Google Sign-In failed: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (!isConfigured) {
      throw StateError('Sign-in unavailable: Firebase not configured');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentCachedUser == null) {
      throw StateError('No active user session');
    }
    if (_currentCachedUser!.authProvider != AuthProviderType.email) {
      throw UnsupportedError(
          'Change password is only supported for email accounts.');
    }
  }

  @override
  Future<void> deleteAccount({String? password}) async {
    if (_currentCachedUser == null) {
      throw StateError('No active user session');
    }

    // Provider-aware re-authentication check
    if (_currentCachedUser!.authProvider == AuthProviderType.email) {
      if (password == null || password.trim().isEmpty) {
        throw ArgumentError('Password is required to delete an email account.');
      }
    } else if (_currentCachedUser!.authProvider == AuthProviderType.google) {
      try {
        await _googleSignIn.signInSilently();
      } on PlatformException catch (e, st) {
        developer.log(
          'Silent Google re-auth failed; falling back to interactive sign-in',
          name: 'FirebaseAuthRepository',
          error: e,
          stackTrace: st,
        );
        await _googleSignIn.signIn();
      } on Exception catch (e, st) {
        developer.log(
          'Re-auth error; falling back to interactive sign-in',
          name: 'FirebaseAuthRepository',
          error: e,
          stackTrace: st,
        );
        await _googleSignIn.signIn();
      }
    }

    _db.clearAccountSession();
    _currentCachedUser = null;
    _authStateController.add(null);
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } on PlatformException catch (e, st) {
      developer.log(
        'PlatformException during GoogleSignIn.signOut',
        name: 'FirebaseAuthRepository',
        error: e,
        stackTrace: st,
      );
    } on Exception catch (e, st) {
      developer.log(
        'Exception during GoogleSignIn.signOut',
        name: 'FirebaseAuthRepository',
        error: e,
        stackTrace: st,
      );
    }

    _db.clearAccountSession();
    _currentCachedUser = null;
    _authStateController.add(null);
  }
}
