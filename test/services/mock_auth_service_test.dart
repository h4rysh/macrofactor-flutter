import 'package:flutter_test/flutter_test.dart';
import 'package:macro_factor_app/data/services/mock_auth_service.dart';
import 'package:macro_factor_app/domain/models/user_account.dart';

void main() {
  group('MockAuthService Test Suite', () {
    late MockAuthService authService;

    setUp(() {
      authService = MockAuthService();
    });

    test('getCurrentUser starts null and increments call telemetry', () async {
      expect(authService.getCurrentUserCallCount, equals(0));

      final user = await authService.getCurrentUser();
      expect(user, isNull);
      expect(authService.getCurrentUserCallCount, equals(1));
    });

    test('initialUser constructor sets the starting session', () async {
      final initial = UserAccount.fromGoogle(
        googleUserId: 'init_1',
        displayName: 'Preloaded User',
        email: 'preloaded@test.com',
      );

      final service = MockAuthService(initialUser: initial);
      final user = await service.getCurrentUser();

      expect(user, equals(initial));
      expect(user?.isAuthenticated, isTrue);
    });

    test('signInWithGoogle authenticates mock user and tracks call count',
        () async {
      expect(authService.signInWithGoogleCallCount, equals(0));

      final user = await authService.signInWithGoogle();

      expect(authService.signInWithGoogleCallCount, equals(1));
      expect(user.isAuthenticated, isTrue);
      expect(user.displayName, equals('Alex Mercer'));
      expect(user.email, equals('alex.mercer@gmail.com'));
      expect(user.googleUserId, equals('google_1092837465'));

      // Subsequent getCurrentUser reflects authenticated session
      final current = await authService.getCurrentUser();
      expect(current, equals(user));
    });

    test('signInSilently returns active session if present', () async {
      expect(await authService.signInSilently(), isNull);
      expect(authService.signInSilentlyCallCount, equals(1));

      await authService.signInWithGoogle();
      final silent = await authService.signInSilently();

      expect(silent, isNotNull);
      expect(silent?.displayName, equals('Alex Mercer'));
      expect(authService.signInSilentlyCallCount, equals(2));
    });

    test('signInWithGoogle throws Exception when shouldFailSignIn is true',
        () async {
      authService.shouldFailSignIn = true;
      authService.signInErrorMessage = 'User aborted OAuth screen';

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User aborted OAuth screen'),
          ),
        ),
      );

      expect(authService.signInWithGoogleCallCount, equals(1));
      expect(await authService.getCurrentUser(), isNull);
    });

    test('signOut clears active user and increments counter', () async {
      await authService.signInWithGoogle();
      expect(await authService.getCurrentUser(), isNotNull);

      await authService.signOut();
      expect(authService.signOutCallCount, equals(1));
      expect(await authService.getCurrentUser(), isNull);
    });

    test('setCurrentUser and reset manage state isolation', () async {
      final custom = UserAccount.fromGoogle(
        googleUserId: 'custom_1',
        displayName: 'Custom Athlete',
        email: 'custom@athletic.com',
      );

      authService.setCurrentUser(custom);
      expect(await authService.getCurrentUser(), equals(custom));

      authService.shouldFailSignIn = true;
      authService.reset();

      expect(authService.getCurrentUserCallCount, equals(0));
      expect(authService.signInWithGoogleCallCount, equals(0));
      expect(authService.signOutCallCount, equals(0));
      expect(authService.shouldFailSignIn, isFalse);
      expect(await authService.getCurrentUser(), isNull);
    });
  });
}
