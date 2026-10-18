import 'dart:async';

import 'package:macro_factor_app/domain/models/user_account.dart';
import 'package:macro_factor_app/domain/services/auth_service.dart';

/// Deterministic mock implementation of [AuthService] for headless tests and CI.
class MockAuthService implements AuthService {
  MockAuthService({
    UserAccount? initialUser,
    UserAccount? mockUser,
    this.shouldFailSignIn = false,
    this.signInErrorMessage = 'Google Sign-In canceled by user',
    this.delay = Duration.zero,
  })  : _currentUser = initialUser,
        _mockUser = mockUser ?? _defaultMockUser();

  UserAccount? _currentUser;
  final UserAccount _mockUser;

  /// Whether [signInWithGoogle] should throw an error.
  bool shouldFailSignIn;

  /// Error message thrown when [shouldFailSignIn] is true.
  String signInErrorMessage;

  /// Simulated asynchronous latency.
  Duration delay;

  // Telemetry & Call tracking for test assertions
  int getCurrentUserCallCount = 0;
  int signInSilentlyCallCount = 0;
  int signInWithGoogleCallCount = 0;
  int signOutCallCount = 0;

  @override
  Future<UserAccount?> getCurrentUser() async {
    getCurrentUserCallCount++;
    if (delay > Duration.zero) await Future.delayed(delay);
    return _currentUser;
  }

  @override
  Future<UserAccount?> signInSilently() async {
    signInSilentlyCallCount++;
    if (delay > Duration.zero) await Future.delayed(delay);
    return _currentUser;
  }

  @override
  Future<UserAccount> signInWithGoogle() async {
    signInWithGoogleCallCount++;
    if (delay > Duration.zero) await Future.delayed(delay);

    if (shouldFailSignIn) {
      throw Exception(signInErrorMessage);
    }

    _currentUser = _mockUser;
    return _mockUser;
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    if (delay > Duration.zero) await Future.delayed(delay);
    _currentUser = null;
  }

  /// Sets the active user directly for test setup.
  void setCurrentUser(UserAccount? user) {
    _currentUser = user;
  }

  /// Resets call counters and state for test isolation.
  void reset() {
    getCurrentUserCallCount = 0;
    signInSilentlyCallCount = 0;
    signInWithGoogleCallCount = 0;
    signOutCallCount = 0;
    shouldFailSignIn = false;
    _currentUser = null;
  }

  static UserAccount _defaultMockUser() {
    return UserAccount.fromGoogle(
      id: 'active_session',
      googleUserId: 'google_1092837465',
      displayName: 'Alex Mercer',
      email: 'alex.mercer@gmail.com',
      photoUrl: 'https://lh3.googleusercontent.com/a/mock_avatar_id',
      healthConnectEnabled: true,
      lastHealthSyncTime: DateTime.now().subtract(const Duration(hours: 2)),
    );
  }
}
