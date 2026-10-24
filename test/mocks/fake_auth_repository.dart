import 'dart:async';

import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/repositories/auth_repository.dart';

/// Test double simulating complete authentication repository behaviors in-memory.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    UserAccount? initialUser,
    this.isConfigured = true,
  }) : _currentUser = initialUser {
    if (initialUser != null) {
      _usersByEmail[initialUser.email.toLowerCase()] = initialUser;
    }
  }

  final StreamController<UserAccount?> _authStateController =
      StreamController<UserAccount?>.broadcast();

  final Map<String, String> _passwordsByEmail = {};
  final Map<String, UserAccount> _usersByEmail = {};

  UserAccount? _currentUser;
  bool _throwOnNextOperation = false;
  String? _simulatedErrorMessage;

  @override
  bool isConfigured;

  @override
  Stream<UserAccount?> get authStateChanges => _authStateController.stream;

  @override
  Future<UserAccount?> getCurrentUser() async {
    _checkFaultInjection();
    return _currentUser;
  }

  @override
  Future<UserAccount> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _checkFaultInjection();
    if (!isConfigured) {
      throw StateError('Sign-in unavailable: Firebase not configured');
    }

    final key = email.trim().toLowerCase();
    final user = _usersByEmail[key];
    if (user == null) {
      throw ArgumentError('User not found');
    }

    final savedPassword = _passwordsByEmail[key];
    if (savedPassword != password) {
      throw ArgumentError('Invalid email or password');
    }

    _currentUser = user;
    _authStateController.add(user);
    return user;
  }

  @override
  Future<UserAccount> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _checkFaultInjection();
    if (!isConfigured) {
      throw StateError('Sign-in unavailable: Firebase not configured');
    }

    final key = email.trim().toLowerCase();
    if (_usersByEmail.containsKey(key)) {
      throw ArgumentError('An account already exists for this email address.');
    }

    final now = DateTime.now();
    final newUser = UserAccount(
      id: 'usr_${now.millisecondsSinceEpoch}',
      googleUserId: 'email_${now.millisecondsSinceEpoch}',
      displayName: displayName ?? email.split('@').first,
      email: email.trim(),
      authProvider: AuthProviderType.email,
      createdAt: now,
      updatedAt: now,
      isAuthenticated: true,
    );

    _passwordsByEmail[key] = password;
    _usersByEmail[key] = newUser;
    _currentUser = newUser;
    _authStateController.add(newUser);
    return newUser;
  }

  @override
  Future<UserAccount> signInWithGoogle() async {
    _checkFaultInjection();
    if (!isConfigured) {
      throw StateError('Sign-in unavailable: Firebase not configured');
    }

    final now = DateTime.now();
    final googleUser = UserAccount(
      id: 'google_user_123',
      googleUserId: 'gid_123456789',
      displayName: 'Google Athlete',
      email: 'athlete@gmail.com',
      photoUrl: 'https://lh3.googleusercontent.com/photo.jpg',
      authProvider: AuthProviderType.google,
      createdAt: now,
      updatedAt: now,
      isAuthenticated: true,
    );

    _currentUser = googleUser;
    _authStateController.add(googleUser);
    return googleUser;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    _checkFaultInjection();
    if (!isConfigured) {
      throw StateError('Sign-in unavailable: Firebase not configured');
    }

    final key = email.trim().toLowerCase();
    if (!_usersByEmail.containsKey(key)) {
      throw ArgumentError('No user record found for this email address.');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _checkFaultInjection();
    if (_currentUser == null) {
      throw StateError('No active user session');
    }

    if (_currentUser!.authProvider != AuthProviderType.email) {
      throw UnsupportedError(
          'Password change is only supported for email accounts.');
    }

    final key = _currentUser!.email.toLowerCase();
    final savedPassword = _passwordsByEmail[key];
    if (savedPassword != currentPassword) {
      throw ArgumentError('Current password does not match.');
    }

    _passwordsByEmail[key] = newPassword;
  }

  @override
  Future<void> deleteAccount({String? password}) async {
    _checkFaultInjection();
    if (_currentUser == null) {
      throw StateError('No active user session');
    }

    // Provider-aware re-authentication check
    if (_currentUser!.authProvider == AuthProviderType.email) {
      if (password == null || password.isEmpty) {
        throw ArgumentError('Password is required to delete an email account.');
      }
      final key = _currentUser!.email.toLowerCase();
      if (_passwordsByEmail[key] != password) {
        throw ArgumentError('Invalid password for account deletion.');
      }
      _passwordsByEmail.remove(key);
      _usersByEmail.remove(key);
    } else if (_currentUser!.authProvider == AuthProviderType.google) {
      // Google account deletion: simulates successful fresh Google re-authentication
    }

    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<void> signOut() async {
    _checkFaultInjection();
    _currentUser = null;
    _authStateController.add(null);
  }

  void injectFault(String errorMessage) {
    _throwOnNextOperation = true;
    _simulatedErrorMessage = errorMessage;
  }

  void _checkFaultInjection() {
    if (_throwOnNextOperation) {
      _throwOnNextOperation = false;
      throw Exception(_simulatedErrorMessage ?? 'Simulated auth fault');
    }
  }

  void dispose() {
    _authStateController.close();
  }
}
