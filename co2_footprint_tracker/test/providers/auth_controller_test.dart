import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:co2_footprint_tracker/providers/auth_provider.dart';
import 'package:co2_footprint_tracker/services/auth_service.dart';
import 'package:co2_footprint_tracker/models/user.dart';

class MockAuthService extends Mock implements AuthService {}

class FakeFirebaseAuthException extends Fake implements FirebaseAuthException {
  @override
  final String code;
  @override
  final String? message;
  FakeFirebaseAuthException({required this.code, this.message});
}

class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}

void main() {
  setUpAll(() {
    // Register fallback value to allow Mocktail's any() matcher on custom classes
    registerFallbackValue(UserModel(email: ''));
  });

  group('AuthController Unit Tests - Credentials Validation', () {
    late ProviderContainer container;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      
      // Inject our Mock service directly into Riverpod's dependency graph
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    // ── Login Tests ────────────────────────────────────────────────────────
    
    test('Login: Returns TRUE and clears errors on CORRECT credentials', () async {
      final mockCredential = MockUserCredential();
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('user123');
      when(() => mockCredential.user).thenReturn(mockUser);

      when(() => mockAuthService.signInWithEmail(email: 'test@example.com', password: 'correct_password'))
          .thenAnswer((_) async => mockCredential);

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.loginWithEmail(email: 'test@example.com', password: 'correct_password');

      expect(result, isTrue, reason: 'Login should succeed with correct credentials');
      expect(container.read(authControllerProvider).error, isNull);
      expect(container.read(authControllerProvider).isLoading, isFalse);
    });

    test('Login: Returns FALSE and maps message on FALSE credentials (wrong password)', () async {
      when(() => mockAuthService.signInWithEmail(email: 'test@example.com', password: 'wrong_password'))
          .thenThrow(FakeFirebaseAuthException(code: 'wrong-password'));

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.loginWithEmail(email: 'test@example.com', password: 'wrong_password');

      expect(result, isFalse, reason: 'Login should fail with wrong credentials');
      expect(container.read(authControllerProvider).error, 'Incorrect email or password.');
    });
    
    test('Login: Maps invalid-credential properly on FALSE credentials', () async {
      when(() => mockAuthService.signInWithEmail(email: 'bad@example.com', password: 'bad'))
          .thenThrow(FakeFirebaseAuthException(code: 'invalid-credential'));

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.loginWithEmail(email: 'bad@example.com', password: 'bad');

      expect(result, isFalse);
      expect(container.read(authControllerProvider).error, 'Incorrect email or password.');
    });


    // ── Registration Tests ──────────────────────────────────────────────────
    
    test('Signup: Returns TRUE on unique email and registers user', () async {
      final mockCredential = MockUserCredential();
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('user123');
      when(() => mockCredential.user).thenReturn(mockUser);

      // Successfully sign up in Firebase
      when(() => mockAuthService.signUpWithEmail(email: 'new@example.com', password: 'password123'))
          .thenAnswer((_) async => mockCredential);

      // Successfully create document in Firestore
      when(() => mockAuthService.createUserDocument(userId: 'user123', userData: any(named: 'userData')))
          .thenAnswer((_) async {});

      final controller = container.read(authControllerProvider.notifier);
      final userData = UserModel(email: 'new@example.com', displayName: 'New User');

      final result = await controller.registerWithEmail(email: 'new@example.com', password: 'password123', userData: userData);

      expect(result, isTrue, reason: 'Registration should succeed');
      expect(container.read(authControllerProvider).error, isNull);
    });

    test('Signup: Returns FALSE if email is ALREADY IN USE', () async {
      when(() => mockAuthService.signUpWithEmail(email: 'used@example.com', password: 'password123'))
          .thenThrow(FakeFirebaseAuthException(code: 'email-already-in-use'));

      final controller = container.read(authControllerProvider.notifier);
      final userData = UserModel(email: 'used@example.com');

      final result = await controller.registerWithEmail(email: 'used@example.com', password: 'password123', userData: userData);

      expect(result, isFalse, reason: 'Registration should fail for existing email');
      expect(container.read(authControllerProvider).error, 'This email is already registered.');
    });
  });
}
