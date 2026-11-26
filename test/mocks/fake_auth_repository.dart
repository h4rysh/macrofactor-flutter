import 'dart:async';

import 'package:sique/domain/models/user_account.dart';
import 'package:sique/domain/repositories/auth_repository.dart';

/// Test double simulating streamlined Google + Guest authentication behaviors in-memory.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    UserAccount? initialUser,
    this.isConfigured = true,
  }) : _currentUser = initialUser;

  final StreamController<UserAccount?> _authStateController =
      StreamController<UserAccount?>.broadcast();

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
  Future<void> deleteAccount() async {
    _checkFaultInjection();
    if (_currentUser == null) {
      throw StateError('No active user session');
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
