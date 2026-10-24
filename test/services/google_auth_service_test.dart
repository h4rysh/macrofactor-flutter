import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
// ignore: depend_on_referenced_packages
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:sique/data/services/google_auth_service.dart';

/// Test double extending [GoogleSignInPlatform] to test [GoogleAuthServiceImpl].
class FakeGoogleSignInPlatform extends GoogleSignInPlatform {
  GoogleSignInUserData? mockUserData;
  bool shouldThrow = false;
  PlatformException? platformExceptionToThrow;
  int initCallCount = 0;
  int signInCallCount = 0;
  int signInSilentlyCallCount = 0;
  int signOutCallCount = 0;

  @override
  Future<void> init({
    List<String> scopes = const <String>[],
    SignInOption signInOption = SignInOption.standard,
    String? hostedDomain,
    String? clientId,
    String? serverClientId,
    bool forceCodeForRefreshToken = false,
  }) async {
    initCallCount++;
  }

  @override
  Future<void> initWithParams(SignInInitParameters params) async {
    initCallCount++;
  }

  @override
  Future<GoogleSignInUserData?> signIn() async {
    signInCallCount++;
    if (platformExceptionToThrow != null) throw platformExceptionToThrow!;
    if (shouldThrow) throw Exception('Simulated sign-in failure');
    return mockUserData;
  }

  @override
  Future<GoogleSignInUserData?> signInSilently() async {
    signInSilentlyCallCount++;
    if (platformExceptionToThrow != null) throw platformExceptionToThrow!;
    if (shouldThrow) throw Exception('Simulated silent sign-in failure');
    return mockUserData;
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    if (platformExceptionToThrow != null) throw platformExceptionToThrow!;
    if (shouldThrow) throw Exception('Simulated sign-out failure');
    mockUserData = null;
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> isSignedIn() async => mockUserData != null;

  @override
  Future<void> clearAuthCache({required String token}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGoogleSignInPlatform fakePlatform;
  late GoogleSignIn googleSignIn;
  late GoogleAuthServiceImpl authService;

  setUp(() {
    fakePlatform = FakeGoogleSignInPlatform();
    GoogleSignInPlatform.instance = fakePlatform;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    googleSignIn = GoogleSignIn();
    authService = GoogleAuthServiceImpl(googleSignIn: googleSignIn);
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('Platform Support & Capability Guard', () {
    test('isPlatformSupported returns true on Android and iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(authService.isPlatformSupported, isTrue);

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(authService.isPlatformSupported, isTrue);
    });

    test('isPlatformSupported returns false on desktop platforms', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(authService.isPlatformSupported, isFalse);

      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(authService.isPlatformSupported, isFalse);

      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(authService.isPlatformSupported, isFalse);
    });

    test('getCurrentUser returns null immediately on unsupported platform',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final user = await authService.getCurrentUser();
      expect(user, isNull);
      expect(fakePlatform.signInSilentlyCallCount, equals(0));
    });

    test('signInSilently returns null immediately on unsupported platform',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final user = await authService.signInSilently();
      expect(user, isNull);
      expect(fakePlatform.signInSilentlyCallCount, equals(0));
    });

    test('signInWithGoogle throws UnsupportedError on unsupported platform',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(
        () => authService.signInWithGoogle(),
        throwsA(isA<UnsupportedError>()),
      );
      expect(fakePlatform.signInCallCount, equals(0));
    });

    test('signOut is a safe no-op on unsupported platform', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      await authService.signOut();
      expect(fakePlatform.signOutCallCount, equals(0));
    });
  });

  group('Silent Authentication & Cached State', () {
    test('signInSilently returns mapped UserAccount on valid credentials',
        () async {
      fakePlatform.mockUserData = GoogleSignInUserData(
        email: 'athlete@sique.test',
        id: 'google-user-12345',
        displayName: 'Sam Athlete',
        photoUrl: 'https://example.com/avatar.jpg',
      );

      final user = await authService.signInSilently();

      expect(user, isNotNull);
      expect(user!.googleUserId, equals('google-user-12345'));
      expect(user.displayName, equals('Sam Athlete'));
      expect(user.email, equals('athlete@sique.test'));
      expect(user.photoUrl, equals('https://example.com/avatar.jpg'));
      expect(user.healthConnectEnabled, isFalse);
    });

    test('signInSilently returns null when no cached session exists', () async {
      fakePlatform.mockUserData = null;

      final user = await authService.signInSilently();
      expect(user, isNull);
    });

    test(
        'signInSilently swallows PlatformException gracefully and returns null',
        () async {
      fakePlatform.platformExceptionToThrow = PlatformException(
        code: 'sign_in_required',
        message: 'Silent auth failed, user must sign in interactively',
      );

      final user = await authService.signInSilently();
      expect(user, isNull);
    });

    test('signInSilently swallows unexpected exceptions and returns null',
        () async {
      fakePlatform.shouldThrow = true;

      final user = await authService.signInSilently();
      expect(user, isNull);
    });

    test(
        'getCurrentUser falls back to silent sign-in if in-memory cache is null',
        () async {
      fakePlatform.mockUserData = GoogleSignInUserData(
        email: 'cached@example.com',
        id: 'cached-id-789',
        displayName: 'Cached User',
      );

      final user = await authService.getCurrentUser();
      expect(user, isNotNull);
      expect(user!.email, equals('cached@example.com'));
      expect(fakePlatform.signInSilentlyCallCount, equals(1));
    });

    test('getCurrentUser returns in-memory account when already populated',
        () async {
      fakePlatform.mockUserData = GoogleSignInUserData(
        email: 'active@example.com',
        id: 'active-id-999',
        displayName: 'Active Runner',
      );

      // Populate in-memory currentUser
      await googleSignIn.signIn();
      expect(googleSignIn.currentUser, isNotNull);

      // Now call getCurrentUser — should use currentUser directly without signInSilently
      final user = await authService.getCurrentUser();
      expect(user, isNotNull);
      expect(user!.displayName, equals('Active Runner'));
      expect(fakePlatform.signInSilentlyCallCount, equals(0));
    });
  });

  group('Interactive Sign-In & Error Handling', () {
    test('signInWithGoogle succeeds and maps user attributes correctly',
        () async {
      fakePlatform.mockUserData = GoogleSignInUserData(
        email: 'sarah.powerlifter@gym.com',
        id: 'google-uid-8888',
        displayName: 'Sarah Power',
        photoUrl: 'https://cdn.example.com/sarah.png',
      );

      final user = await authService.signInWithGoogle();

      expect(user.id, equals('active_session'));
      expect(user.googleUserId, equals('google-uid-8888'));
      expect(user.displayName, equals('Sarah Power'));
      expect(user.email, equals('sarah.powerlifter@gym.com'));
      expect(user.photoUrl, equals('https://cdn.example.com/sarah.png'));
      expect(user.healthConnectEnabled, isFalse);
    });

    test('signInWithGoogle throws cancel exception when user dismisses dialog',
        () async {
      fakePlatform.mockUserData =
          null; // native dialog closed without selection

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Google Sign-In canceled by user'),
          ),
        ),
      );
    });

    test(
        'signInWithGoogle handles kSignInCanceledError code from PlatformException',
        () async {
      fakePlatform.platformExceptionToThrow = PlatformException(
        code: GoogleSignIn.kSignInCanceledError,
        message: 'User tapped back button',
      );

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Google Sign-In canceled by user'),
          ),
        ),
      );
    });

    test('signInWithGoogle handles kNetworkError code from PlatformException',
        () async {
      fakePlatform.platformExceptionToThrow = PlatformException(
        code: GoogleSignIn.kNetworkError,
        message: 'No internet connection',
      );

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network error during Google Sign-In'),
          ),
        ),
      );
    });

    test(
        'signInWithGoogle wraps unexpected platform errors in descriptive Exception',
        () async {
      fakePlatform.platformExceptionToThrow = PlatformException(
        code: 'developer_error',
        message: 'Misconfigured SHA-1 fingerprint',
      );

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Misconfigured SHA-1 fingerprint'),
          ),
        ),
      );
    });

    test(
        'signInWithGoogle maps error 10 / DEVELOPER_ERROR to actionable Firebase configuration message',
        () async {
      fakePlatform.platformExceptionToThrow = PlatformException(
        code: '10',
        message: 'DEVELOPER_ERROR',
      );

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            allOf(
              contains('DEVELOPER_ERROR'),
              contains('Firebase Console'),
            ),
          ),
        ),
      );
    });
  });

  group('Display Name Fallback Logic', () {
    test('extracts email username prefix when displayName is null', () async {
      fakePlatform.mockUserData = GoogleSignInUserData(
        email: 'strength_coach@domain.org',
        id: 'no-name-id',
        displayName: null,
      );

      final user = await authService.signInWithGoogle();
      expect(user.displayName, equals('strength_coach'));
    });

    test('extracts email username prefix when displayName is empty whitespace',
        () async {
      fakePlatform.mockUserData = GoogleSignInUserData(
        email: 'iron_lifter@example.com',
        id: 'whitespace-name-id',
        displayName: '   ',
      );

      final user = await authService.signInWithGoogle();
      expect(user.displayName, equals('iron_lifter'));
    });

    test('falls back to Athlete when email has no username or at sign',
        () async {
      fakePlatform.mockUserData = GoogleSignInUserData(
        email: '',
        id: 'empty-email-id',
        displayName: null,
      );

      final user = await authService.signInWithGoogle();
      expect(user.displayName, equals('Athlete'));
    });
  });

  group('Sign Out Lifecycle', () {
    test('signOut invokes platform signOut and clears user state', () async {
      fakePlatform.mockUserData = GoogleSignInUserData(
        email: 'signout@example.com',
        id: 'signout-id',
        displayName: 'Signout Test',
      );

      await authService.signOut();

      expect(fakePlatform.signOutCallCount, equals(1));
      expect(fakePlatform.mockUserData, isNull);
    });

    test('signOut absorbs platform exceptions safely without throwing',
        () async {
      fakePlatform.platformExceptionToThrow = PlatformException(
        code: 'sign_out_failed',
        message: 'Could not disconnect from Google Services',
      );

      // Should complete without throwing
      await expectLater(authService.signOut(), completes);
      expect(fakePlatform.signOutCallCount, equals(1));
    });

    test('signOut absorbs unexpected exceptions safely without throwing',
        () async {
      fakePlatform.shouldThrow = true;

      await expectLater(authService.signOut(), completes);
      expect(fakePlatform.signOutCallCount, equals(1));
    });
  });
}
