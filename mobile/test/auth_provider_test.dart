import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/auth_user.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/services/auth_service.dart';

void main() {
  test('AuthProvider signs in and signs out through AuthService', () async {
    final service = _FakeAuthService();
    final provider = AuthProvider(authService: service, autoInitialize: false);

    expect(provider.isAuthenticated, isFalse);

    await provider.signInWithGoogle();

    expect(provider.isAuthenticated, isTrue);
    expect(provider.user?.email, 'researcher@example.com');

    await provider.signOut();

    expect(provider.isAuthenticated, isFalse);
    expect(provider.user, isNull);

    provider.dispose();
    service.dispose();
  });
}

class _FakeAuthService implements AuthService {
  final _controller = StreamController<AuthUser?>.broadcast();

  AuthUser? _user;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<AuthUser?> signInWithGoogle() async {
    _user = const AuthUser(
      uid: 'test-user',
      displayName: 'Test Researcher',
      email: 'researcher@example.com',
    );
    _controller.add(_user);
    return _user;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}
